# Pipeline of the data-driven nowcast (R/nowcast.R, stan/nowcast.stan):
# fitted to the reports up to each of a series of dates, projected to the
# last report, and scored against it.
#   targets::tar_make(script = "_targets_nowcast.R", store = "_targets_nowcast")
# NOWCAST_DATES and NOWCAST_COLUMNS (separated by commas) choose the fits;
# NOWCAST_ITERATIONS the warm-up and kept draws of each chain; NOWCAST_MODEL
# the form of the model (by default the simpler stan/nowcast_simple.stan),
# either one Stan file for every column or pairs <column>=<Stan file>, or
# "joint" for stan/nowcast_joint.stan, which fits cases and deaths together;
# NOWCAST_TARGET "last" (the default) projects counts to the last report, to
# score them against it, and "eventual" until every delay has elapsed, for
# the eventual counts and case fatality ratio.
# Where both cases and deaths are fitted to a date, the case fatality ratio
# by onset week is the ratio of their projections.

library(targets)
library(tarchetypes)

# PIPELINE_WORKERS fits at once (each runs its chains in parallel)
n_workers <- as.integer(Sys.getenv("PIPELINE_WORKERS", "1"))
tar_option_set(packages = c("dplyr", "tidyr", "ggplot2"),
               controller = if(n_workers > 1)
                 crew::crew_controller_local(workers = n_workers, seconds_idle = 30))
tar_source("R")

f_env <- function(name, default) {
  value <- trimws(strsplit(Sys.getenv(name, ""), ",")[[1]])
  value <- value[value != ""]
  if(length(value) == 0) default else value
}
grid <- tidyr::expand_grid(
  date = f_env("NOWCAST_DATES", c("2026-08-01", "2026-09-02", "2026-09-30")),
  column = f_env("NOWCAST_COLUMNS", c("cases_reported", "deaths_reported")))
grid$id <- paste0(gsub("-", "", grid$date), "_", sub("_reported$", "", grid$column))
# the Stan file of each column
models <- f_env("NOWCAST_MODEL", "stan/nowcast_simple.stan")
is_joint <- identical(models, "joint")
if(is_joint) {
  grid <- dplyr::distinct(grid, date)
  grid$id <- gsub("-", "", grid$date)
  grid$model <- "stan/nowcast_joint.stan"
} else if(any(grepl("=", models))) {
  pairs <- strsplit(models, "=", fixed = TRUE)
  models <- setNames(vapply(pairs, `[`, "", 2), vapply(pairs, `[`, "", 1))
  if(!all(grid$column %in% names(models)))
    stop("NOWCAST_MODEL names no Stan file for ", setdiff(grid$column, names(models)))
  grid$model <- unname(models[grid$column])
} else grid$model <- models
iterations <- as.integer(f_env("NOWCAST_ITERATIONS", "500"))

fits <- if(is_joint) tar_map(
  # each fit gives a list of the fits of cases and of deaths, with paired draws
  values = grid, names = "id",
  tar_target(nowcast, fit_nowcast_joint(
    prepare_bvd_deaths_analysis(nowcast_snapshots, as.Date(date)),
    nowcast_date_target, iter_warmup = iterations, iter_sampling = iterations,
    model_file = nowcast_model)),
  tar_target(nowcast_score, lapply(nowcast, score_nowcast,
    prepare_bvd_deaths_analysis(nowcast_snapshots, nowcast_date_last)$snapshots))) else tar_map(
  values = grid, names = "id",
  tar_target(nowcast, fit_nowcast(
    prepare_bvd_deaths_analysis(nowcast_snapshots, as.Date(date)), column,
    nowcast_date_target, iter_warmup = iterations, iter_sampling = iterations,
    model_file = nowcast_model[match(model, nowcast_stan)])),
  tar_target(nowcast_score, score_nowcast(
    nowcast, prepare_bvd_deaths_analysis(nowcast_snapshots, nowcast_date_last)$snapshots)))
# the fits of the joint model are lists of two, which are joined into one list
f_combine <- function(name, targets) {
  if(is_joint)
    tar_combine_raw(name, targets, command = quote(do.call(c, unname(list(!!!.x)))))
  else tar_combine_raw(name, targets, command = quote(list(!!!.x)))
}

list(
  # the raw files are not tracked: scripts/decrypt_bvd_data.sh restores them
  tar_target(nowcast_files,
             list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$",
                        full.names = TRUE),
             format = "file", cue = tar_cue(mode = "always")),
  tar_target(nowcast_snapshots, build_bvd_snapshots(nowcast_files)),
  tar_target(nowcast_date_last, max(nowcast_snapshots$date_reported)),
  # a year after the last report is beyond the longest delay of any onset day
  tar_target(nowcast_date_target,
             nowcast_date_last + if(f_env("NOWCAST_TARGET", "last") == "eventual") 365 else 0),
  tar_target(nowcast_stan, c(!!!unique(grid$model)), format = "file"),
  # compiled once here, so that fits run at once do not compile them together
  tar_target(nowcast_model, {
    for(f in nowcast_stan) cmdstanr::cmdstan_model(f)
    nowcast_stan
  }, deployment = "main"),
  fits,
  f_combine("nowcast_scores", fits[["nowcast_score"]]),
  tar_target(files_nowcast, write_nowcast_outputs(nowcast_scores, "outputs/nowcast"),
             format = "file"),
  f_combine("nowcast_fits", fits[["nowcast"]]),
  tar_target(nowcast_cfr_table, {
    analysis_later <- prepare_bvd_deaths_analysis(nowcast_snapshots, nowcast_date_last)
    columns <- vapply(nowcast_fits, `[[`, "", "column")
    dates <- vapply(nowcast_fits, function(x) as.character(x$date_now), "")
    dplyr::bind_rows(lapply(unique(dates), function(d) {
      i_cases <- which(dates == d & columns == "cases_reported")
      i_deaths <- which(dates == d & columns == "deaths_reported")
      if(length(i_cases) == 1 && length(i_deaths) == 1)
        nowcast_cfr(nowcast_fits[[i_cases]], nowcast_fits[[i_deaths]], analysis_later)
    }))
  }),
  tar_target(files_nowcast_cfr, write_nowcast_cfr(nowcast_cfr_table, "outputs/nowcast"),
             format = "file")
)

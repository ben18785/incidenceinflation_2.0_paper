# Pipeline of the data-driven nowcast (R/nowcast.R, stan/nowcast.stan):
# fitted to the reports up to each of a series of dates, projected to the
# last report, and scored against it.
#   targets::tar_make(script = "_targets_nowcast.R", store = "_targets_nowcast")
# NOWCAST_DATES and NOWCAST_COLUMNS (separated by commas) choose the fits;
# NOWCAST_ITERATIONS the warm-up and kept draws of each chain; NOWCAST_MODEL
# the form of the model (by default the simpler stan/nowcast_simple.stan).
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
iterations <- as.integer(f_env("NOWCAST_ITERATIONS", "500"))

fits <- tar_map(
  values = grid, names = "id",
  tar_target(nowcast, fit_nowcast(
    prepare_bvd_deaths_analysis(nowcast_snapshots, as.Date(date)), column,
    nowcast_date_last, iter_warmup = iterations, iter_sampling = iterations,
    model_file = nowcast_model)),
  tar_target(nowcast_score, score_nowcast(
    nowcast, prepare_bvd_deaths_analysis(nowcast_snapshots, nowcast_date_last)$snapshots)))

list(
  # the raw files are not tracked: scripts/decrypt_bvd_data.sh restores them
  tar_target(nowcast_files,
             list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$",
                        full.names = TRUE),
             format = "file", cue = tar_cue(mode = "always")),
  tar_target(nowcast_snapshots, build_bvd_snapshots(nowcast_files)),
  tar_target(nowcast_date_last, max(nowcast_snapshots$date_reported)),
  tar_target(nowcast_stan, f_env("NOWCAST_MODEL", "stan/nowcast_simple.stan"),
             format = "file"),
  # compiled once here, so that fits run at once do not compile it together
  tar_target(nowcast_model, {
    cmdstanr::cmdstan_model(nowcast_stan)
    nowcast_stan
  }, deployment = "main"),
  fits,
  tar_combine(nowcast_scores, fits[["nowcast_score"]],
              command = list(!!!.x)),
  tar_target(files_nowcast, write_nowcast_outputs(nowcast_scores, "outputs/nowcast"),
             format = "file"),
  tar_combine(nowcast_fits, fits[["nowcast"]], command = list(!!!.x)),
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

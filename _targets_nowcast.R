# Pipeline of the data-driven nowcast (R/nowcast.R, stan/nowcast.stan):
# fitted to the reports up to each of a series of dates, projected to the
# last report, and scored against it.
#   targets::tar_make(script = "_targets_nowcast.R", store = "_targets_nowcast")
# NOWCAST_DATES and NOWCAST_COLUMNS (separated by commas) choose the fits;
# NOWCAST_ITERATIONS the warm-up and kept draws of each chain.

library(targets)
library(tarchetypes)

tar_option_set(packages = c("dplyr", "tidyr", "ggplot2"))
tar_source("R")

f_env <- function(name, default) {
  value <- trimws(strsplit(Sys.getenv(name, ""), ",")[[1]])
  value <- value[value != ""]
  if(length(value) == 0) default else value
}
grid <- tidyr::expand_grid(
  date = f_env("NOWCAST_DATES", c("2026-08-01", "2026-09-02", "2026-09-30")),
  column = f_env("NOWCAST_COLUMNS", "cases_reported"))
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
  tar_target(nowcast_model, "stan/nowcast.stan", format = "file"),
  fits,
  tar_combine(nowcast_scores, fits[["nowcast_score"]],
              command = list(!!!.x)),
  tar_target(files_nowcast, write_nowcast_outputs(nowcast_scores, "outputs/nowcast"),
             format = "file")
)

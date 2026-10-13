# Pipeline of the experiments of experiments/experiments.yml: one target per
# chain. On GitHub Actions each job makes one chain; on one machine
#   targets::tar_make(script = "_targets_experiments.R", store = "_targets_experiments")
# makes them all. BVD_EXPERIMENTS (names separated by commas) and BVD_CHAIN
# choose which chains are in the pipeline. A chain stops after
# BVD_TIME_LIMIT minutes if that is set, and is carried on from the file of
# its progress in the folder BVD_RESUME_DIR (default states/) if there is one.

library(targets)
library(tarchetypes)

.libPaths(c(file.path(getwd(), ".lib"), .libPaths()))

n_workers <- as.integer(Sys.getenv("PIPELINE_WORKERS", "1"))
tar_option_set(
  packages = c("dplyr", "tidyr", "purrr", "ggplot2", "rlang", "incidenceinflation"),
  library = .libPaths(),
  controller = if(n_workers > 1)
    crew::crew_controller_local(workers = n_workers, seconds_idle = 30))

tar_source("R")

f_env <- function(name) {
  value <- trimws(strsplit(Sys.getenv(name, ""), ",")[[1]])
  if(length(value) == 0 || all(value == "")) NULL else value
}
experiments <- bvd_experiments()
chain_wanted <- f_env("BVD_CHAIN")
grid <- bvd_experiment_chains(experiments, f_env("BVD_EXPERIMENTS"),
                              if(!is.null(chain_wanted)) as.integer(chain_wanted))
grid$settings <- experiments[grid$experiment]

grid$chain_index <- grid$chain
chains <- tar_map(
  values = grid[, c("id", "chain_index", "settings")], names = "id",
  tar_target(chain, run_bvd_experiment_chain(
    settings, chain_index, bvd_snapshots, resume = bvd_progress_saved(id),
    time_limit = bvd_time_limit())))

list(
  # the raw files are not tracked: scripts/decrypt_bvd_data.sh restores them
  tar_target(bvd_files,
             list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$",
                        full.names = TRUE),
             format = "file", cue = tar_cue(mode = "always")),
  tar_target(bvd_snapshots, build_bvd_snapshots(bvd_files)),
  chains,
  tar_combine(experiment_chains, chains, command = list(!!!.x)),
  tar_target(files_experiments,
             write_bvd_experiment_results(experiment_chains, bvd_snapshots,
                                          "outputs/bvd_experiments"),
             format = "file")
)

# Pipeline of the fits to simulated data of R/misdated_simulation.R, for
# GitHub Actions, where each job makes the fits of one scenario; on one
# machine
#   targets::tar_make(script = "_targets_simulations.R", store = "_targets_simulations")
# makes them all (the same targets are in _targets.R). MISDATED_SCENARIOS
# (names separated by commas) chooses the scenarios.

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

n_replicates_misdated <- as.integer(Sys.getenv("PIPELINE_REPLICATES_MISDATED", "3"))
n_chains_misdated <- as.integer(Sys.getenv("PIPELINE_CHAINS_MISDATED", "3"))
n_iterations_misdated <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_MISDATED", "400"))
scenarios_wanted <- trimws(strsplit(Sys.getenv("MISDATED_SCENARIOS", ""), ",")[[1]])
scenarios_wanted <- scenarios_wanted[scenarios_wanted != ""]
if(length(scenarios_wanted) == 0)
  scenarios_wanted <- misdated_scenarios()$scenario
unknown <- setdiff(scenarios_wanted, misdated_scenarios()$scenario)
if(length(unknown) > 0)
  stop(paste0("Unknown scenarios: ", paste(unknown, collapse = ", "), "."))

list(
  tar_target(misdated_sim_grid,
             tidyr::expand_grid(scenario = scenarios_wanted,
                                replicate = seq_len(n_replicates_misdated))),
  tar_target(misdated_sim_dataset,
             simulate_misdated_dataset(misdated_sim_grid$scenario,
                                       misdated_sim_grid$replicate),
             pattern = map(misdated_sim_grid), iteration = "list"),
  tar_target(misdated_sim_chain, seq_len(n_chains_misdated)),
  tar_target(misdated_sim_fit,
             fit_misdated_chain(misdated_sim_dataset, misdated_sim_chain,
                                n_iterations_misdated),
             pattern = cross(misdated_sim_dataset, misdated_sim_chain),
             iteration = "list"),
  tar_target(misdated_sim_summary,
             purrr::map_dfr(misdated_sim_dataset, summarise_misdated_fits,
                            fits = misdated_sim_fit),
             deployment = "main")
)

# Makes the fits to simulated data of one scenario of
# R/misdated_simulation.R (GitHub Actions). Its measures are saved to
# simulations_out/<scenario>.csv and its chains to simulations_out/<scenario>.rds.
# Usage: Rscript scripts/run_simulation_scenario.R <scenario>
args <- commandArgs(trailingOnly = TRUE)
Sys.setenv(MISDATED_SCENARIOS = args[1])
targets::tar_make(script = "_targets_simulations.R", store = "_targets_simulations")
f_read <- function(name) targets::tar_read_raw(name, store = "_targets_simulations")
summary <- f_read("misdated_sim_summary")
dir.create("simulations_out", showWarnings = FALSE)
utils::write.csv(summary, file.path("simulations_out", paste0(args[1], ".csv")),
                 row.names = FALSE)
saveRDS(f_read("misdated_sim_fit"),
        file.path("simulations_out", paste0(args[1], ".rds")), compress = "xz")
print(as.data.frame(summary[, intersect(
  c("scenario", "replicate", "chains", "error", "minutes", "fraction_true", "fraction",
    "triggered_true", "triggered", "deaths_all_true", "deaths_all"), names(summary))]))

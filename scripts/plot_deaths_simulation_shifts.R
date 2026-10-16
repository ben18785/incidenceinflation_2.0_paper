.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
store <- "_targets"
ds <- tar_read(deaths_sim_dataset, store = store); fits <- tar_read(deaths_sim_fit, store = store)
cat(length(ds), length(fits), "\n")
p <- plot_deaths_simulation(ds, fits, c("cfr_fall", "cfr_rise", "recording_change"))
save_plot(p, "outputs/bvd_deaths_simulation_shifts.png", 11, 1.2 + 1.9 * 3)

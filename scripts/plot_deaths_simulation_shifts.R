.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
store <- "_targets"
ds <- tar_read(deaths_sim_dataset, store = store); fits <- tar_read(deaths_sim_fit, store = store)
save_plot(plot_deaths_simulation(ds, fits, c("cfr_fall", "cfr_rise")), "outputs/bvd_deaths_simulation_cfr.png", 11, 1.2 + 1.9 * 2)
save_plot(plot_deaths_simulation(ds, fits, c("Rt_fall", "recording_change")), "outputs/bvd_deaths_simulation_rt_delay.png", 11, 1.2 + 1.9 * 2)

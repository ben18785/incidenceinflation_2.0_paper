# Plots of cases and deaths by onset date at each fit date, one figure per
# model of the joint experiments, from chains saved in a folder.
# Usage: Rscript scripts/plot_experiments.R <folder of chains> <folder of plots>
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(targets); library(incidenceinflation)})
tar_source("R")
set.seed(1)
chains <- lapply(list.files(args[1], pattern = "\\.rds$", full.names = TRUE,
                            recursive = TRUE), readRDS)
chains <- purrr::keep(chains, ~is.null(.$error) && grepl("^joint", .$model))
snapshots <- build_bvd_snapshots(
  list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$", full.names = TRUE))
by_day <- bvd_experiment_by_day(chains, snapshots, max(snapshots$date_reported))
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
utils::write.csv(by_day, file.path(args[2], "by_day.csv"), row.names = FALSE)
for(model in unique(by_day$model)) {
  name <- gsub("[^a-z]+", "_", model)
  for(count in c("cases", "deaths"))
    print(save_plot(plot_bvd_experiment_counts(filter(by_day, .data$model == !!model), count),
                    file.path(args[2], sprintf("%s_%s.png", name, count)), 12, 7))
}

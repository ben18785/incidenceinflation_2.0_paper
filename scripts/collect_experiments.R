# Writes the results of the chains saved in a folder (GitHub Actions).
# Usage: Rscript scripts/collect_experiments.R <folder of chains> <folder of results>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(targets)})
tar_source("R")
chains <- lapply(list.files(args[1], pattern = "\\.rds$", full.names = TRUE,
                            recursive = TRUE), readRDS)
cat(length(chains), "chains read\n")
snapshots <- build_bvd_snapshots(
  list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$", full.names = TRUE))
paths <- write_bvd_experiment_results(chains, snapshots, args[2])
dir.create(file.path(args[2], "chains"), showWarnings = FALSE)
for(fit in chains)
  saveRDS(fit, file.path(args[2], "chains", paste0(fit$experiment, "_", fit$chain, ".rds")),
          compress = "xz")
print(paths)

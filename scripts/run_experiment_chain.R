# Makes one chain of one experiment and saves it to chains/ (GitHub Actions).
# Usage: Rscript scripts/run_experiment_chain.R <experiment> <chain>
args <- commandArgs(trailingOnly = TRUE)
Sys.setenv(BVD_EXPERIMENTS = args[1], BVD_CHAIN = args[2])
target <- paste("chain", args[1], args[2], sep = "_")
targets::tar_make(names = tidyselect::starts_with("chain_"),
                  script = "_targets_experiments.R", store = "_targets_experiments")
dir.create("chains", showWarnings = FALSE)
saveRDS(targets::tar_read_raw(target, store = "_targets_experiments"),
        file.path("chains", paste0(args[1], "_", args[2], ".rds")))

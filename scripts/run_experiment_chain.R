# Makes one chain of one experiment (GitHub Actions). The chain is saved to
# chains/ and what is needed to carry it on to states/. If states/ already
# holds the progress of an earlier run of the chain, the chain is carried on
# from it; it stops after BVD_TIME_LIMIT minutes if that is set.
# Usage: Rscript scripts/run_experiment_chain.R <experiment> <chain>
args <- commandArgs(trailingOnly = TRUE)
Sys.setenv(BVD_EXPERIMENTS = args[1], BVD_CHAIN = args[2])
id <- paste(args[1], args[2], sep = "_")
target <- paste0("chain_", id)
targets::tar_make(names = tidyselect::starts_with("chain_"),
                  script = "_targets_experiments.R", store = "_targets_experiments")
fit <- targets::tar_read_raw(target, store = "_targets_experiments")
cat(sprintf("%d of %d iterations done\n", fit$niterations, fit$niterations_target))
dir.create("chains", showWarnings = FALSE)
dir.create("states", showWarnings = FALSE)
if(!is.null(fit$progress))
  saveRDS(list(experiment = args[1], chain = as.integer(args[2]),
               progress = fit$progress),
          file.path("states", paste0(id, ".rds")), compress = "xz")
fit$progress <- NULL
saveRDS(fit, file.path("chains", paste0(id, ".rds")))

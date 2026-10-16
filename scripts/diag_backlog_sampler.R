# Usage: Rscript diag_backlog.R <sampler> <start: default|truth> <iterations>
a <- commandArgs(trailingOnly = TRUE)
suppressMessages({devtools::load_all("/Users/bcl206/Documents/GitHub/incidenceinflation_2.0", quiet = TRUE)
  library(dplyr); library(targets)})
setwd("/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad/wt_cp")
tar_source("R")
d <- simulate_misdated_dataset("backlog", 1)
fit <- list(sampler = a[1])
if(a[2] == "truth") {
  fit$initial_share <- d$truth_by_day$backlog_share
  fit$initial_rate <- d$settings$recording_backlog$rate[seq_len(d$n_days)]
  fit$initial_rate_rw_sd <- 1
}
d$settings$fit_backlog <- fit
t0 <- Sys.time()
out <- fit_misdated_chain(d, 1, as.integer(a[3]),
  progress_dir = "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad/diag_progress")
# keep every iteration of the backlog: rerun keeps only the second half, so fine
saveRDS(out, sprintf("/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad/diag_%s_%s.rds", a[1], a[2]))
cat("done", a[1], a[2], "error:", out$error, "sec_per_it", as.numeric(Sys.time() - t0, units = "secs") / as.integer(a[3]), "\n")

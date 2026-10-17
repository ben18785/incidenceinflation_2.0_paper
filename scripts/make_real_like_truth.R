# The truth of the simulations 'like the outbreak' (R/misdated_simulation.R):
# the posterior medians of the fit of the backlog held 21 days to the reports
# of 7 October (experiments batch 14), by onset day, with the days of the
# reports. Only smooth summaries are kept: the expected cases of each day are
# a centred seven-day mean of the fitted cases.
# Usage: Rscript scripts/make_real_like_truth.R <folder of chains of batch 14>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(library(dplyr))
files <- Sys.glob(file.path(args[1], "*_misdated_triggered_july_backlog_1007_*.rds"))
chains <- Filter(function(x) is.null(x$error), lapply(files, readRDS))
f_rows <- function(name) dplyr::bind_rows(lapply(chains, `[[`, name))
f_median <- function(name, column) f_rows(name) %>%
  dplyr::group_by(.data$time_onset) %>%
  dplyr::summarise(value = stats::median(.data[[column]]), .groups = "drop") %>%
  dplyr::pull("value")
n_days <- nrow(chains[[1]]$analysis$dates)
report_days <- sort(unique(chains[[1]]$analysis$snapshots$time_reported))
parameters <- f_rows("deaths_parameters")
columns <- paste0("backlog_rate_", report_days)
rate_report <- vapply(columns, function(x) stats::median(parameters[[x]]), numeric(1))
# the rate of each day is that of the report interval it is in
rate_day <- rate_report[findInterval(seq_len(n_days) - 1e-8, report_days) + 1]
cases <- f_median("cases", "cases_true")
cases_mean <- as.numeric(stats::filter(cases, rep(1 / 7, 7), sides = 2))
cases_mean[is.na(cases_mean)] <- cases[is.na(cases_mean)]
by_day <- dplyr::tibble(
  time_onset = seq_len(n_days),
  cases_mean = round(cases_mean, 1),
  cfr = round(f_median("deaths", "cfr"), 3),
  reporting_mean = round(f_median("reporting_days", "mean"), 2),
  reporting_sd = round(f_median("reporting_days", "sd"), 2),
  recording_mean = round(f_median("deaths", "delay_mean"), 2),
  recording_sd = round(f_median("deaths", "delay_sd"), 2),
  backlog_share = round(f_median("deaths", "backlog_share"), 3),
  backlog_rate = signif(rate_day, 3),
  is_report = seq_len(n_days) %in% report_days)
revisions <- f_rows("revisions")
scalars <- dplyr::tibble(
  name = c("triggered", "fraction", "eta", "rho", "delta"),
  value = signif(c(stats::median(parameters$triggered), stats::median(parameters$dated_fraction),
                   stats::median(revisions$eta), stats::median(revisions$rho),
                   stats::median(parameters$wrong_dead)), 3))
dir.create("simulations/truth", recursive = TRUE, showWarnings = FALSE)
utils::write.csv(by_day, "simulations/truth/real_like_by_day.csv", row.names = FALSE)
utils::write.csv(scalars, "simulations/truth/real_like_scalars.csv", row.names = FALSE)
print(scalars)
print(summary(by_day))

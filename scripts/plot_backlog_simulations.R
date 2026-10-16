# Plots of the fits to simulated data of the backlog of deaths (simulations
# batch 2) beside the truth: the fatal cases of each onset day, the share in
# the backlog, the rate at which it is cleared and the totals.
# Usage: Rscript scripts/plot_backlog_simulations.R <folder of results of the batch>
# where the folder (of experiment-results) holds by_dataset.csv and draws/.
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(targets)})
tar_source("R")
folder <- args[1]
out <- "outputs/backlog_simulations"
dir.create(out, recursive = TRUE, showWarnings = FALSE)

labels <- c(
  backlog = "Backlog model\nfit on day 90", backlog_fit_f = "Option (f)\nfit on day 90",
  backlog_mid = "Backlog model\nfit on day 63", backlog_mid_fit_f = "Option (f)\nfit on day 63",
  backlog_before = "Backlog model\nfit on day 50",
  backlog_before_fit_f = "Option (f)\nfit on day 50",
  backlog_fit_tail = "Tail alone\nfit on day 90",
  backlog_late = "Backlog cleared\nfrom day 80", backlog_steady = "Constant share\nand rate",
  backlog_none = "No backlog")
scenarios <- names(labels)
f_label <- function(x) factor(labels[x], levels = labels)

# the truth: the datasets are made again from their seeds
datasets <- tidyr::expand_grid(scenario = scenarios, replicate = 1:2)
truth <- list(); shown <- list(); rates <- list()
for(i in seq_len(nrow(datasets))) {
  d <- simulate_misdated_dataset(datasets$scenario[i], datasets$replicate[i])
  truth[[i]] <- dplyr::mutate(d$truth_by_day, scenario = d$scenario, replicate = d$replicate)
  last <- max(d$snapshots$time_reported)
  shown[[i]] <- d$snapshots %>%
    dplyr::filter(.data$time_reported == last) %>%
    dplyr::select("time_onset", deaths_shown = "deaths_reported") %>%
    dplyr::mutate(scenario = d$scenario, replicate = d$replicate,
                  first_report = min(d$snapshots$time_reported), last_report = last)
  rate <- d$settings$recording_backlog$rate
  if(!is.null(rate))
    rates[[i]] <- dplyr::tibble(day = seq_len(d$n_days), rate = rate[seq_len(d$n_days)],
                                scenario = d$scenario, replicate = d$replicate)
}
truth <- dplyr::bind_rows(truth)
shown <- dplyr::bind_rows(shown)
rates <- dplyr::bind_rows(rates)

f_read <- function(name) utils::read.csv(gzfile(file.path(folder, "draws", paste0(name, ".csv.gz"))))
deaths <- f_read("deaths")
parameters <- f_read("deaths_parameters")
f_band <- function(df, column, ...) df %>%
  dplyr::group_by(...) %>%
  dplyr::summarise(lo = stats::quantile(.data[[column]], 0.05),
                   mid = stats::median(.data[[column]]),
                   hi = stats::quantile(.data[[column]], 0.95), .groups = "drop")

# fatal cases of each onset day
fatal <- f_band(deaths, "deaths_recorded", scenario, replicate, time_onset) %>%
  dplyr::left_join(truth %>% dplyr::select("scenario", "replicate", "time_onset",
                                           truth = "deaths_recorded"),
                   by = c("scenario", "replicate", "time_onset")) %>%
  dplyr::left_join(shown, by = c("scenario", "replicate", "time_onset"))
f_fatal <- function(wanted, file, ncol = 2, height = 8) {
  df <- fatal %>% dplyr::filter(.data$scenario %in% wanted) %>%
    dplyr::mutate(label = f_label(.data$scenario),
                  replicate = paste("Dataset", .data$replicate))
  lines <- df %>% dplyr::distinct(.data$label, .data$replicate, .data$first_report,
                                  .data$last_report)
  g <- ggplot(df, aes(x = time_onset)) +
    geom_col(aes(y = deaths_shown, fill = "Shown in the last report fitted"), width = 1,
             alpha = 0.5) +
    geom_ribbon(aes(ymin = lo, ymax = hi, fill = "Estimate (90% interval)"), alpha = 0.4) +
    geom_line(aes(y = mid, colour = "Estimate (median)")) +
    geom_line(aes(y = truth, colour = "Truth")) +
    geom_vline(data = lines, aes(xintercept = first_report), linetype = 2, colour = "grey40") +
    scale_fill_manual(NULL, values = c("Shown in the last report fitted" = "grey70",
                                       "Estimate (90% interval)" = "#3B7DD8")) +
    scale_colour_manual(NULL, values = c("Estimate (median)" = "#1F4E9C", "Truth" = "black")) +
    facet_grid(label ~ replicate, scales = "free_x") +
    labs(x = "Day of onset", y = "Fatal cases") +
    theme_bw() + theme(legend.position = "bottom", strip.text.y = element_text(size = 8))
  ggsave(file.path(out, file), g, width = 9, height = height, dpi = 150)
}
f_fatal(scenarios[1:6], "fatal_by_onset_backlog_vs_f.png", height = 10)
f_fatal(scenarios[7:10], "fatal_by_onset_checks.png", height = 7.5)

# the share in the backlog by onset day
share <- f_band(deaths %>% dplyr::filter(!is.na(.data$backlog_share)), "backlog_share",
                scenario, replicate, time_onset) %>%
  dplyr::left_join(truth %>% dplyr::select("scenario", "replicate", "time_onset",
                                           truth = "backlog_share"),
                   by = c("scenario", "replicate", "time_onset")) %>%
  dplyr::mutate(label = f_label(.data$scenario), replicate = paste("Dataset", .data$replicate))
g <- ggplot(share, aes(x = time_onset)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#3B7DD8", alpha = 0.4) +
  geom_line(aes(y = mid), colour = "#1F4E9C") +
  geom_line(aes(y = truth), colour = "black") +
  facet_grid(label ~ replicate) +
  labs(x = "Day of onset", y = "Share of deaths in the backlog") +
  theme_bw() + theme(strip.text.y = element_text(size = 8))
ggsave(file.path(out, "backlog_share.png"), g, width = 8, height = 9, dpi = 150)

# the rate the backlog is cleared at: each rate holds from the report before
# to its report
columns <- grep("^backlog_rate_[0-9]+$", names(parameters), value = TRUE)
rate_draws <- parameters %>%
  dplyr::select("scenario", "replicate", dplyr::all_of(columns)) %>%
  tidyr::pivot_longer(dplyr::all_of(columns), names_to = "report", values_to = "rate") %>%
  dplyr::filter(!is.na(.data$rate)) %>%
  dplyr::mutate(report = as.integer(sub("backlog_rate_", "", .data$report)))
rate_band <- f_band(rate_draws, "rate", scenario, replicate, report) %>%
  dplyr::group_by(.data$scenario, .data$replicate) %>%
  dplyr::arrange(.data$report, .by_group = TRUE) %>%
  dplyr::mutate(start = dplyr::lag(.data$report, default = 0)) %>%
  dplyr::ungroup()
# a step for every day, so that a ribbon follows the steps
rate_days <- rate_band %>%
  dplyr::rowwise() %>%
  dplyr::reframe(scenario, replicate, lo, mid, hi,
                 day = seq(.data$start, .data$report)) %>%
  dplyr::mutate(label = f_label(.data$scenario), replicate = paste("Dataset", .data$replicate))
last_reports <- rate_band %>%
  dplyr::group_by(.data$scenario, .data$replicate) %>%
  dplyr::summarise(last = max(.data$report), .groups = "drop")
rate_truth <- rates %>%
  dplyr::inner_join(last_reports, by = c("scenario", "replicate")) %>%
  dplyr::filter(.data$day <= .data$last) %>%
  dplyr::mutate(label = f_label(.data$scenario), replicate = paste("Dataset", .data$replicate))
g <- ggplot(rate_days, aes(x = day)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#3B7DD8", alpha = 0.4) +
  geom_line(aes(y = mid), colour = "#1F4E9C") +
  geom_step(data = rate_truth, aes(y = rate), colour = "black", direction = "mid") +
  scale_y_log10() +
  facet_grid(label ~ replicate) +
  labs(x = "Day (a report each day from day 40; the first rate covers days 1 to 40)",
       y = "Rate the backlog is cleared at (per day)") +
  theme_bw() + theme(strip.text.y = element_text(size = 8))
ggsave(file.path(out, "backlog_rate.png"), g, width = 8, height = 9, dpi = 150)

# the totals of fatal cases: all days and onsets before the first report
by_dataset <- utils::read.csv(file.path(folder, "by_dataset.csv")) %>%
  dplyr::filter(.data$scenario %in% scenarios)
totals <- dplyr::bind_rows(
  by_dataset %>% dplyr::transmute(scenario, replicate, what = "All onset days",
                                  truth = deaths_all_true, mid = deaths_all,
                                  lo = deaths_all_lo, hi = deaths_all_hi),
  by_dataset %>% dplyr::transmute(scenario, replicate, what = "Onsets before the first report",
                                  truth = deaths_old_true, mid = deaths_old,
                                  lo = deaths_old_lo, hi = deaths_old_hi),
  by_dataset %>% dplyr::transmute(scenario, replicate, what = "Latest 14 onset days",
                                  truth = deaths_recent_true, mid = deaths_recent,
                                  lo = deaths_recent_lo, hi = deaths_recent_hi)) %>%
  dplyr::mutate(label = factor(labels[.data$scenario], levels = rev(labels)),
                what = factor(.data$what, levels = c("All onset days",
                                                     "Onsets before the first report",
                                                     "Latest 14 onset days")),
                dataset = factor(.data$replicate))
g <- ggplot(totals, aes(y = label, colour = dataset)) +
  geom_pointrange(aes(x = mid / truth, xmin = lo / truth, xmax = hi / truth),
                  position = position_dodge(width = 0.5), size = 0.3) +
  geom_vline(xintercept = 1, linetype = 2) +
  scale_x_continuous(breaks = c(0.6, 0.8, 1, 1.2)) +
  facet_wrap(~what, nrow = 1) +
  labs(x = "Estimate / truth (median and 90% interval)", y = NULL, colour = "Dataset") +
  theme_bw() + theme(legend.position = "bottom")
ggsave(file.path(out, "totals.png"), g, width = 10, height = 5, dpi = 150)
cat("Plots in", out, "\n")

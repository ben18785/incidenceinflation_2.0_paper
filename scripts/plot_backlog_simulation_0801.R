# The fits to simulated data like the outbreak, to the reports to day 83 (as
# 1 August), in the relaxed (simulations batch 6) and exact (batch 11) forms of
# the fatal cases dated by death: the eventual fatal cases of each onset day and
# week of onset against the truth, what the report of day 83 showed and what
# the last report (as 7 October) shows.
# Usage: Rscript scripts/plot_backlog_simulation_0801.R <results of batch 6> <results of batch 11> [folder of plots]
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(targets)})
tar_source("R")
out <- if(length(args) > 2) args[3] else "outputs/backlog_simulations_11"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
fits <- c(real_like_0801 = "Relaxed form", real_like_0801_exact = "Exact form")
draws <- dplyr::bind_rows(
  utils::read.csv(gzfile(file.path(args[1], "draws", "deaths.csv.gz"))),
  utils::read.csv(gzfile(file.path(args[2], "draws", "deaths.csv.gz")))) %>%
  dplyr::filter(.data$scenario %in% names(fits), .data$replicate == 1) %>%
  dplyr::mutate(model = factor(fits[.data$scenario], levels = fits))

# the truth and the reports: the dataset fitted to day 83 is that of the fit
# to all reports, cut at day 83
d_now <- simulate_misdated_dataset("real_like_0801", 1)
d_all <- simulate_misdated_dataset("real_like", 1)
f_last <- function(d) d$snapshots %>%
  dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
  dplyr::select("time_onset", "deaths_reported")
fit_day <- max(d_now$snapshots$time_reported)
last_day <- max(d_all$snapshots$time_reported)
stopifnot(identical(d_now$truth_by_day$deaths_recorded[seq_len(fit_day)],
                    d_all$truth_by_day$deaths_recorded[seq_len(fit_day)]))
counts <- d_now$truth_by_day %>%
  dplyr::select("time_onset", truth = "deaths_recorded") %>%
  dplyr::left_join(dplyr::rename(f_last(d_now), now = "deaths_reported"), by = "time_onset") %>%
  dplyr::left_join(dplyr::rename(f_last(d_all), later = "deaths_reported"), by = "time_onset") %>%
  dplyr::filter(.data$time_onset <= fit_day)

lab <- c(now = sprintf("Reported on day %d (as 1 August)", fit_day),
         later = sprintf("Reported on day %d (as 7 October)", last_day),
         truth = "Truth", estimate = "Estimate (median, 90% interval)")
cols <- setNames(c("#E69F00", "grey45", "black", "#009E73"), lab)
f_band <- function(df, ...) df %>%
  dplyr::group_by(.data$model, ...) %>%
  dplyr::summarise(p05 = stats::quantile(.data$deaths, 0.05), p50 = stats::median(.data$deaths),
                   p95 = stats::quantile(.data$deaths, 0.95), .groups = "drop")
f_lines <- function(df, x) dplyr::bind_rows(lapply(c("now", "later", "truth"), function(w)
  dplyr::transmute(df, model, x = .data[[x]], y = .data[[w]], what = lab[[w]]))) %>%
  dplyr::mutate(what = factor(what, levels = lab))

# by onset day
daily <- f_band(dplyr::rename(draws, deaths = "deaths_recorded"), .data$time_onset) %>%
  dplyr::left_join(counts, by = "time_onset")
g_day <- ggplot(daily, aes(x = time_onset)) +
  geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3) +
  geom_line(aes(y = p50, colour = lab[["estimate"]]), linewidth = 0.4) +
  geom_line(data = f_lines(daily, "time_onset"), aes(x = x, y = y, colour = what), linewidth = 0.4) +
  scale_colour_manual(values = cols, breaks = unname(lab), name = NULL) +
  facet_wrap(~model, ncol = 1) +
  labs(x = "Day of onset", y = "Fatal cases by onset day") +
  theme_paper() + theme(legend.position = "none")

# by week of onset (days 1 to 7, 8 to 14, ...; the last a part week)
f_week <- function(t) 7 * ((t - 1) %/% 7) + 1
weekly <- draws %>%
  dplyr::mutate(week = f_week(.data$time_onset)) %>%
  dplyr::group_by(.data$model, .data$chain, .data$iteration, .data$week) %>%
  dplyr::summarise(deaths = sum(.data$deaths_recorded), .groups = "drop") %>%
  f_band(.data$week) %>%
  dplyr::left_join(counts %>% dplyr::mutate(week = f_week(.data$time_onset)) %>%
                     dplyr::group_by(.data$week) %>%
                     dplyr::summarise(dplyr::across(c("truth", "now", "later"), sum)),
                   by = "week")
g_week <- ggplot(weekly, aes(x = week + 3)) +
  geom_linerange(aes(ymin = p05, ymax = p95), colour = "#009E73", linewidth = 2.5, alpha = 0.4) +
  geom_point(aes(y = p50, colour = lab[["estimate"]]), size = 2) +
  geom_point(data = f_lines(weekly, "week"), aes(x = x + 3, y = y, colour = what),
             size = 2, shape = 4, stroke = 1.1) +
  scale_colour_manual(values = cols, breaks = unname(lab), name = NULL) +
  facet_wrap(~model, ncol = 1) +
  guides(colour = guide_legend(nrow = 2)) +
  labs(x = "Week of onset (first day)", y = "Fatal cases by week of onset") +
  theme_paper()
save_plot(patchwork::wrap_plots(g_day, g_week + theme(legend.position = "bottom"), nrow = 1),
          file.path(out, "fatal_0801_weekly.png"), 12, 7)
utils::write.csv(weekly, file.path(out, "fatal_0801_weekly.csv"), row.names = FALSE)
cat("Plots in", out, "\n")

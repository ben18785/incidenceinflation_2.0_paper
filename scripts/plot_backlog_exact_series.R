# The exact form of the backlog held 21 days fitted to the reports to each of
# a series of dates from 1 August to 14 October (experiments batches 15, 15c,
# 16 and 16c): the totals over the onset days of each fit against what the
# reports of the fit date and of the last date show, the fatal cases by week of
# onset of each fit, and the case fatality ratio and Rt of each fit.
# Usage: Rscript scripts/plot_backlog_exact_series.R <folder of chains> [<folder of chains> ...] [--out folder of plots]
# A chain in a later folder (a continuation) replaces the same chain in an
# earlier one.
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(targets)})
tar_source("R")
i_out <- which(args == "--out")
out <- if(length(i_out)) args[i_out + 1] else "outputs/backlog_exact_series"
folders <- if(length(i_out)) args[-c(i_out, i_out + 1)] else args
dir.create(out, recursive = TRUE, showWarnings = FALSE)

files <- unlist(lapply(folders, function(f)
  Sys.glob(file.path(f, "*_misdated_triggered_july_backlog_exact_*_[0-9].rds"))))
files <- files[!duplicated(basename(files), fromLast = TRUE)]
chains <- Filter(function(x) is.null(x$error), lapply(files, readRDS))
fits <- split(chains, vapply(chains, function(x) format(as.Date(x$date_now)), character(1)))
fit_dates <- as.Date(names(fits))
cat("Fits to", format(fit_dates, "%d %b"), "\n")
cat("Iterations:", vapply(fits, function(f) paste(vapply(f, `[[`, 1, "niterations"), collapse = "/"), ""), "\n")

snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$",
                                       full.names = TRUE))
last <- max(snap$date_reported)
f_rows <- function(chains, name) dplyr::bind_rows(lapply(chains, function(x) x[[name]]))
f_label <- function(d) factor(format(d, "Fit to %d %b"), levels = format(sort(fit_dates), "Fit to %d %b"))

# the draws of the counts the reports count by onset day, for each fit: the
# cases less the fatal cases counted on their day of death, plus those of
# earlier onset who died on the day (as in bvd_experiment_totals)
draws <- dplyr::bind_rows(lapply(seq_along(fits), function(k) {
  dates <- fits[[k]][[1]]$analysis$dates
  dplyr::inner_join(
    dplyr::select(f_rows(fits[[k]], "cases"), "chain", "iteration", "time_onset", "cases_true"),
    dplyr::select(f_rows(fits[[k]], "deaths"), "chain", "iteration", "time_onset",
                  "deaths_true", deaths = "deaths_recorded"),
    by = c("chain", "iteration", "time_onset")) %>%
    dplyr::transmute(.data$chain, .data$iteration, .data$time_onset,
                     cases = .data$cases_true + .data$deaths - .data$deaths_true, .data$deaths) %>%
    dplyr::left_join(dates, by = "time_onset") %>%
    dplyr::mutate(fit_date = fit_dates[k])
}))
# what the report of the fit date and the last report show for the same onset days
f_shown <- function(d) snap %>%
  dplyr::filter(.data$date_reported == d) %>%
  dplyr::select(date = "date_onset", "cases_reported", "deaths_reported")
shown <- dplyr::bind_rows(lapply(fit_dates, function(d) {
  dplyr::bind_rows(dplyr::mutate(f_shown(d), when = "now"),
                   dplyr::mutate(f_shown(last), when = "last")) %>%
    dplyr::filter(.data$date %in% draws$date[draws$fit_date == d]) %>%
    dplyr::mutate(fit_date = d)
}))
f_band <- function(df, column, ...) df %>%
  dplyr::group_by(...) %>%
  dplyr::summarise(p05 = stats::quantile(.data[[column]], 0.05), p50 = stats::median(.data[[column]]),
                   p95 = stats::quantile(.data[[column]], 0.95), .groups = "drop")
lab <- c(now = "Reported on the fit date", estimate = "Estimate (median, 90% interval)",
         last = format(last, "Reported on %d %B"))
cols <- setNames(c("#E69F00", "#009E73", "black"), lab)
counts <- c(cases = "Cases", deaths = "Deaths")

# the totals over the onset days of each fit, all of them and the latest 28
totals <- dplyr::bind_rows(lapply(c(all = Inf, latest = 28), function(n) {
  keep <- function(df) df %>% dplyr::filter(.data$date > .data$fit_date - n)
  est <- draws %>% keep() %>%
    dplyr::group_by(.data$fit_date, .data$chain, .data$iteration) %>%
    dplyr::summarise(cases = sum(.data$cases), deaths = sum(.data$deaths), .groups = "drop") %>%
    tidyr::pivot_longer(c("cases", "deaths"), names_to = "count") %>%
    f_band("value", .data$fit_date, .data$count)
  rep <- shown %>% keep() %>%
    dplyr::group_by(.data$fit_date, .data$when) %>%
    dplyr::summarise(cases = sum(.data$cases_reported), deaths = sum(.data$deaths_reported), .groups = "drop") %>%
    tidyr::pivot_longer(c("cases", "deaths"), names_to = "count") %>%
    tidyr::pivot_wider(names_from = "when", values_from = "value")
  dplyr::left_join(est, rep, by = c("fit_date", "count")) %>%
    dplyr::mutate(days = if(is.finite(n)) sprintf("Onsets in the last %d days", n) else "All onsets")
})) %>%
  dplyr::mutate(days = factor(.data$days, levels = c("All onsets", "Onsets in the last 28 days")),
                count = counts[.data$count])
points <- totals %>%
  tidyr::pivot_longer(c("now", "last"), names_to = "when", values_to = "y") %>%
  dplyr::mutate(what = factor(lab[.data$when], levels = lab))
g_totals <- ggplot(totals, aes(x = fit_date)) +
  geom_linerange(aes(ymin = p05, ymax = p95), colour = "#009E73", linewidth = 2.5, alpha = 0.4) +
  geom_point(aes(y = p50, colour = lab[["estimate"]]), size = 2) +
  geom_point(data = points, aes(y = y, colour = what), size = 2, shape = 4, stroke = 1.1) +
  scale_colour_manual(values = cols, breaks = unname(lab), name = NULL) +
  facet_grid(count ~ days, scales = "free_y") +
  labs(x = "Date of the fit", y = "Total by onset") +
  theme_paper() + theme(legend.position = "bottom")
save_plot(g_totals, file.path(out, "totals.png"), 11, 7)

# the fatal cases by week of onset (weeks starting on Monday)
f_week <- function(date) as.Date(cut(date, "week", start.on.monday = TRUE))
weekly <- draws %>%
  dplyr::mutate(week = f_week(.data$date)) %>%
  dplyr::group_by(.data$fit_date, .data$chain, .data$iteration, .data$week) %>%
  dplyr::summarise(deaths = sum(.data$deaths), .groups = "drop") %>%
  f_band("deaths", .data$fit_date, .data$week) %>%
  dplyr::left_join(shown %>% dplyr::mutate(week = f_week(.data$date)) %>%
                     dplyr::group_by(.data$fit_date, .data$week, .data$when) %>%
                     dplyr::summarise(y = sum(.data$deaths_reported), .groups = "drop") %>%
                     tidyr::pivot_wider(names_from = "when", values_from = "y"),
                   by = c("fit_date", "week")) %>%
  dplyr::mutate(fit = f_label(.data$fit_date))
points <- weekly %>%
  tidyr::pivot_longer(c("now", "last"), names_to = "when", values_to = "y") %>%
  dplyr::mutate(what = factor(lab[.data$when], levels = lab))
g_week <- ggplot(weekly, aes(x = week + 3)) +
  geom_linerange(aes(ymin = p05, ymax = p95), colour = "#009E73", linewidth = 1.8, alpha = 0.4) +
  geom_point(aes(y = p50, colour = lab[["estimate"]]), size = 1.2) +
  geom_point(data = points, aes(y = y, colour = what), size = 1.2, shape = 4, stroke = 0.8) +
  scale_colour_manual(values = cols, breaks = unname(lab), name = NULL) +
  facet_wrap(~fit, ncol = 3) +
  labs(x = "Week of onset", y = "Deaths by week of onset") +
  theme_paper() + theme(legend.position = "bottom")
save_plot(g_week, file.path(out, "deaths_weekly.png"), 12, 11)

# the fatal cases by onset day of each fit, as the plots of the fits to
# simulated data (fatal_by_onset_*.png of plot_backlog_simulations.R), with
# the last report in place of the truth: one plot for each fit and one of all
daily <- f_band(draws, "deaths", .data$fit_date, .data$date) %>%
  dplyr::left_join(shown %>%
                     dplyr::select("fit_date", "date", "when", "deaths_reported") %>%
                     tidyr::pivot_wider(names_from = "when", values_from = "deaths_reported"),
                   by = c("fit_date", "date")) %>%
  dplyr::mutate(fit = f_label(.data$fit_date))
first_report <- min(snap$date_reported)
lab_last <- format(last, "Reported on %d %B")
f_daily <- function(df) ggplot(df, aes(x = date)) +
  geom_col(aes(y = now, fill = "Shown in the last report fitted"), width = 1, alpha = 0.5) +
  geom_ribbon(aes(ymin = p05, ymax = p95, fill = "Estimate (90% interval)"), alpha = 0.4) +
  geom_line(aes(y = p50, colour = "Estimate (median)")) +
  geom_line(aes(y = last, colour = lab_last)) +
  geom_vline(xintercept = first_report, linetype = 2, colour = "grey40") +
  scale_fill_manual(NULL, values = c("Shown in the last report fitted" = "grey70",
                                     "Estimate (90% interval)" = "#3B7DD8")) +
  scale_colour_manual(NULL, values = setNames(c("#1F4E9C", "black"), c("Estimate (median)", lab_last))) +
  labs(x = "Onset date", y = "Fatal cases") +
  theme_bw() + theme(legend.position = "bottom")
for(d in fit_dates)
  ggsave(file.path(out, format(as.Date(d), "fatal_by_onset_%m%d.png")),
         f_daily(dplyr::filter(daily, .data$fit_date == d)) +
           scale_x_date(limits = range(daily$date) + c(-1, 1)) +
           labs(title = format(as.Date(d), "Fit to the reports to %d %B")),
         width = 9, height = 4, dpi = 150)
ggsave(file.path(out, "fatal_by_onset_all.png"),
       f_daily(daily) + facet_wrap(~fit, ncol = 2) + theme(strip.text = element_text(size = 8)),
       width = 11, height = 2.2 * ceiling(length(fit_dates) / 2) + 1, dpi = 150)

# the case fatality ratio and Rt by onset date of each fit
f_by_onset <- function(table, column) dplyr::bind_rows(lapply(seq_along(fits), function(k)
  f_band(f_rows(fits[[k]], table), column, .data$time_onset) %>%
    dplyr::left_join(fits[[k]][[1]]$analysis$dates, by = "time_onset") %>%
    dplyr::mutate(fit_date = fit_dates[k])))
f_plot <- function(df, y) ggplot(df, aes(x = date, group = fit_date, colour = fit_date, fill = fit_date)) +
  geom_ribbon(aes(ymin = p05, ymax = p95), alpha = 0.08, colour = NA) +
  geom_line(aes(y = p50), linewidth = 0.5) +
  scale_colour_viridis_c(NULL, trans = "date", end = 0.9, aesthetics = c("colour", "fill"),
                         labels = function(x) format(as.Date(x, origin = "1970-01-01"), "%d %b")) +
  labs(x = "Onset date", y = y) +
  theme_paper()
cfr <- f_by_onset("deaths", "cfr")
rt <- f_by_onset("Rt", "Rt")
save_plot(patchwork::wrap_plots(
  f_plot(cfr, "Case fatality ratio") + theme(legend.position = "none"),
  f_plot(rt, expression(R[t])) + scale_y_log10() + geom_hline(yintercept = 1, linetype = 2) +
    theme(legend.position = "right", legend.key.height = grid::unit(1.2, "cm")),
  ncol = 1), file.path(out, "cfr_rt.png"), 11, 8)

for(x in c("totals", "weekly", "cfr", "rt"))
  utils::write.csv(get(x), file.path(out, paste0(x, ".csv")), row.names = FALSE)
cat("Plots in", out, "\n")

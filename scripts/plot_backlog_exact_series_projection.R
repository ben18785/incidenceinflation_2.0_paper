# The fits of the exact form of the backlog held 21 days to the reports to each
# date from 1 August (experiments batches 15, 15c, 16 and 16c), projected to the
# last report (14 October) against what that report shows: the fatal cases by
# onset day of each fit, as fatal_by_onset_*.png of
# plot_backlog_exact_series.R, but with the projection in place of the
# eventual count.
# Usage: Rscript scripts/plot_backlog_exact_series_projection.R <folder of chains> [<folder of chains> ...] [--out folder of plots]
# A chain in a later folder (a continuation) replaces the same chain in an
# earlier one.
args <- commandArgs(trailingOnly = TRUE)
# the version of the model with the exact form (BVD_LIB, by default .lib)
.libPaths(c(Sys.getenv("BVD_LIB", ".lib"), .libPaths()))
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(targets); library(incidenceinflation)})
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
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$",
                                       full.names = TRUE))
last <- max(snap$date_reported)
# the fit to the last report has nothing to project
fits <- fits[as.Date(names(fits)) < last]
fit_dates <- as.Date(names(fits))

# the projections take a while: those saved are used again while the chains
# are the same length
draws <- dplyr::bind_rows(parallel::mclapply(names(fits), function(d) {
  n <- paste(vapply(fits[[d]], `[[`, 1, "niterations"), collapse = "_")
  path <- file.path(out, sprintf("projection_%s_%s.rds", format(as.Date(d), "%m%d"), n))
  if(file.exists(path)) return(readRDS(path))
  set.seed(1)
  x <- bvd_projection_draws(fits[[d]], snap, last, n_draws = 100) %>%
    dplyr::left_join(fits[[d]][[1]]$analysis$dates, by = "time_onset") %>%
    dplyr::mutate(fit_date = as.Date(d))
  saveRDS(x, path)
  x
}, mc.cores = min(length(fits), max(1, parallel::detectCores() - 2))))

f_shown <- function(d) snap %>%
  dplyr::filter(.data$date_reported == d) %>%
  dplyr::select(date = "date_onset", "deaths_reported")
shown <- dplyr::bind_rows(lapply(fit_dates, function(d)
  dplyr::bind_rows(dplyr::mutate(f_shown(d), when = "now"),
                   dplyr::mutate(f_shown(last), when = "last")) %>%
    dplyr::filter(.data$date %in% draws$date[draws$fit_date == d]) %>%
    dplyr::mutate(fit_date = d))) %>%
  tidyr::pivot_wider(names_from = "when", values_from = "deaths_reported")
daily <- draws %>%
  dplyr::group_by(.data$fit_date, .data$date) %>%
  dplyr::summarise(p05 = stats::quantile(.data$deaths, 0.05), p50 = stats::median(.data$deaths),
                   p95 = stats::quantile(.data$deaths, 0.95), .groups = "drop") %>%
  dplyr::left_join(shown, by = c("fit_date", "date")) %>%
  dplyr::mutate(fit = factor(format(.data$fit_date, "Fit to %d %b"),
                             levels = format(sort(fit_dates), "Fit to %d %b")))

first_report <- min(snap$date_reported)
lab_est <- format(last, "Projected to %d %B")
lab_last <- format(last, "Reported on %d %B")
f_daily <- function(df) ggplot(df, aes(x = date)) +
  geom_col(aes(y = now, fill = "Shown in the last report fitted"), width = 1, alpha = 0.5) +
  geom_ribbon(aes(ymin = p05, ymax = p95, fill = paste0(lab_est, " (90% interval)")), alpha = 0.4) +
  geom_line(aes(y = p50, colour = paste0(lab_est, " (median)"))) +
  geom_line(aes(y = last, colour = lab_last)) +
  geom_vline(xintercept = first_report, linetype = 2, colour = "grey40") +
  scale_fill_manual(NULL, values = setNames(c("grey70", "#3B7DD8"),
                                            c("Shown in the last report fitted", paste0(lab_est, " (90% interval)")))) +
  scale_colour_manual(NULL, values = setNames(c("#1F4E9C", "black"),
                                              c(paste0(lab_est, " (median)"), lab_last))) +
  labs(x = "Onset date", y = "Fatal cases") +
  theme_bw() + theme(legend.position = "bottom")
for(d in fit_dates)
  ggsave(file.path(out, format(as.Date(d), "fatal_by_onset_projected_%m%d.png")),
         f_daily(dplyr::filter(daily, .data$fit_date == d)) +
           scale_x_date(limits = range(daily$date) + c(-1, 1)) +
           labs(title = format(as.Date(d), "Fit to the reports to %d %B")),
         width = 9, height = 4, dpi = 150)
ggsave(file.path(out, "fatal_by_onset_projected_all.png"),
       f_daily(daily) + facet_wrap(~fit, ncol = 2) + theme(strip.text = element_text(size = 8)) +
         guides(fill = guide_legend(nrow = 2), colour = guide_legend(nrow = 2)),
       width = 11, height = 2.2 * ceiling(length(fit_dates) / 2) + 1, dpi = 150)

# the totals, and the share of the projections that cover what the report shows
totals <- draws %>%
  dplyr::group_by(.data$fit_date, .data$chain, .data$iteration) %>%
  dplyr::summarise(deaths = sum(.data$deaths), .groups = "drop") %>%
  dplyr::group_by(.data$fit_date) %>%
  dplyr::summarise(p05 = stats::quantile(.data$deaths, 0.05), p50 = stats::median(.data$deaths),
                   p95 = stats::quantile(.data$deaths, 0.95), .groups = "drop") %>%
  dplyr::left_join(dplyr::group_by(shown, .data$fit_date) %>%
                     dplyr::summarise(now = sum(.data$now), last = sum(.data$last)),
                   by = "fit_date") %>%
  dplyr::left_join(dplyr::group_by(daily, .data$fit_date) %>%
                     dplyr::summarise(days_covered = mean(.data$last >= .data$p05 & .data$last <= .data$p95)),
                   by = "fit_date")
print(totals)
utils::write.csv(totals, file.path(out, "projected_totals.csv"), row.names = FALSE)
utils::write.csv(daily, file.path(out, "projected_daily.csv"), row.names = FALSE)
cat("Plots in", out, "\n")

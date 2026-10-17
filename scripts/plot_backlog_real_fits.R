# The fits to the reports of the backlog held 21 days (experiments batch 14)
# beside option (f) (batch 13): the fits to 1 August projected to the reports
# of 30 August and 7 October against what those reports show, and the
# eventual counts of the fits to 7 October against what that report shows.
# Usage: Rscript scripts/plot_backlog_real_fits.R <folder of chains of batch 14> <folder of chains of batch 13> [folder of plots]
args <- commandArgs(trailingOnly = TRUE)
# the version of the model with the backlog (BVD_LIB, by default .lib)
.libPaths(c(Sys.getenv("BVD_LIB", ".lib"), .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R"); set.seed(1)
out <- if(length(args) > 2) args[3] else "outputs/backlog_real"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$",
                                       full.names = TRUE))
models <- c(july_tail_reports = "Option (f)", july_backlog = "Held backlog")
f_chains <- function(model, date) {
  folder <- if(model == "july_backlog") args[1] else args[2]
  files <- Sys.glob(file.path(folder, sprintf("*_misdated_triggered_%s_%s_*.rds", model, date)))
  Filter(function(x) is.null(x$error), lapply(files, readRDS))
}
f_by_day <- function(m, date, later) {
  bvd_experiment_by_day(f_chains(m, date), snap, later, n_draws = 60) %>%
    dplyr::mutate(model = factor(models[[m]], levels = models),
                  later = format(later, "%d %B"))
}

# the fits to 1 August, projected to later reports
later_dates <- as.Date(c("2026-08-30", "2026-10-07"))
# the projections take a while: those saved are used again
path <- file.path(out, "by_day_0801.rds")
if(file.exists(path)) aug <- readRDS(path) else {
  aug <- dplyr::bind_rows(lapply(names(models), function(m)
    dplyr::bind_rows(lapply(later_dates, function(d) f_by_day(m, "0801", d)))))
  saveRDS(aug, path)
}
lab <- c(now = "Reported on 1 August", projected = "Projected (median, 90% interval)",
         later = "Actually reported")
cols <- setNames(c("#E69F00", "#009E73", "black"), lab)
f_projection <- function(what, file) {
  df <- aug %>%
    dplyr::filter(.data$count == what, .data$date >= as.Date("2026-06-15")) %>%
    dplyr::mutate(date = as.Date(.data$date),
                  later = factor(paste("Report of", .data$later),
                                 levels = paste("Report of", format(later_dates, "%d %B"))))
  lines <- dplyr::bind_rows(
    dplyr::transmute(df, model, later, date, y = shown_now, what = lab[["now"]]),
    dplyr::transmute(df, model, later, date, y = p50, what = lab[["projected"]]),
    dplyr::transmute(df, model, later, date, y = shown_later, what = lab[["later"]])) %>%
    dplyr::mutate(what = factor(what, levels = lab))
  g <- ggplot(df, aes(x = date)) +
    geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3, na.rm = TRUE) +
    geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
    scale_colour_manual(values = cols, name = NULL) +
    guides(colour = guide_legend(override.aes = list(linewidth = 1.2))) +
    facet_grid(model ~ later) +
    labs(x = "Onset date", y = if(what == "deaths") "Deaths" else "Cases") +
    theme_paper() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          strip.text = element_text(size = 12, face = "bold"),
          legend.position = "bottom", legend.text = element_text(size = 11))
  save_plot(g, file.path(out, file), 11, 7)
}
f_projection("deaths", "projected_deaths_0801.png")
f_projection("cases", "projected_cases_0801.png")
totals <- aug %>%
  dplyr::group_by(.data$model, .data$later, .data$count) %>%
  dplyr::summarise(shown_now = sum(.data$shown_now, na.rm = TRUE),
                   projected = sum(.data$p50, na.rm = TRUE),
                   lo = sum(.data$p05, na.rm = TRUE), hi = sum(.data$p95, na.rm = TRUE),
                   actual = sum(.data$shown_later, na.rm = TRUE), .groups = "drop")
print(as.data.frame(totals))

# the fits to 7 October: the counts the reports will come to show
path <- file.path(out, "by_day_1007.rds")
if(file.exists(path)) oct <- readRDS(path) else {
  oct <- dplyr::bind_rows(lapply(names(models), function(m)
    f_by_day(m, "1007", as.Date("2026-10-07"))))
  saveRDS(oct, path)
}
df <- oct %>%
  dplyr::filter(.data$date >= as.Date("2026-07-01")) %>%
  dplyr::mutate(date = as.Date(.data$date),
                count = factor(ifelse(.data$count == "deaths", "Deaths", "Cases"),
                               levels = c("Cases", "Deaths")))
lab <- c(now = "Reported on 7 October", eventual = "Estimated eventual count (median, 90% interval)")
cols <- setNames(c("#E69F00", "#3B7DD8"), lab)
lines <- dplyr::bind_rows(
  dplyr::transmute(df, model, count, date, y = shown_now, what = lab[["now"]]),
  dplyr::transmute(df, model, count, date, y = q50, what = lab[["eventual"]])) %>%
  dplyr::mutate(what = factor(what, levels = lab))
g <- ggplot(df, aes(x = date)) +
  geom_ribbon(aes(ymin = q05, ymax = q95), fill = "#3B7DD8", alpha = 0.3) +
  geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
  scale_colour_manual(values = cols, name = NULL) +
  guides(colour = guide_legend(override.aes = list(linewidth = 1.2))) +
  facet_grid(count ~ model, scales = "free_y") +
  labs(x = "Onset date", y = NULL) +
  theme_paper() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(size = 12, face = "bold"),
        legend.position = "bottom", legend.text = element_text(size = 11))
save_plot(g, file.path(out, "eventual_1007.png"), 11, 7)
cat("Plots in", out, "\n")

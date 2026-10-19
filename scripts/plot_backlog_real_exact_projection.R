# The fits to the reports to 1 August of the backlog held 21 days, in the
# relaxed (experiments batch 14) and exact (batch 15) forms of the fatal cases
# dated by death, projected to the report of 7 October against what that
# report shows: by onset day, and by week of onset.
# Usage: Rscript scripts/plot_backlog_real_exact_projection.R <folder of chains of batch 14> <folder of chains of batch 15> [folder of plots]
args <- commandArgs(trailingOnly = TRUE)
# the version of the model with the exact form (BVD_LIB, by default .lib)
.libPaths(c(Sys.getenv("BVD_LIB", ".lib"), .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R"); set.seed(1)
out <- if(length(args) > 2) args[3] else "outputs/backlog_real_exact"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$",
                                       full.names = TRUE))
models <- c(july_backlog = "Relaxed form", july_backlog_exact = "Exact form")
f_chains <- function(model, date) {
  folder <- if(model == "july_backlog") args[1] else args[2]
  files <- Sys.glob(file.path(folder, sprintf("*_misdated_triggered_%s_%s_*.rds", model, date)))
  Filter(function(x) is.null(x$error), lapply(files, readRDS))
}
later <- as.Date("2026-10-07")
# the projections take a while: those saved are used again
path <- file.path(out, "projection_draws_0801.rds")
if(file.exists(path)) draws <- readRDS(path) else {
  draws <- dplyr::bind_rows(lapply(names(models), function(m) {
    chains <- f_chains(m, "0801")
    bvd_projection_draws(chains, snap, later, n_draws = 100) %>%
      dplyr::left_join(chains[[1]]$analysis$dates, by = "time_onset") %>%
      dplyr::mutate(model = factor(models[[m]], levels = models))
  }))
  saveRDS(draws, path)
}
shown <- snap %>%
  dplyr::filter(.data$date_reported %in% as.Date(c("2026-08-01", "2026-10-07")),
                .data$date_onset %in% draws$date) %>%
  dplyr::transmute(date = .data$date_onset, deaths = .data$deaths_reported,
                   when = ifelse(.data$date_reported == later, "later", "now")) %>%
  tidyr::pivot_wider(names_from = "when", values_from = "deaths")
f_band <- function(df, ...) df %>%
  dplyr::group_by(.data$model, ...) %>%
  dplyr::summarise(p05 = stats::quantile(.data$deaths, 0.05), p50 = stats::median(.data$deaths),
                   p95 = stats::quantile(.data$deaths, 0.95), .groups = "drop")
lab <- c(now = "Reported on 1 August", projected = "Projected to 7 October (median, 90% interval)",
         later = "Reported on 7 October")
cols <- setNames(c("#E69F00", "#009E73", "black"), lab)

# by onset day
daily <- f_band(draws, .data$date) %>% dplyr::left_join(shown, by = "date")
lines <- dplyr::bind_rows(
  dplyr::transmute(daily, model, date, y = now, what = lab[["now"]]),
  dplyr::transmute(daily, model, date, y = p50, what = lab[["projected"]]),
  dplyr::transmute(daily, model, date, y = later, what = lab[["later"]])) %>%
  dplyr::mutate(what = factor(what, levels = lab))
g_day <- ggplot(daily, aes(x = date)) +
  geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3) +
  geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
  scale_colour_manual(values = cols, name = NULL) +
  facet_wrap(~model, ncol = 1) +
  labs(x = "Onset date", y = "Deaths by onset day") +
  theme_paper() + theme(legend.position = "none")

# by week of onset (weeks starting on Monday; the first and last are part weeks)
f_week <- function(date) as.Date(cut(date, "week", start.on.monday = TRUE))
weekly <- draws %>%
  dplyr::mutate(week = f_week(.data$date)) %>%
  dplyr::group_by(.data$model, .data$chain, .data$iteration, .data$week) %>%
  dplyr::summarise(deaths = sum(.data$deaths), .groups = "drop") %>%
  f_band(.data$week) %>%
  dplyr::left_join(shown %>% dplyr::mutate(week = f_week(.data$date)) %>%
                     dplyr::group_by(.data$week) %>%
                     dplyr::summarise(now = sum(.data$now), later = sum(.data$later)),
                   by = "week")
points <- dplyr::bind_rows(
  dplyr::transmute(weekly, model, week, y = now, what = lab[["now"]]),
  dplyr::transmute(weekly, model, week, y = later, what = lab[["later"]])) %>%
  dplyr::mutate(what = factor(what, levels = lab))
g_week <- ggplot(weekly, aes(x = week + 3)) +
  geom_linerange(aes(ymin = p05, ymax = p95), colour = "#009E73", linewidth = 2.5, alpha = 0.4) +
  geom_point(aes(y = p50, colour = lab[["projected"]]), size = 2) +
  geom_point(data = points, aes(y = y, colour = what), size = 2, shape = 4, stroke = 1.1) +
  scale_colour_manual(values = cols, breaks = unname(lab), name = NULL) +
  guides(colour = guide_legend(nrow = 2)) +
  facet_wrap(~model, ncol = 1) +
  labs(x = "Week of onset", y = "Deaths by week of onset") +
  theme_paper()
save_plot(patchwork::wrap_plots(g_day, g_week + theme(legend.position = "bottom"), nrow = 1),
          file.path(out, "projected_deaths_0801.png"), 12, 7)
utils::write.csv(weekly, file.path(out, "projected_deaths_0801_weekly.csv"), row.names = FALSE)
cat("Plots in", out, "\n")

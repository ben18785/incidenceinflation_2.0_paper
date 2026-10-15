# For one fit date of the chosen model, option (f), the counts projected for
# a series of later reports, against what those reports showed: how well the
# fit predicts as the report it is compared with moves further ahead.
# Usage: Rscript scripts/plot_projection_horizons.R <folder with chains/> <fit date MMDD> <dates of later reports, YYYY-MM-DD, comma-separated>
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R"); set.seed(1)
args <- commandArgs(TRUE)
dir <- args[1]; fit <- args[2]; later <- as.Date(strsplit(args[3], ",")[[1]])
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
ch <- Filter(function(x) is.null(x$error), lapply(
  Sys.glob(file.path(dir, "chains", sprintf("*_july_tail_reports_%s_*.rds", fit))), function(f) {
    x <- readRDS(f)
    for (n in c("deaths", "cases", "reporting_days", "deaths_parameters", "overdispersion", "Rt"))
      if (!is.null(x[[n]])) x[[n]] <- half(x[[n]])
    x }))
date_now <- ch[[1]]$analysis$date_now
by_day <- bind_rows(lapply(later, function(d) bvd_experiment_by_day(ch, snap, d, n_draws = 60) %>%
  mutate(observed = d)))
from <- date_now - 41
for (count in c("cases", "deaths")) {
  df <- by_day %>% filter(.data$count == !!count, date >= from) %>% mutate(date = as.Date(date))
  df$panel <- factor(paste("Sitrep of", trimws(format(df$observed, "%e %B"))),
                     levels = paste("Sitrep of", trimws(format(later, "%e %B"))))
  noun <- count
  lab <- c(now = sprintf("%s reported in the sitrep of %s (fit date)", tools::toTitleCase(noun), trimws(format(date_now, "%e %B"))),
           projected = sprintf("Projected reported %s for that sitrep", noun),
           later = sprintf("Actual %s reported in that sitrep", noun))
  lines <- bind_rows(
    transmute(df, panel, date, y = shown_now, what = lab[["now"]]),
    transmute(df, panel, date, y = p50, what = lab[["projected"]]),
    transmute(df, panel, date, y = shown_later, what = lab[["later"]])) %>%
    mutate(what = factor(what, levels = lab))
  g <- ggplot(df, aes(x = date)) +
    geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3, na.rm = TRUE) +
    geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.5, na.rm = TRUE) +
    scale_colour_manual(values = setNames(c("#E69F00", "#009E73", "black"), lab), name = NULL) +
    guides(colour = guide_legend(override.aes = list(linewidth = 1.2), ncol = 1)) +
    facet_wrap(~panel, nrow = 1) +
    labs(x = "Onset date", y = if (count == "cases") "Confirmed cases" else "Deaths") +
    theme_paper() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 11), axis.text.y = element_text(size = 11),
          axis.title = element_text(size = 13), strip.text = element_text(size = 13, face = "bold"),
          legend.position = "bottom", legend.text = element_text(size = 12))
  save_plot(g, sprintf("outputs/bvd_horizons_%s_%s.png", count, fit), 13, 5)
  # totals over the 28 onset days to the fit date
  tot <- df %>% filter(date > date_now - 28, date <= date_now) %>% group_by(observed) %>%
    summarise(shown_then = sum(shown_now), projected = sum(p50), actual = sum(shown_later), .groups = "drop")
  cat("\n", count, "(latest 28 onset days; projected = sum of daily medians):\n"); print(as.data.frame(tot), row.names = FALSE)
}

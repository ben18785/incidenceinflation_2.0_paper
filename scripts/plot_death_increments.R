# The title figure of docs/bvd_death_slides.tex and its equivalent for cases:
# deaths (cases) added by each report to each onset day (per day since the
# report before), with the changes to onset days at least 35 days old summed
# by report alongside.
# Usage: Rscript scripts/plot_death_increments.R
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
snap <- build_bvd_snapshots(
  list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$", full.names = TRUE))
r <- sort(unique(snap$date_reported))
ylim <- range(r[-1]) + c(-1, 1)
big <- theme(plot.title = element_text(size = 17, face = "bold"),
             axis.title = element_text(size = 16), axis.text = element_text(size = 14),
             legend.title = element_text(size = 14), legend.text = element_text(size = 13))
for(count in c("deaths", "cases")) {
  column <- paste0(count, "_reported")
  increments <- bind_rows(lapply(2:length(r), function(i) {
    a <- snap %>% filter(date_reported == r[i - 1]) %>% select(date_onset, n0 = !!column)
    b <- snap %>% filter(date_reported == r[i]) %>% select(date_onset, n1 = !!column)
    full_join(a, b, by = "date_onset") %>%
      mutate(across(-date_onset, ~ coalesce(.x, 0)),
             report = r[i], days = as.numeric(r[i] - r[i - 1]),
             age = as.numeric(r[i] - date_onset), added = (n1 - n0) / days)
  })) %>% filter(date_onset >= as.Date("2026-05-01"))
  old <- increments %>% filter(age >= 35) %>% group_by(report) %>%
    summarise(added = sum(added), .groups = "drop")
  Count <- paste0(toupper(substr(count, 1, 1)), substr(count, 2, nchar(count)))
  tiles <- ggplot(increments, aes(x = date_onset, y = report,
                                  fill = pmax(pmin(added, 5), -5))) +
    geom_tile(height = 1, width = 1) +
    geom_abline(intercept = 35, slope = 1, linetype = "dashed", colour = "grey30") +
    scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                         limits = c(-5, 5), breaks = c(-5, -2.5, 0, 2.5, 5),
                         labels = c("≤ −5", "−2.5", "0", "2.5", "≥ 5"),
                         name = paste0(Count, " added per day  ")) +
    scale_y_date(limits = ylim, expand = c(0, 0)) +
    labs(x = "Onset date", y = "Date of report",
         title = sprintf("A. %s added to each onset day", Count)) +
    theme_paper() + big + theme(legend.position = "bottom", legend.key.width = unit(1.6, "cm"))
  bars <- ggplot(old, aes(x = report, y = added)) +
    geom_col(fill = "#B2182B", width = 0.8) +
    geom_hline(yintercept = 0, colour = "grey50") +
    coord_flip() +
    scale_x_date(limits = ylim, expand = c(0, 0)) +
    labs(x = NULL, y = "Change per day",
         title = sprintf("B. Changes to %s\nfrom onset days at\nleast 35 days old\n(left of the line)", count)) +
    theme_paper() + big + theme(axis.text.y = element_blank())
  p <- patchwork::wrap_plots(tiles, bars, widths = c(2.3, 1))
  save_plot(p, sprintf("outputs/bvd_%s_increments.png", count), 12, 6.5)
}

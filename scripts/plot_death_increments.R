# The title figure of docs/bvd_death_slides.tex: deaths added by each report
# to each onset day (per day since the report before), with the deaths added
# to onset days at least 35 days old summed by report alongside.
# Usage: Rscript scripts/plot_death_increments.R
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
snap <- build_bvd_snapshots(
  list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$", full.names = TRUE))
r <- sort(unique(snap$date_reported))
increments <- bind_rows(lapply(2:length(r), function(i) {
  a <- snap %>% filter(date_reported == r[i - 1]) %>% select(date_onset, d0 = deaths_reported)
  b <- snap %>% filter(date_reported == r[i]) %>% select(date_onset, d1 = deaths_reported)
  full_join(a, b, by = "date_onset") %>%
    mutate(across(-date_onset, ~ coalesce(.x, 0)),
           report = r[i], days = as.numeric(r[i] - r[i - 1]),
           age = as.numeric(r[i] - date_onset), added = (d1 - d0) / days)
})) %>% filter(date_onset >= as.Date("2026-05-01"))
old <- increments %>% filter(age >= 35) %>% group_by(report) %>%
  summarise(added = sum(added), .groups = "drop")

ylim <- range(r[-1]) + c(-1, 1)
tiles <- ggplot(increments, aes(x = date_onset, y = report,
                                fill = pmax(pmin(added, 5), -5))) +
  geom_tile(height = 1, width = 1) +
  geom_abline(intercept = 35, slope = 1, linetype = "dashed", colour = "grey30") +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       limits = c(-5, 5), breaks = c(-5, -2.5, 0, 2.5, 5),
                       labels = c("≤ −5", "−2.5", "0", "2.5", "≥ 5"),
                       name = "Deaths added\nper day") +
  scale_y_date(limits = ylim, expand = c(0, 0)) +
  labs(x = "Onset date", y = "Date of report",
       title = "A. Deaths added to each onset day") +
  theme_paper() + theme(legend.position = "left")
bars <- ggplot(old, aes(x = report, y = added)) +
  geom_col(fill = "#B2182B", width = 0.8) +
  geom_hline(yintercept = 0, colour = "grey50") +
  coord_flip() +
  scale_x_date(limits = ylim, expand = c(0, 0)) +
  labs(x = NULL, y = "Deaths added per day",
       title = "B. To onset days at least\n35 days old (left of the line)") +
  theme_paper() + theme(axis.text.y = element_blank())
p <- patchwork::wrap_plots(tiles, bars, widths = c(3, 1))
save_plot(p, "outputs/bvd_deaths_increments.png", 12, 6.5)

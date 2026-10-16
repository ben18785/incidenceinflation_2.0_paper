# Completeness of deaths (and cases) by age of onset day, by onset week:
# shown at a report relative to the latest report.
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
later <- max(snap$date_reported)
fin <- snap %>% filter(date_reported == later) %>% select(date_onset, cf = cases_reported, df = deaths_reported)
x <- snap %>% inner_join(fin, by = "date_onset") %>%
  mutate(age = as.numeric(date_reported - date_onset),
         week = as.Date(cut(date_onset, "2 weeks", start.on.monday = TRUE))) %>%
  filter(date_onset >= as.Date("2026-06-01"), date_onset <= later - 35, age <= 60) %>%
  group_by(week, age) %>% filter(n_distinct(date_onset) >= 5) %>%
  summarise(deaths = sum(deaths_reported) / sum(df), cases = sum(cases_reported) / sum(cf),
            cfr_shown = sum(deaths_reported) / sum(cases_reported), .groups = "drop")
long <- tidyr::pivot_longer(x, c(deaths, cases, cfr_shown), names_to = "what") %>%
  mutate(what = factor(what, c("cases", "deaths", "cfr_shown"),
    c("Cases shown / cases on 7 Oct", "Deaths shown / deaths on 7 Oct", "Deaths shown / cases shown")))
g <- ggplot(long, aes(age, value, colour = week, group = week)) +
  geom_line(linewidth = 0.6) + facet_wrap(~what, nrow = 1) +
  scale_colour_viridis_c(name = "Onset fortnight from", end = 0.9, trans = "date", labels = function(d) format(d, "%d %b")) +
  labs(x = "Days from onset to report", y = NULL) + theme_paper() +
  theme(legend.position = "bottom", strip.text = element_text(size = 12))
save_plot(g, "outputs/bvd_death_completeness.png", 13, 5)
print(as.data.frame(x %>% filter(age %in% c(7, 14, 21, 28, 35, 50)) %>%
  mutate(across(deaths:cfr_shown, ~ round(.x, 2)), week = format(week, "%d %b"))), row.names = FALSE)

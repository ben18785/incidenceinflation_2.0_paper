# Deaths by onset date, and the delay from onset to the report that first
# shows each death, by month of onset, from the reports up to 7 October.
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(patchwork)})
tar_source("R")
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
r <- sort(unique(snap$date_reported)); first <- r[1]; later <- max(r)
grid <- tidyr::expand_grid(date_onset = sort(unique(snap$date_onset)), date_reported = r) %>%
  filter(date_reported >= date_onset) %>%
  left_join(select(snap, date_onset, date_reported, deaths_reported), by = c("date_onset", "date_reported")) %>%
  mutate(deaths_reported = coalesce(deaths_reported, 0L)) %>%
  arrange(date_onset, date_reported) %>% group_by(date_onset) %>%
  mutate(added = deaths_reported - lag(deaths_reported, default = 0L)) %>% ungroup() %>%
  mutate(delay = as.numeric(date_reported - date_onset),
         month = factor(format(date_onset, "%B"), levels = month.name),
         in_first = date_reported == first)
cat("deaths removed by later reports:", -sum(pmin(grid$added, 0)), "\n")
months <- c("May", "June", "July", "August", "September")
# a: deaths by onset date on 7 October, split by when they were first shown
a_df <- grid %>% filter(added > 0, date_onset >= as.Date("2026-05-01")) %>%
  mutate(when = case_when(in_first ~ "In the first report (12 July)",
                          delay <= 21 ~ "Within 21 days of onset",
                          TRUE ~ "More than 21 days after onset"),
         when = factor(when, c("In the first report (12 July)", "Within 21 days of onset",
                               "More than 21 days after onset"))) %>%
  group_by(date_onset, when) %>% summarise(n = sum(added), .groups = "drop")
ga <- ggplot(a_df, aes(date_onset, n, fill = when)) + geom_col(width = 1) +
  scale_fill_manual(values = c("grey70", "#0072B2", "#D55E00"), name = NULL) +
  labs(x = "Onset date", y = "Deaths", title = "Deaths by onset date, by when first shown") +
  theme_paper() + theme(legend.position = "bottom")
# b: delay from onset to first shown, deaths added after the first report
b_df <- grid %>% filter(added > 0, !in_first, month %in% months) %>% mutate(month = droplevels(month))
lims <- b_df %>% distinct(month) %>%
  mutate(max_delay = as.numeric(later - as.Date(paste0("2026-", match(as.character(month), month.name), "-01"))),
         min_full = pmax(0, as.numeric(first - as.Date(paste0("2026-", match(as.character(month), month.name), "-01")))))
lab <- grid %>% filter(added > 0, month %in% months) %>% group_by(month) %>%
  summarise(first = sum(added[in_first]), after = sum(added[!in_first]), .groups = "drop") %>%
  mutate(text = sprintf("%d after 12 Jul\n%d in first report", after, first), month = droplevels(month))
gb <- ggplot(b_df, aes(delay, weight = added)) +
  geom_histogram(binwidth = 3, boundary = 0, fill = "#0072B2") +
  geom_vline(data = lims, aes(xintercept = max_delay), linetype = 2, colour = "grey40") +
  geom_text(data = lab, aes(x = Inf, y = Inf, label = text), hjust = 1.05, vjust = 1.3, size = 3.2,
            inherit.aes = FALSE) +
  facet_wrap(~month, nrow = 1, scales = "free_y") +
  labs(x = "Days from onset to the report first showing the death", y = "Deaths",
       title = "Delay to a death first being shown, by month of onset (deaths first shown after 12 July)") +
  theme_paper() + theme(strip.text = element_text(size = 12))
save_plot(ga / gb + plot_layout(heights = c(1, 1)), "outputs/bvd_death_delays_by_month.png", 14, 9)
print(as.data.frame(b_df %>% group_by(month) %>%
  summarise(n = sum(added), median = median(rep(delay, added)), q75 = quantile(rep(delay, added), .75),
            q90 = quantile(rep(delay, added), .9), share_over_21 = round(sum(added[delay > 21]) / n, 2))))
# like with like: onsets after the first report and at least 35 days before
# 7 October, deaths first shown within 35 days of onset
cmp <- grid %>% filter(added > 0, date_onset > first, date_onset <= later - 35, delay <= 35) %>%
  mutate(half = as.Date(cut(date_onset, "2 weeks", start.on.monday = TRUE))) %>%
  group_by(half) %>% summarise(n = sum(added), median = median(rep(delay, added)),
                               share_over_14 = round(sum(added[delay > 14]) / n, 2),
                               share_over_21 = round(sum(added[delay > 21]) / n, 2), .groups = "drop")
print(as.data.frame(cmp))

# c: the same delays, by month of the report that first shows the death
c_df <- grid %>% filter(added > 0, !in_first) %>%
  mutate(report_month = factor(format(date_reported, "%B"), levels = month.name) %>% droplevels(),
         onset_month = factor(format(date_onset, "%B"), levels = month.name) %>% droplevels())
c_lab <- c_df %>% group_by(report_month) %>%
  summarise(text = sprintf("%d deaths\nmedian %g days\n%.0f%% over 21 days", sum(added),
                           median(rep(delay, added)), 100 * sum(added[delay > 21]) / sum(added)),
            .groups = "drop")
gc <- ggplot(c_df, aes(delay, weight = added, fill = onset_month)) +
  geom_histogram(binwidth = 3, boundary = 0) +
  geom_text(data = c_lab, aes(x = Inf, y = Inf, label = text), hjust = 1.05, vjust = 1.2, size = 3.4,
            inherit.aes = FALSE) +
  scale_fill_viridis_d(name = "Month of onset", end = 0.9) +
  facet_wrap(~report_month, nrow = 1, scales = "free_y",
             labeller = as_labeller(c(July = "July (from 14 July)", August = "August",
                                      September = "September", October = "October (to 7 October)"))) +
  labs(x = "Days from onset to the report first showing the death", y = "Deaths") +
  theme_paper() + theme(strip.text = element_text(size = 12), legend.position = "bottom")
save_plot(gc, "outputs/bvd_death_delays_by_report_month.png", 14, 5)
print(as.data.frame(c_df %>% group_by(report_month) %>% summarise(n = sum(added), reports = n_distinct(date_reported),
  median = median(rep(delay, added)), over_21 = round(sum(added[delay > 21]) / n, 2),
  over_60 = round(sum(added[delay > 60]) / n, 2))))

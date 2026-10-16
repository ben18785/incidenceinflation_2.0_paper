# Mean recording delay mu^d by onset day, for option (f) at every fit date.
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
files <- Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_*.rds"))
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
res <- lapply(files, function(f) {
  x <- readRDS(f); if (!is.null(x$error)) return(NULL)
  day1 <- x$analysis$dates$date[1]; fit <- x$analysis$date_now
  list(d = half(x$deaths) %>% transmute(chain, iteration, date = day1 + time_onset - 1, mu = delay_mean, fit = fit),
       p = half(x$deaths_parameters) %>% transmute(chain, n = n_delay_changes, fit = fit))
})
res <- Filter(Negate(is.null), res)
d <- bind_rows(lapply(res, `[[`, "d")); p <- bind_rows(lapply(res, `[[`, "p"))
s <- d %>% group_by(fit, date) %>% summarise(q05 = quantile(mu, .05), q50 = median(mu), q95 = quantile(mu, .95), .groups = "drop") %>%
  mutate(panel = factor(format(fit, "Fit to %d %b"), levels = unique(format(sort(unique(fit)), "Fit to %d %b"))))
g <- ggplot(s, aes(date)) +
  geom_ribbon(aes(ymin = q05, ymax = q95), fill = "#0072B2", alpha = 0.3) +
  geom_line(aes(y = q50), colour = "#0072B2") +
  geom_vline(xintercept = as.Date("2026-07-31"), linetype = 2, colour = "grey50") +
  facet_wrap(~panel, nrow = 2) +
  labs(x = "Onset date", y = "Mean delay from death to recording (days)") + theme_paper() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), strip.text = element_text(size = 12))
save_plot(g, "outputs/bvd_recording_delay_f.png", 14, 6.5)
print(as.data.frame(p %>% group_by(fit) %>% summarise(changes_median = median(n), p_any = round(mean(n > 0), 2), max = max(n))))
print(as.data.frame(s %>% filter(format(date, "%d") %in% c("01", "15")) %>% select(fit, date, q05, q50, q95) %>%
  filter(fit == max(fit)) %>% mutate(across(q05:q95, ~ round(.x, 1)))))

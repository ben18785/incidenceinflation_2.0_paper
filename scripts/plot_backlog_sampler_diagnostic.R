suppressMessages({devtools::load_all("/Users/bcl206/Documents/GitHub/incidenceinflation_2.0", quiet = TRUE)
  library(dplyr); library(tidyr); library(ggplot2); library(targets)})
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
setwd(file.path(S, "wt_cp")); tar_source("R")
d <- simulate_misdated_dataset("backlog", 1)
runs <- expand.grid(sampler = c("metropolis", "slice"), start = c("default", "truth"), stringsAsFactors = FALSE)
lab <- function(r) paste0(r$sampler, ", start ", r$start)
rate <- list(); share <- list(); trace <- list()
for(i in seq_len(nrow(runs))) {
  f <- readRDS(sprintf("%s/diag_%s_%s.rds", S, runs$sampler[i], runs$start[i]))
  p <- f$deaths_parameters
  cols <- grep("^backlog_rate_[0-9]+$", names(p), value = TRUE)
  days <- as.integer(sub("backlog_rate_", "", cols))
  q <- apply(p[, cols], 2, quantile, c(0.05, 0.5, 0.95))
  start <- c(0, head(days, -1))
  rate[[i]] <- bind_rows(lapply(seq_along(days), function(j) tibble(
    day = seq(start[j], days[j]), lo = q[1, j], mid = q[2, j], hi = q[3, j]))) %>% mutate(run = lab(runs[i, ]))
  share[[i]] <- f$deaths %>% group_by(time_onset) %>%
    summarise(lo = quantile(backlog_share, .05), mid = median(backlog_share), hi = quantile(backlog_share, .95)) %>%
    mutate(run = lab(runs[i, ]))
  old <- f$deaths %>% filter(time_onset < 40) %>% group_by(iteration) %>% summarise(v = sum(deaths_recorded))
  trace[[i]] <- bind_rows(
    tibble(iteration = p$iteration, v = p$backlog_rate_rw_sd, what = "sd of the rate walk"),
    tibble(iteration = p$iteration, v = p$backlog_share_rw_sd, what = "sd of the share walk"),
    tibble(iteration = old$iteration, v = old$v, what = "Fatal cases, onsets before day 40"),
    tibble(iteration = p$iteration, v = p$backlog_rate_60, what = "Rate on day 60"),
    f$deaths %>% filter(time_onset == 10) %>% transmute(iteration, v = backlog_share, what = "Share, onset day 10")) %>%
    mutate(run = lab(runs[i, ]))
  cat(lab(runs[i, ]), "minutes", round(f$minutes, 1), "old deaths median", median(old$v), "truth", sum(d$truth_by_day$deaths_recorded[1:39]), "\n")
}
rt <- tibble(day = 1:90, truth = d$settings$recording_backlog$rate[1:90])
g1 <- ggplot(bind_rows(rate), aes(day)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#3B7DD8", alpha = .4) +
  geom_line(aes(y = mid), colour = "#1F4E9C") + geom_step(data = rt, aes(y = truth), direction = "mid") +
  scale_y_log10() + facet_wrap(~run, nrow = 1) + labs(y = "Clearing rate", x = "Day") + theme_bw()
st <- d$truth_by_day %>% select(time_onset, truth = backlog_share)
g2 <- ggplot(bind_rows(share), aes(time_onset)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#3B7DD8", alpha = .4) +
  geom_line(aes(y = mid), colour = "#1F4E9C") + geom_line(data = st, aes(y = truth)) +
  facet_wrap(~run, nrow = 1) + labs(y = "Share in backlog", x = "Day of onset") + theme_bw()
truth_lines <- tibble(what = c("Fatal cases, onsets before day 40", "Rate on day 60", "Share, onset day 10"),
                      v = c(sum(d$truth_by_day$deaths_recorded[1:39]), 0.05, 0.4))
g3 <- ggplot(bind_rows(trace), aes(iteration, v, colour = run)) + geom_line() +
  geom_hline(data = truth_lines, aes(yintercept = v), linetype = 2) +
  facet_wrap(~what, scales = "free_y", ncol = 1) + theme_bw() + theme(legend.position = "bottom")
ggsave(file.path(S, "diag_paths.png"), patchwork::wrap_plots(g1, g2, ncol = 1), width = 13, height = 7, dpi = 120)
ggsave(file.path(S, "diag_traces.png"), g3, width = 9, height = 10, dpi = 120)

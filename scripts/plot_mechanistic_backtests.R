# Back-tests of the series of fits of the mechanistic model (batch 19: the
# exact form, the share of fatal cases reported when their death is recorded
# held at 0.95, the July backlog), one fit to the reports to each date from 1
# August to 14 October. For each fit, the eventual cases and deaths of each
# onset day (posterior median and 90% interval, from the second half of each
# chain) are set against those the report of 14 October showed, which are
# close to final for the earlier onset days. The eventual counts of the
# data-driven model (bvd_cfr_paper, outputs/data-driven/eventual_*.csv) are
# drawn alongside if BVD_DATA_DRIVEN names the folder which holds them.
#
# Usage: Rscript scripts/plot_mechanistic_backtests.R <folder of the chains> [<output folder>]
suppressMessages({library(dplyr); library(tidyr); library(ggplot2)})
args <- commandArgs(trailingOnly = TRUE)
out <- if(length(args) > 1) args[2] else "outputs/mechanistic_backtests"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source("R/bvd.R")
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", "^Varified.*\\.csv$", full.names = TRUE))
date_last <- as.Date("2026-10-14")
date0 <- as.Date("2026-05-11")
last <- snap %>% filter(date_reported == date_last) %>%
  transmute(time_onset = as.integer(date_onset - date0) + 1L,
            cases_shown = cases_reported, deaths_shown = deaths_reported)
f <- Sys.glob(file.path(args[1], "*_exact_*_[0-9].rds"))
labs <- unique(sub("_[0-9]\\.rds$", "", sub(".*_exact_", "", basename(f))))
q <- function(v) c(p05 = unname(quantile(v, .05)), p50 = median(v), p95 = unname(quantile(v, .95)))
res <- lapply(labs, function(l) {
  ch <- lapply(f[grepl(paste0("_exact_", l, "_"), f)], readRDS)
  a <- ch[[1]]$analysis
  now <- a$snapshots %>% group_by(time_onset) %>% filter(time_reported == max(time_reported)) %>% ungroup() %>%
    transmute(time_onset, cases_now = cases_reported, deaths_now = deaths_reported)
  draws <- bind_rows(lapply(seq_along(ch), function(i) {
    x <- ch[[i]]; it <- sort(unique(x$cases$iteration)); keep <- it[it > max(it) / 2]
    inner_join(x$cases %>% filter(iteration %in% keep) %>% select(iteration, time_onset, cases = cases_true),
               x$deaths %>% filter(iteration %in% keep) %>% select(iteration, time_onset, deaths = deaths_true),
               by = c("iteration", "time_onset")) %>% mutate(chain = i)
  }))
  by_day <- draws %>% pivot_longer(c(cases, deaths), names_to = "series") %>% group_by(series, time_onset) %>%
    summarise(p05 = quantile(value, .05), p50 = median(value), p95 = quantile(value, .95), .groups = "drop")
  tot <- draws %>% group_by(chain, iteration) %>% summarise(cases = sum(cases), deaths = sum(deaths), .groups = "drop") %>%
    pivot_longer(c(cases, deaths), names_to = "series") %>% group_by(series) %>%
    summarise(p05 = quantile(value, .05), p50 = median(value), p95 = quantile(value, .95), .groups = "drop")
  shown <- now %>% left_join(last, by = "time_onset")
  tot <- tot %>% mutate(now = c(sum(shown$cases_now), sum(shown$deaths_now)),
                        shown_last = c(sum(shown$cases_shown, na.rm = TRUE), sum(shown$deaths_shown, na.rm = TRUE)))
  list(by_day = by_day %>% left_join(shown %>% pivot_longer(-time_onset, names_to = c("series", ".value"), names_sep = "_"),
                                     by = c("series", "time_onset")) %>% mutate(date_now = a$date_now),
       totals = tot %>% mutate(date_now = a$date_now))
})
by_day <- bind_rows(lapply(res, `[[`, "by_day")) %>% mutate(date = date0 + time_onset - 1, model = "Mechanistic")
totals <- bind_rows(lapply(res, `[[`, "totals"))
dd_dir <- Sys.getenv("BVD_DATA_DRIVEN", "")
ddr <- if(dd_dir != "") read.csv(file.path(dd_dir, "eventual_by_day.csv")) %>%
  mutate(date = as.Date(date), date_now = as.Date(date_now), model = "Data-driven")
ddt <- if(dd_dir != "") read.csv(file.path(dd_dir, "eventual_totals.csv")) %>% mutate(date_now = as.Date(date_now))
fl <- function(d) factor(format(d, "Fit %e %b"), levels = unique(format(sort(unique(d)), "Fit %e %b")))
for (s in c("cases", "deaths")) {
  m <- by_day %>% filter(series == s, date >= as.Date("2026-06-15")) %>% mutate(fit = fl(date_now))
  g <- ggplot(m, aes(date)) +
    geom_col(aes(y = now, fill = "Shown in the last report fitted"), width = 1)
  if(!is.null(ddr))
    g <- g + geom_ribbon(data = ddr %>% filter(series == s, date >= as.Date("2026-06-15")) %>% mutate(fit = fl(date_now)),
                         aes(ymin = p05, ymax = p95, fill = "Data-driven, eventual (90%)"), alpha = 0.45)
  g <- g +
    geom_ribbon(aes(ymin = p05, ymax = p95, fill = "Mechanistic, eventual (90%)"), alpha = 0.5) +
    geom_line(aes(y = p50, colour = "Mechanistic (median)")) +
    geom_line(aes(y = shown, colour = "Shown on 14 Oct")) +
    facet_wrap(~fit, ncol = 2, scales = "free_y") +
    scale_fill_manual(NULL, values = c("Data-driven, eventual (90%)" = "#f4b183", "Mechanistic, eventual (90%)" = "#a6c8f0",
                                       "Shown in the last report fitted" = "grey80")) +
    scale_colour_manual(NULL, values = c("#1f4e9c", "black")) +
    labs(x = "Onset date", y = s) + theme_bw() + theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2), colour = guide_legend(nrow = 2))
  ggsave(file.path(out, paste0("backtest_", s, ".png")), g, width = 10, height = 13, dpi = 130)
}
tt <- bind_rows(totals %>% select(-shown_last, -now) %>% mutate(model = "Mechanistic"), if(!is.null(ddt)) ddt %>% mutate(model = "Data-driven")) %>%
  left_join(totals %>% select(series, date_now, shown_last), by = c("series", "date_now"))
g <- ggplot(tt, aes(date_now, p50, colour = model)) +
  geom_pointrange(aes(ymin = p05, ymax = p95), position = position_dodge(width = 2.5)) +
  geom_line(data = distinct(tt, series, date_now, shown_last), aes(date_now, shown_last, colour = "Shown on 14 Oct"), inherit.aes = FALSE) +
  facet_wrap(~series, scales = "free_y") +
  scale_colour_manual(NULL, values = c("Data-driven" = "#d0711f", "Mechanistic" = "#1f4e9c", "Shown on 14 Oct" = "black")) +
  labs(x = "Fit date", y = "Eventual total of the onset days up to the fit date (90% interval)") + theme_bw() + theme(legend.position = "bottom")
ggsave(file.path(out, "totals.png"), g, width = 10, height = 4.5, dpi = 130)
print(tt %>% mutate(across(c(p05, p50, p95), round)) %>% arrange(series, date_now, model) %>% as.data.frame())

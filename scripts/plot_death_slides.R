# Figures and numbers for docs/bvd_death_slides.tex, from the chains of
# batches 11 and 12 (from the branch experiment-results) and the reports.
# The numbers are printed, to be typed into the slides.
# Usage: Rscript scripts/plot_death_slides.R <folder of batch 11 chains> <folder of batch 12 chains>
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R")
set.seed(1)
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$", full.names = TRUE))
later <- max(snap$date_reported)
fmt <- function(x) ifelse(abs(x) >= 100, format(round(x), big.mark = ","),
                          ifelse(abs(x) >= 10, sprintf("%.1f", x), sprintf("%.2f", x)))
qs <- function(x) sprintf("%s (%s--%s)", fmt(median(x)), fmt(quantile(x, .05)), fmt(quantile(x, .95)))

# --- deaths added by each report to onset days at least 35 days old --------
r <- sort(unique(snap$date_reported))
late <- bind_rows(lapply(2:length(r), function(i) {
  a <- snap %>% filter(date_reported == r[i - 1]) %>% select(date_onset, d0 = deaths_reported)
  b <- snap %>% filter(date_reported == r[i]) %>% select(date_onset, d1 = deaths_reported)
  x <- full_join(a, b, by = "date_onset") %>% mutate(across(-date_onset, ~ coalesce(.x, 0)),
                                                    age = as.numeric(r[i] - date_onset))
  tibble(report = r[i], days = as.numeric(r[i] - r[i - 1]),
         old = sum((x$d1 - x$d0)[x$age >= 35]), recent = sum((x$d1 - x$d0)[x$age < 35]))
}))
p <- ggplot(late, aes(x = report, y = old / days)) +
  geom_col(fill = "#D55E00", width = 0.8) +
  labs(x = "Date of report", y = "Deaths added per day") +
  theme_paper()
save_plot(p, "outputs/bvd_deaths_late_additions.png", 9, 4)
cat("late additions (35d+), per day, by report:\n")
print(as.data.frame(late %>% mutate(per_day = round(old / days, 1), report = format(report, "%d %b"))),
      row.names = FALSE)

# --- batch 11 at every fit date ------------------------------------------
half <- function(d) { n <- max(d$iteration); d[d$iteration > n / 2, ] }
load_chains <- function(files) lapply(files, function(f) {
  x <- readRDS(f)
  for (n in c("deaths", "cases", "reporting_days", "deaths_parameters", "overdispersion", "Rt"))
    if (!is.null(x[[n]])) x[[n]] <- half(x[[n]])
  x
})
b11 <- load_chains(Sys.glob(file.path(args[1], "*.rds")))
b11 <- purrr::keep(b11, ~is.null(.$error))
by_day <- bvd_experiment_by_day(b11, snap, later, n_draws = 60)
for (count in c("cases", "deaths")) {
  g <- plot_bvd_experiment_counts(by_day, count) + ggplot2::labs(title = NULL, subtitle = NULL)
  save_plot(g, sprintf("outputs/bvd_deaths_fits_%s.png", count), 12, 6.5)
}

summ <- function(ch, label) {
  g <- function(n) bind_rows(lapply(ch, `[[`, n))
  p <- g("deaths_parameters"); d <- g("deaths")
  a <- ch[[1]]$analysis; day1 <- a$dates$date[1]; tl <- max(d$time_onset)
  rh <- function(x, chain) split_rhat(x, chain)
  recent <- d[d$time_onset > tl - 28, ] %>% group_by(chain, iteration) %>%
    summarise(cfr = mean(cfr), deaths = sum(deaths_recorded), .groups = "drop")
  sh <- function(dt) { s <- snap %>% filter(date_reported == dt) %>%
    mutate(t = as.numeric(date_onset - day1) + 1) %>% filter(t > tl - 28, t <= tl); sum(s$deaths_reported) }
  out <- tibble(model = label, date = format(a$date_now, "%d %b"), chains = length(ch),
    f = qs(p$dated_fraction), f_rhat = rh(p$dated_fraction, p$chain),
    tau = qs(p$triggered), tau_rhat = rh(p$triggered, p$chain),
    tail = qs(p$recording_tail_weight), tail_rhat = rh(p$recording_tail_weight, p$chain),
    tail_mean = qs(p$recording_tail_mean), tail_mean_rhat = rh(p$recording_tail_mean, p$chain),
    cfr28 = qs(recent$cfr), cfr28_rhat = rh(recent$cfr, recent$chain),
    eventual28 = qs(recent$deaths), shown_now = sh(a$date_now))
  if (a$date_now < later) {
    pr <- bvd_projection_draws(ch, snap, later, n_draws = 60) %>% filter(time_onset > tl - 28) %>%
      group_by(chain, iteration) %>% summarise(d = sum(deaths), .groups = "drop")
    out$projected_later <- qs(pr$d); out$shown_later <- sh(later)
  }
  out
}
dates11 <- unique(sub(".*_(\\d{4})_\\d\\.rds$", "\\1", basename(Sys.glob(file.path(args[1], "*.rds")))))
tab11 <- bind_rows(lapply(dates11, function(dt) {
  ch <- purrr::keep(b11, ~format(.$analysis$date_now, "%m%d") == dt)
  summ(ch, "base")
}))
options(width = 250)
cat("\nbatch 11:\n"); print(as.data.frame(tab11), row.names = FALSE)

# --- 16 September, the options for the recording delay ---------------------
versions <- list(base = Sys.glob(file.path(args[1], "*early_0916_*.rds")),
                 july = Sys.glob(file.path(args[2], "*july_0916_*.rds")),
                 one_delay = Sys.glob(file.path(args[2], "*one_delay_0916_*.rds")),
                 reports = Sys.glob(file.path(args[2], "*early_reports_0916_*.rds")),
                 one_delay_reports = Sys.glob(file.path(args[2], "*one_delay_reports_0916_*.rds")))
tab12 <- bind_rows(lapply(names(versions), function(v) summ(load_chains(versions[[v]]), v)))
cat("\n16 September:\n"); print(as.data.frame(tab12), row.names = FALSE)

# per-report multipliers of the fit with report effects at 16 September
ch <- load_chains(versions$reports)
p <- bind_rows(lapply(ch, `[[`, "deaths_parameters"))
day1 <- ch[[1]]$analysis$dates$date[1]
cols <- grep("^recording_report_[0-9]+$", names(p), value = TRUE)
eff <- tibble(report = day1 + as.integer(sub("recording_report_", "", cols)) - 1,
              q05 = sapply(cols, function(cc) quantile(p[[cc]], .05)),
              q50 = sapply(cols, function(cc) median(p[[cc]])),
              q95 = sapply(cols, function(cc) quantile(p[[cc]], .95)))
g <- ggplot(eff, aes(x = report)) +
  geom_hline(yintercept = 1, colour = "grey60") +
  geom_pointrange(aes(y = q50, ymin = q05, ymax = q95), size = 0.2, colour = "#0072B2") +
  scale_y_log10() +
  labs(x = "Date of report", y = "Multiplier of the hazard of recording") +
  theme_paper()
save_plot(g, "outputs/bvd_deaths_report_effects.png", 9, 4)
cat("\nreport effects:\n"); print(as.data.frame(eff %>% mutate(report = format(report, "%d %b"),
                                                                across(q05:q95, ~round(.x, 2)))), row.names = FALSE)
cat("sd:", qs(p$recording_report_sd), "\n")
cat("done\n")

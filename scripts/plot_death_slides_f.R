# Figures and numbers for docs/bvd_death_slides.tex from the chosen model,
# option (f): the delay to a death being recorded fixed for onset days to 31
# July and free to change after, with an effect of each report on the tail of
# that delay alone (batch 13, run 23 on the branch experiment-results).
# Usage: Rscript scripts/plot_death_slides_f.R <folder with chains/>
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R")
set.seed(1)
dir <- commandArgs(TRUE)[1]
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
later <- max(snap$date_reported)
fmt <- function(x, digits) formatC(x, format = "f", digits = digits, big.mark = ",")
qs <- function(x, digits = 2) sprintf("%s & %s to %s", fmt(median(x), digits),
                                      fmt(quantile(x, .05), digits), fmt(quantile(x, .95), digits))
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
load_chains <- function(files) lapply(files, function(f) {
  x <- readRDS(f)
  for (n in c("deaths", "cases", "reporting_days", "deaths_parameters", "overdispersion", "Rt",
              "Rt_changepoints", "reporting_changepoints", "revisions"))
    if (!is.null(x[[n]]) && "iteration" %in% names(x[[n]])) x[[n]] <- half(x[[n]])
  x
})

plot_slide_counts <- function(by_day, count, later, from = as.Date("2026-07-10")) {
  noun <- if (count == "cases") "cases" else "deaths"
  lab <- c(now = sprintf("%s reported as of that sitrep", tools::toTitleCase(noun)),
           projected = sprintf("Projected reported %s for sitrep on %s", noun, paste(as.integer(format(later, "%d")), format(later, "%B"))),
           later = sprintf("Actual %s reported on %s", noun, paste(as.integer(format(later, "%d")), format(later, "%B"))))
  cols <- setNames(c("#E69F00", "#009E73", "black"), lab)
  df <- dplyr::filter(by_day, .data$count == !!count, .data$date >= from) %>%
    dplyr::mutate(date = as.Date(.data$date), panel = format_date_now(.data$date_now))
  lines <- dplyr::bind_rows(
    dplyr::transmute(df, panel, date, y = shown_now, what = lab[["now"]]),
    dplyr::transmute(df, panel, date, y = p50, what = lab[["projected"]]),
    dplyr::transmute(df, panel, date, y = shown_later, what = lab[["later"]])) %>%
    dplyr::mutate(what = factor(what, levels = lab))
  g <- ggplot(df, aes(x = date)) +
    geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3, na.rm = TRUE) +
    geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
    scale_colour_manual(values = cols, name = NULL) +
    guides(colour = guide_legend(override.aes = list(linewidth = 1.2))) +
    facet_wrap(~panel, scales = "free_x", nrow = 2) +
    labs(x = "Onset date", y = if (count == "cases") "Confirmed cases" else "Deaths") +
    theme_paper() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          strip.text = element_text(size = 14, face = "bold"),
          legend.position = "bottom", legend.text = element_text(size = 12))
  save_plot(g, sprintf("outputs/bvd_deaths_fits_%s.png", count), 12, 6.8)
}


# --- fits at every fit date ----------------------------------------------
ch_all <- load_chains(Sys.glob(file.path(dir, "chains", "*_july_tail_reports_*.rds")))
ch_all <- purrr::keep(ch_all, ~is.null(.$error))
by_day <- bvd_experiment_by_day(ch_all, snap, later, n_draws = 60)
plot_slide_counts(by_day, "cases", later)
plot_slide_counts(by_day, "deaths", later)

# --- projected and actual deaths, latest 28 onset days of each fit ----------
dates <- sort(unique(sapply(ch_all, function(x) format(x$analysis$date_now))))
rows <- c()
for (dt in dates) {
  ch <- purrr::keep(ch_all, ~format(.$analysis$date_now) == dt)
  a <- ch[[1]]$analysis; day1 <- a$dates$date[1]
  tl <- max(ch[[1]]$deaths$time_onset)
  sh <- function(d) { s <- snap %>% filter(date_reported == d) %>%
    mutate(t = as.numeric(date_onset - day1) + 1) %>% filter(t > tl - 28, t <= tl); sum(s$deaths_reported) }
  if (a$date_now < later) {
    pr <- bvd_projection_draws(ch, snap, later, n_draws = 60) %>% filter(time_onset > tl - 28) %>%
      group_by(chain, iteration) %>% summarise(d = sum(deaths), .groups = "drop")
    rows <- c(rows, sprintf("%s & %s & %s (%s--%s) & %s \\\\", trimws(format(a$date_now, "%e %b")),
                            fmt(sh(a$date_now), 0), fmt(median(pr$d), 0), fmt(quantile(pr$d, .05), 0),
                            fmt(quantile(pr$d, .95), 0), fmt(sh(later), 0)))
  }
}
cat("\nprojections:\n", paste(rows, collapse = "\n"), "\n")

# --- the fit to 7 October -------------------------------------------------
ch <- purrr::keep(ch_all, ~.$analysis$date_now == later)
g <- function(n) bind_rows(lapply(ch, `[[`, n))
p <- g("deaths_parameters"); d <- g("deaths"); rt <- g("Rt"); rd <- g("reporting_days")
tl <- max(d$time_onset)
cases_rows <- c(
  paste("$R_t$, latest onset day &", qs(rt$Rt[rt$time_onset == max(rt$time_onset)])),
  paste("Number of changes in $R_t$ &", qs(g("Rt_changepoints")$n_changes, 0)),
  paste("Overdispersion $\\kappa$ &", qs(g("overdispersion")$overdispersion, 0)),
  paste("Mean reporting delay, latest onset day (days) &", qs(rd$mean[rd$time_onset == max(rd$time_onset)], 1)),
  paste("Sd of reporting delay, latest onset day (days) &", qs(rd$sd[rd$time_onset == max(rd$time_onset)], 1)),
  paste("Number of changes in the reporting delay &", qs(g("reporting_changepoints")$n_changes, 0)),
  paste("Wrong records per genuine case reported, $\\eta$ &", qs(g("revisions")$eta, 3)),
  paste("Daily probability a wrong record is removed, $\\rho$ &", qs(g("revisions")$rho, 3)))
deaths_rows <- c(
  paste("$\\cfr_t$, latest onset day &", qs(d$cfr[d$time_onset == tl])),
  paste("Number of changes in $\\cfr_t$ &", qs(p$n_cfr_changes, 0)),
  paste("Share of fatal cases whose death brings the report, $\\tau$ &", qs(p$triggered)),
  paste("Share of fatal cases misdated, $f$ &", qs(p$dated_fraction)),
  paste("Mean delay from death to recording, latest onset day (days) &", qs(d$delay_mean[d$time_onset == tl], 1)),
  paste("Share of deaths recorded in the tail, $\\omega^{d}$ &", qs(p$recording_tail_weight)),
  paste("Mean of the tail, $m^{d}$ (days) &", qs(p$recording_tail_mean, 0)),
  paste("Sd of the effects of each report, $s$ &", qs(p$recording_report_sd)),
  paste("Probability a wrong record is shown as dead, $\\delta$ &", qs(p$wrong_dead)))
cat("\ncases:\n", paste0(cases_rows, " \\\\", collapse = "\n"), "\n")
cat("\ndeaths:\n", paste0(deaths_rows, " \\\\", collapse = "\n"), "\n")

# effect of each report on the tail of recording, fit to 7 October
day1 <- ch[[1]]$analysis$dates$date[1]
cols <- grep("^recording_report_[0-9]+$", names(p), value = TRUE)
eff <- tibble(report = day1 + as.integer(sub("recording_report_", "", cols)) - 1,
              q05 = sapply(cols, function(cc) quantile(p[[cc]], .05)),
              q50 = sapply(cols, function(cc) median(p[[cc]])),
              q95 = sapply(cols, function(cc) quantile(p[[cc]], .95)))
fig <- ggplot(eff, aes(x = report)) +
  geom_hline(yintercept = 1, colour = "grey60") +
  geom_pointrange(aes(y = q50, ymin = q05, ymax = q95), size = 0.2, colour = "#0072B2") +
  scale_y_log10() +
  labs(x = "Date of report", y = "Multiplier of the hazard of\nrecording in the tail") +
  theme_paper() + theme(axis.title = element_text(size = 13), axis.text = element_text(size = 11))
save_plot(fig, "outputs/bvd_deaths_report_effects.png", 9, 4)
cat("\nreport effects above 2 (median):\n")
print(as.data.frame(eff %>% filter(q50 > 2) %>% mutate(report = format(report, "%d %b"), across(q05:q95, ~round(.x, 1)))), row.names = FALSE)
cat("done\n")

# The fits to the reports of the backlog held 21 days in the exact form of the
# fatal cases dated by death (experiments batch 15) beside the relaxed form
# (batch 14): the share of deaths in the backlog by onset day, its clearing
# rate by report, the deaths by onset day, the case fatality ratio, Rt, and a
# table of every parameter with its split R-hat.
# Usage: Rscript scripts/plot_backlog_real_exact.R <folder of chains of batch 14> <folder of chains of batch 15> [folder of plots]
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(targets)})
tar_source("R")
out <- if(length(args) > 2) args[3] else "outputs/backlog_real_exact"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
models <- c(july_backlog = "Relaxed form", july_backlog_exact = "Exact form")
fit_dates <- c("0801" = "Fit to 1 August", "1007" = "Fit to 7 October")
fills <- c("Relaxed form" = "#E69F00", "Exact form" = "#3B7DD8")
lines <- c("Relaxed form" = "#B07800", "Exact form" = "#1F4E9C")
f_chains <- function(model, date) {
  folder <- if(model == "july_backlog") args[1] else args[2]
  files <- Sys.glob(file.path(folder, sprintf("*_misdated_triggered_%s_%s_*.rds", model, date)))
  Filter(function(x) is.null(x$error), lapply(files, readRDS))
}
fits <- list()
for(m in names(models)) for(d in names(fit_dates)) fits[[paste(m, d)]] <- f_chains(m, d)
f_rows <- function(chains, name) dplyr::bind_rows(lapply(chains, function(x)
  dplyr::mutate(x[[name]], chain = x$chain)))
f_dates <- function(chains) chains[[1]]$analysis$dates

# split R-hat: each chain cut in two halves of the same length
f_rhat <- function(x, chain) {
  s <- split(x, chain)
  n <- min(lengths(s))
  h <- n %/% 2
  if(h < 2) return(NA_real_)
  halves <- unlist(lapply(s, function(v) { v <- utils::tail(v, 2 * h); list(v[1:h], v[(h + 1):(2 * h)]) }),
                   recursive = FALSE)
  W <- mean(vapply(halves, stats::var, numeric(1)))
  B <- h * stats::var(vapply(halves, mean, numeric(1)))
  if(!is.finite(W) || W == 0) return(NA_real_)
  sqrt(((h - 1) / h * W + B / h) / W)
}
f_band <- function(df, column, ...) df %>%
  dplyr::group_by(...) %>%
  dplyr::summarise(lo = stats::quantile(.data[[column]], 0.05), mid = stats::median(.data[[column]]),
                   hi = stats::quantile(.data[[column]], 0.95),
                   rhat = f_rhat(.data[[column]], .data$chain), .groups = "drop")
f_by_onset <- function(table, column) dplyr::bind_rows(lapply(names(fits), function(key) {
  parts <- strsplit(key, " ")[[1]]
  f_band(f_rows(fits[[key]], table), column, time_onset) %>%
    dplyr::left_join(f_dates(fits[[key]]), by = "time_onset") %>%
    dplyr::mutate(model = factor(models[[parts[1]]], levels = models), fit = fit_dates[[parts[2]]])
}))
f_plot <- function(df, y, log = FALSE) {
  g <- ggplot(df, aes(x = date, fill = model, colour = model)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.25, colour = NA) +
    geom_line(aes(y = mid)) +
    scale_fill_manual(NULL, values = fills) +
    scale_colour_manual(NULL, values = lines) +
    facet_wrap(~fit, nrow = 1, scales = "free_x") +
    labs(x = "Onset date", y = y) +
    theme_paper() + theme(legend.position = "bottom")
  if(log) g + scale_y_log10() else g
}

# the share of deaths in the backlog by onset day
share <- f_by_onset("deaths", "backlog_share")
# the clearing rate by report: each rate holds from the report before to its
# report (the first from the first onset day)
rate <- dplyr::bind_rows(lapply(names(fits), function(key) {
  parts <- strsplit(key, " ")[[1]]
  chains <- fits[[key]]
  p <- f_rows(chains, "deaths_parameters")
  columns <- grep("^backlog_rate_[0-9]+$", names(p), value = TRUE)
  dates <- f_dates(chains)
  p %>%
    dplyr::select("chain", dplyr::all_of(columns)) %>%
    tidyr::pivot_longer(dplyr::all_of(columns), names_to = "report", values_to = "rate") %>%
    dplyr::mutate(report = as.integer(sub("backlog_rate_", "", .data$report))) %>%
    f_band("rate", report) %>%
    dplyr::arrange(.data$report) %>%
    dplyr::mutate(start = dplyr::lag(.data$report, default = 1L),
                  model = factor(models[[parts[1]]], levels = models),
                  fit = fit_dates[[parts[2]]],
                  date_start = dates$date[1] + .data$start - 1,
                  date_end = dates$date[1] + .data$report - 1)
}))
rate_steps <- rate %>%
  dplyr::rowwise() %>%
  dplyr::reframe(model, fit, lo, mid, hi, date = seq(.data$date_start, .data$date_end, by = 1))
g_share <- f_plot(share, "Share of deaths\nin the backlog") + theme(legend.position = "none")
g_rate <- f_plot(rate_steps, "Clearing rate\n(per day)", log = TRUE) +
  labs(x = "Date (the first rate covers the days to the first report)")
save_plot(patchwork::wrap_plots(g_share, g_rate, ncol = 1), file.path(out, "backlog_share_rate.png"), 11, 7)

deaths <- f_by_onset("deaths", "deaths_true")
save_plot(f_plot(deaths, "Fatal cases"), file.path(out, "deaths.png"), 11, 5)
cfr <- f_by_onset("deaths", "cfr")
save_plot(f_plot(cfr, "Case fatality ratio"), file.path(out, "cfr.png"), 11, 5)
rt <- f_by_onset("Rt", "Rt")
save_plot(f_plot(rt, expression(R[t]), log = TRUE) + geom_hline(yintercept = 1, linetype = 2),
          file.path(out, "Rt.png"), 11, 5)

# every parameter, with its split R-hat
tables <- c("overdispersion", "revisions", "Rt_changepoints", "reporting_changepoints",
            "reporting_effects", "deaths_parameters")
parameters <- dplyr::bind_rows(lapply(names(fits), function(key) {
  parts <- strsplit(key, " ")[[1]]
  dplyr::bind_rows(lapply(tables, function(t) {
    df <- f_rows(fits[[key]], t)
    columns <- setdiff(names(df)[vapply(df, is.numeric, logical(1))], c("iteration", "chain"))
    df %>%
      dplyr::select("chain", dplyr::all_of(columns)) %>%
      tidyr::pivot_longer(-"chain", names_to = "parameter") %>%
      dplyr::filter(!is.na(.data$value)) %>%
      f_band("value", parameter) %>%
      dplyr::mutate(table = t)
  })) %>%
    dplyr::mutate(model = models[[parts[1]]], fit = fit_dates[[parts[2]]])
}))
utils::write.csv(parameters, file.path(out, "parameters.csv"), row.names = FALSE)
for(x in c("share", "rate", "deaths", "cfr", "rt"))
  utils::write.csv(get(x), file.path(out, paste0(x, ".csv")), row.names = FALSE)
cat("Plots in", out, "\n")

#' Draws of the counts a later report should show for each onset day, from
#' the chains of one joint experiment
#'
#' For each draw, the cases and fatal cases of an onset day not yet shown in
#' the report of the fit date are shown by the later report with the
#' probability the model gives, conditional on their not having been shown by
#' the fit date: a fatal case dated by onset is shown as dead once reported
#' and its death recorded (with a share of such cases reported when the death
#' is recorded, where deaths bring reports), and one dated by death once
#' reported after the delay from its death. Day-of-the-week and per-report
#' effects on the delays, and wrong records, are left out.
#'
#' @param fits the chains of one experiment
#' @param snapshots_all all the reports (from build_bvd_snapshots)
#' @param date_later the date of the later report
#' @param n_draws draws taken from each chain
#' @param onset_to_death mean and sd of the time from onset to death, where
#'   the model takes it as given
#'
#' @return a tibble of chain, iteration, time_onset, cases and deaths
bvd_projection_draws <- function(fits, snapshots_all, date_later, n_draws = 100,
                                 onset_to_death = list(mean = 9.3, sd = 5.5)) {
  ii <- asNamespace("incidenceinflation")
  analysis <- fits[[1]]$analysis
  day_first <- analysis$dates$date[1]
  t_now <- as.numeric(analysis$date_now - day_first) + 1
  t_later <- as.numeric(date_later - day_first) + 1
  shown <- snapshots_all %>%
    dplyr::filter(.data$date_reported == analysis$date_now) %>%
    dplyr::transmute(time_onset = as.numeric(.data$date_onset - day_first) + 1,
                     .data$cases_reported, .data$deaths_reported)
  shown <- shown[match(seq_len(t_now), shown$time_onset), ]
  shown[is.na(shown)] <- 0
  t_later_reports <- as.numeric(unique(snapshots_all$date_reported[
    snapshots_all$date_reported > analysis$date_now &
      snapshots_all$date_reported <= date_later]) - day_first) + 1
  is_misdated <- "dated_fraction" %in% names(fits[[1]]$deaths_parameters)
  # the holding period of a backlog, which its label gives ("backlog held 21 days")
  held <- regmatches(fits[[1]]$model, regexpr("backlog held [0-9]+ days", fits[[1]]$model))
  backlog_hold_days <- if(length(held) == 1) as.numeric(gsub("[^0-9]", "", held)) else 0
  lags <- ii$lag_probabilities_gamma(onset_to_death$mean, onset_to_death$sd)
  # the probability, from the fit date to the later report, that one of a set
  # of kinds of case not shown yet is shown
  f_draw <- function(n, shown, F_now, F_later) {
    p <- rowSums(n * (F_later - F_now)) / pmax(rowSums(n * (1 - F_now)), 1e-12)
    shown + stats::rbinom(length(shown), pmax(rowSums(n) - shown, 0),
                          pmin(pmax(p, 0), 1))
  }
  purrr::map_dfr(fits, function(fit) {
    iterations <- unique(fit$deaths$iteration)
    iterations <- iterations[sort(sample.int(length(iterations),
                                             min(n_draws, length(iterations))))]
    purrr::map_dfr(iterations, function(iteration) {
      deaths <- dplyr::filter(fit$deaths, .data$iteration == !!iteration) %>%
        dplyr::arrange(.data$time_onset)
      cases <- dplyr::filter(fit$cases, .data$iteration == !!iteration) %>%
        dplyr::arrange(.data$time_onset)
      reporting <- dplyr::filter(fit$reporting_days, .data$iteration == !!iteration) %>%
        dplyr::arrange(.data$time_onset)
      parameters <- fit$deaths_parameters[
        which.min(abs(fit$deaths_parameters$iteration - iteration)), ]
      recording_effects <- if(is_misdated)
        list(tail = list(weight = parameters$recording_tail_weight,
                         mean = parameters$recording_tail_mean),
             before = list(lag_probabilities = lags))
      # where each report has its own effect on recording: those fitted, and
      # for the reports after the fit date, effects drawn from their prior
      if(is_misdated && !is.null(parameters$recording_report_sd)) {
        columns <- grep("^recording_report_[0-9]+$", names(parameters), value = TRUE)
        days_fitted <- as.numeric(sub("recording_report_", "", columns))
        days_later <- setdiff(t_later_reports, days_fitted)
        recording_effects <- ii$update_report_multipliers(c(recording_effects, list(
          report_tail_only = grepl("report effects on recording tail", fits[[1]]$model),
          report_days = c(days_fitted, days_later),
          report_log_effects = c(log(unlist(parameters[columns])),
                                 stats::rnorm(length(days_later), 0,
                                              parameters$recording_report_sd)))))
      }
      # where deaths join a backlog: its share for each onset day and its
      # hazard for each report interval fitted, and for the reports after the
      # fit date, hazards drawn from its random walk
      if(is_misdated && !is.null(parameters$backlog_rate_rw_sd)) {
        columns <- grep("^backlog_rate_[0-9]+$", names(parameters), value = TRUE)
        days_fitted <- as.numeric(sub("backlog_rate_", "", columns))
        days_later <- sort(setdiff(t_later_reports, days_fitted))
        gaps <- diff(c(max(days_fitted), days_later))
        log_rate <- log(unlist(parameters[columns]))
        log_rate_later <- log_rate[length(log_rate)] +
          cumsum(stats::rnorm(length(days_later), 0,
                              parameters$backlog_rate_rw_sd * sqrt(gaps / 7)))
        recording_effects$tail <- NULL
        recording_effects$backlog <- ii$refresh_backlog(list(
          logit_share = stats::qlogis(deaths$backlog_share),
          week_of_day = seq_len(nrow(deaths)),
          log_rate = c(log_rate, log_rate_later),
          report_days = c(days_fitted, days_later),
          hold_days = backlog_hold_days))
      }
      tau <- parameters$triggered
      F <- t(vapply(seq_len(t_now), function(t) {
        survivals <- ii$joint_survivals(
          c(t_now, t_later), t,
          list(mean = reporting$mean[t], sd = reporting$sd[t]),
          list(mean = deaths$delay_mean[t], sd = deaths$delay_sd[t]),
          dated_reporting_parameters = if(is_misdated) "recording",
          recording_effects = recording_effects)
        S_reported <- exp(survivals$log_reported)
        S_recorded <- exp(survivals$log_recorded)
        c(reported = 1 - S_reported,
          fatal_reported = 1 - S_reported * ((1 - tau) + tau * S_recorded),
          fatal_dead = (1 - S_recorded) * (tau + (1 - tau) * (1 - S_reported)),
          dated = -expm1(survivals$log_dated))
      }, numeric(8)))
      n_dated <- deaths$dated_by_death
      n_fatal <- deaths$deaths_recorded - n_dated
      n_other <- cases$cases_true - deaths$deaths_true
      n_cases <- cbind(n_other, n_fatal, n_dated)
      dplyr::tibble(
        chain = fit$chain, iteration = iteration, time_onset = seq_len(t_now),
        cases = f_draw(n_cases, shown$cases_reported,
                       F[, c(1, 3, 7)], F[, c(2, 4, 8)]),
        deaths = f_draw(cbind(n_fatal, n_dated), shown$deaths_reported,
                        F[, c(5, 7)], F[, c(6, 8)]))
    })
  })
}

#' Estimated and projected counts by onset day for each joint experiment,
#' with what the reports showed
#'
#' @param chains chains of joint experiments
#' @inheritParams bvd_projection_draws
#'
#' @return a tibble with a row per experiment, count and onset day: the
#'   eventual count (q05, q50, q95), the count projected for the later report
#'   (p05, p50, p95; missing where the fit is of the later date) and the counts
#'   shown in the reports of the fit date and the later date
bvd_experiment_by_day <- function(chains, snapshots_all, date_later, n_draws = 100) {
  groups <- bvd_experiment_groups(chains)
  q <- function(df, prefix) df %>%
    dplyr::group_by(.data$count, .data$time_onset) %>%
    dplyr::summarise(!!paste0(prefix, "05") := stats::quantile(.data$value, 0.05),
                     !!paste0(prefix, "50") := stats::median(.data$value),
                     !!paste0(prefix, "95") := stats::quantile(.data$value, 0.95),
                     .groups = "drop")
  long <- function(df) tidyr::pivot_longer(df, c("cases", "deaths"),
                                           names_to = "count", values_to = "value")
  purrr::map_dfr(groups, function(fits) {
    analysis <- fits[[1]]$analysis
    eventual <- purrr::map_dfr(fits, function(fit)
      dplyr::left_join(fit$deaths, fit$cases,
                       by = c("iteration", "chain", "time_onset")) %>%
        dplyr::transmute(.data$chain, .data$iteration, .data$time_onset,
                         cases = .data$cases_true + .data$deaths_recorded - .data$deaths_true,
                         deaths = .data$deaths_recorded))
    out <- q(long(eventual), "q")
    if(analysis$date_now < date_later)
      out <- dplyr::left_join(
        out, q(long(bvd_projection_draws(fits, snapshots_all, date_later, n_draws)), "p"),
        by = c("count", "time_onset"))
    reports <- snapshots_all %>%
      dplyr::filter(.data$date_reported %in% c(analysis$date_now, date_later)) %>%
      dplyr::inner_join(analysis$dates, by = c("date_onset" = "date")) %>%
      dplyr::mutate(when = ifelse(.data$date_reported == analysis$date_now, "now", "later")) %>%
      tidyr::pivot_longer(c("cases_reported", "deaths_reported"),
                          names_to = "count", values_to = "shown") %>%
      dplyr::mutate(count = sub("_reported", "", .data$count)) %>%
      dplyr::select("count", "time_onset", "when", "shown") %>%
      tidyr::pivot_wider(names_from = "when", values_from = "shown",
                         names_prefix = "shown_")
    out %>%
      dplyr::left_join(reports, by = c("count", "time_onset")) %>%
      dplyr::left_join(analysis$dates, by = "time_onset") %>%
      dplyr::mutate(experiment = fits[[1]]$experiment, model = fits[[1]]$model,
                    date_now = analysis$date_now, .before = 1)
  })
}

#' Counts by onset date at each fit date, as plot_bvd_changepoint_cases():
#' the eventual count estimated (green), what the report of the fit date
#' showed (orange), what the later report showed (black) and the count
#' projected for that report (purple)
#'
#' @param by_day from bvd_experiment_by_day, for one model
#' @param count "cases" or "deaths"
#' @param from the first onset date shown
plot_bvd_experiment_counts <- function(by_day, count, from = as.Date("2026-07-10")) {
  df <- dplyr::filter(by_day, .data$count == !!count, .data$date >= from)
  df$panel <- format_date_now(df$date_now)
  if(!"p50" %in% names(df))
    df$p05 <- df$p50 <- df$p95 <- NA_real_
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                         fill = "#009E73", alpha = 0.3) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$p05, ymax = .data$p95),
                         fill = "#CC79A7", alpha = 0.3, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data$shown_later), colour = "black",
                       linewidth = 0.3, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data$shown_now), colour = "#E69F00",
                       linewidth = 0.3, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data$p50), colour = "#CC79A7",
                       linewidth = 0.4, na.rm = TRUE) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50), colour = "#009E73",
                       linewidth = 0.4) +
    ggplot2::facet_wrap(~panel, scales = "free_x", nrow = 2) +
    ggplot2::labs(x = "Onset date",
                  y = if(count == "cases") "Confirmed cases" else "Deaths",
                  title = bvd_model_title(unique(df$model)),
                  subtitle = paste(
                    "Green: estimated eventual count (median and 90% interval).",
                    "Orange: report of the fit date. Purple: projected for the report of",
                    format(max(df$date_now[!is.na(df$p50)], df$date_now), "%d %b"),
                    "\nBlack: that report. Panels are the dates of the fits.")) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' A title for a model of the joint experiments, from its label
bvd_model_title <- function(model) {
  title <- if(grepl("counted on day of death", model))
    "Time from onset to death supplied; fraction counted on the day of death estimated"
  else "Previous joint model"
  if(grepl("deaths bring reports", model))
    title <- paste0(title, "; deaths can bring reports")
  if(grepl("fixed to 31 July", model))
    title <- paste0(title, "; recording delay fixed to 31 July")
  if(grepl("one recording delay", model))
    title <- paste0(title, "; one recording delay")
  if(grepl("report effects on recording", model))
    title <- paste0(title, "; report effects on recording")
  title
}

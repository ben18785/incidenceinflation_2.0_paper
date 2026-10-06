# Preparing real snapshot data for analysis as if on a given date.

#' Restricts snapshots to what was known on a given date
#'
#' @param df a tibble with columns date_onset, date_reported, cases_reported
#' @param date_onset_min earliest onset date analysed
#' @param date_now the date on which the analysis is imagined to take place
#' @return a list of 'snapshots' (integer times), 'dates' (lookup from time to
#' date) and 'later' (the counts for the same onset dates as known on the
#' latest reporting date available, for comparison with nowcasts)
prepare_real_analysis <- function(df, date_onset_min, date_now) {
  date_onset_min <- as.Date(date_onset_min)
  date_now <- as.Date(date_now)
  window <- df %>%
    dplyr::filter(.data$date_onset >= date_onset_min,
                  .data$date_onset <= date_now)
  known <- dplyr::filter(window, .data$date_reported <= date_now)

  # counts reported on the onset day itself are taken to be genuine, so cannot
  # later fall below this: where they do, the onset-day report is dropped and
  # the onset day is treated as first observed the day after
  falls_below <- known %>%
    dplyr::group_by(.data$date_onset) %>%
    dplyr::arrange(.data$date_reported, .by_group = TRUE) %>%
    dplyr::summarise(
      drop_first = .data$date_reported[1] == .data$date_onset[1] &
        any(.data$cases_reported < .data$cases_reported[1]))
  known <- known %>%
    dplyr::left_join(falls_below, by = "date_onset") %>%
    dplyr::filter(!(.data$drop_first & .data$date_reported == .data$date_onset)) %>%
    dplyr::select(-"drop_first")

  later <- window %>%
    dplyr::filter(.data$date_reported == max(df$date_reported)) %>%
    dplyr::transmute(
      time_onset = as.integer(.data$date_onset - date_onset_min) + 1L,
      cases_later = .data$cases_reported)

  list(
    snapshots = snapshots_to_times(known, date_onset_min),
    dates = dplyr::tibble(
      date = seq(date_onset_min, date_now, by = 1),
      time_onset = seq_along(seq(date_onset_min, date_now, by = 1))),
    later = later,
    date_now = date_now,
    date_later = max(df$date_reported))
}

#' Compares nowcasts for real data with the counts known later
score_real_fit <- function(fit_summary, analysis, days_recent = 14) {
  out <- dplyr::tibble(model = fit_summary$model, seconds = fit_summary$seconds,
                       failed = !is.null(fit_summary$error),
                       error = ifelse(is.null(fit_summary$error), NA_character_,
                                      fit_summary$error))
  if(out$failed)
    return(out)
  cases <- dplyr::left_join(fit_summary$cases, analysis$later, by = "time_onset")
  recent <- dplyr::filter(cases, .data$time_onset > max(cases$time_onset) - days_recent)
  out$recent_coverage <- mean(recent$cases_later >= recent$q05 &
                                recent$cases_later <= recent$q95)
  out$recent_abs_error <- mean(abs(recent$q50 - recent$cases_later)) /
    mean(recent$cases_later)
  out$recent_bias <- mean(recent$q50 - recent$cases_later) / mean(recent$cases_later)
  out$recent_width <- mean(recent$q95 - recent$q05) / mean(recent$cases_later)
  f_parameter <- function(name) {
    row <- dplyr::filter(fit_summary$parameters, .data$parameter == name)
    if(nrow(row) == 0) NA_character_
    else sprintf("%.3g (%.3g, %.3g)", row$q50, row$q05, row$q95)
  }
  for(name in c("reporting_mean", "reporting_sd", "eta", "rho", "pi"))
    out[[name]] <- f_parameter(name)
  if(!is.null(fit_summary$batch_parameters))
    out$p_any_batch <- mean(fit_summary$batch_parameters$n_batches > 0)
  out
}

#' Estimates piecewise-constant Rt from a series of case counts taken as complete
#'
#' With a gamma(shape, rate) prior, Rt for a period has posterior
#' gamma(shape + sum of cases, rate + sum of expected infectiousness), where
#' the sums are over the onset days in the period (see equation 2.4 of Bajaj,
#' Thompson & Lambert 2025).
#'
#' @param cases vector of case counts for consecutive onset days
#' @param Rt_piece_width number of onset days sharing each Rt value
#' @param serial_parameters named list of mean and sd of the serial interval
#' @param prior named list of shape and rate
#' @param serial_max longest serial interval allowed for
#' @return a tibble with a row for each onset day and columns time_onset,
#' q05, q50 and q95
estimate_Rt_complete_data <- function(cases, Rt_piece_width, serial_parameters,
                                      prior = list(shape = 1, rate = 1),
                                      serial_max = 40) {
  w <- incidenceinflation:::weights_series(serial_max, serial_parameters)
  n_days <- length(cases)
  infectiousness <- purrr::map_dbl(seq_len(n_days), function(t) {
    lags <- seq_len(min(serial_max, t - 1))
    sum(w[lags] * cases[t - lags])
  })
  Rt_index <- ceiling(seq_len(n_days) / Rt_piece_width)
  # the first onset day has no earlier cases to have generated it
  is_used <- seq_len(n_days) > 1
  dplyr::tibble(time_onset = seq_len(n_days), Rt_index = Rt_index,
                cases = cases, infectiousness = infectiousness,
                is_used = is_used) %>%
    dplyr::group_by(.data$Rt_index) %>%
    dplyr::mutate(
      shape = prior$shape + sum(.data$cases[.data$is_used]),
      rate = prior$rate + sum(.data$infectiousness[.data$is_used])) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      .data$time_onset,
      q05 = stats::qgamma(0.05, .data$shape, .data$rate),
      q50 = stats::qgamma(0.5, .data$shape, .data$rate),
      q95 = stats::qgamma(0.95, .data$shape, .data$rate))
}

#' Rt estimated from counts reported so far and from counts known later
#'
#' @param analysis as returned by prepare_real_analysis()
#' @return a tibble of estimates labelled 'naive' (taking the counts reported
#' by the analysis date as complete) and 'gold standard' (using the counts
#' known at the later date)
estimate_Rt_naive_and_gold <- function(analysis, Rt_piece_width, serial_parameters) {
  reported <- analysis$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::summarise(cases = dplyr::last(.data$cases_reported)) %>%
    dplyr::arrange(.data$time_onset)
  later <- dplyr::arrange(analysis$later, .data$time_onset)
  dplyr::bind_rows(
    estimate_Rt_complete_data(reported$cases, Rt_piece_width, serial_parameters) %>%
      dplyr::mutate(estimator = "naive"),
    estimate_Rt_complete_data(later$cases_later, Rt_piece_width, serial_parameters) %>%
      dplyr::mutate(estimator = "gold standard"))
}

#' Empirical distribution of reporting delays for each onset date
#'
#' The proportion of the cases eventually known for an onset date (those in
#' the latest file) which had been reported by each delay.
#'
#' @param df a tibble with columns date_onset, date_reported, cases_reported
#' @param n_periods number of consecutive periods into which onset dates are split
#' @return a tibble with a row for each onset date and delay
reporting_delay_ecdf <- function(df, date_onset_min, date_onset_max,
                                 delay_max = 40, n_periods = 3) {
  date_onset_min <- as.Date(date_onset_min)
  date_onset_max <- as.Date(date_onset_max)
  final <- df %>%
    dplyr::filter(.data$date_reported == max(.data$date_reported)) %>%
    dplyr::select("date_onset", cases_final = "cases_reported")
  n_days <- as.integer(date_onset_max - date_onset_min) + 1
  df %>%
    dplyr::filter(.data$date_onset >= date_onset_min,
                  .data$date_onset <= date_onset_max) %>%
    dplyr::mutate(delay = as.integer(.data$date_reported - .data$date_onset)) %>%
    dplyr::filter(.data$delay <= delay_max) %>%
    dplyr::left_join(final, by = "date_onset") %>%
    dplyr::mutate(
      ecdf = .data$cases_reported / .data$cases_final,
      period_index = pmin(n_periods, 1 + floor(
        n_periods * as.integer(.data$date_onset - date_onset_min) / n_days)))
}

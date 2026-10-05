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

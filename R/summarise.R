# Summaries of fits and comparisons with the truth.

quantile_probs <- function() c(0.05, 0.25, 0.5, 0.75, 0.95)

#' Posterior quantiles of a column of draws within groups
summarise_draws_by <- function(df, value, ...) {
  df %>%
    dplyr::group_by(...) %>%
    dplyr::summarise(
      q05 = stats::quantile({{ value }}, 0.05),
      q25 = stats::quantile({{ value }}, 0.25),
      q50 = stats::quantile({{ value }}, 0.5),
      q75 = stats::quantile({{ value }}, 0.75),
      q95 = stats::quantile({{ value }}, 0.95),
      mean = mean({{ value }}),
      .groups = "drop")
}

#' Reduces a fit to posterior summaries, discarding the first half as warm-up
#'
#' @param fit as returned by fit_model()
#' @return a list of tibbles of posterior summaries (or the error message)
summarise_fit <- function(fit) {
  out <- list(model = fit$model, seconds = fit$seconds,
              niterations = fit$niterations, error = NULL)
  if(!is.null(fit$error)) {
    out$error <- fit$error
    return(out)
  }
  warmup <- floor(fit$niterations / 2)
  f_keep <- function(df) dplyr::filter(df, .data$iteration > warmup)

  out$cases <- summarise_draws_by(f_keep(fit$cases), .data$cases_true, .data$time_onset)
  out$Rt <- f_keep(fit$Rt) %>%
    summarise_draws_by(.data$Rt, .data$Rt_index) %>%
    dplyr::left_join(fit$Rt_lookup, by = "Rt_index", relationship = "many-to-many")
  out$parameters <- f_keep(fit$reporting) %>%
    tidyr::pivot_longer(c("mean", "sd"), names_to = "parameter") %>%
    dplyr::mutate(parameter = paste0("reporting_", .data$parameter)) %>%
    summarise_draws_by(.data$value, .data$parameter)
  if(!is.null(fit$revisions)) {
    revisions <- f_keep(fit$revisions) %>%
      tidyr::pivot_longer(c("eta", "rho", "pi"), names_to = "parameter") %>%
      summarise_draws_by(.data$value, .data$parameter)
    out$parameters <- dplyr::bind_rows(out$parameters, revisions)
    out$acceptance_revisions <- mean(diff(fit$revisions$eta) != 0)
  }
  out$acceptance_reporting <- mean(diff(fit$reporting$mean) != 0)
  if(!is.null(fit$batches)) {
    out$batches <- f_keep(fit$batches)
    out$batch_parameters <- f_keep(fit$batch_parameters)
  }
  out
}

#' Probability that each onset day lies in the footprint of a batch
batch_footprint_probability <- function(fit_summary, onset_times) {
  if(is.null(fit_summary$batch_parameters))
    return(dplyr::tibble(time_onset = onset_times, probability = NA_real_))
  n_draws <- nrow(fit_summary$batch_parameters)
  batches <- fit_summary$batches
  probability <- purrr::map_dbl(onset_times, function(t) {
    in_footprint <- batches$start <= t & t < batches$start + batches$width
    dplyr::n_distinct(batches$iteration[in_footprint]) / n_draws
  })
  dplyr::tibble(time_onset = onset_times, probability = probability)
}

#' Compares a fit to a simulated dataset with the truth
#'
#' @param fit_summary as returned by summarise_fit()
#' @param dataset as returned by simulate_dataset()
#' @param days_recent number of latest onset days over which nowcasts are assessed
#' @return a one-row tibble of performance measures
score_fit <- function(fit_summary, dataset, days_recent = 14) {
  out <- dplyr::tibble(regime = dataset$regime, replicate = dataset$replicate,
                       model = fit_summary$model, seconds = fit_summary$seconds,
                       failed = !is.null(fit_summary$error),
                       error = ifelse(is.null(fit_summary$error), NA_character_,
                                      fit_summary$error))
  if(out$failed)
    return(out)

  truth <- dataset$truth
  cases <- dplyr::left_join(fit_summary$cases, truth$cases, by = "time_onset")
  f_cases <- function(df, prefix) {
    stats::setNames(
      list(mean(df$cases_true >= df$q05 & df$cases_true <= df$q95),
           mean(abs(df$q50 - df$cases_true)) / mean(df$cases_true),
           mean(df$q50 - df$cases_true) / mean(df$cases_true),
           mean(df$q95 - df$q05) / mean(df$cases_true)),
      paste0(prefix, c("_coverage", "_abs_error", "_bias", "_width")))
  }
  day_last <- max(cases$time_onset)
  recent <- dplyr::filter(cases, .data$time_onset > day_last - days_recent)
  out <- dplyr::bind_cols(out, dplyr::as_tibble(f_cases(recent, "recent")))
  # onset days in the footprint of the simulated batch (if any)
  if(!is.null(truth$batches)) {
    footprint <- dplyr::filter(
      cases, .data$time_onset >= truth$batches$start,
      .data$time_onset < truth$batches$start + truth$batches$width)
    out <- dplyr::bind_cols(out, dplyr::as_tibble(f_cases(footprint, "footprint")))
  }

  Rt <- dplyr::left_join(fit_summary$Rt, truth$Rt, by = "time_onset",
                         suffix = c("_estimated", "")) %>%
    dplyr::filter(.data$Rt_index == max(.data$Rt_index)) %>%
    dplyr::slice(1)
  out$Rt_last_bias <- Rt$q50 - Rt$Rt
  out$Rt_last_covered <- Rt$Rt >= Rt$q05 & Rt$Rt <= Rt$q95
  out$Rt_last_width <- Rt$q95 - Rt$q05

  f_parameter <- function(name) {
    row <- dplyr::filter(fit_summary$parameters, .data$parameter == name)
    if(nrow(row) == 0) NA_real_ else row$q50
  }
  out$reporting_mean <- f_parameter("reporting_mean")
  out$reporting_sd <- f_parameter("reporting_sd")
  out$eta <- f_parameter("eta")
  out$rho <- f_parameter("rho")
  out$pi <- f_parameter("pi")
  if(!is.null(fit_summary$batch_parameters)) {
    out$p_any_batch <- mean(fit_summary$batch_parameters$n_batches > 0)
    out$mean_n_batches <- mean(fit_summary$batch_parameters$n_batches)
  }
  out
}

#' Averages performance measures across replicates
summarise_scores <- function(scores) {
  scores %>%
    dplyr::group_by(.data$regime, .data$model) %>%
    dplyr::summarise(
      n_fits = dplyr::n(),
      n_failed = sum(.data$failed),
      dplyr::across(
        dplyr::any_of(c("recent_coverage", "recent_abs_error", "recent_bias",
                        "recent_width", "footprint_coverage", "footprint_abs_error",
                        "footprint_bias", "Rt_last_bias", "Rt_last_width",
                        "reporting_mean", "reporting_sd", "eta", "rho", "pi",
                        "p_any_batch", "seconds")),
        ~mean(.x, na.rm = TRUE)),
      Rt_last_coverage = mean(.data$Rt_last_covered, na.rm = TRUE),
      .groups = "drop") %>%
    dplyr::mutate(
      regime = factor(.data$regime, levels = simulation_regimes()$regime),
      model = factor(.data$model, levels = model_names())) %>%
    dplyr::arrange(.data$regime, .data$model)
}

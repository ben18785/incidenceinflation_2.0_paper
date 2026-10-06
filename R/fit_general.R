# Fitting with either a Poisson or a negative binomial renewal model, and
# applying the models to real snapshots as of a given date.
#
# fit_model_general() repeats fit_model() (R/fit.R) with the renewal
# distribution as an option. fit_model() is retained unchanged so that results
# already obtained with it remain valid; the two should be merged when the
# whole pipeline is next rerun.

#' Fits a model to snapshots with a Poisson or negative binomial renewal model
#'
#' @inheritParams fit_model
#' @param is_negative_binomial whether the renewal model is negative binomial
#' (with overdispersion parameter kappa, such that the variance of the case
#' count is mean + mean^2 / kappa) rather than Poisson
#' @return as fit_model()
fit_model_general <- function(snapshots, model, serial_parameters, Rt_piece_width,
                              niterations, seed, settings = fit_settings(),
                              is_negative_binomial = FALSE) {
  set.seed(seed)
  if(model == "original")
    snapshots <- monotonise_snapshots(snapshots)

  onset_times <- sort(unique(snapshots$time_onset))
  data <- snapshots %>%
    dplyr::mutate(Rt_index = ceiling(
      (.data$time_onset - min(onset_times) + 1) / Rt_piece_width))
  n_Rt <- max(data$Rt_index)

  largest_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- max(onset_times) - largest_reported$time_onset
  initial_cases_true <- largest_reported %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + 2 * exp(-days_before_end / 4)) + 5 * (days_before_end < 5)))
  max_cases <- ceiling(4 * max(initial_cases_true$cases_true) + 50)

  priors <- list(Rt = settings$priors$Rt,
                 reporting = settings$priors$reporting,
                 max_cases = max_cases)
  if(is_negative_binomial)
    priors$overdispersion <- list(mean = 20, sd = 20)
  initial_revision_parameters <- NULL
  if(model %in% c("sporadic", "full")) {
    priors$revisions <- settings$priors$revisions
    priors$max_erroneous <- settings$max_erroneous
    initial_revision_parameters <- settings$initial_revisions
  }
  if(model == "full") {
    initial_revision_parameters$pi <- settings$initial_pi
    initial_revision_parameters$shifts <- settings$shifts
    initial_revision_parameters$shift_probs <- settings$shift_probs
    priors$batches <- settings$priors$batches
  }

  time_start <- Sys.time()
  result <- tryCatch(
    incidenceinflation::mcmc(
      niterations = niterations,
      data = data,
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = initial_cases_true,
      initial_reporting_parameters = list(mean = 7, sd = 4),
      initial_Rt = dplyr::tibble(Rt_index = seq_len(n_Rt), Rt = 1),
      reporting_metropolis_parameters = settings$reporting_metropolis,
      print_to_screen = FALSE,
      initial_overdispersion = 10,
      is_negative_binomial = is_negative_binomial,
      overdispersion_metropolis_sd = 3,
      initial_revision_parameters = initial_revision_parameters,
      revision_metropolis_parameters = settings$revision_metropolis),
    error = function(e) list(error = conditionMessage(e)))
  result$model <- model
  result$seconds <- as.numeric(Sys.time() - time_start, units = "secs")
  result$niterations <- niterations
  result$Rt_lookup <- unique(dplyr::select(data, "time_onset", "Rt_index"))
  result
}

#' Fits a model to real snapshots as of an analysis date
#'
#' Sporadic revisions and misdating are allowed for under the "full" model;
#' batches are not.
#'
#' @param analysis as returned by prepare_real_analysis()
#' @param model "original" or "full"
#' @param dataset a label for the data
#' @return a list holding the labels, the analysis and the summary of the fit
fit_real_analysis <- function(analysis, model, is_negative_binomial, dataset,
                              serial_parameters, Rt_piece_width, niterations) {
  settings <- fit_settings()
  settings$max_erroneous <- max(3, incidenceinflation::max_downward_revision(
    analysis$snapshots) + 1)
  settings$priors$reporting <- list(mean_mu = 7, mean_sigma = 10,
                                    sd_mu = 5, sd_sigma = 5)
  settings$priors$revisions$eta_mu <- 0.005
  settings$priors$revisions$eta_sigma <- 0.005
  settings$priors$batches <- NULL
  fit <- fit_model_general(analysis$snapshots, model, serial_parameters,
                           Rt_piece_width, niterations, seed = 1,
                           settings = settings,
                           is_negative_binomial = is_negative_binomial)
  overdispersion <- NULL
  if(is_negative_binomial & is.null(fit$error)) {
    draws <- fit$overdispersion$overdispersion[
      fit$overdispersion$iteration > floor(niterations / 2)]
    overdispersion <- stats::quantile(draws, c(0.05, 0.5, 0.95))
  }
  list(dataset = dataset,
       model = model,
       is_negative_binomial = is_negative_binomial,
       analysis = analysis,
       summary = summarise_fit(fit),
       overdispersion = overdispersion)
}

#' Scores a list of results from fit_real_analysis() against counts known later
score_real_results <- function(results) {
  purrr::map_dfr(results, function(result) {
    renewal <- if(isTRUE(result$is_negative_binomial)) "negative binomial" else "Poisson"
    out <- dplyr::bind_cols(
      dplyr::tibble(
        dataset = if(is.null(result$dataset)) NA_character_ else result$dataset,
        date_now = result$analysis$date_now,
        renewal = renewal),
      score_real_fit(result$summary, result$analysis))
    out$overdispersion <- if(is.null(result$overdispersion)) NA_real_
    else unname(result$overdispersion[2])
    out
  })
}

#' Averages scores across analysis dates
summarise_real_scores <- function(scores) {
  scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::group_by(.data$dataset, .data$renewal, .data$model) %>%
    dplyr::summarise(
      n_dates = dplyr::n(),
      coverage = mean(.data$recent_coverage),
      abs_error = mean(.data$recent_abs_error),
      bias = mean(.data$recent_bias),
      width = mean(.data$recent_width),
      overdispersion = mean(.data$overdispersion),
      seconds = mean(.data$seconds),
      .groups = "drop")
}

#' Selects the results with a given renewal model
filter_results <- function(results, is_negative_binomial) {
  results[purrr::map_lgl(
    results, ~isTRUE(.$is_negative_binomial) == is_negative_binomial)]
}

#' Reads a processed table of snapshots
read_snapshots <- function(path, date_column = "date_onset") {
  df <- dplyr::as_tibble(utils::read.csv(path))
  dplyr::tibble(date_onset = as.Date(df[[date_column]]),
                date_reported = as.Date(df$date_reported),
                cases_reported = as.integer(df$cases_reported))
}

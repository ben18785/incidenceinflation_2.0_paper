# Fitting the models to a table of snapshots.

#' The models fitted
#'
#' - "original": the model of Bajaj, Thompson & Lambert (2025), in which
#'   reported counts can only rise. Since it cannot be fitted to counts which
#'   fall, each onset day's counts are first replaced by their running maximum.
#' - "sporadic": erroneous records are entered and withdrawn one at a time.
#' - "full": sporadic revisions, misdated onset days and batches of erroneous
#'   records.
model_names <- function() c("original", "sporadic", "full")

#' Replaces reported counts by their running maximum for each onset day
monotonise_snapshots <- function(snapshots) {
  snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::mutate(cases_reported = cummax(.data$cases_reported)) %>%
    dplyr::ungroup()
}

#' Default priors and tuning used for all fits
fit_settings <- function() {
  list(
    priors = list(
      Rt = list(shape = 1, rate = 1),
      reporting = list(mean_mu = 5, mean_sigma = 10, sd_mu = 3, sd_sigma = 5),
      revisions = list(eta_mu = 0.02, eta_sigma = 0.02,
                       rho_alpha = 1, rho_beta = 4,
                       pi_alpha = 1, pi_beta = 9),
      # batches are rare a priori: about one per 200 onset days
      batches = list(beta = 0.005, zeta = 4, phi_mu = 0.3, phi_sigma = 0.2,
                     rho_batch = 0.05,
                     beta_alpha = 1, beta_beta = 199,
                     max_batch = 60)),
    max_erroneous = 4,
    shifts = c(-2, -1, 1, 2),
    shift_probs = c(0.15, 0.35, 0.35, 0.15),
    initial_revisions = list(eta = 0.01, rho = 0.2),
    initial_pi = 0.05,
    revision_metropolis = list(eta_step = 0.3, rho_step = 0.3, pi_step = 0.3),
    reporting_metropolis = list(mean_step = 0.1, sd_step = 0.05))
}

#' Fits a model to snapshots
#'
#' @param snapshots a tibble with columns time_onset, time_reported, cases_reported
#' @param model one of model_names()
#' @param serial_parameters named list of mean and sd of the serial interval
#' @param Rt_piece_width number of onset days sharing each Rt value
#' @param niterations number of MCMC iterations
#' @param seed random seed
#' @param settings as returned by fit_settings()
#' @return a list with the draws (as returned by incidenceinflation::mcmc), or
#' with an element 'error' if the model could not be fitted
fit_model <- function(snapshots, model, serial_parameters, Rt_piece_width,
                      niterations, seed, settings = fit_settings()) {
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
  # start recent onset days well above the counts reported so far
  days_before_end <- max(onset_times) - largest_reported$time_onset
  initial_cases_true <- largest_reported %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + 2 * exp(-days_before_end / 4)) + 5 * (days_before_end < 5)))
  max_cases <- ceiling(4 * max(initial_cases_true$cases_true) + 50)

  priors <- list(Rt = settings$priors$Rt,
                 reporting = settings$priors$reporting,
                 max_cases = max_cases)
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
      initial_revision_parameters = initial_revision_parameters,
      revision_metropolis_parameters = settings$revision_metropolis),
    error = function(e) list(error = conditionMessage(e)))
  result$model <- model
  result$seconds <- as.numeric(Sys.time() - time_start, units = "secs")
  result$niterations <- niterations
  result$Rt_lookup <- unique(dplyr::select(data, "time_onset", "Rt_index"))
  result
}

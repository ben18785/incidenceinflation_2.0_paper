# Simulated datasets under different regimes of revision to reported counts.

#' Parameters shared by all simulated datasets
simulation_settings <- function() {
  list(
    days_total = 60,
    Rt = c(rep(1.3, 30), rep(0.9, 30)),
    Rt_piece_width = 15,
    serial_parameters = list(mean = 5, sd = 3),
    reporting_parameters = list(mean = 5, sd = 3),
    days_max_follow_up = 60,
    initial_parameters = list(mean = 30, length = 20),
    shifts = c(-2, -1, 1, 2),
    shift_probs = c(0.15, 0.35, 0.35, 0.15))
}

#' The regimes under which data are simulated
#'
#' @return a tibble with a row for each regime: eta, rho and pi are the
#' revision parameters used to simulate (NA if that mechanism is absent) and
#' has_batch indicates whether a batch of erroneous records is included
simulation_regimes <- function() {
  dplyr::tribble(
    ~regime,      ~eta,  ~rho, ~pi,  ~has_batch,
    "none",       NA,    NA,   NA,   FALSE,
    "sporadic",   0.03,  0.15, NA,   FALSE,
    "misdating",  0.005, 0.15, 0.10, FALSE,
    "batch",      0.005, 0.15, NA,   TRUE,
    "combined",   0.03,  0.15, 0.10, TRUE)
}

#' Simulates a dataset of snapshots under a regime
#'
#' @param regime_row a one-row tibble from simulation_regimes()
#' @param replicate index of replicate (used with the regime to set the seed)
#' @return a list holding the snapshots (as would be available on the last
#' day), the truth and the settings used
simulate_dataset <- function(regime_row, replicate) {
  settings <- simulation_settings()
  set.seed(1000 * match(regime_row$regime, simulation_regimes()$regime) + replicate)

  revision_parameters <- NULL
  if(!is.na(regime_row$eta)) {
    revision_parameters <- list(eta = regime_row$eta, rho = regime_row$rho)
    if(!is.na(regime_row$pi)) {
      revision_parameters$pi <- regime_row$pi
      revision_parameters$shifts <- settings$shifts
      revision_parameters$shift_probs <- settings$shift_probs
    }
  }
  # a single batch, detected while later onset days are still being reported
  batches <- NULL
  if(regime_row$has_batch)
    batches <- dplyr::tibble(start = 28, width = 7, phi = 0.25, time_detected = 48)

  Rt_function <- stats::approxfun(seq_len(settings$days_total), settings$Rt)
  df <- incidenceinflation::generate_snapshots(
    settings$days_total, Rt_function,
    settings$serial_parameters, settings$reporting_parameters,
    days_max_follow_up = settings$days_max_follow_up,
    initial_parameters = settings$initial_parameters,
    revision_parameters = revision_parameters,
    batches = batches)

  list(
    regime = regime_row$regime,
    replicate = replicate,
    snapshots = dplyr::select(df, -"cases_true"),
    truth = list(
      cases = unique(dplyr::select(df, "time_onset", "cases_true")),
      Rt = dplyr::tibble(time_onset = seq_len(settings$days_total),
                         Rt = settings$Rt),
      reporting = settings$reporting_parameters,
      revisions = revision_parameters,
      batches = batches),
    settings = settings)
}

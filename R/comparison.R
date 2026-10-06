# Comparison of mechanisms in the model of reporting: each can be switched on
# or off, and models are compared by how well they estimate recent case counts
# on real data as of a series of analysis dates.

#' The models compared
#'
#' Each row switches on a set of mechanisms. All include sporadic revisions,
#' since the extensions to reporting act within that model.
comparison_models <- function() {
  dplyr::tribble(
    ~model,                      ~tail, ~weekday, ~report_effects, ~misdating,
    "sporadic",                  FALSE, FALSE,    FALSE,           FALSE,
    "tail",                      TRUE,  FALSE,    FALSE,           FALSE,
    "weekday",                   FALSE, TRUE,     FALSE,           FALSE,
    "weekday + report",          FALSE, TRUE,     TRUE,            FALSE,
    "tail + weekday + report",   TRUE,  TRUE,     TRUE,            FALSE,
    "misdating",                 FALSE, FALSE,    FALSE,           TRUE)
}

#' The datasets and analysis dates used in the comparison
comparison_datasets <- function() {
  list(
    "Bundibugyo virus disease, 2026" = list(
      key = "bvd", date_earliest = "2026-05-11",
      dates_now = c("2026-08-09", "2026-08-16", "2026-08-23", "2026-08-30",
                    "2026-09-05"),
      serial_parameters = list(mean = 15.3, sd = 9.3)),
    "Measles, Netherlands, 2013" = list(
      key = "measles", date_earliest = "2013-06-03",
      dates_now = c("2013-07-14", "2013-07-28", "2013-08-11", "2013-08-25"),
      # Vink et al. 2014, as used by Bajaj, Thompson & Lambert (2025)
      serial_parameters = list(mean = 11.7, sd = 2.15)),
    "COVID-19 deaths, Sweden, 2020" = list(
      key = "sweden", date_earliest = "2020-10-05",
      dates_now = c("2020-11-22", "2020-11-29", "2020-12-06", "2020-12-13"),
      serial_parameters = list(mean = 5, sd = 3)),
    "COVID-19 cases, Hong Kong, 2020" = list(
      key = "hk", date_earliest = "2020-06-29",
      dates_now = c("2020-07-26", "2020-08-02", "2020-08-09", "2020-08-16"),
      serial_parameters = list(mean = 5, sd = 3)))
}

#' Measles snapshots from the incidenceinflation package, as dated cumulative counts
build_measles_snapshots <- function() {
  incidenceinflation::measles_NL_2013 %>%
    dplyr::as_tibble() %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    # the package holds the cases newly reported at each delay
    dplyr::mutate(cases_reported = cumsum(.data$cases_reported)) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      .data$date_onset,
      date_reported = .data$date_onset + (.data$time_reported - .data$time_onset),
      cases_reported = as.integer(.data$cases_reported))
}

#' Prepares snapshots for analysis as of a date, for the comparison
#'
#' As prepare_real_analysis(), except that the first onset date is chosen so
#' that the periods over which Rt is constant end on the analysis date, and
#' that the counts with which estimates are compared are those in the last
#' report available for each onset date (which need not be the same report
#' for every onset date).
prepare_comparison_analysis <- function(snapshots, date_earliest, date_now,
                                        Rt_piece_width = 7) {
  date_now <- as.Date(date_now)
  date_start <- aligned_start_date(date_now, date_earliest, Rt_piece_width)
  analysis <- prepare_real_analysis(snapshots, date_start, date_now)
  analysis$later <- snapshots %>%
    dplyr::filter(.data$date_onset >= date_start, .data$date_onset <= date_now) %>%
    dplyr::group_by(.data$date_onset) %>%
    dplyr::arrange(.data$date_reported, .by_group = TRUE) %>%
    dplyr::summarise(cases_later = dplyr::last(.data$cases_reported)) %>%
    dplyr::transmute(
      time_onset = as.integer(.data$date_onset - date_start) + 1L,
      .data$cases_later)
  analysis$weekday_first <- as.integer(format(date_start, "%u"))
  analysis
}

#' Fits a model with a given set of mechanisms to an analysis
#'
#' The renewal model is negative binomial.
#'
#' @param analysis as returned by prepare_comparison_analysis()
#' @param mechanisms a one-row tibble from comparison_models()
#' @return a list holding the summary of the fit and of the parameters of the
#' mechanisms
fit_comparison_model <- function(analysis, mechanisms, serial_parameters,
                                 niterations, Rt_piece_width = 7, seed = 1) {
  set.seed(seed)
  settings <- fit_settings()
  snapshots <- analysis$snapshots
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

  priors <- list(
    Rt = settings$priors$Rt,
    reporting = list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5),
    max_cases = ceiling(4 * max(initial_cases_true$cases_true) + 50),
    overdispersion = list(mean = 20, sd = 20),
    revisions = utils::modifyList(settings$priors$revisions,
                                  list(eta_mu = 0.005, eta_sigma = 0.005)),
    max_erroneous = max(3, incidenceinflation::max_downward_revision(snapshots) + 1))

  initial <- settings$initial_revisions
  if(mechanisms$misdating) {
    initial$pi <- settings$initial_pi
    initial$shifts <- settings$shifts
    initial$shift_probs <- settings$shift_probs
  }
  if(mechanisms$tail)
    initial$tail <- list(weight = 0.1, mean = 15)
  if(mechanisms$weekday) {
    initial$weekday <- TRUE
    initial$weekday_first <- analysis$weekday_first
  }
  if(mechanisms$report_effects)
    initial$report_effects <- TRUE

  time_start <- Sys.time()
  fit <- tryCatch(
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
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 3,
      initial_revision_parameters = initial,
      revision_metropolis_parameters = settings$revision_metropolis),
    error = function(e) list(error = conditionMessage(e)))
  fit$model <- mechanisms$model
  fit$seconds <- as.numeric(Sys.time() - time_start, units = "secs")
  fit$niterations <- niterations
  fit$Rt_lookup <- unique(dplyr::select(data, "time_onset", "Rt_index"))

  effects <- NULL
  if(is.null(fit$error) && !is.null(fit$reporting_effects)) {
    effects <- fit$reporting_effects %>%
      dplyr::filter(.data$iteration > floor(niterations / 2)) %>%
      dplyr::select(-"iteration", -dplyr::any_of("chain")) %>%
      dplyr::summarise(dplyr::across(dplyr::everything(), stats::median))
  }
  list(model = mechanisms$model, analysis = analysis,
       summary = summarise_fit(fit), effects = effects,
       serial_parameters = serial_parameters)
}

#' Weighted interval score of estimates given as quantiles
#'
#' The score combines the absolute error of the median with the interval
#' scores of the central 50% and 90% intervals; smaller is better.
weighted_interval_score <- function(truth, q05, q25, q50, q75, q95) {
  f_interval <- function(lower, upper, alpha)
    (upper - lower) + (2 / alpha) * pmax(lower - truth, 0) +
    (2 / alpha) * pmax(truth - upper, 0)
  (0.5 * abs(truth - q50) + 0.25 * f_interval(q25, q75, 0.5) +
     0.05 * f_interval(q05, q95, 0.1)) / 2.5
}

#' Scores one fit of the comparison against the counts known later
score_comparison_result <- function(result, dataset, Rt_piece_width = 7,
                                    days_recent = 14) {
  summary <- result$summary
  out <- dplyr::tibble(dataset = dataset, date_now = result$analysis$date_now,
                       model = result$model, seconds = summary$seconds,
                       failed = !is.null(summary$error),
                       error = ifelse(is.null(summary$error), NA_character_,
                                      summary$error))
  if(out$failed)
    return(out)
  cases <- dplyr::left_join(summary$cases, result$analysis$later, by = "time_onset")
  recent <- dplyr::filter(cases, .data$time_onset > max(cases$time_onset) - days_recent)
  scale <- mean(recent$cases_later)
  out$wis <- mean(weighted_interval_score(recent$cases_later, recent$q05, recent$q25,
                                          recent$q50, recent$q75, recent$q95)) / scale
  out$coverage_90 <- mean(recent$cases_later >= recent$q05 & recent$cases_later <= recent$q95)
  out$coverage_50 <- mean(recent$cases_later >= recent$q25 & recent$cases_later <= recent$q75)
  out$abs_error <- mean(abs(recent$q50 - recent$cases_later)) / scale
  out$bias <- mean(recent$q50 - recent$cases_later) / scale
  out$width_90 <- mean(recent$q95 - recent$q05) / scale

  # latest Rt compared with that estimated from the counts known later
  later <- dplyr::arrange(result$analysis$later, .data$time_onset)
  gold <- estimate_Rt_complete_data(later$cases_later, Rt_piece_width,
                                    result$serial_parameters)
  Rt <- summary$Rt %>%
    dplyr::filter(.data$Rt_index == max(.data$Rt_index)) %>%
    dplyr::slice(1)
  out$Rt_latest <- Rt$q50
  out$Rt_gold <- gold$q50[nrow(gold)]

  f_parameter <- function(name) {
    row <- dplyr::filter(summary$parameters, .data$parameter == name)
    if(nrow(row) == 0) NA_real_ else row$q50
  }
  out$reporting_mean <- f_parameter("reporting_mean")
  out$pi <- f_parameter("pi")
  if(!is.null(result$effects))
    out <- dplyr::bind_cols(out, result$effects)
  out
}

#' Averages scores across analysis dates, and across datasets
summarise_comparison <- function(scores) {
  models <- comparison_models()$model
  by_dataset <- scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::group_by(.data$dataset, .data$model) %>%
    dplyr::summarise(
      n_dates = dplyr::n(),
      wis = mean(.data$wis), coverage_90 = mean(.data$coverage_90),
      coverage_50 = mean(.data$coverage_50), abs_error = mean(.data$abs_error),
      bias = mean(.data$bias), width_90 = mean(.data$width_90),
      Rt_abs_error = mean(abs(.data$Rt_latest - .data$Rt_gold)),
      minutes = mean(.data$seconds) / 60,
      .groups = "drop")
  # scores relative to the model with sporadic revisions only, for the same
  # dataset and date, so that datasets can be averaged
  relative <- scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::group_by(.data$dataset, .data$date_now) %>%
    dplyr::mutate(wis_relative = .data$wis / .data$wis[.data$model == "sporadic"][1]) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(.data$model) %>%
    dplyr::summarise(
      n_fits = dplyr::n(),
      n_better = sum(.data$wis_relative < 1),
      wis_relative = exp(mean(log(.data$wis_relative))),
      coverage_90 = mean(.data$coverage_90), coverage_50 = mean(.data$coverage_50),
      .groups = "drop")
  list(
    by_dataset = dplyr::arrange(by_dataset, .data$dataset,
                                match(.data$model, models)),
    overall = dplyr::arrange(relative, match(.data$model, models)))
}

#' Weighted interval score of each model for each dataset and analysis date
plot_comparison_scores <- function(scores) {
  models <- comparison_models()$model
  df <- scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::mutate(model = factor(.data$model, levels = models))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$model, y = .data$wis)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$date_now), colour = "grey70") +
    ggplot2::geom_point(ggplot2::aes(colour = factor(.data$date_now)), size = 1.6) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 95, size = 10) +
    ggplot2::facet_wrap(~dataset, scales = "free_y") +
    ggplot2::labs(x = "Mechanisms included (all include sporadic revisions)",
                  y = "Weighted interval score, latest 14 onset days\n(relative to mean count; smaller is better)",
                  colour = "Analysis date") +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
                   legend.position = "none")
}

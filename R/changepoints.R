# Changes at unknown times in Rt and in the reporting delay: a simulation study
# and a comparison on real data. In all earlier analyses Rt was constant within
# periods fixed in advance and the reporting delay was the same throughout.

#' The models compared: which of Rt and the reporting delay change at times
#' which are inferred
changepoint_models <- function() {
  dplyr::tribble(
    ~model,                  ~Rt_changepoints, ~reporting_changepoints,
    "preset weekly Rt",      FALSE,            FALSE,
    "Rt changes",            TRUE,             FALSE,
    "delay changes",         FALSE,            TRUE,
    "Rt and delay changes",  TRUE,             TRUE)
}

#' Settings of the simulation study of changes
changepoint_simulation_settings <- function() {
  list(
    days_total = 63,
    serial_parameters = list(mean = 5, sd = 3),
    days_max_follow_up = 63,
    initial_parameters = list(mean = 30, length = 20),
    Rt_piece_width = 7)
}

#' Regimes of the simulation study of changes
#'
#' A single change is made either to Rt or to the reporting delay, either 21
#' or 7 days before the analysis date (the last of 63 onset days).
changepoint_regimes <- function() {
  dplyr::tribble(
    ~regime,                      ~day_change, ~Rt_before, ~Rt_after, ~delay_before, ~delay_after,
    "no change",                  NA,          1.1,        1.1,       5,             5,
    "Rt falls, 21 days before",   43,          1.4,        0.8,       5,             5,
    "Rt falls, 7 days before",    57,          1.4,        0.8,       5,             5,
    "delay doubles, 21 days before", 43,       1.1,        1.1,       5,             10,
    "delay doubles, 7 days before",  57,       1.1,        1.1,       5,             10)
}

#' Simulates a dataset with a single change in Rt or in the reporting delay
#'
#' The sd of the delay is 0.6 of its mean throughout.
#'
#' @param regime_row a one-row tibble from changepoint_regimes()
#' @param replicate index of replicate
simulate_changepoint_dataset <- function(regime_row, replicate) {
  settings <- changepoint_simulation_settings()
  set.seed(70000 + 1000 * match(regime_row$regime, changepoint_regimes()$regime) +
             replicate)
  n_days <- settings$days_total
  starts <- 1
  if(!is.na(regime_row$day_change))
    starts <- c(1, regime_row$day_change)
  n_segments <- length(starts)
  Rt <- incidenceinflation::piecewise_values(
    starts, c(regime_row$Rt_before, regime_row$Rt_after)[seq_len(n_segments)], n_days)
  delay_means <- c(regime_row$delay_before, regime_row$delay_after)[seq_len(n_segments)]
  reporting <- incidenceinflation::piecewise_reporting_parameters(
    starts, delay_means, 0.6 * delay_means, n_days)

  cases_true <- incidenceinflation::true_cases(
    n_days, function(t) Rt[pmin(pmax(round(t), 1), n_days)], 1000,
    settings$serial_parameters, initial_parameters = settings$initial_parameters)
  df <- incidenceinflation::observed_cases(cases_true, reporting,
                                           settings$days_max_follow_up)
  list(
    regime = regime_row$regime,
    replicate = replicate,
    snapshots = dplyr::select(df, -"cases_true"),
    truth = list(
      cases = unique(dplyr::select(df, "time_onset", "cases_true")),
      Rt = dplyr::tibble(time_onset = seq_len(n_days), Rt = Rt),
      reporting = reporting,
      day_change = regime_row$day_change),
    settings = settings)
}

#' Fits a model in which Rt, the reporting delay or both can change at times
#' which are inferred
#'
#' @param snapshots a tibble with columns time_onset, time_reported, cases_reported
#' @param mechanisms a one-row tibble from changepoint_models()
#' @param initial_revision_parameters passed to incidenceinflation::mcmc()
#' (NULL for the model without revisions)
#' @param priors_extra further elements of the priors
#' @return the draws, put into the form expected by summarise_fit() by
#' normalise_changepoint_fit()
fit_changepoint_model <- function(snapshots, mechanisms, serial_parameters,
                                  niterations, seed = 1, Rt_piece_width = 7,
                                  is_negative_binomial = FALSE,
                                  initial_revision_parameters = NULL,
                                  priors_extra = list(),
                                  priors_reporting = fit_settings()$priors$reporting) {
  set.seed(seed)
  settings <- fit_settings()
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

  priors <- c(
    list(Rt = settings$priors$Rt,
         reporting = priors_reporting,
         max_cases = ceiling(4 * max(initial_cases_true$cases_true) + 50)),
    priors_extra)
  if(is_negative_binomial)
    priors$overdispersion <- list(mean = 20, sd = 20)
  if(mechanisms$Rt_changepoints)
    priors$Rt_changepoints <- list()
  if(mechanisms$reporting_changepoints)
    priors$reporting_changepoints <- list()

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
      is_negative_binomial = is_negative_binomial,
      overdispersion_metropolis_sd = 3,
      initial_revision_parameters = initial_revision_parameters,
      revision_metropolis_parameters = settings$revision_metropolis),
    error = function(e) list(error = conditionMessage(e)))
  fit$model <- mechanisms$model
  fit$seconds <- as.numeric(Sys.time() - time_start, units = "secs")
  fit$niterations <- niterations
  fit$Rt_lookup <- unique(dplyr::select(data, "time_onset", "Rt_index"))
  normalise_changepoint_fit(fit, onset_times)
}

#' Puts draws from a model with changes at inferred times into the form of
#' those from a model without
#'
#' Rt is given for each onset time (as if each were its own period), and the
#' reporting parameters are those of the latest onset time. The draws specific
#' to changes are kept under 'changes'.
normalise_changepoint_fit <- function(fit, onset_times) {
  if(!is.null(fit$error))
    return(fit)
  warmup <- floor(fit$niterations / 2)
  changes <- list()
  if(!is.null(fit$Rt_changepoints)) {
    kept <- dplyr::filter(fit$Rt, .data$iteration > warmup)
    changes$Rt_n <- dplyr::filter(fit$Rt_changepoints, .data$iteration > warmup)$n_changes
    # probability that Rt changes on each onset time
    changes$Rt_starts <- kept %>%
      dplyr::group_by(.data$iteration) %>%
      dplyr::arrange(.data$time_onset, .by_group = TRUE) %>%
      dplyr::mutate(is_start = c(FALSE, diff(.data$Rt_index) != 0)) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(probability = mean(.data$is_start))
    fit$Rt <- fit$Rt %>%
      dplyr::transmute(.data$iteration, Rt_index = .data$time_onset, .data$Rt)
    fit$Rt_lookup <- dplyr::tibble(time_onset = onset_times, Rt_index = onset_times)
  }
  if(!is.null(fit$reporting_changepoints)) {
    kept <- dplyr::filter(fit$reporting_days, .data$iteration > warmup)
    changes$reporting_n <- dplyr::filter(fit$reporting_changepoints,
                                         .data$iteration > warmup)$n_changes
    changes$reporting_starts <- kept %>%
      dplyr::group_by(.data$iteration) %>%
      dplyr::arrange(.data$time_onset, .by_group = TRUE) %>%
      dplyr::mutate(is_start = c(FALSE, diff(.data$reporting_piece_index) != 0)) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(probability = mean(.data$is_start))
    changes$reporting_days <- summarise_draws_by(kept, .data$mean, .data$time_onset)
    fit$reporting <- fit$reporting_days %>%
      dplyr::filter(.data$time_onset == max(.data$time_onset)) %>%
      dplyr::transmute(reporting_piece_index = 1, .data$mean, .data$sd, .data$iteration)
  } else {
    changes$reporting_days <- fit$reporting %>%
      dplyr::filter(.data$iteration > warmup) %>%
      summarise_draws_by(.data$mean) %>%
      tidyr::crossing(time_onset = onset_times)
  }
  fit$changes <- changes
  fit
}

#' Fits a model to a simulated dataset of the study of changes
fit_changepoint_simulation <- function(dataset, mechanisms, niterations) {
  fit <- fit_changepoint_model(
    dataset$snapshots, mechanisms, dataset$settings$serial_parameters,
    niterations, seed = dataset$replicate,
    Rt_piece_width = dataset$settings$Rt_piece_width)
  list(regime = dataset$regime, replicate = dataset$replicate,
       model = mechanisms$model, summary = summarise_fit(fit),
       changes = fit$changes)
}

#' Scores a fit to a simulated dataset of the study of changes
score_changepoint_simulation <- function(result, dataset, days_recent = 14) {
  summary <- result$summary
  out <- dplyr::tibble(regime = result$regime, replicate = result$replicate,
                       model = result$model, seconds = summary$seconds,
                       failed = !is.null(summary$error),
                       error = ifelse(is.null(summary$error), NA_character_,
                                      summary$error))
  if(out$failed)
    return(out)
  truth <- dataset$truth
  day_last <- max(truth$cases$time_onset)
  recent <- summary$cases %>%
    dplyr::left_join(truth$cases, by = "time_onset") %>%
    dplyr::filter(.data$time_onset > day_last - days_recent)
  scale <- mean(recent$cases_true)
  out$wis <- mean(weighted_interval_score(recent$cases_true, recent$q05, recent$q25,
                                          recent$q50, recent$q75, recent$q95)) / scale
  out$coverage_90 <- mean(recent$cases_true >= recent$q05 & recent$cases_true <= recent$q95)
  out$bias <- mean(recent$q50 - recent$cases_true) / scale

  Rt <- summary$Rt %>%
    dplyr::left_join(truth$Rt, by = "time_onset", suffix = c("_estimated", "")) %>%
    dplyr::filter(.data$time_onset > day_last - days_recent)
  out$Rt_abs_error <- mean(abs(Rt$q50 - Rt$Rt))
  out$Rt_coverage_90 <- mean(Rt$Rt >= Rt$q05 & Rt$Rt <= Rt$q95)
  out$Rt_width_90 <- mean(Rt$q95 - Rt$q05)
  Rt_last <- dplyr::filter(Rt, .data$time_onset == day_last)
  out$Rt_last_error <- Rt_last$q50[1] - Rt_last$Rt[1]

  delay <- result$changes$reporting_days %>%
    dplyr::left_join(truth$reporting, by = "time_onset", suffix = c("_estimated", "")) %>%
    dplyr::filter(.data$time_onset > day_last - days_recent)
  out$delay_abs_error <- mean(abs(delay$q50 - delay$mean))

  f_changes <- function(n) if(is.null(n)) NA_real_ else mean(n >= 1)
  f_n <- function(n) if(is.null(n)) NA_real_ else mean(n)
  out$p_Rt_change <- f_changes(result$changes$Rt_n)
  out$n_Rt_changes <- f_n(result$changes$Rt_n)
  out$p_delay_change <- f_changes(result$changes$reporting_n)
  out$n_delay_changes <- f_n(result$changes$reporting_n)
  # probability of a change within three days of the true one
  f_near <- function(starts) {
    if(is.null(starts) || is.na(truth$day_change))
      return(NA_real_)
    sum(starts$probability[abs(starts$time_onset - truth$day_change) <= 3])
  }
  out$p_Rt_change_near <- f_near(result$changes$Rt_starts)
  out$p_delay_change_near <- f_near(result$changes$reporting_starts)
  out
}

#' Averages the scores of the simulation study of changes over replicates
summarise_changepoint_simulation <- function(scores) {
  scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::group_by(.data$regime, .data$model) %>%
    dplyr::summarise(
      n = dplyr::n(),
      dplyr::across(c("wis", "coverage_90", "bias", "Rt_abs_error", "Rt_coverage_90",
                      "Rt_width_90", "delay_abs_error", "p_Rt_change",
                      "n_Rt_changes", "p_delay_change", "n_delay_changes",
                      "p_Rt_change_near", "p_delay_change_near"), mean),
      minutes = mean(.data$seconds) / 60,
      .groups = "drop") %>%
    dplyr::arrange(match(.data$regime, changepoint_regimes()$regime),
                   match(.data$model, changepoint_models()$model))
}

changepoint_model_colours <- function() {
  stats::setNames(c("#D55E00", "#0072B2", "#CC79A7", "#009E73"),
                  changepoint_models()$model)
}

#' Scores of each model in each regime of the simulation study of changes
plot_changepoint_simulation_scores <- function(scores) {
  measures <- c(wis = "Weighted interval score of cases\n(latest 14 onset days)",
                Rt_abs_error = "Absolute error of Rt\n(latest 14 onset days)",
                delay_abs_error = "Absolute error of mean delay, days\n(latest 14 onset days)")
  df <- scores %>%
    dplyr::filter(!.data$failed) %>%
    tidyr::pivot_longer(dplyr::all_of(names(measures)), names_to = "measure") %>%
    dplyr::mutate(
      measure = factor(measures[.data$measure], levels = measures),
      regime = factor(.data$regime, levels = changepoint_regimes()$regime),
      model = factor(.data$model, levels = changepoint_models()$model))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$regime, y = .data$value,
                                   colour = .data$model)) +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.7),
                        alpha = 0.45, size = 1.3) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 95, size = 9,
                          position = ggplot2::position_dodge(width = 0.7)) +
    ggplot2::facet_wrap(~measure, scales = "free_y", ncol = 1) +
    ggplot2::scale_colour_manual(values = changepoint_model_colours()) +
    ggplot2::labs(x = NULL, y = NULL, colour = "Model fitted") +
    theme_paper()
}

#' Estimates of Rt and of the mean delay over onset time for one replicate of
#' each regime
plot_changepoint_simulation_examples <- function(datasets, results, replicate = 1) {
  f_rows <- function(result) {
    if(result$replicate != replicate || !is.null(result$summary$error))
      return(NULL)
    dplyr::bind_rows(
      dplyr::mutate(dplyr::select(result$summary$Rt, "time_onset", "q05", "q50", "q95"),
                    quantity = "Rt"),
      dplyr::mutate(dplyr::select(result$changes$reporting_days,
                                  "time_onset", "q05", "q50", "q95"),
                    quantity = "Mean reporting delay, days")) %>%
      dplyr::mutate(regime = result$regime, model = result$model)
  }
  estimates <- purrr::map_dfr(results, f_rows)
  truth <- purrr::map_dfr(datasets, function(dataset) {
    if(dataset$replicate != replicate)
      return(NULL)
    dplyr::bind_rows(
      dplyr::transmute(dataset$truth$Rt, .data$time_onset, value = .data$Rt,
                       quantity = "Rt"),
      dplyr::transmute(dataset$truth$reporting, .data$time_onset, value = .data$mean,
                       quantity = "Mean reporting delay, days")) %>%
      dplyr::mutate(regime = dataset$regime)
  })
  f_levels <- function(df) {
    dplyr::mutate(df,
      regime = factor(.data$regime, levels = changepoint_regimes()$regime),
      quantity = factor(.data$quantity, levels = c("Rt", "Mean reporting delay, days")))
  }
  estimates <- f_levels(estimates) %>%
    dplyr::mutate(model = factor(.data$model, levels = changepoint_models()$model))
  ggplot2::ggplot(estimates, ggplot2::aes(x = .data$time_onset)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.18) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::geom_step(data = f_levels(truth), ggplot2::aes(y = .data$value),
                       linetype = 2) +
    ggplot2::facet_grid(quantity ~ regime, scales = "free_y",
                        labeller = ggplot2::label_wrap_gen(18)) +
    ggplot2::scale_colour_manual(values = changepoint_model_colours()) +
    ggplot2::scale_fill_manual(values = changepoint_model_colours()) +
    ggplot2::coord_cartesian(xlim = c(22, NA)) +
    ggplot2::labs(x = "Onset day", y = NULL, colour = "Model fitted",
                  fill = "Model fitted") +
    theme_paper()
}

#' Fits a model with changes at inferred times to a real analysis
#'
#' All models include sporadic revisions, the effect of the day of the week of
#' each report and a negative binomial renewal model, as the best model of
#' fit_comparison_model().
fit_changepoint_comparison <- function(analysis, mechanisms, serial_parameters,
                                       niterations, seed = 1) {
  settings <- fit_settings()
  initial <- settings$initial_revisions
  initial$weekday <- TRUE
  initial$weekday_first <- analysis$weekday_first
  fit <- fit_changepoint_model(
    analysis$snapshots, mechanisms, serial_parameters, niterations, seed = seed,
    is_negative_binomial = TRUE,
    initial_revision_parameters = initial,
    priors_extra = list(
      revisions = utils::modifyList(settings$priors$revisions,
                                    list(eta_mu = 0.005, eta_sigma = 0.005)),
      max_erroneous = max(3, incidenceinflation::max_downward_revision(
        analysis$snapshots) + 1)),
    priors_reporting = list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5))
  list(model = mechanisms$model, analysis = analysis,
       summary = summarise_fit(fit), effects = NULL, changes = fit$changes,
       serial_parameters = serial_parameters)
}

#' Scores a fit of the comparison of models with changes on real data
score_changepoint_comparison <- function(result) {
  out <- score_comparison_result(result, result$analysis$dataset)
  if(out$failed)
    return(out)
  f_changes <- function(n) if(is.null(n)) NA_real_ else mean(n >= 1)
  f_n <- function(n) if(is.null(n)) NA_real_ else mean(n)
  out$p_Rt_change <- f_changes(result$changes$Rt_n)
  out$n_Rt_changes <- f_n(result$changes$Rt_n)
  out$p_delay_change <- f_changes(result$changes$reporting_n)
  out$n_delay_changes <- f_n(result$changes$reporting_n)
  delay <- result$changes$reporting_days
  out$delay_first <- delay$q50[which.min(delay$time_onset)]
  out$delay_last <- delay$q50[which.max(delay$time_onset)]
  out
}

#' Averages scores of the comparison of models with changes
summarise_changepoint_comparison <- function(scores) {
  models <- changepoint_models()$model
  kept <- dplyr::filter(scores, !.data$failed)
  by_dataset <- kept %>%
    dplyr::group_by(.data$dataset, .data$model) %>%
    dplyr::summarise(
      n_dates = dplyr::n(),
      dplyr::across(c("wis", "coverage_90", "coverage_50", "bias", "width_90",
                      "n_Rt_changes", "n_delay_changes", "delay_first",
                      "delay_last"), mean),
      Rt_abs_error = mean(abs(.data$Rt_latest - .data$Rt_gold)),
      minutes = mean(.data$seconds) / 60,
      .groups = "drop") %>%
    dplyr::arrange(.data$dataset, match(.data$model, models))
  overall <- kept %>%
    dplyr::group_by(.data$dataset, .data$date_now) %>%
    dplyr::filter(any(.data$model == models[1])) %>%
    dplyr::mutate(wis_relative = .data$wis / .data$wis[.data$model == models[1]][1]) %>%
    dplyr::group_by(.data$model) %>%
    dplyr::summarise(
      n_fits = dplyr::n(),
      n_better = sum(.data$wis_relative < 1),
      wis_relative = exp(mean(log(.data$wis_relative))),
      coverage_90 = mean(.data$coverage_90), coverage_50 = mean(.data$coverage_50),
      Rt_abs_error = mean(abs(.data$Rt_latest - .data$Rt_gold)),
      .groups = "drop") %>%
    dplyr::arrange(match(.data$model, models))
  list(by_dataset = by_dataset, overall = overall)
}

#' Weighted interval score of each model with changes for each dataset and date
plot_changepoint_comparison_scores <- function(scores) {
  models <- changepoint_models()$model
  df <- scores %>%
    dplyr::filter(!.data$failed) %>%
    dplyr::mutate(model = factor(.data$model, levels = models))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$model, y = .data$wis)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$date_now), colour = "grey70") +
    ggplot2::geom_point(ggplot2::aes(colour = factor(.data$date_now)), size = 1.6) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 95, size = 10) +
    ggplot2::facet_wrap(~dataset, scales = "free_y") +
    ggplot2::labs(x = NULL,
                  y = "Weighted interval score, latest 14 onset days\n(relative to mean count; smaller is better)",
                  colour = "Analysis date") +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
                   legend.position = "none")
}

#' Rt and the mean reporting delay over onset date at the latest analysis date
#' of each dataset
plot_changepoint_comparison_trajectories <- function(results) {
  dates_latest <- purrr::map_dfr(results, function(result) {
    dplyr::tibble(dataset = result$analysis$dataset, date_now = result$analysis$date_now)
  }) %>%
    dplyr::group_by(.data$dataset) %>%
    dplyr::summarise(date_now = max(.data$date_now))
  df <- purrr::map_dfr(results, function(result) {
    latest <- dates_latest$date_now[dates_latest$dataset == result$analysis$dataset]
    if(result$analysis$date_now != latest || !is.null(result$summary$error))
      return(NULL)
    dplyr::bind_rows(
      dplyr::mutate(dplyr::select(result$summary$Rt, "time_onset", "q05", "q50", "q95"),
                    quantity = "Rt"),
      dplyr::mutate(dplyr::select(result$changes$reporting_days,
                                  "time_onset", "q05", "q50", "q95"),
                    quantity = "Mean reporting delay, days")) %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset") %>%
      dplyr::mutate(dataset = result$analysis$dataset, model = result$model)
  }) %>%
    dplyr::mutate(
      model = factor(.data$model, levels = changepoint_models()$model),
      quantity = factor(.data$quantity, levels = c("Rt", "Mean reporting delay, days")))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.18) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::facet_wrap(quantity ~ dataset, scales = "free", nrow = 2,
                        labeller = ggplot2::label_wrap_gen(24)) +
    ggplot2::scale_colour_manual(values = changepoint_model_colours()) +
    ggplot2::scale_fill_manual(values = changepoint_model_colours()) +
    ggplot2::labs(x = "Onset date", y = NULL, colour = "Model fitted",
                  fill = "Model fitted") +
    theme_paper()
}

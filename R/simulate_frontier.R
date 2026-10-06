# A second simulation study, in which a batch of erroneous records covers
# recent onset days: those whose true counts are still being estimated on the
# analysis date. In the first study (R/simulate.R) the batch covered onset days
# old enough that their counts are simply read from the latest report.

#' Regimes for the study of batches near the analysis date
#'
#' The batch covers onset days 47 to 53 of 60. It is either detected on day 57,
#' shortly before the analysis date, or not until after it.
frontier_regimes <- function() {
  dplyr::tribble(
    ~regime,              ~time_detected,
    "detected recently",  57,
    "not yet detected",   70)
}

#' Simulates a dataset with a batch near the analysis date
#'
#' @param regime_row a one-row tibble from frontier_regimes()
#' @param replicate index of replicate
#' @return a list of the same form as that returned by simulate_dataset()
simulate_frontier_dataset <- function(regime_row, replicate) {
  settings <- simulation_settings()
  set.seed(50000 + 1000 * match(regime_row$regime, frontier_regimes()$regime) +
             replicate)
  revision_parameters <- list(eta = 0.005, rho = 0.15)
  batches <- dplyr::tibble(start = 47, width = 7, phi = 0.25,
                           time_detected = regime_row$time_detected)
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

#' The models compared in the study of batches near the analysis date
#'
#' The original model cannot be fitted to counts which fall, so is fitted to
#' counts made non-decreasing in one of two ways: by replacing each count by
#' the largest reported up to then ("running maximum"), which retains records
#' later withdrawn; or by replacing each count by the smallest reported from
#' then on ("later minimum"), which removes them.
frontier_model_names <- function() {
  c("original, running maximum", "original, later minimum", "full")
}

#' Replaces reported counts by the smallest count reported from then on
later_minimum_snapshots <- function(snapshots) {
  snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::mutate(cases_reported = rev(cummin(rev(.data$cases_reported)))) %>%
    dplyr::ungroup()
}

#' Fits one of frontier_model_names() to a dataset and scores it
fit_frontier_model <- function(dataset, model, niterations) {
  snapshots <- dataset$snapshots
  if(model == "original, later minimum")
    snapshots <- later_minimum_snapshots(snapshots)
  fit_summary <- summarise_fit(fit_model(
    snapshots, ifelse(model == "full", "full", "original"),
    dataset$settings$serial_parameters,
    dataset$settings$Rt_piece_width,
    niterations = niterations,
    seed = dataset$replicate,
    settings = utils::modifyList(fit_settings(), list(max_erroneous = 10))))
  fit_summary$model <- model
  list(regime = dataset$regime,
       replicate = dataset$replicate,
       summary = fit_summary,
       score = score_fit(fit_summary, dataset))
}

#' Averages scores across replicates for the study of batches near the analysis date
summarise_frontier_scores <- function(scores) {
  scores %>%
    dplyr::group_by(.data$regime, .data$model) %>%
    dplyr::summarise(
      n_fits = dplyr::n(),
      n_failed = sum(.data$failed),
      dplyr::across(
        dplyr::any_of(c("footprint_coverage", "footprint_abs_error",
                        "footprint_bias", "footprint_width",
                        "recent_coverage", "recent_abs_error", "recent_bias",
                        "recent_width", "Rt_last_bias", "p_any_batch", "seconds")),
        ~mean(.x, na.rm = TRUE)),
      Rt_last_coverage = mean(.data$Rt_last_covered, na.rm = TRUE),
      .groups = "drop") %>%
    dplyr::mutate(
      regime = factor(.data$regime, levels = frontier_regimes()$regime),
      model = factor(.data$model, levels = frontier_model_names())) %>%
    dplyr::arrange(.data$regime, .data$model)
}

#' Estimates of case counts for each dataset with a batch near the analysis date
#'
#' @param datasets list of datasets from simulate_frontier_dataset()
#' @param results list of results from fit_frontier_model()
#' @param replicate which replicate to show
plot_frontier_examples <- function(datasets, results, replicate = 1) {
  truth <- purrr::map_dfr(datasets, function(dataset) {
    reported <- dataset$snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
      dplyr::summarise(cases_reported = dplyr::last(.data$cases_reported),
                       cases_peak = max(.data$cases_reported))
    dataset$truth$cases %>%
      dplyr::left_join(reported, by = "time_onset") %>%
      dplyr::mutate(regime = dataset$regime, replicate = dataset$replicate)
  })
  df <- purrr::map_dfr(results, function(result) {
    if(!is.null(result$summary$error))
      return(NULL)
    dplyr::mutate(result$summary$cases, model = result$summary$model,
                  regime = result$regime, replicate = result$replicate)
  }) %>%
    dplyr::left_join(truth, by = c("time_onset", "regime", "replicate")) %>%
    dplyr::filter(.data$replicate == .env$replicate, .data$time_onset >= 36) %>%
    dplyr::mutate(
      regime = factor(.data$regime, levels = frontier_regimes()$regime),
      model = factor(.data$model, levels = frontier_model_names()))
  colours <- stats::setNames(c("#D55E00", "#CC79A7", "#009E73"),
                             frontier_model_names())
  ggplot2::ggplot(df, ggplot2::aes(x = .data$time_onset)) +
    ggplot2::annotate("rect", xmin = 46.5, xmax = 53.5, ymin = -Inf, ymax = Inf,
                      fill = "grey85", alpha = 0.6) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.35) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_reported), colour = "grey40",
                       linetype = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$cases_true), size = 0.7) +
    ggplot2::facet_grid(.data$regime ~ .data$model) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::labs(
      x = "Onset day", y = "Cases",
      caption = paste("Points: true cases. Dashed: cases reported by the final day.",
                      "Shaded: onset days covered by the batch.",
                      "Line and band: posterior median and 90% interval.")) +
    theme_paper()
}

#' Accuracy for the onset days covered by the batch, for each dataset
plot_frontier_scores <- function(scores) {
  measures <- c(footprint_coverage = "Coverage of 90% interval",
                footprint_abs_error = "Absolute error of median\n(relative to mean cases)",
                footprint_bias = "Bias of median\n(relative to mean cases)")
  df <- scores %>%
    dplyr::filter(!.data$failed) %>%
    tidyr::pivot_longer(dplyr::all_of(names(measures)), names_to = "measure") %>%
    dplyr::mutate(
      measure = factor(measures[.data$measure], levels = measures),
      regime = factor(.data$regime, levels = frontier_regimes()$regime),
      model = factor(.data$model, levels = frontier_model_names()))
  reference <- dplyr::tibble(measure = factor(measures, levels = measures),
                             value = c(0.9, 0, 0))
  colours <- stats::setNames(c("#D55E00", "#CC79A7", "#009E73"),
                             frontier_model_names())
  ggplot2::ggplot(df, ggplot2::aes(x = .data$regime, y = .data$value,
                                   colour = .data$model)) +
    ggplot2::geom_hline(data = reference, ggplot2::aes(yintercept = .data$value),
                        linetype = 2, colour = "grey40") +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.6),
                        alpha = 0.45, size = 1.3) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 95, size = 9,
                          position = ggplot2::position_dodge(width = 0.6)) +
    ggplot2::facet_wrap(~measure, scales = "free_y") +
    ggplot2::scale_colour_manual(values = colours) +
    ggplot2::labs(x = "When the batch is detected", y = NULL,
                  colour = "Model fitted") +
    theme_paper()
}

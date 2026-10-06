# Figures.

model_colours <- function() {
  c(original = "#D55E00", sporadic = "#0072B2", full = "#009E73")
}

theme_paper <- function() {
  ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   legend.position = "bottom",
                   strip.background = ggplot2::element_rect(fill = "grey95"))
}

save_plot <- function(plot, filename, width, height) {
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(filename, plot, width = width, height = height, dpi = 200)
  filename
}

#' Performance of each model across replicates within each regime
plot_simulation_scores <- function(scores) {
  measures <- c(recent_coverage = "Coverage of 90% interval\n(latest 14 onset days)",
                recent_abs_error = "Absolute error of median\n(relative to mean cases)",
                recent_bias = "Bias of median\n(relative to mean cases)",
                Rt_last_bias = "Bias in latest Rt")
  df <- scores %>%
    dplyr::filter(!.data$failed) %>%
    tidyr::pivot_longer(dplyr::all_of(names(measures)), names_to = "measure") %>%
    dplyr::mutate(
      measure = factor(measures[.data$measure], levels = measures),
      regime = factor(.data$regime, levels = simulation_regimes()$regime),
      model = factor(.data$model, levels = model_names()))
  reference <- dplyr::tibble(
    measure = factor(measures, levels = measures),
    value = c(0.9, 0, 0, 0))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$regime, y = .data$value,
                                   colour = .data$model)) +
    ggplot2::geom_hline(data = reference, ggplot2::aes(yintercept = .data$value),
                        linetype = 2, colour = "grey40") +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.6),
                        alpha = 0.45, size = 1.3) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 95, size = 9,
                          position = ggplot2::position_dodge(width = 0.6)) +
    ggplot2::facet_wrap(~measure, scales = "free_y") +
    ggplot2::scale_colour_manual(values = model_colours()) +
    ggplot2::labs(x = "Regime used to simulate data", y = NULL, colour = "Model fitted") +
    theme_paper()
}

#' Nowcasts from each model for one simulated dataset from each regime
plot_simulation_examples <- function(examples) {
  df <- purrr::map_dfr(examples, function(example) {
    reported <- example$dataset$snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(cases_reported = dplyr::last(.data$cases_reported))
    purrr::map_dfr(example$summaries, function(fit_summary) {
      if(!is.null(fit_summary$error))
        return(NULL)
      fit_summary$cases %>%
        dplyr::left_join(example$dataset$truth$cases, by = "time_onset") %>%
        dplyr::left_join(reported, by = "time_onset") %>%
        dplyr::mutate(model = fit_summary$model, regime = example$dataset$regime)
    })
  }) %>%
    dplyr::mutate(
      regime = factor(.data$regime, levels = simulation_regimes()$regime),
      model = factor(.data$model, levels = model_names())) %>%
    dplyr::filter(.data$time_onset > max(.data$time_onset) - 35)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$time_onset)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_reported), colour = "grey50",
                       linetype = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$cases_true), size = 0.7) +
    ggplot2::facet_grid(.data$regime ~ .data$model, scales = "free_y") +
    ggplot2::scale_colour_manual(values = model_colours(), guide = "none") +
    ggplot2::scale_fill_manual(values = model_colours(), guide = "none") +
    ggplot2::labs(
      x = "Onset day", y = "Cases",
      caption = paste("Points: true cases. Dashed: cases reported by the final day.",
                      "Line and band: posterior median and 90% interval.")) +
    theme_paper()
}

#' Snapshots of reported cases by onset date
plot_snapshots <- function(df, every = 7) {
  dates_reported <- sort(unique(df$date_reported))
  keep <- dates_reported[seq(1, length(dates_reported), by = every)]
  df %>%
    dplyr::filter(.data$date_reported %in% keep) %>%
    ggplot2::ggplot(ggplot2::aes(x = .data$date_onset, y = .data$cases_reported,
                                 colour = .data$date_reported,
                                 group = .data$date_reported)) +
    ggplot2::geom_line(linewidth = 0.4) +
    ggplot2::scale_colour_viridis_c(trans = "date", direction = -1) +
    ggplot2::labs(x = "Onset date", y = "Cases reported", colour = "Reported on") +
    theme_paper()
}

#' Nowcasts for real data compared with counts known later
plot_real_nowcast <- function(summaries, analysis, days_shown = 35) {
  reported <- analysis$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_reported = dplyr::last(.data$cases_reported))
  df <- purrr::map_dfr(summaries, function(fit_summary) {
    if(!is.null(fit_summary$error))
      return(NULL)
    dplyr::mutate(fit_summary$cases, model = fit_summary$model)
  }) %>%
    dplyr::left_join(analysis$later, by = "time_onset") %>%
    dplyr::left_join(reported, by = "time_onset") %>%
    dplyr::left_join(analysis$dates, by = "time_onset") %>%
    dplyr::mutate(model = factor(.data$model, levels = model_names())) %>%
    dplyr::filter(.data$time_onset > max(.data$time_onset) - days_shown)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_reported), colour = "grey50",
                       linetype = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$cases_later), size = 0.7) +
    ggplot2::facet_wrap(~model) +
    ggplot2::scale_colour_manual(values = model_colours(), guide = "none") +
    ggplot2::scale_fill_manual(values = model_colours(), guide = "none") +
    ggplot2::labs(
      x = "Onset date", y = "Cases",
      caption = paste0("Points: cases as known on ", analysis$date_later,
                       ". Dashed: cases reported by ", analysis$date_now,
                       ". Line and band: posterior median and 90% interval.")) +
    theme_paper()
}

#' Writes a short report of the results in Markdown
write_report <- function(score_summary, scores, real_scores, real_revisions,
                         filename) {
  f_table <- function(df, digits = 2) {
    df <- dplyr::mutate(df, dplyr::across(where(is.numeric), ~round(.x, digits)))
    df <- dplyr::mutate(df, dplyr::across(dplyr::everything(), as.character))
    df[is.na(df)] <- ""
    header <- paste0("| ", paste(colnames(df), collapse = " | "), " |")
    rule <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|")
    rows <- apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
    c(header, rule, rows)
  }
  failures <- scores %>%
    dplyr::filter(.data$failed) %>%
    dplyr::count(.data$regime, .data$model, .data$error)
  lines <- c(
    "# Results",
    "",
    "Generated by the targets pipeline; do not edit by hand.",
    "",
    "## Simulated data",
    "",
    "Means across replicates. 'recent' refers to the latest 14 onset days and",
    "'footprint' to the onset days covered by the simulated batch.",
    "Errors, biases and widths of 90% intervals for cases are relative to the mean true count.",
    "",
    f_table(dplyr::select(score_summary, dplyr::any_of(c(
      "regime", "model", "n_fits", "n_failed", "recent_coverage",
      "recent_abs_error", "recent_bias", "recent_width", "Rt_last_bias",
      "Rt_last_coverage", "footprint_coverage", "footprint_bias")))),
    "",
    "Posterior medians of parameters (means across replicates) and run time in seconds:",
    "",
    f_table(dplyr::select(score_summary, dplyr::any_of(c(
      "regime", "model", "reporting_mean", "reporting_sd", "eta", "rho", "pi",
      "p_any_batch", "seconds"))), digits = 3),
    "",
    "Fits which failed:",
    "",
    if(nrow(failures) > 0) f_table(failures) else "None.",
    "",
    "## Netherlands COVID-19 cases by symptom onset date",
    "",
    "Revisions between successive daily files within the period analysed:",
    "",
    f_table(real_revisions),
    "",
    "Nowcasts compared with counts known at the later date ('recent' is the latest 14 onset days).",
    "Parameters are posterior medians with 90% intervals.",
    "",
    f_table(real_scores, digits = 3))
  dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, filename)
  filename
}

estimator_colours <- function() {
  c("reported" = "#E69F00", "naive" = "#E69F00", "known later" = "black",
    "gold standard" = "black", "original model" = "#0072B2",
    "model with misdating" = "#009E73")
}

estimator_label <- function(model) {
  ifelse(model == "original", "original model", "model with misdating")
}

format_date_now <- function(date) {
  labels <- format(as.Date(date), "%d %b %Y")
  factor(labels, levels = unique(labels[order(as.Date(date))]))
}

#' Case counts by onset date with the periods used for reporting delays
plot_real_cases_periods <- function(ecdf_df) {
  cases <- ecdf_df %>%
    dplyr::select("date_onset", "cases_final", "period_index") %>%
    unique()
  periods <- cases %>%
    dplyr::group_by(.data$period_index) %>%
    dplyr::summarise(start = min(.data$date_onset) - 0.5,
                     end = max(.data$date_onset) + 0.5,
                     middle = mean(.data$date_onset)) %>%
    dplyr::mutate(label = paste0("(", tolower(utils::as.roman(.data$period_index)), ")"))
  ggplot2::ggplot(cases) +
    ggplot2::geom_rect(data = periods,
                       ggplot2::aes(xmin = .data$start, xmax = .data$end,
                                    ymin = 0, ymax = Inf,
                                    fill = factor(.data$period_index)),
                       alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(x = .data$date_onset, y = .data$cases_final)) +
    ggplot2::geom_text(data = periods,
                       ggplot2::aes(x = .data$middle, y = Inf, label = .data$label),
                       vjust = 2) +
    ggplot2::scale_fill_brewer(palette = "Dark2", guide = "none") +
    ggplot2::labs(x = "Onset date", y = "Cases") +
    theme_paper()
}

#' Empirical distributions of reporting delay for each onset date, by period
plot_real_ecdf <- function(ecdf_df) {
  ecdf_df <- ecdf_df %>%
    dplyr::group_by(.data$period_index) %>%
    dplyr::mutate(period = paste0(
      "(", tolower(utils::as.roman(.data$period_index)), ") ",
      format(min(.data$date_onset), "%d %b"), " to ",
      format(max(.data$date_onset), "%d %b"))) %>%
    dplyr::ungroup()
  average <- ecdf_df %>%
    dplyr::group_by(.data$period, .data$delay) %>%
    dplyr::summarise(ecdf = mean(.data$ecdf), .groups = "drop")
  medians <- average %>%
    dplyr::group_by(.data$period) %>%
    dplyr::summarise(delay = min(.data$delay[.data$ecdf >= 0.5]))
  ggplot2::ggplot(ecdf_df, ggplot2::aes(x = .data$delay, y = .data$ecdf)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$date_onset,
                                    colour = .data$cases_final), alpha = 0.5) +
    ggplot2::geom_line(data = average, colour = "orange", linetype = 2,
                       linewidth = 0.8) +
    ggplot2::geom_segment(data = medians, colour = "orange",
                          ggplot2::aes(x = 0, xend = .data$delay, y = 0.5, yend = 0.5)) +
    ggplot2::geom_segment(data = medians, colour = "orange",
                          ggplot2::aes(x = .data$delay, xend = .data$delay,
                                       y = 0, yend = 0.5)) +
    ggplot2::facet_wrap(~period) +
    ggplot2::scale_colour_viridis_c() +
    ggplot2::labs(x = "Reporting delay, days", y = "eCDF", colour = "Cases\nknown later") +
    theme_paper() +
    ggplot2::theme(legend.position = "right")
}

#' Estimates of case counts across a range of analysis dates
#'
#' @param results a list with an element for each analysis date and model,
#' each holding 'analysis' and the fit 'summary'
plot_real_cases_dates <- function(results) {
  estimates <- purrr::map_dfr(results, function(result) {
    if(!is.null(result$summary$error))
      return(NULL)
    result$summary$cases %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset") %>%
      dplyr::mutate(date_now = result$analysis$date_now,
                    series = estimator_label(result$model))
  })
  observed <- purrr::map_dfr(results, function(result) {
    reported <- result$analysis$snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
      dplyr::summarise(cases = dplyr::last(.data$cases_reported)) %>%
      dplyr::mutate(series = "reported")
    later <- result$analysis$later %>%
      dplyr::transmute(.data$time_onset, cases = .data$cases_later,
                       series = "known later")
    dplyr::bind_rows(reported, later) %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset") %>%
      dplyr::mutate(date_now = result$analysis$date_now)
  }) %>%
    unique()
  estimates$panel <- format_date_now(estimates$date_now)
  observed$panel <- factor(format(observed$date_now, "%d %b %Y"),
                           levels = levels(estimates$panel))
  ggplot2::ggplot(mapping = ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(data = estimates,
                         ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$series), alpha = 0.35) +
    ggplot2::geom_line(data = observed,
                       ggplot2::aes(y = .data$cases, colour = .data$series)) +
    ggplot2::geom_line(data = estimates,
                       ggplot2::aes(y = .data$q50, colour = .data$series)) +
    ggplot2::facet_wrap(~panel) +
    ggplot2::scale_colour_manual(values = estimator_colours()) +
    ggplot2::scale_fill_manual(values = estimator_colours(), guide = "none") +
    ggplot2::labs(x = "Onset date", y = "Cases", colour = NULL) +
    theme_paper()
}

#' Estimates of Rt across a range of analysis dates
plot_real_Rt_dates <- function(results, Rt_piece_width, serial_parameters) {
  estimates <- purrr::map_dfr(results, function(result) {
    if(!is.null(result$summary$error))
      return(NULL)
    result$summary$Rt %>%
      dplyr::select("time_onset", "q05", "q50", "q95") %>%
      dplyr::mutate(estimator = estimator_label(result$model),
                    date_now = result$analysis$date_now) %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset")
  })
  analyses <- purrr::map(results, "analysis")
  analyses <- analyses[!duplicated(purrr::map_chr(analyses, ~as.character(.$date_now)))]
  simple <- purrr::map_dfr(analyses, function(analysis) {
    estimate_Rt_naive_and_gold(analysis, Rt_piece_width, serial_parameters) %>%
      dplyr::mutate(date_now = analysis$date_now) %>%
      dplyr::left_join(analysis$dates, by = "time_onset")
  })
  df <- dplyr::bind_rows(estimates, simple) %>%
    dplyr::mutate(estimator = factor(.data$estimator, levels = c(
      "naive", "gold standard", "original model", "model with misdating")))
  df$panel <- format_date_now(df$date_now)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 2) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$estimator), alpha = 0.35) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$estimator)) +
    ggplot2::facet_wrap(~panel) +
    ggplot2::scale_colour_manual(values = estimator_colours()) +
    ggplot2::scale_fill_manual(values = estimator_colours()) +
    ggplot2::coord_cartesian(ylim = c(0, 2.5)) +
    ggplot2::labs(x = "Onset date", y = expression(R[t]), colour = "Estimator",
                  fill = "Estimator") +
    theme_paper()
}

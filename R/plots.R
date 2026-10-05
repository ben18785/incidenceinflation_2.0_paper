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

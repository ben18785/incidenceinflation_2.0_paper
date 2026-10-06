# Bundibugyo virus disease outbreak, 2026: confirmed cases by date of symptom
# onset as shown in successive situation reports.
#
# The raw files are not tracked: each is the epidemic curve of one situation
# report, extracted from its figure and verified by hand. Tables derived from
# them are also kept out of tracked files (under data/raw/).

#' Reads one verified extraction of a situation report's epidemic curve
#'
#' Columns are read by position, since one file lacks names for the verified
#' columns: the fifth to seventh columns hold the verified total, alive and
#' dead counts.
#'
#' @param path path to a Varified_SitRep_*.csv file
#' @return a tibble with columns sitrep, date_reported, date_onset,
#' cases_reported (all confirmed cases) and deaths_reported (those who have died)
read_bvd_sitrep <- function(path) {
  name <- basename(path)
  parts <- regmatches(name, regexec(
    "_([0-9]{3})_([0-9]{2})[_-]([0-9]{2})[_-]([0-9]{4})_", name))[[1]]
  df <- utils::read.csv(path, header = FALSE, skip = 1, stringsAsFactors = FALSE)
  dplyr::tibble(
    sitrep = as.integer(parts[2]),
    date_reported = as.Date(paste(parts[5], parts[4], parts[3], sep = "-")),
    date_onset = as.Date(df[[1]], format = "%d/%m/%Y"),
    cases_reported = as.integer(df[[5]]),
    deaths_reported = as.integer(df[[7]])) %>%
    dplyr::filter(!is.na(.data$date_onset), !is.na(.data$cases_reported),
                  .data$date_onset <= .data$date_reported)
}

#' Builds snapshots of confirmed cases by onset date from the situation reports
build_bvd_snapshots <- function(paths) {
  purrr::map_dfr(sort(paths), read_bvd_sitrep) %>%
    dplyr::arrange(.data$date_onset, .data$date_reported)
}

#' First onset date to analyse so that Rt periods end on the analysis date
#'
#' @param date_now analysis date
#' @param date_earliest earliest onset date to consider
#' @param Rt_piece_width number of onset days sharing each Rt value
#' @return the first date on or after date_earliest for which the number of
#' onset days up to date_now is a multiple of Rt_piece_width
aligned_start_date <- function(date_now, date_earliest, Rt_piece_width) {
  n_days <- as.integer(as.Date(date_now) - as.Date(date_earliest)) + 1
  as.Date(date_earliest) + n_days %% Rt_piece_width
}

#' Prepares the BVD snapshots for analysis as of a situation report date
prepare_bvd_analysis <- function(snapshots, date_now, date_earliest = "2026-05-11",
                                 Rt_piece_width = 7) {
  df <- dplyr::select(snapshots, "date_onset", "date_reported", "cases_reported")
  date_start <- aligned_start_date(date_now, date_earliest, Rt_piece_width)
  prepare_real_analysis(df, date_start, date_now)
}

#' The models fitted to the BVD data
#'
#' - "original": the original model, fitted to counts replaced by their
#'   running maximum.
#' - "revisions": sporadic revisions and misdating, with the limit on erroneous
#'   records per onset day set large enough for the largest fall seen.
#' - "revisions and batches": as "revisions" with a small limit on erroneous
#'   records, larger falls being attributed to batches.
bvd_model_names <- function() c("original", "revisions", "revisions and batches")

#' Fits a model to the BVD data as of an analysis date
#'
#' The renewal model is negative binomial. No serial interval has been
#' published for Bundibugyo virus disease, so by default one estimated for
#' Ebola virus disease caused by Zaire ebolavirus in West Africa is used: mean
#' 15.3 and standard deviation 9.3 days (WHO Ebola Response Team, N Engl J Med
#' 2014).
fit_bvd_analysis <- function(analysis, model, niterations, Rt_piece_width = 7,
                             serial_parameters = list(mean = 15.3, sd = 9.3)) {
  settings <- fit_settings()
  settings$priors$reporting <- list(mean_mu = 10, mean_sigma = 10,
                                    sd_mu = 6, sd_sigma = 6)
  settings$priors$revisions$eta_mu <- 0.02
  settings$priors$revisions$eta_sigma <- 0.02
  largest_fall <- incidenceinflation::max_downward_revision(analysis$snapshots)
  if(model == "revisions and batches") {
    settings$max_erroneous <- 4
    settings$priors$batches$max_batch <- 30
  } else {
    settings$max_erroneous <- max(3, largest_fall + 1)
    settings$priors$batches <- NULL
  }
  fit <- fit_model_general(
    analysis$snapshots, ifelse(model == "original", "original", "full"),
    serial_parameters = serial_parameters,
    Rt_piece_width = Rt_piece_width,
    niterations = niterations, seed = 1, settings = settings,
    is_negative_binomial = TRUE)
  fit_summary <- summarise_fit(fit)
  fit_summary$model <- model
  list(model = model, analysis = analysis, summary = fit_summary,
       largest_fall = largest_fall, serial_parameters = serial_parameters)
}

bvd_colours <- function() {
  c("original" = "#0072B2", "revisions" = "#009E73",
    "revisions and batches" = "#CC79A7")
}

#' Combines estimates of case counts across results
bvd_case_estimates <- function(results) {
  purrr::map_dfr(results, function(result) {
    if(!is.null(result$summary$error))
      return(NULL)
    reported <- result$analysis$snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
      dplyr::summarise(cases_reported = dplyr::last(.data$cases_reported))
    result$summary$cases %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset") %>%
      dplyr::left_join(reported, by = "time_onset") %>%
      dplyr::left_join(result$analysis$later, by = "time_onset") %>%
      dplyr::mutate(model = factor(result$model, levels = bvd_model_names()),
                    date_now = result$analysis$date_now)
  })
}

#' Estimates of case counts as of each analysis date, for each model
plot_bvd_cases <- function(results, days_shown = 120) {
  df <- bvd_case_estimates(results)
  df$panel <- format_date_now(df$date_now)
  df <- dplyr::filter(df, .data$date > .data$date_now - days_shown)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_later), colour = "black",
                       linewidth = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_reported), colour = "#E69F00",
                       linewidth = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model),
                       linewidth = 0.4) +
    ggplot2::facet_grid(.data$model ~ .data$panel, scales = "free_x") +
    ggplot2::scale_colour_manual(values = bvd_colours(), guide = "none") +
    ggplot2::scale_fill_manual(values = bvd_colours(), guide = "none") +
    ggplot2::labs(
      x = "Onset date", y = "Confirmed cases",
      caption = paste("Orange: reported in the situation report of the analysis date.",
                      "Black: reported in the latest situation report.",
                      "Coloured line and band: posterior median and 90% interval.")) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Estimates of Rt as of each analysis date, for each model
plot_bvd_Rt <- function(results) {
  df <- purrr::map_dfr(results, function(result) {
    if(!is.null(result$summary$error))
      return(NULL)
    result$summary$Rt %>%
      dplyr::select("time_onset", "q05", "q50", "q95") %>%
      dplyr::left_join(result$analysis$dates, by = "time_onset") %>%
      dplyr::mutate(model = factor(result$model, levels = bvd_model_names()),
                    date_now = result$analysis$date_now)
  })
  df$panel <- format_date_now(df$date_now)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 2) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$model), alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$model)) +
    ggplot2::facet_wrap(~panel) +
    ggplot2::scale_colour_manual(values = bvd_colours()) +
    ggplot2::scale_fill_manual(values = bvd_colours()) +
    ggplot2::coord_cartesian(ylim = c(0, 3)) +
    ggplot2::labs(x = "Onset date", y = expression(R[t]), colour = "Model",
                  fill = "Model") +
    theme_paper()
}

#' The batches inferred in each fit which allowed for them
summarise_bvd_batches <- function(results) {
  purrr::map_dfr(results, function(result) {
    summary <- result$summary
    if(is.null(summary$batch_parameters))
      return(NULL)
    n_draws <- nrow(summary$batch_parameters)
    date_origin <- min(result$analysis$dates$date) - 1
    summary$batches %>%
      dplyr::group_by(.data$start, .data$width, .data$time_detected) %>%
      dplyr::summarise(proportion_of_draws = dplyr::n() / n_draws,
                       phi = stats::median(.data$phi), .groups = "drop") %>%
      dplyr::filter(.data$proportion_of_draws >= 0.05) %>%
      dplyr::arrange(dplyr::desc(.data$proportion_of_draws)) %>%
      dplyr::transmute(
        date_now = result$analysis$date_now,
        onset_from = date_origin + .data$start,
        onset_to = date_origin + .data$start + .data$width - 1,
        detected = date_origin + .data$time_detected,
        .data$proportion_of_draws, .data$phi,
        mean_n_batches = mean(summary$batch_parameters$n_batches))
  })
}

#' Scores, parameters and run times for each BVD fit
score_bvd_results <- function(results) {
  purrr::map_dfr(results, function(result) {
    out <- dplyr::bind_cols(
      dplyr::tibble(date_now = result$analysis$date_now,
                    largest_fall = result$largest_fall),
      score_real_fit(result$summary, result$analysis))
    out$model <- result$model
    if(!out$failed) {
      Rt <- result$summary$Rt %>%
        dplyr::filter(.data$Rt_index == max(.data$Rt_index)) %>%
        dplyr::slice(1)
      out$Rt_latest <- sprintf("%.2f (%.2f, %.2f)", Rt$q50, Rt$q05, Rt$q95)
    }
    out
  })
}

#' Reporting delays as tiles: onset date against delay
#'
#' Each tile is one onset date as seen in one situation report, placed at the
#' delay from onset to that report and extending to the next report. Its
#' colour gives the cases reported by then as a proportion of those in the
#' latest report, so that values above one (red) are cases later removed.
#'
#' @param snapshots a tibble with columns date_onset, date_reported, cases_reported
#' @param date_onset_min earliest onset date shown. By default this is the
#' date of the first situation report, so that every onset date shown is
#' followed from the day of onset.
#' @param min_cases onset dates with fewer cases than this in the latest
#' report are omitted, since their proportions are erratic
plot_delay_tiles <- function(snapshots, date_onset_min = NULL, min_cases = 5) {
  if(is.null(date_onset_min))
    date_onset_min <- min(snapshots$date_reported)
  latest <- snapshots %>%
    dplyr::filter(.data$date_reported == max(.data$date_reported)) %>%
    dplyr::select("date_onset", cases_latest = "cases_reported")
  df <- snapshots %>%
    dplyr::filter(.data$date_onset >= as.Date(date_onset_min)) %>%
    dplyr::inner_join(latest, by = "date_onset") %>%
    dplyr::filter(.data$cases_latest >= min_cases) %>%
    dplyr::group_by(.data$date_onset) %>%
    dplyr::arrange(.data$date_reported, .by_group = TRUE) %>%
    dplyr::mutate(
      delay = as.integer(.data$date_reported - .data$date_onset),
      delay_next = dplyr::lead(.data$delay, default = max(.data$delay) + 1),
      proportion = .data$cases_reported / .data$cases_latest) %>%
    dplyr::ungroup()
  ggplot2::ggplot(df) +
    ggplot2::geom_rect(ggplot2::aes(
      xmin = .data$date_onset - 0.5, xmax = .data$date_onset + 0.5,
      ymin = .data$delay, ymax = .data$delay_next,
      fill = pmin(.data$proportion, 1.4))) +
    ggplot2::scale_fill_gradient2(
      low = "#2166AC", mid = "grey97", high = "#B2182B", midpoint = 1,
      limits = c(0, 1.4), breaks = c(0, 0.5, 1, 1.4),
      labels = c("0", "0.5", "1", "1.4 or more")) +
    ggplot2::scale_x_date(date_breaks = "1 week", date_labels = "%d %b",
                          expand = c(0, 0)) +
    ggplot2::scale_y_continuous(expand = c(0, 0)) +
    ggplot2::labs(
      x = "Onset date", y = "Reporting delay (days from onset to situation report)",
      fill = "Cases reported,\nas a proportion of\nthose in the\nlatest report") +
    theme_paper() +
    ggplot2::theme(legend.position = "right",
                   panel.grid = ggplot2::element_blank())
}

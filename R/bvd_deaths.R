# Bundibugyo virus disease analysed with the joint model of cases and deaths:
# Rt, the reporting delay, the case fatality ratio and the delay from onset to
# a death being recorded all change at times which are inferred.

#' Prepares the cases and deaths shown in each report, as of a date
#'
#' As prepare_bvd_changepoint_analysis, with the deaths shown in each report
#' added and with two differences.
#'
#' The first onset day analysed is date_first, which is before the first
#' situation report: those onset days are first seen some time after onset,
#' so say little about the reporting delay, but deaths among their cases go
#' on being recorded from report to report.
#'
#' The report of date_corrected corrected the records of onset days before
#' date_onset_corrected (it removed many records, added some and changed
#' which were shown as dead). For those onset days the reports made before it
#' are returned separately, as 'uncorrected'. The main fits leave them out;
#' one fit, as a check, uses them as a separate series.
#'
#' Onset days more than days_observed before the first report say almost
#' nothing about the reporting delay, since nearly all their cases are in the
#' first report which includes them. No change in the reporting delay is
#' allowed until delay_min_length days after the first onset day which is
#' within days_observed of the first report, so that those early days share
#' the delay of the first onset days which do inform it.
#' 'reporting_first_length' is the resulting minimum number of onset days in
#' the first segment of the reporting delay.
prepare_bvd_deaths_analysis <- function(snapshots, date_now,
                                        date_first = "2026-05-11",
                                        date_corrected = "2026-09-06",
                                        date_onset_corrected = "2026-06-28",
                                        serial_max = 40, days_observed = 7,
                                        delay_min_length = bvd_delay_settings()$min_length) {
  date_now <- as.Date(date_now)
  analysis <- prepare_bvd_analysis(snapshots, date_now, date_earliest = date_first,
                                   Rt_piece_width = 1)
  date_start <- min(analysis$dates$date)
  analysis$weekday_first <- as.integer(format(date_start, "%u"))
  known <- snapshots %>%
    dplyr::filter(.data$date_reported <= date_now) %>%
    dplyr::filter(.data$date_reported == max(.data$date_reported),
                  .data$date_onset < date_start,
                  .data$date_onset >= date_start - serial_max)
  before <- dplyr::tibble(date = seq(date_start - serial_max, date_start - 1, by = 1)) %>%
    dplyr::left_join(dplyr::select(known, date = "date_onset", "cases_reported"),
                     by = "date") %>%
    dplyr::mutate(cases = dplyr::coalesce(as.numeric(.data$cases_reported), 0))
  analysis$cases_before <- before$cases
  analysis$dates_before <- before$date
  deaths <- snapshots %>%
    dplyr::transmute(
      time_onset = as.integer(.data$date_onset - date_start) + 1L,
      time_reported = as.integer(.data$date_reported - date_start) + 1L,
      deaths_reported = as.integer(.data$deaths_reported))
  all_reports <- dplyr::left_join(analysis$snapshots, deaths,
                                  by = c("time_onset", "time_reported"))
  if(any(is.na(all_reports$deaths_reported)))
    stop("Some reports of cases have no count of deaths.")
  if(any(all_reports$deaths_reported > all_reports$cases_reported))
    stop("Some reports show more deaths than cases.")
  f_time <- function(date) as.integer(as.Date(date) - date_start) + 1L
  date_observed <- min(snapshots$date_reported) - days_observed
  analysis$date_observed <- date_observed
  analysis$reporting_first_length <- max(
    delay_min_length, f_time(date_observed) - 1L + delay_min_length)
  analysis$all_reports <- all_reports
  analysis$snapshots <- all_reports
  analysis$uncorrected <- NULL
  if(as.Date(date_corrected) <= date_now & as.Date(date_onset_corrected) > date_start) {
    analysis$correction <- list(
      time_reported = f_time(date_corrected),
      onset_times = seq_len(f_time(date_onset_corrected) - 1))
    parts <- incidenceinflation::split_corrected_reports(
      all_reports, analysis$correction$time_reported, analysis$correction$onset_times)
    analysis$snapshots <- parts$corrected
    analysis$uncorrected <- parts$uncorrected
  }
  analysis
}

#' The fits made: what each is told about fatal cases dated by death, and
#' whether it uses the reports made before the correction
#'
#' The reports do not say how many fatal cases are recorded for their day of
#' death, nor how long after onset those deaths were. "none" takes there to be
#' none and is the main fit. "a fifth" is a check of how much the results
#' depend on this: a fifth of fatal cases, dying a mean of 7 days after onset
#' (sd 4) and reported a mean of 2 days after death (sd 1.5). These values are
#' illustrative: they are not estimates for this outbreak.
#'
#' For the onset days which the correction changed, these two fits use only
#' the reports from the correction on. "earlier reports" is a check of what
#' the reports made before it add: as "none", with those reports as a
#' separate series which informs only the delays and the wrong records.
bvd_deaths_variants <- function() {
  list(
    none = list(dated_by_death = NULL, uncorrected = FALSE),
    `a fifth` = list(dated_by_death = list(fraction = 0.2, mean = 7, sd = 4,
                                           reporting = list(mean = 2, sd = 1.5)),
                     uncorrected = FALSE),
    `earlier reports` = list(dated_by_death = NULL, uncorrected = TRUE))
}

#' Starting values of a chain
#'
#' "spread" starts the three chains far apart. "close" starts them near the
#' values on which two chains of a first fit to the reports up to 1 October
#' 2026 agreed, differing between chains by a tenth: the chains then say
#' nothing about whether there is another mode elsewhere. "near" starts
#' them near values which simple fits to the reports suggest (a delay to a
#' death being recorded of mean 15 and sd 13 days, a case fatality ratio of
#' 0.37), differing between chains by up to a tenth.
#'
#' @return a list: the multiple of the reported cases added for the latest
#'   onset day and the days over which this falls off, and starting values of
#'   the parameters
bvd_deaths_starts <- function(starts, chain) {
  index <- (chain - 1) %% 3 + 1
  if(starts == "spread")
    return(list(
      inflation = c(2, 1, 3.5)[index], inflation_days = 4,
      cfr = c(0.5, 0.25, 0.7)[index],
      delay = list(list(mean = 14, sd = 8), list(mean = 8, sd = 5),
                   list(mean = 20, sd = 10))[[index]],
      reporting = list(list(mean = 7, sd = 4), list(mean = 4, sd = 2.5),
                       list(mean = 11, sd = 7))[[index]],
      overdispersion = c(10, 3, 30)[index],
      tail = list(weight = c(0.02, 0.05, 0.01)[index], mean = c(40, 25, 60)[index]),
      eta = NULL, rho = NULL))
  if(starts == "near") {
    scale <- c(1, 0.9, 1.1, 0.95)[(chain - 1) %% 4 + 1]
    return(list(
      inflation = 2 * scale, inflation_days = 4,
      cfr = 0.37 * scale,
      delay = list(mean = 15 * scale, sd = 13 * scale),
      reporting = list(mean = 7.6 * scale, sd = 5.4 * scale),
      overdispersion = 30 * scale,
      tail = list(weight = 0.1 * scale, mean = 40 * scale),
      eta = NULL, rho = NULL))
  }
  scale <- c(1, 0.9, 1.1)[index]
  list(inflation = 4 * scale, inflation_days = 5,
       cfr = 0.5 * scale,
       delay = list(mean = 22 * scale, sd = 35 * scale),
       reporting = list(mean = 7.6 * scale, sd = 5.4 * scale),
       overdispersion = 30 * scale,
       tail = list(weight = 0.17 * scale, mean = 40 * scale),
       eta = 0.034 * scale, rho = 0.05 * scale)
}

#' Runs one chain of the joint model of cases and deaths
#'
#' As fit_bvd_changepoint_chain (wrong records, an effect of the day of the
#' week of each report, a negative binomial renewal model, earlier cases
#' supplied as known), with the deaths shown in each report. The reports made
#' before the correction, of the onset days it corrected, are left out unless
#' the variant uses them, as a separate series which informs only the delays
#' and the wrong records.
fit_bvd_deaths_chain <- function(analysis, variant, chain, niterations, n_draws = 300,
                                 starts = "spread",
                                 serial_parameters = list(mean = 15.3, sd = 9.3),
                                 progress_dir = "outputs/bvd_deaths/progress",
                                 tail = TRUE, tail_prior = NULL,
                                 delay_settings = NULL, deaths_prior = NULL,
                                 resume = NULL, time_limit = NULL) {
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(1000 * chain + as.integer(analysis$date_now) %% 1000)
  settings <- fit_settings()
  snapshots <- analysis$snapshots
  largest_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- max(snapshots$time_onset) - largest_reported$time_onset
  start <- bvd_deaths_starts(starts, chain)
  # the latest few onset days show few cases yet: start them no lower than
  # half the level of two to four weeks before
  level <- stats::median(largest_reported$cases_true[days_before_end %in% 14:27])
  initial_cases_true <- largest_reported %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + start$inflation *
                            exp(-days_before_end / start$inflation_days)) +
        5 * (days_before_end < 5)))
  if(starts == "close")
    initial_cases_true$cases_true <- pmax(
      initial_cases_true$cases_true,
      ceiling(0.5 * level * (days_before_end < 5)))
  options <- bvd_deaths_variants()[[variant]]
  uncorrected <- if(options$uncorrected) analysis$uncorrected
  f_largest_fall <- function(column) {
    # a fall across the correction is not one the model has to explain
    falls <- dplyr::bind_rows(
      snapshots,
      if(!is.null(uncorrected))
        dplyr::mutate(uncorrected, time_onset = .data$time_onset + 1e6)) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
      dplyr::summarise(fall = max(c(0, -diff(.data[[column]]))))
    max(falls$fall)
  }
  max_erroneous <- max(3, f_largest_fall("cases_reported") + 1,
                       f_largest_fall("deaths_reported") + 1)
  priors <- list(
    Rt = settings$priors$Rt,
    reporting = list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5),
    max_cases = ceiling(4 * max(initial_cases_true$cases_true) + 50),
    overdispersion = list(mean = 20, sd = 20),
    revisions = utils::modifyList(
      settings$priors$revisions[c("eta_mu", "eta_sigma", "rho_alpha", "rho_beta")],
      list(eta_mu = 0.005, eta_sigma = 0.005)),
    max_erroneous = max_erroneous,
    # a small share of cases are reported with a long delay: a few cases are
    # added to an onset day months after it
    reporting_effects = utils::modifyList(
      list(tail_weight_alpha = 1, tail_weight_beta = 19,
           tail_mean_mu = 40, tail_mean_sigma = 30),
      if(is.null(tail_prior)) list() else tail_prior[names(tail_prior) != "label"]),
    Rt_changepoints = list(),
    reporting_changepoints = c(
      bvd_delay_settings(), list(first_length = analysis$reporting_first_length)))
  # settings of the changes in the delay to a death being recorded which
  # replace the usual ones (see bvd_delay_settings_given)
  deaths_settings <- list(
    initial_cfr = start$cfr,
    initial_delay = start$delay,
    delay_changepoints = utils::modifyList(
      bvd_delay_settings(),
      bvd_delay_settings_given(delay_settings, dplyr::n_distinct(snapshots$time_onset))))
  if(!is.null(deaths_prior))
    deaths_settings <- utils::modifyList(
      deaths_settings, deaths_prior[names(deaths_prior) != "label"])
  # what the variant says of fatal cases dated by death, unless the
  # settings given say something of their own
  if(is.null(deaths_prior$dated_by_death))
    deaths_settings["dated_by_death"] <- list(options$dated_by_death)

  time_start <- Sys.time()
  fit <- tryCatch(
    bvd_mcmc(
      resume = resume, time_limit = time_limit, niterations = niterations,
      snapshot_with_Rt_index_df = snapshots %>%
        dplyr::select("time_onset", "time_reported", "cases_reported") %>%
        dplyr::mutate(Rt_index = 1),
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = initial_cases_true,
      initial_reporting_parameters = start$reporting,
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      initial_overdispersion = start$overdispersion,
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 8,
      initial_revision_parameters = c(
        list(eta = if(is.null(start$eta)) settings$initial_revisions$eta else start$eta,
             rho = if(is.null(start$rho)) settings$initial_revisions$rho else start$rho,
             weekday = TRUE, weekday_first = analysis$weekday_first),
        if(tail) list(tail = start$tail)),
      revision_metropolis_parameters = settings$revision_metropolis,
      cases_before = analysis$cases_before,
      n_parameter_steps = 5,
      progress_file = file.path(progress_dir, sprintf(
        "%s_%s_%d.txt", gsub(" ", "_", variant), analysis$date_now, chain)),
      progress_every = 10,
      deaths = c(list(snapshot = snapshots %>%
                        dplyr::select("time_onset", "time_reported", "deaths_reported"),
                      settings = deaths_settings),
                 if(!is.null(uncorrected)) list(uncorrected = uncorrected))),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(variant = variant, chain = chain, analysis = analysis,
              niterations = niterations, niterations_target = niterations,
              starts = starts,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, serial_parameters = serial_parameters,
              error = fit$error)
  if(!is.null(fit$error))
    return(out)
  out$niterations <- fit$iterations
  out$minutes <- out$minutes + fit$minutes_before
  out$progress <- bvd_progress(fit, out$minutes)
  warmup <- floor(out$niterations / 2)
  kept <- unique(round(seq(warmup + 1, out$niterations, length.out = n_draws)))
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "overdispersion", "deaths", "deaths_parameters",
    "Rt_changepoints", "reporting_changepoints", "revisions", "reporting_effects",
    "deaths_uncorrected")))
    out[[name]] <- fit[[name]] %>%
    dplyr::filter(.data$iteration %in% kept) %>%
    dplyr::select(-dplyr::any_of("chain")) %>%
    dplyr::mutate(chain = chain, variant = variant)
  out
}

#' Draws of one kind from the chains of one variant which ran
bvd_deaths_draws <- function(chains, variant, name) {
  chains <- purrr::keep(chains, ~.$variant == variant & is.null(.$error))
  purrr::map_dfr(chains, name)
}

#' Quantities whose agreement between chains is checked
bvd_deaths_monitored <- function(chains, variant, days_recent = 14) {
  f <- function(name) dplyr::arrange(bvd_deaths_draws(chains, variant, name),
                                     .data$chain, .data$iteration)
  cases <- f("cases")
  deaths <- f("deaths")
  reporting <- f("reporting_days")
  parameters <- f("deaths_parameters")
  revisions <- f("revisions")
  day_last <- max(cases$time_onset)
  f_days <- function(df, column, days, fun, quantity) {
    df %>%
      dplyr::filter(.data$time_onset %in% days) %>%
      dplyr::group_by(.data$chain, .data$iteration) %>%
      dplyr::summarise(value = fun(.data[[column]]), .groups = "drop") %>%
      dplyr::mutate(quantity = quantity)
  }
  recent <- (day_last - days_recent + 1):day_last
  f_parameter <- function(df, column, quantity)
    dplyr::tibble(chain = df$chain, iteration = df$iteration, value = df[[column]],
                  quantity = quantity)
  # only where a death can bring about the report of its case
  is_triggered <- "triggered" %in% names(parameters) && any(parameters$triggered > 0)
  # only where some fatal cases are counted on their day of death
  is_dated <- "dated_fraction" %in% names(parameters) &&
    any(parameters$dated_fraction > 0)
  dplyr::bind_rows(
    f_days(cases, "cases_true", recent, sum, "Cases, latest 14 onset days"),
    f_days(cases, "cases_true", 1:day_last, sum, "Cases, all onset days"),
    f_days(deaths, "deaths_true", recent, sum, "Fatal cases, latest 14 onset days"),
    f_days(deaths, "deaths_true", 1:day_last, sum, "Fatal cases, all onset days"),
    f_days(deaths, "cfr", 1, mean, "Case fatality ratio, first onset day"),
    f_days(deaths, "cfr", day_last, mean, "Case fatality ratio, latest onset day"),
    f_days(deaths, "delay_mean", 1, mean, "Mean delay to death recorded, first onset day"),
    f_days(deaths, "delay_mean", day_last, mean,
           "Mean delay to death recorded, latest onset day"),
    f_days(deaths, "delay_sd", day_last, mean,
           "Sd of delay to death recorded, latest onset day"),
    if(is_triggered)
      f_parameter(parameters, "triggered",
                  "Share of fatal cases reported when the death is recorded"),
    if(is_dated)
      f_parameter(parameters, "dated_fraction",
                  "Fraction of fatal cases counted on their day of death"),
    if(is_dated)
      f_days(deaths, "dated_by_death", 1:day_last, sum,
             "Fatal cases counted on their day of death, all days"),
    f_days(reporting, "mean", 1, mean, "Mean delay to case reported, first onset day"),
    f_days(reporting, "mean", day_last, mean,
           "Mean delay to case reported, latest onset day"),
    f_parameter(parameters, "n_cfr_changes", "Changes in the case fatality ratio"),
    f_parameter(parameters, "n_delay_changes", "Changes in the delay to death recorded"),
    f_parameter(parameters, "fatal_delay_ratio",
                "Reporting delay of fatal cases relative to others"),
    f_parameter(parameters, "wrong_dead", "Share of wrong records shown as dead"),
    f_parameter(f("reporting_effects"), "tail_weight",
                "Share of cases reported with a long delay"),
    f_parameter(f("reporting_effects"), "tail_mean",
                "Mean of the long reporting delay (days)"),
    f_parameter(revisions, "eta", "Wrong records per case and report (eta)"),
    f_parameter(revisions, "rho", "Removal of wrong records per report (rho)"))
}

#' Summary of each monitored quantity: median, 90% interval and split R-hat
summarise_bvd_deaths <- function(chains) {
  variants <- unique(purrr::map_chr(purrr::keep(chains, ~is.null(.$error)), "variant"))
  purrr::map_dfr(variants, function(variant) {
    monitored <- bvd_deaths_monitored(chains, variant)
    ratio <- monitored$value[monitored$quantity ==
                               "Reporting delay of fatal cases relative to others"]
    monitored %>%
      dplyr::group_by(.data$quantity) %>%
      dplyr::summarise(
        median = stats::median(.data$value),
        lo = stats::quantile(.data$value, 0.05),
        hi = stats::quantile(.data$value, 0.95),
        rhat = split_rhat(.data$value, .data$chain), .groups = "drop") %>%
      dplyr::mutate(variant = variant, n_chains = length(unique(monitored$chain)),
                    share_fatal_delay_same = mean(ratio == 1), .before = 1)
  })
}

#' Which chains ran, how long they took and any errors
bvd_deaths_runs <- function(chains) {
  purrr::map_dfr(chains, function(fit) {
    dplyr::tibble(variant = fit$variant, chain = fit$chain,
                  niterations = fit$niterations, minutes = fit$minutes,
                  error = if(is.null(fit$error)) "" else fit$error)
  })
}

#' Estimates by onset day, for the figure and as a table
bvd_deaths_by_day <- function(chains) {
  variants <- unique(purrr::map_chr(purrr::keep(chains, ~is.null(.$error)), "variant"))
  analysis <- chains[[1]]$analysis
  f_summary <- function(df, value, series, quantity) {
    df %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(lo = stats::quantile({{value}}, 0.05),
                       mid = stats::median({{value}}),
                       hi = stats::quantile({{value}}, 0.95), .groups = "drop") %>%
      dplyr::mutate(series = series, quantity = quantity)
  }
  purrr::map_dfr(variants, function(variant) {
    f <- function(name) bvd_deaths_draws(chains, variant, name)
    delays <- f("reporting_days") %>%
      dplyr::left_join(
        f("deaths_parameters")[, c("iteration", "chain", "fatal_delay_ratio")],
        by = c("iteration", "chain"))
    dplyr::bind_rows(
      f_summary(f("cases"), .data$cases_true, "Cases", "Cases by day of onset"),
      f_summary(f("deaths"), .data$deaths_true, "Fatal cases",
                "Fatal cases by day of onset"),
      f_summary(f("Rt"), .data$Rt, "Reproduction number", "Reproduction number"),
      f_summary(delays, .data$mean, "Onset to case reported", "Mean delay (days)"),
      f_summary(delays, .data$mean * .data$fatal_delay_ratio,
                "Onset to case reported, fatal cases", "Mean delay (days)"),
      f_summary(f("deaths"), .data$delay_mean, "Onset to death recorded",
                "Mean delay (days)"),
      f_summary(f("deaths"), .data$cfr, "Case fatality ratio", "Case fatality ratio")) %>%
      dplyr::mutate(variant = variant, .before = 1)
  }) %>%
    dplyr::left_join(dplyr::select(analysis$dates, "time_onset", "date"),
                     by = "time_onset")
}

#' Estimates by onset day with the counts of the latest report
plot_bvd_deaths <- function(by_day, analysis) {
  quantities <- c("Cases by day of onset", "Fatal cases by day of onset",
                  "Reproduction number", "Mean delay (days)", "Case fatality ratio")
  labels <- c(none = "No cases dated by death",
              `a fifth` = "A fifth of fatal cases dated by death",
              `earlier reports` = "With the reports before the correction")
  latest <- analysis$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
    dplyr::ungroup() %>%
    dplyr::left_join(dplyr::select(analysis$dates, "time_onset", "date"),
                     by = "time_onset")
  variants <- unique(by_day$variant)
  reported <- tidyr::crossing(
    variant = variants,
    dplyr::bind_rows(
      dplyr::tibble(date = latest$date, value = latest$cases_reported,
                    series = "Cases in the latest report", quantity = quantities[1]),
      dplyr::tibble(date = latest$date, value = latest$deaths_reported,
                    series = "Deaths in the latest report", quantity = quantities[2])))
  f_factors <- function(df) {
    dplyr::mutate(df, quantity = factor(.data$quantity, levels = quantities),
                  variant = factor(labels[.data$variant], levels = labels[variants]))
  }
  colours <- c("Cases" = "#4C72B0", "Fatal cases" = "#C44E52",
               "Reproduction number" = "#333333",
               "Onset to case reported" = "#4C72B0",
               "Onset to case reported, fatal cases" = "#DD8452",
               "Onset to death recorded" = "#C44E52", "Case fatality ratio" = "#333333",
               "Cases in the latest report" = "#111111",
               "Deaths in the latest report" = "#111111")
  ggplot2::ggplot(f_factors(by_day), ggplot2::aes(x = .data$date)) +
    ggplot2::geom_col(data = f_factors(reported), ggplot2::aes(y = .data$value),
                      fill = "grey80", width = 1) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi,
                                      fill = .data$series), alpha = 0.25) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid, colour = .data$series)) +
    ggplot2::facet_grid(.data$quantity ~ .data$variant, scales = "free_y",
                        switch = "y") +
    ggplot2::scale_colour_manual(values = colours, breaks = c(
      "Onset to case reported", "Onset to case reported, fatal cases",
      "Onset to death recorded"), name = "Delay") +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::expand_limits(y = 0) +
    ggplot2::labs(x = "Date of onset", y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(strip.placement = "outside",
                   strip.background = ggplot2::element_blank(),
                   legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}


# ---- fits to the reports up to earlier dates ---------------------------------

#' The dates taken in turn as the date of the latest report
#'
#' The last is the latest report. 5 September is the day before the report
#' which corrected many records.
bvd_nowcast_dates <- function() {
  as.Date(c("2026-08-01", "2026-08-20", "2026-09-05", "2026-09-15", "2026-10-01"))
}

#' The chains of each date, as a list named by date
bvd_nowcast_by_date <- function(chains) {
  dates <- purrr::map_chr(chains, ~as.character(.$analysis$date_now))
  split(chains, dates)
}

#' Which chains ran, how long they took and any errors, by date
bvd_nowcast_runs <- function(chains) {
  purrr::imap_dfr(bvd_nowcast_by_date(chains), function(fits, date) {
    dplyr::mutate(bvd_deaths_runs(fits), date_now = date, .before = 1)
  })
}

#' Summary of each monitored quantity, by date
bvd_nowcast_summary <- function(chains) {
  purrr::imap_dfr(bvd_nowcast_by_date(chains), function(fits, date) {
    fits <- purrr::keep(fits, ~is.null(.$error))
    if(length(fits) == 0)
      return(NULL)
    monitored <- bvd_deaths_monitored(fits, fits[[1]]$variant)
    by_chain <- monitored %>%
      dplyr::group_by(.data$quantity, .data$chain) %>%
      dplyr::summarise(median = stats::median(.data$value), .groups = "drop") %>%
      tidyr::pivot_wider(names_from = "chain", values_from = "median",
                         names_prefix = "chain_")
    summarise_bvd_deaths(fits) %>%
      dplyr::left_join(by_chain, by = "quantity") %>%
      dplyr::mutate(date_now = date, .before = 1)
  })
}

#' Estimates by onset day, by date, with the counts then and in the latest report
#'
#' @param snapshots the cases and deaths shown in every report
#' @return a row for each date, onset day and series ("Cases", "Fatal
#'   cases", the delays, the case fatality ratio and the reproduction number)
#'   with the 90% interval and median; for cases and fatal cases also the
#'   count in the report of that date ('reported_then') and in the latest
#'   report of all ('reported_latest')
bvd_nowcast_by_day <- function(chains, snapshots) {
  latest <- snapshots %>%
    dplyr::filter(.data$date_reported == max(.data$date_reported)) %>%
    dplyr::select(date = "date_onset", Cases = "cases_reported",
                  `Fatal cases` = "deaths_reported") %>%
    tidyr::pivot_longer(c("Cases", "Fatal cases"), names_to = "series",
                        values_to = "reported_latest")
  purrr::imap_dfr(bvd_nowcast_by_date(chains), function(fits, now) {
    fits <- purrr::keep(fits, ~is.null(.$error))
    if(length(fits) == 0)
      return(NULL)
    then <- snapshots %>%
      dplyr::filter(.data$date_reported <= as.Date(now)) %>%
      dplyr::filter(.data$date_reported == max(.data$date_reported)) %>%
      dplyr::select(date = "date_onset", Cases = "cases_reported",
                    `Fatal cases` = "deaths_reported") %>%
      tidyr::pivot_longer(c("Cases", "Fatal cases"), names_to = "series",
                          values_to = "reported_then")
    bvd_deaths_by_day(fits) %>%
      dplyr::left_join(then, by = c("date", "series")) %>%
      dplyr::left_join(latest, by = c("date", "series")) %>%
      dplyr::mutate(date_now = as.Date(now), .before = 1)
  })
}

#' How the estimates of each date compare with the latest report
#'
#' For onset days not corrected by the report of date_onset_corrected, in
#' bands of days before the date: the total in the report of that date, the
#' estimated total (median and 90% interval over draws) and the total in the
#' latest report; and the share of onset days whose count in the latest
#' report is inside the 90% interval for that day. The latest report is not
#' the truth: its counts for recent onset days, deaths above all, are still
#' rising.
bvd_nowcast_comparison <- function(chains, snapshots,
                                   date_onset_corrected = "2026-06-28") {
  by_day <- bvd_nowcast_by_day(chains, snapshots) %>%
    dplyr::filter(.data$series %in% c("Cases", "Fatal cases"),
                  .data$date >= as.Date(date_onset_corrected))
  f_band <- function(days) {
    cut(days, c(-1, 6, 13, 27, Inf),
        labels = c("0-6", "7-13", "14-27", "28 or more"))
  }
  covered <- by_day %>%
    dplyr::mutate(band = f_band(as.integer(.data$date_now - .data$date))) %>%
    dplyr::group_by(.data$date_now, .data$series, .data$band) %>%
    dplyr::summarise(
      n_days = dplyr::n(),
      days_inside = mean(.data$reported_latest >= .data$lo &
                           .data$reported_latest <= .data$hi),
      days_below = mean(.data$reported_latest < .data$lo),
      reported_then = sum(.data$reported_then, na.rm = TRUE),
      reported_latest = sum(.data$reported_latest), .groups = "drop") %>%
    dplyr::relocate("days_inside", "days_below", .after = "reported_latest")
  totals <- purrr::imap_dfr(bvd_nowcast_by_date(chains), function(fits, now) {
    fits <- purrr::keep(fits, ~is.null(.$error))
    if(length(fits) == 0)
      return(NULL)
    dates <- fits[[1]]$analysis$dates
    f <- function(name, column, series) {
      purrr::map_dfr(fits, name) %>%
        dplyr::left_join(dplyr::select(dates, "time_onset", "date"), by = "time_onset") %>%
        dplyr::filter(.data$date >= as.Date(date_onset_corrected)) %>%
        dplyr::mutate(band = f_band(as.integer(as.Date(now) - .data$date))) %>%
        dplyr::group_by(.data$chain, .data$iteration, .data$band) %>%
        dplyr::summarise(total = sum(.data[[column]]), .groups = "drop") %>%
        dplyr::group_by(.data$band) %>%
        dplyr::summarise(estimate = stats::median(.data$total),
                         lo = stats::quantile(.data$total, 0.05),
                         hi = stats::quantile(.data$total, 0.95), .groups = "drop") %>%
        dplyr::mutate(series = series, date_now = as.Date(now))
    }
    dplyr::bind_rows(f("cases", "cases_true", "Cases"),
                     f("deaths", "deaths_true", "Fatal cases"))
  })
  dplyr::left_join(covered, totals, by = c("date_now", "series", "band")) %>%
    dplyr::relocate("estimate", "lo", "hi", .after = "reported_then")
}

#' Estimated cases and fatal cases at each date against the latest report
plot_bvd_nowcasts <- function(by_day, days_shown = 42) {
  shown <- by_day %>%
    dplyr::filter(.data$series %in% c("Cases", "Fatal cases"),
                  .data$date > .data$date_now - days_shown) %>%
    dplyr::mutate(
      label = factor(format(.data$date_now, "Reports to %e %B"),
                     levels = unique(format(sort(.data$date_now), "Reports to %e %B"))),
      series = factor(.data$series, levels = c("Cases", "Fatal cases"),
                      labels = c("Cases by day of onset", "Fatal cases by day of onset")))
  ggplot2::ggplot(shown, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_col(ggplot2::aes(y = .data$reported_then, fill = "In the report of that date"),
                      width = 1) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi),
                         fill = "#4C72B0", alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid, colour = "Estimate at that date")) +
    ggplot2::geom_point(ggplot2::aes(y = .data$reported_latest,
                                     colour = "In the report of 1 October"), size = 0.8) +
    ggplot2::facet_grid(.data$series ~ .data$label, scales = "free", switch = "y") +
    ggplot2::scale_fill_manual(values = c("In the report of that date" = "grey80"),
                               name = NULL) +
    ggplot2::scale_colour_manual(values = c("Estimate at that date" = "#4C72B0",
                                            "In the report of 1 October" = "#C44E52"),
                                 name = NULL) +
    ggplot2::labs(x = "Date of onset", y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(strip.placement = "outside",
                   strip.background = ggplot2::element_blank(),
                   legend.position = "bottom", panel.grid.minor = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' The case fatality ratio and the delays by onset day, as estimated at each date
plot_bvd_nowcast_parameters <- function(by_day) {
  shown <- by_day %>%
    dplyr::filter(.data$series %in% c("Case fatality ratio", "Onset to death recorded",
                                      "Onset to case reported", "Reproduction number"),
                  !(.data$series == "Reproduction number" &
                      .data$date < as.Date("2026-06-01"))) %>%
    dplyr::mutate(
      now = factor(format(.data$date_now, "%e %B"),
                   levels = unique(format(sort(.data$date_now), "%e %B"))),
      series = factor(.data$series, levels = c(
        "Case fatality ratio", "Onset to death recorded", "Onset to case reported",
        "Reproduction number"), labels = c(
          "Case fatality ratio", "Mean delay, onset to\ndeath recorded (days)",
          "Mean delay, onset to\ncase reported (days)", "Reproduction number")))
  ggplot2::ggplot(shown, ggplot2::aes(x = .data$date, colour = .data$now, fill = .data$now)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi), alpha = 0.12,
                         colour = NA) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid)) +
    ggplot2::facet_wrap(~.data$series, scales = "free_y", ncol = 1,
                        strip.position = "left") +
    ggplot2::expand_limits(y = 0) +
    ggplot2::labs(x = "Date of onset", y = NULL, colour = "Reports to", fill = "Reports to") +
    ggplot2::theme_bw() +
    ggplot2::theme(strip.placement = "outside",
                   strip.background = ggplot2::element_blank(),
                   legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

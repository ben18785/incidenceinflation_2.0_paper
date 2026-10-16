# Simulated data for the model in which the time from onset to death is
# supplied, a death is recorded after a further delay which is estimated, and
# the fraction of fatal cases counted on their day of death is estimated
# (docs/bvd_deaths.tex, 'A supplied time from onset to death'). Each scenario
# is a way in which an outbreak and its reports are simulated and a way in
# which the model is fitted.

#' The scenarios
#'
#' @return a tibble with a row for each scenario: its name, the label used in
#' tables, the group and the question it is there to answer
misdated_scenarios <- function() {
  dplyr::tribble(
    ~scenario, ~label, ~group, ~why,
    "base", "Base: 30% counted on day of death, half of deaths bring the report", "Right model", "Are the fraction, the share, the delays and the deaths recovered?",
    "tau_0", "No death brings the report", "Right model", "The share is at its lower limit.",
    "tau_25", "A quarter of deaths bring the report", "Right model", "Recovery across the range of the share.",
    "tau_75", "Three quarters of deaths bring the report", "Right model", "Recovery across the range of the share.",
    "tau_100", "Every death brings the report", "Right model", "The share is at its upper limit.",
    "fraction_0", "None counted on day of death", "Right model", "The fraction is at its lower limit.",
    "fraction_10", "10% counted on day of death", "Right model", "Recovery across the range of the fraction.",
    "fraction_50", "50% counted on day of death", "Right model", "Recovery across the range of the fraction.",
    "fit_no_triggered", "Base, fitted with no death bringing the report", "An option left out", "Does the fraction absorb what the share should explain?",
    "fit_fraction_low", "Base, fitted with the fraction held at 10%", "An option left out", "What happens to the deaths when the fraction is held too low?",
    "fit_old", "Base, fitted with a free delay from onset to death recorded", "An option left out", "Does the earlier model overshoot deaths, as on the outbreak?",
    "recording_fast", "Deaths recorded 1.5 days after death", "How well determined", "Cases counted on day of death appear at once.",
    "recording_slow", "Deaths recorded 6 days after death", "How well determined", "Cases counted on day of death are harder to tell from others.",
    "cfr_low", "CFR 0.1", "How well determined", "Few deaths.",
    "few_cases", "Eight cases a day", "How well determined", "Little information.",
    "cfr_fall", "CFR halves", "Changes", "A change in the case fatality ratio with four weeks of later data.",
    "recording_change", "Delay from death to recording falls from 8 to 3 days", "Changes", "The pattern the outbreak fits suggest.",
    "cfr_recording_together", "CFR halves as the delay from death falls", "Changes", "Two changes on the same day.",
    "fraction_change", "Fraction rises from 10% to 50%", "Changes", "The model has one fraction for all onset days.",
    "tau_change", "Share rises from 0.2 to 0.8", "Changes", "The model has one share for all onset days.",
    "otd_sd_low", "Time to death: sd 5.5, fitted with 4.5", "Wrong inputs", "The fraction rests on the sd supplied.",
    "otd_sd_high", "Time to death: sd 5.5, fitted with 8", "Wrong inputs", "The fraction rests on the sd supplied.",
    "otd_mean_high", "Time to death: 9.3 (sd 5.5), fitted with 12 (sd 7)", "Wrong inputs", "A time to death which is too long.",
    "sooner", "Fatal cases reported twice as fast, no death brings the report", "Another mechanism", "Is faster reporting of fatal cases mistaken for the share or the fraction?",
    "tail", "15% of deaths recorded after a long delay, fitted with a tail", "Another mechanism", "Deaths added months later, allowed for.",
    "tail_ignored", "15% of deaths recorded after a long delay, fitted without a tail", "Another mechanism", "Deaths added months later, not allowed for.",
    "wrong", "Wrong records", "Structure of the outbreak data", "Counts of cases and deaths sometimes fall.",
    "early", "First report on day 25", "Structure of the outbreak data", "The first 24 onset days are first seen 1 to 24 days after onset.",
    "corrected_dropped", "Report of day 45 corrects onset days 1 to 20, earlier reports of them left out", "Structure of the outbreak data", "As the report of 6 September is handled.",
    "backlog", "Backlog: share falls from 0.4 to 0.1, cleared mostly on days 51 to 75, fitted with the backlog", "A backlog of deaths", "Are the share, the clearing rate and the deaths still to be recorded recovered?",
    "backlog_fit_f", "Backlog, fitted with a tail and an effect of each report on it (option f)", "A backlog of deaths", "Does the model fitted to the outbreak miss the deaths still to be recorded?",
    "backlog_mid", "Backlog, fitted on day 63, part way through the clearing", "A backlog of deaths", "Are the deaths still to be recorded found while the backlog is being cleared?",
    "backlog_mid_fit_f", "Backlog, fitted on day 63 with option f", "A backlog of deaths", "The same, with the model fitted to the outbreak.",
    "backlog_before", "Backlog, fitted on day 50, before the clearing", "A backlog of deaths", "What can be known of a backlog nothing has yet cleared?",
    "backlog_before_fit_f", "Backlog, fitted on day 50 with option f", "A backlog of deaths", "The same, with the model fitted to the outbreak.",
    "backlog_fit_tail", "Backlog, fitted with a tail alone", "A backlog of deaths", "A tail with a constant rate and share.",
    "backlog_late", "Backlog cleared only from day 80", "A backlog of deaths", "Little of the backlog has been seen by the end.",
    "backlog_steady", "Backlog with a constant share (0.2) and rate (1/40), fitted with the backlog", "A backlog of deaths", "The exponential tail as a special case: is anything lost?",
    "backlog_none", "No backlog, fitted with the backlog", "A backlog of deaths", "Is a backlog found where there is none?")
}

#' How each scenario is simulated and fitted
#'
#' Values are near those of the fits to the outbreak: a case fatality ratio
#' of 0.48, a reporting delay of mean 7.6 and sd 5.4 days, a time from onset
#' to death of mean 9.3 and sd 5.5 days and a delay from death to its being
#' recorded of mean 3 and sd 2.5 days.
#'
#' @param scenario the name of a scenario
#' @return a named list of what is simulated ('n_days'; 'cases_mean'; the
#' functions of onset day 'Rt', 'cfr', 'reporting', 'recording' (the delay
#' from death to its being recorded), 'fraction' (counted on their day of
#' death) and 'triggered' (reported when their death is recorded);
#' 'onset_to_death'; 'fatal_ratio'; 'recording_tail'; 'wrong';
#' 'first_report'; 'correction') and of how the model is fitted
#' ('fit_onset_to_death', NULL for the earlier model with a free delay from
#' onset; 'fit_dated', TRUE if the fraction is estimated, FALSE if no cases
#' are taken to be counted on their day of death, or a value at which the
#' fraction is held; 'fit_triggered';
#' 'fit_tail'; 'fit_fatal_delay')
misdated_scenario_settings <- function(scenario) {
  f_constant <- function(value) function(t) value + 0 * t
  f_step <- function(day, before, after) function(t) ifelse(t < day, before, after)
  f_delay <- function(mean, sd) function(t) list(mean = mean + 0 * t, sd = sd + 0 * t)
  f_delay_step <- function(day, before, after)
    function(t) list(mean = ifelse(t < day, before[1], after[1]),
                     sd = ifelse(t < day, before[2], after[2]))
  onset_to_death <- list(mean = 9.3, sd = 5.5)
  defaults <- list(
    n_days = 60, cases_mean = 40, Rt = f_constant(1), cfr = f_constant(0.48),
    reporting = f_delay(7.6, 5.4), recording = f_delay(3, 2.5),
    fraction = f_constant(0.3), triggered = f_constant(0.5),
    onset_to_death = onset_to_death, fatal_ratio = 1, recording_tail = NULL,
    recording_backlog = NULL,
    wrong = NULL, first_report = 1, correction = NULL, fit_until = NULL,
    fit_onset_to_death = onset_to_death, fit_dated = TRUE, fit_triggered = TRUE,
    fit_tail = FALSE, fit_report = FALSE, fit_backlog = FALSE, fit_fatal_delay = FALSE)
  tail <- list(weight = 0.15, mean = 40)
  correction <- list(time_reported = 45, onset_times = 1:20, wrong = 0.08,
                     missing = 0.03, misdated = 0.1)
  # a backlog much as the outbreak's reports suggest: 90 onset days, the first
  # report on day 40, a share which falls with onset day and a backlog
  # cleared mostly in a period of reconciliation (rate for each day 1 to 90)
  f_rate <- function(...) {
    pieces <- list(...)
    rate <- rep(NA_real_, 90)
    for(piece in pieces) rate[piece$days] <- piece$rate
    rate
  }
  backlog_days <- list(n_days = 90, first_report = 40)
  backlog <- c(backlog_days, list(
    recording_backlog = list(
      share = function(t) pmin(0.4, pmax(0.1, 0.4 - 0.3 * (t - 30) / 30)),
      rate = f_rate(list(days = 1:50, rate = 0.003), list(days = 51:75, rate = 0.05),
                    list(days = 76:90, rate = 0.015)))))
  changes <- list(
    base = list(),
    tau_0 = list(triggered = f_constant(0)),
    tau_25 = list(triggered = f_constant(0.25)),
    tau_75 = list(triggered = f_constant(0.75)),
    tau_100 = list(triggered = f_constant(1)),
    fraction_0 = list(fraction = f_constant(0)),
    fraction_10 = list(fraction = f_constant(0.1)),
    fraction_50 = list(fraction = f_constant(0.5)),
    fit_no_triggered = list(fit_triggered = FALSE),
    fit_fraction_low = list(fit_dated = 0.1),
    fit_old = list(fit_onset_to_death = NULL, fit_dated = FALSE),
    recording_fast = list(recording = f_delay(1.5, 1.2)),
    recording_slow = list(recording = f_delay(6, 5)),
    cfr_low = list(cfr = f_constant(0.1)),
    few_cases = list(cases_mean = 8),
    cfr_fall = list(cfr = f_step(33, 0.5, 0.25)),
    recording_change = list(recording = f_delay_step(31, c(8, 6), c(3, 2.5))),
    cfr_recording_together = list(cfr = f_step(31, 0.5, 0.25),
                                  recording = f_delay_step(31, c(8, 6), c(3, 2.5))),
    fraction_change = list(fraction = f_step(31, 0.1, 0.5)),
    tau_change = list(triggered = f_step(31, 0.2, 0.8)),
    otd_sd_low = list(fit_onset_to_death = list(mean = 9.3, sd = 4.5)),
    otd_sd_high = list(fit_onset_to_death = list(mean = 9.3, sd = 8)),
    otd_mean_high = list(fit_onset_to_death = list(mean = 12, sd = 7)),
    sooner = list(fatal_ratio = 0.5, triggered = f_constant(0)),
    tail = list(recording_tail = tail, fit_tail = TRUE),
    tail_ignored = list(recording_tail = tail),
    wrong = list(wrong = list(eta = 0.03, rho = 0.3, delta = 0.4)),
    early = list(first_report = 25),
    corrected_dropped = list(first_report = 25, correction = correction),
    backlog = c(backlog, list(fit_backlog = TRUE)),
    backlog_fit_f = c(backlog, list(fit_tail = TRUE, fit_report = TRUE)),
    backlog_mid = c(backlog, list(fit_backlog = TRUE, fit_until = 63)),
    backlog_mid_fit_f = c(backlog, list(fit_tail = TRUE, fit_report = TRUE, fit_until = 63)),
    backlog_before = c(backlog, list(fit_backlog = TRUE, fit_until = 50)),
    backlog_before_fit_f = c(backlog, list(fit_tail = TRUE, fit_report = TRUE, fit_until = 50)),
    backlog_fit_tail = c(backlog, list(fit_tail = TRUE)),
    backlog_late = c(backlog_days, list(
      recording_backlog = list(
        share = backlog$recording_backlog$share,
        rate = f_rate(list(days = 1:79, rate = 0.003), list(days = 80:90, rate = 0.05))),
      fit_backlog = TRUE)),
    backlog_steady = c(backlog_days, list(
      recording_backlog = list(share = f_constant(0.2), rate = rep(1 / 40, 90)),
      fit_backlog = TRUE)),
    backlog_none = c(backlog_days, list(fit_backlog = TRUE)))
  if(!scenario %in% names(changes))
    stop(paste0("Unknown scenario: ", scenario, "."))
  out <- defaults
  for(name in names(changes[[scenario]]))
    out[name] <- list(changes[[scenario]][[name]])
  out
}

#' Simulates an outbreak and the reports of its cases and deaths
#'
#' Replicates differ in the outbreak; scenarios with the same transmission
#' share the outbreak of a replicate.
#'
#' @param scenario the name of a scenario
#' @param replicate the number of the replicate, which sets the seed
#' @return a named list of 'snapshots' and 'truth' (see
#' incidenceinflation::simulate_cases_deaths), 'cases_before', 'serial',
#' 'n_days', 'scenario', 'replicate', 'settings' and 'truth_by_day' (a tibble
#' of the true values for each onset day)
simulate_misdated_dataset <- function(scenario, replicate) {
  settings <- misdated_scenario_settings(scenario)
  n_days <- settings$n_days
  set.seed(replicate)
  serial <- list(mean = 5, sd = 3)
  cases_all <- incidenceinflation::true_cases(
    n_days + 40, function(t) settings$Rt(t - 40), kappa = 1000, serial,
    initial_parameters = list(mean = settings$cases_mean, length = 10))
  days <- seq_len(n_days)
  reporting <- settings$reporting(days)
  recording <- settings$recording(days)
  fraction <- settings$fraction(days)
  triggered <- settings$triggered(days)
  sim <- incidenceinflation::simulate_cases_deaths(
    cases_all[41:(n_days + 40)], settings$first_report:n_days, reporting,
    settings$cfr(days), recording,
    fatal_reporting_parameters = if(settings$fatal_ratio != 1)
      list(mean = reporting$mean * settings$fatal_ratio,
           sd = reporting$sd * settings$fatal_ratio),
    dated_by_death = if(any(fraction > 0)) list(fraction = fraction),
    wrong = if(!is.null(settings$wrong) && settings$wrong$eta > 0) settings$wrong,
    correction = settings$correction, triggered = triggered,
    onset_to_death = settings$onset_to_death,
    recording_tail = settings$recording_tail,
    recording_backlog = if(!is.null(settings$recording_backlog))
      list(share = settings$recording_backlog$share(days),
           rate = settings$recording_backlog$rate))
  if(!is.null(settings$fit_until)) {
    keep <- seq_len(settings$fit_until)
    sim$snapshots <- dplyr::filter(sim$snapshots, .data$time_reported <= settings$fit_until,
                                   .data$time_onset <= settings$fit_until)
    sim$truth <- sim$truth[keep, ]
    days <- keep
    reporting <- lapply(reporting, function(x) x[keep])
    recording <- lapply(recording, function(x) x[keep])
    fraction <- fraction[keep]
    triggered <- triggered[keep]
    n_days <- settings$fit_until
  }
  c(sim, list(
    cases_before = cases_all[1:40], serial = serial, n_days = n_days,
    scenario = scenario, replicate = replicate, settings = settings,
    truth_by_day = dplyr::tibble(
      time_onset = days,
      Rt = settings$Rt(days),
      cfr = settings$cfr(days),
      reporting_mean = reporting$mean,
      recording_mean = recording$mean,
      fraction = fraction,
      triggered = triggered,
      cases_onset = sim$truth$cases_onset,
      deaths_onset = sim$truth$deaths_onset,
      cases_recorded = sim$truth$cases_true,
      deaths_recorded = sim$truth$deaths_true,
      backlog_share = if(!is.null(settings$recording_backlog))
        settings$recording_backlog$share(days) else 0)))
}

#' Fits the joint model of cases and deaths to a simulated dataset
#'
#' Changes in Rt, in both delays and in the case fatality ratio, wrong
#' records and effects of the day of the week are fitted whatever the
#' scenario. Chains start near one another, at plausible values.
#'
#' @param dataset as returned by simulate_misdated_dataset()
#' @param chain the number of the chain, which sets its starting values
#' @param niterations the number of iterations, the first half of which are
#' discarded
#' @param progress_dir the folder to which progress is written
#' @return a named list of the draws kept, with 'scenario', 'replicate',
#' 'chain', 'minutes' and 'error' (NULL unless the fit failed)
fit_misdated_chain <- function(dataset, chain, niterations,
                               progress_dir = "outputs/misdated_simulation/progress") {
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(100 * dataset$replicate + chain)
  options <- dataset$settings
  snapshots <- dataset$snapshots
  # the reports made before a report which corrected the records of some
  # onset days are left out for those days
  if(!is.null(options$correction))
    snapshots <- incidenceinflation::split_corrected_reports(
      snapshots, options$correction$time_reported,
      options$correction$onset_times)$corrected
  largest <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- dataset$n_days - largest$time_onset
  k <- (chain - 1) %% 3 + 1
  initial_cases <- largest %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + c(2, 1.5, 2.5)[k] * exp(-days_before_end / 4)) +
        5 * (days_before_end < 5)))
  f_largest_fall <- function(column) {
    falls <- snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
      dplyr::summarise(fall = max(c(0, -diff(.data[[column]]))))
    max(falls$fall)
  }
  max_erroneous <- max(2, f_largest_fall("cases_reported") + 1,
                       f_largest_fall("deaths_reported") + 1)
  priors <- list(
    Rt = list(shape = 1, rate = 1),
    reporting = list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5),
    max_cases = ceiling(4 * max(initial_cases$cases_true) + 50),
    Rt_changepoints = list(),
    reporting_changepoints = list(min_length = 14, n_partition_moves = 20),
    revisions = list(eta_mu = 0.01, eta_sigma = 0.02, rho_alpha = 2, rho_beta = 4),
    max_erroneous = max_erroneous)
  is_new <- !is.null(options$fit_onset_to_death)
  settings <- list(
    initial_cfr = c(0.45, 0.4, 0.5)[k],
    delay_changepoints = list(min_length = 14, n_partition_moves = 20),
    fatal_delay = if(options$fit_fatal_delay) list() else FALSE,
    triggered = if(options$fit_triggered) list(initial = c(0.5, 0.4, 0.6)[k]) else FALSE)
  if(is_new) {
    settings$onset_to_death <- options$fit_onset_to_death
    settings$initial_delay <- list(list(mean = 3, sd = 2.5), list(mean = 4, sd = 3),
                                   list(mean = 2.5, sd = 2))[[k]]
    if(isTRUE(options$fit_dated))
      settings$dated_by_death <- list(
        fraction = list(alpha = 1, beta = 1, initial = c(0.25, 0.15, 0.35)[k]))
    else if(is.numeric(options$fit_dated))
      settings$dated_by_death <- list(fraction = options$fit_dated)
    if(options$fit_tail)
      settings$recording_tail <- list()
    if(options$fit_report)
      settings$recording_report <- list(tail_only = TRUE)
    # fit_backlog: TRUE, or a list of settings of the backlog
    if(!isFALSE(options$fit_backlog))
      settings$recording_backlog <- utils::modifyList(
        list(initial_share = c(0.2, 0.15, 0.3)[k],
             initial_rate = c(1 / 60, 1 / 30, 1 / 100)[k]),
        if(is.list(options$fit_backlog)) options$fit_backlog else list())
  } else {
    settings$initial_delay <- list(list(mean = 12, sd = 9), list(mean = 14, sd = 10),
                                   list(mean = 10, sd = 8))[[k]]
  }

  time_start <- Sys.time()
  fit <- tryCatch(
    incidenceinflation::mcmc_single(
      niterations = niterations,
      snapshot_with_Rt_index_df = snapshots %>%
        dplyr::select("time_onset", "time_reported", "cases_reported") %>%
        dplyr::mutate(Rt_index = 1),
      priors = priors,
      serial_parameters = dataset$serial,
      initial_cases_true = initial_cases,
      initial_reporting_parameters = list(
        list(mean = 7.5, sd = 5.5), list(mean = 9, sd = 6),
        list(mean = 6, sd = 4.5))[[k]],
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      cases_before = dataset$cases_before,
      n_parameter_steps = 3,
      initial_revision_parameters = list(eta = 0.01, rho = 0.3, weekday = TRUE,
                                         weekday_first = 1),
      progress_file = file.path(progress_dir, sprintf(
        "%s_%d_%d.txt", dataset$scenario, dataset$replicate, chain)),
      progress_every = 10,
      deaths = list(snapshot = snapshots %>%
                      dplyr::select("time_onset", "time_reported", "deaths_reported"),
                    settings = settings)),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(scenario = dataset$scenario, replicate = dataset$replicate,
              chain = chain, niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              error = fit$error)
  warmup <- niterations / 2
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "deaths", "deaths_parameters", "revisions")))
    out[[name]] <- fit[[name]] %>%
    dplyr::filter(.data$iteration > warmup) %>%
    dplyr::mutate(chain = chain)
  out
}

#' Measures of how well the fits of one dataset recover the simulated truth
#'
#' For the fraction counted on their day of death and the share reported when
#' the death is recorded: the posterior median and 90% interval beside the
#' truth (the mean over onset days where it changes). For the case fatality
#' ratio, the delay from death to its being recorded, the reporting delay and
#' Rt: the mean absolute error of the posterior median over onset days and
#' the share of onset days on which the truth is inside the 90% interval. For
#' the cases and the fatal cases the reports will come to count (for all
#' days and for the latest 14): the truth, the median and interval, and
#' whether the truth is inside. And the potential scale reduction factor of
#' the main quantities.
#'
#' @param dataset as returned by simulate_misdated_dataset()
#' @param fits a list of results of fit_misdated_chain(), for any datasets
#' @return a tibble with one row; if the summary fails, the error is given
summarise_misdated_fits <- function(dataset, fits) {
  out <- dplyr::tibble(scenario = dataset$scenario, replicate = dataset$replicate)
  tryCatch(
    dplyr::bind_cols(out, misdated_fit_measures(dataset, fits)),
    error = function(e) dplyr::mutate(out, chains = 0, error = conditionMessage(e)))
}

#' The measures of summarise_misdated_fits()
#'
#' @inheritParams summarise_misdated_fits
#' @return a tibble with one row
misdated_fit_measures <- function(dataset, fits) {
  fitted <- deaths_dataset_fits(dataset, fits)
  out <- dplyr::tibble(chains = fitted$n_chains, error = fitted$errors)
  if(fitted$n_chains == 0)
    return(out)
  truth <- dataset$truth_by_day
  n_days <- dataset$n_days
  is_new <- !is.null(dataset$settings$fit_onset_to_death)
  days_middle <- 5:(n_days - 5)
  days_recent <- (n_days - 13):n_days
  deaths <- fitted$draws("deaths")
  parameters <- fitted$draws("deaths_parameters")
  reporting <- fitted$draws("reporting_days")
  f_days <- function(summary, days, name) {
    rows <- summary[summary$time_onset %in% days & !is.na(summary$truth), ]
    stats::setNames(
      list(if(nrow(rows) == 0) NA_real_ else mean(abs(rows$mid - rows$truth)),
           if(nrow(rows) == 0) NA_real_ else mean(rows$is_inside)),
      paste0(name, c("_error", "_coverage")))
  }
  f_value <- function(draws, chain, value, name) {
    lo <- stats::quantile(draws, 0.05)
    hi <- stats::quantile(draws, 0.95)
    stats::setNames(
      list(value, stats::median(draws), lo, hi, value >= lo & value <= hi,
           rhat_chains(draws, chain)),
      paste0(name, c("_true", "", "_lo", "_hi", "_inside", "_rhat")))
  }
  # the totals the reports will come to count: by the day cases are counted
  # for, which is what can be compared with later reports
  cases <- fitted$draws("cases") %>%
    dplyr::left_join(deaths[, c("chain", "iteration", "time_onset", "deaths_true",
                                "deaths_recorded")],
                     by = c("chain", "iteration", "time_onset")) %>%
    dplyr::mutate(cases_recorded = .data$cases_true + .data$deaths_recorded -
                    .data$deaths_true)
  f_total <- function(df, column, days, value, name) {
    totals <- df %>%
      dplyr::filter(.data$time_onset %in% days) %>%
      dplyr::group_by(.data$chain, .data$iteration) %>%
      dplyr::summarise(value = sum(.data[[column]]), .groups = "drop")
    f_value(totals$value, totals$chain, value, name)
  }
  all_days <- seq_len(n_days)
  # the delay the model estimates is from death where the time from onset to
  # death is supplied, and from onset otherwise
  recording_truth <- if(is_new) truth$recording_mean
  else truth$recording_mean + dataset$settings$onset_to_death$mean
  # the backlog: its share for each onset day and its rate for each report
  first_report <- min(dataset$snapshots$time_reported)
  days_old <- seq_len(first_report - 1)
  backlog_measures <- list()
  if("backlog_share" %in% names(deaths)) {
    backlog_measures <- f_days(deaths_day_summary(deaths, "backlog_share",
                                                  truth$backlog_share),
                               days_middle, "share")
    rate_truth <- dataset$settings$recording_backlog$rate
    columns <- grep("^backlog_rate_[0-9]+$", names(parameters), value = TRUE)
    report_days <- as.integer(sub("backlog_rate_", "", columns))
    if(!is.null(rate_truth) && length(columns) > 0) {
      # the truth of each interval: its mean rate
      bounds <- c(0, report_days)
      truth_rate <- vapply(seq_along(report_days), function(r)
        mean(rate_truth[(bounds[r] + 1):bounds[r + 1]]), numeric(1))
      lo <- apply(log(parameters[, columns]), 2, stats::quantile, 0.05)
      mid <- apply(log(parameters[, columns]), 2, stats::median)
      hi <- apply(log(parameters[, columns]), 2, stats::quantile, 0.95)
      backlog_measures$rate_log_error <- mean(abs(mid - log(truth_rate)))
      backlog_measures$rate_coverage <- mean(log(truth_rate) >= lo & log(truth_rate) <= hi)
    }
  }
  dplyr::bind_cols(
    out,
    dplyr::tibble(minutes = fitted$minutes),
    if(length(backlog_measures) > 0) dplyr::as_tibble(backlog_measures),
    if(length(days_old) > 0) dplyr::as_tibble(
      f_total(deaths, "deaths_recorded", days_old,
              sum(truth$deaths_recorded[days_old]), "deaths_old")),
    dplyr::as_tibble(c(
      f_value(parameters$dated_fraction, parameters$chain, mean(truth$fraction),
              "fraction"),
      f_value(parameters$triggered, parameters$chain, mean(truth$triggered),
              "triggered"),
      f_total(deaths, "deaths_recorded", all_days, sum(truth$deaths_recorded),
              "deaths_all"),
      f_total(deaths, "deaths_recorded", days_recent,
              sum(truth$deaths_recorded[days_recent]), "deaths_recent"),
      f_total(cases, "cases_recorded", all_days, sum(truth$cases_recorded),
              "cases_all"),
      f_total(cases, "cases_recorded", days_recent,
              sum(truth$cases_recorded[days_recent]), "cases_recent"),
      f_days(deaths_day_summary(deaths, "cfr", truth$cfr), days_middle, "cfr"),
      f_days(deaths_day_summary(deaths, "delay_mean", recording_truth),
             days_middle, "recording"),
      f_days(deaths_day_summary(reporting, "mean", truth$reporting_mean),
             days_middle, "reporting"),
      f_days(deaths_day_summary(fitted$draws("Rt"), "Rt", truth$Rt), days_recent,
             "Rt_recent"),
      f_days(deaths_day_summary(fitted$draws("cases"), "cases_true",
                                truth$cases_onset), days_recent, "cases_onset_recent"),
      f_days(deaths_day_summary(deaths, "deaths_true", truth$deaths_onset),
             days_recent, "fatal_onset_recent"))),
    dplyr::tibble(
      deaths_shown_at_end = sum(dataset$snapshots$deaths_reported[
        dataset$snapshots$time_reported == max(dataset$snapshots$time_reported)]),
      cfr_p_change = mean(parameters$n_cfr_changes > 0),
      recording_p_change = mean(parameters$n_delay_changes > 0),
      recording_sd = stats::median(deaths$delay_sd[deaths$time_onset %in% days_middle]),
      tail_weight = if("recording_tail_weight" %in% names(parameters))
        stats::median(parameters$recording_tail_weight) else NA_real_))
}

#' The measures of each scenario, averaged over its replicates
#'
#' @param summary rows of results of summarise_misdated_fits()
#' @return a tibble with a row for each scenario, in the order of
#' misdated_scenarios(), with its group, label and the number of datasets
#' fitted. Columns ending in '_inside' are the share of datasets in which the
#' truth is inside the 90% interval.
summarise_misdated_scenarios <- function(summary) {
  scenarios <- misdated_scenarios()
  is_fitted <- !is.na(summary$chains) & summary$chains > 0
  summary[is_fitted, ] %>%
    dplyr::mutate(dplyr::across(dplyr::where(is.logical), as.numeric)) %>%
    dplyr::group_by(.data$scenario) %>%
    dplyr::summarise(
      datasets = dplyr::n(),
      dplyr::across(dplyr::where(is.numeric) & !dplyr::any_of(c("replicate", "chains")),
                    ~round(mean(., na.rm = TRUE), 3)),
      .groups = "drop") %>%
    dplyr::right_join(scenarios[, c("scenario", "group", "label")], by = "scenario") %>%
    dplyr::arrange(match(.data$scenario, scenarios$scenario)) %>%
    dplyr::relocate("group", "scenario", "label")
}

#' A summary of the scenarios to read
#'
#' @param summary as returned by summarise_misdated_scenarios()
#' @param by_dataset rows of results of summarise_misdated_fits()
#' @return lines of markdown: for each scenario the fraction counted on the
#' day of death and the share reported when the death is recorded (truth and
#' the mean of the posterior medians), the fatal cases the reports will come
#' to count (truth, estimate and the share of datasets with the truth inside
#' the 90% interval), and the worst potential scale reduction factor
misdated_summary_text <- function(summary, by_dataset) {
  f <- function(x, digits = 2) ifelse(is.na(x), "", formatC(x, format = "f", digits = digits))
  f_pair <- function(x, truth, digits = 2)
    ifelse(is.na(x), "", paste0(f(x, digits), " (", f(truth, digits), ")"))
  for(name in c("deaths_old", "deaths_old_true", "deaths_old_inside", "share_error",
                "share_coverage", "rate_log_error", "rate_coverage"))
    if(!name %in% names(summary))
      summary[[name]] <- NA_real_
  rhat <- summary %>%
    dplyr::select("scenario", dplyr::ends_with("_rhat")) %>%
    tidyr::pivot_longer(-"scenario") %>%
    dplyr::group_by(.data$scenario) %>%
    dplyr::summarise(rhat = suppressWarnings(max(.data$value, na.rm = TRUE)))
  rows <- summary %>%
    dplyr::left_join(rhat, by = "scenario") %>%
    dplyr::transmute(
      .data$group, .data$label, datasets = ifelse(is.na(.data$datasets), 0, .data$datasets),
      fraction = paste0(f(.data$fraction), " (", f(.data$fraction_true), ")"),
      fraction_inside = f(.data$fraction_inside),
      share = paste0(f(.data$triggered), " (", f(.data$triggered_true), ")"),
      deaths = paste0(f(.data$deaths_all, 0), " (", f(.data$deaths_all_true, 0), ")"),
      deaths_inside = f(.data$deaths_all_inside),
      deaths_recent = paste0(f(.data$deaths_recent, 0), " (", f(.data$deaths_recent_true, 0), ")"),
      deaths_recent_inside = f(.data$deaths_recent_inside),
      deaths_old = f_pair(.data$deaths_old, .data$deaths_old_true, 0),
      deaths_old_inside = f(.data$deaths_old_inside),
      backlog_share = paste(f(.data$share_error), f(.data$share_coverage), sep = " / "),
      backlog_rate = paste(f(.data$rate_log_error), f(.data$rate_coverage), sep = " / "),
      shown = f(.data$deaths_shown_at_end, 0),
      rhat = f(ifelse(is.finite(.data$rhat), .data$rhat, NA)),
      minutes = f(.data$minutes, 0))
  header <- c("Scenario group", "Scenario", "Datasets",
              "Fraction counted on day of death: estimate (truth)", "Truth inside 90% interval",
              "Share reported at death: estimate (truth)",
              "Fatal cases, all days: estimate (truth)", "Truth inside",
              "Fatal cases, latest 14 days: estimate (truth)", "Truth inside",
              "Fatal cases, onset before the first report: estimate (truth)", "Truth inside",
              "Backlog share: error / coverage", "Clearing rate: log error / coverage",
              "Deaths shown in the last report", "Worst R-hat", "Minutes per chain")
  errors <- by_dataset[!is.na(by_dataset$error) & by_dataset$error != "", ]
  c("# Fits to simulated data",
    "",
    "Estimates are means over datasets of the posterior medians. Fatal cases are those the reports will come to count for the days. 'Truth inside' is the share of datasets in which the true value is inside the 90% interval.",
    "",
    paste0("| ", paste(header, collapse = " | "), " |"),
    paste0("|", paste(rep("---", length(header)), collapse = "|"), "|"),
    apply(rows, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")),
    if(nrow(errors) > 0) c(
      "", "## Errors", "",
      paste0("- ", errors$scenario, ", dataset ", errors$replicate, ": ", errors$error)))
}

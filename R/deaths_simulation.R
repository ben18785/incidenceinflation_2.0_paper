# Validation of the joint model of cases and deaths (docs/bvd_deaths.tex) on
# simulated data. Each scenario is a way in which an outbreak and its reports
# are simulated and a way in which the model is fitted. Some are cases in
# which the model should do well; others are designed to cause it trouble.

#' The scenarios of the validation
#'
#' @return a tibble with a row for each scenario: its name, the label used in
#' figures, the group ("Should do well" or "Should struggle") and why
deaths_scenarios <- function() {
  dplyr::tribble(
    ~scenario, ~label, ~group, ~why,
    "base", "Nothing changes", "Should do well", "Nothing to find.",
    "cfr_fall", "CFR halves", "Should do well", "A large change with four weeks of later data.",
    "cfr_rise", "CFR doubles", "Should do well", "As CFR halves, in the other direction.",
    "cfr_low", "CFR 0.1", "Should do well", "Few deaths to inform the delay to a death being recorded.",
    "cfr_high", "CFR 0.7", "Should do well", "Most cases die.",
    "sooner", "Fatal cases reported\ntwice as fast", "Should do well", "The delay ratio for fatal cases is 0.5.",
    "later", "Fatal cases reported\nhalf as fast again", "Should do well", "The delay ratio for fatal cases is 1.5.",
    "wrong", "Wrong records", "Should do well", "Counts of cases and deaths sometimes fall.",
    "recording_change", "Deaths recorded\nmore slowly later", "Should do well", "The delay to a death being recorded rises from 12 to 20 days.",
    "reporting_change", "Cases reported\nfaster later", "Should do well", "The reporting delay falls from 8 to 5 days.",
    "Rt_fall", "Rt falls from\n1.2 to 0.8", "Should do well", "Cases rise and then fall.",
    "dated", "30% dated by death", "Should do well", "Fitted in the exact form with the right inputs.",
    "dated_approximate", "30% dated by death,\napproximate form", "Should do well", "As the scenario before, fitted in the approximate form.",
    "early", "First report on\nday 25", "Should do well", "The first 24 onset days are first seen 1 to 24 days after onset.",
    "early_cfr", "First report on day 25,\nCFR halves on day 15", "Should do well", "The change is among onset days first seen late.",
    "early_recording", "First report on day 25,\ndeaths recorded more\nslowly before day 15", "Should do well", "The delay to a death being recorded falls from 25 to 12 days.",
    "corrected", "Report of day 45 corrects\nonset days 1 to 20", "Should do well", "Fitted with the reports before the correction as a separate series.",
    "corrected_cfr", "Report of day 45 corrects\nonset days 1 to 20,\nCFR halves on day 15", "Should do well", "As the scenario before, with a change among the corrected onset days.",
    "corrected_dropped", "Report of day 45 corrects\nonset days 1 to 20,\nearlier reports of them\nleft out", "Should do well", "Less information on the delays, but nothing wrong.",
    "all", "All together", "Should do well", "CFR halves, fatal cases reported faster, wrong records and 30% dated by death.",
    "cfr_late", "CFR halves ten\ndays before the end", "Should struggle", "Few deaths of the later cases have been recorded.",
    "cfr_two", "CFR halves, then\ndoubles", "Should struggle", "Two changes, twenty days apart.",
    "cfr_gradual", "CFR falls gradually", "Should struggle", "The model has steps, not slopes.",
    "cfr_recording_together", "CFR halves as deaths\nare recorded more slowly", "Should struggle", "Both make recent deaths fewer, on the same day.",
    "few_cases", "Eight cases a day", "Should struggle", "Little information.",
    "dependent", "Death recorded only\nafter the case is reported", "Should struggle", "The two delays of a fatal case are not independent.",
    "Rt_late", "Rt rises ten days\nbefore the end", "Should struggle", "The rise is among cases few of which have been reported.",
    "dated_ignored", "30% dated by death,\nfitted as if none", "Should struggle", "The model is told nothing about them.",
    "dated_fraction_low", "30% dated by death,\nfitted with 10%", "Should struggle", "Too small a fraction is supplied.",
    "dated_fraction_high", "30% dated by death,\nfitted with 50%", "Should struggle", "Too large a fraction is supplied.",
    "dated_lag_wrong", "30% dated by death,\nfitted with too long\na time to death", "Should struggle", "A time from onset to death of mean 12 days is supplied; it is 7.",
    "dated_delay_wrong", "30% dated by death,\nfitted as reported\nlike other fatal cases", "Should struggle", "They are reported much sooner than the model is told.")
}

#' How each scenario is simulated and fitted
#'
#' @param scenario the name of a scenario
#' @return a named list of: 'n_days'; 'cases_mean' (cases a day at the start);
#' functions of onset day 'Rt', 'cfr', 'reporting' and 'recording' (the last
#' two returning a list of the mean and sd of the delay); 'fatal_ratio' (the
#' ratio of the reporting delay of fatal cases to that of others);
#' 'death_from', 'dated' and 'wrong' (as the arguments of
#' incidenceinflation::simulate_cases_deaths); and 'fit_dated' (what the model
#' is told about fatal cases dated by death: NULL for nothing); 'first_report'
#' (the day of the first report; there is one each day from then);
#' 'correction' (NULL, or a report which corrects the records of some onset
#' days, as the argument of simulate_cases_deaths); and 'fit_uncorrected'
#' (whether the reports made before such a correction, of the onset days
#' corrected, are fitted as a separate series or left out)
deaths_scenario_settings <- function(scenario) {
  f_step <- function(day, before, after) function(t) ifelse(t < day, before, after)
  f_delay <- function(mean, sd) function(t) list(mean = mean + 0 * t, sd = sd + 0 * t)
  f_delay_step <- function(day, before, after)
    function(t) list(mean = ifelse(t < day, before[1], after[1]),
                     sd = ifelse(t < day, before[2], after[2]))
  dated <- list(fraction = 0.3, mean = 7, sd = 4, reporting = list(mean = 2, sd = 1.5))
  f_fit <- function(changes = list(), exact = TRUE) {
    out <- utils::modifyList(dated, changes)
    out["reporting"] <- list(if("reporting" %in% names(changes)) changes$reporting
                             else dated$reporting)
    c(out, list(exact = exact))
  }
  wrong <- list(eta = 0.03, rho = 0.3, delta = 0.4)
  defaults <- list(
    n_days = 60, cases_mean = 40, Rt = function(t) 1 + 0 * t,
    cfr = function(t) 0.4 + 0 * t, reporting = f_delay(8, 6),
    recording = f_delay(12, 7), fatal_ratio = 1, death_from = "onset",
    dated = NULL, wrong = NULL, fit_dated = NULL, first_report = 1,
    correction = NULL, fit_uncorrected = TRUE)
  # a tenth of the cases of the first 20 onset days are recorded for a wrong
  # day until the report of day 45, which also removes records which should
  # not be there (8 for every 100 cases) and adds cases which were missing
  correction <- list(time_reported = 45, onset_times = 1:20, wrong = 0.08,
                     missing = 0.03, misdated = 0.1)
  changes <- list(
    early = list(first_report = 25),
    early_cfr = list(first_report = 25, cfr = f_step(15, 0.6, 0.3)),
    early_recording = list(first_report = 25,
                           recording = f_delay_step(15, c(25, 12), c(12, 7))),
    corrected = list(first_report = 25, correction = correction),
    corrected_cfr = list(first_report = 25, correction = correction,
                         cfr = f_step(15, 0.6, 0.3)),
    corrected_dropped = list(first_report = 25, correction = correction,
                             fit_uncorrected = FALSE),
    base = list(),
    cfr_fall = list(cfr = f_step(33, 0.5, 0.25)),
    cfr_rise = list(cfr = f_step(33, 0.25, 0.5)),
    cfr_low = list(cfr = function(t) 0.1 + 0 * t),
    cfr_high = list(cfr = function(t) 0.7 + 0 * t),
    sooner = list(fatal_ratio = 0.5),
    later = list(fatal_ratio = 1.5),
    wrong = list(wrong = wrong),
    recording_change = list(recording = f_delay_step(31, c(12, 7), c(20, 10))),
    reporting_change = list(reporting = f_delay_step(31, c(8, 6), c(5, 4))),
    Rt_fall = list(Rt = f_step(31, 1.2, 0.8), cases_mean = 20),
    dated = list(dated = dated, fit_dated = f_fit()),
    dated_approximate = list(dated = dated, fit_dated = f_fit(exact = FALSE)),
    all = list(cfr = f_step(33, 0.5, 0.25), fatal_ratio = 0.5, wrong = wrong,
               dated = dated, fit_dated = f_fit()),
    cfr_late = list(cfr = f_step(51, 0.5, 0.25)),
    cfr_two = list(cfr = function(t) ifelse(t < 21, 0.5, ifelse(t < 41, 0.25, 0.5))),
    cfr_gradual = list(cfr = function(t) 0.5 - 0.25 * pmin(pmax((t - 15) / 30, 0), 1)),
    cfr_recording_together = list(cfr = f_step(33, 0.5, 0.25),
                                  recording = f_delay_step(33, c(12, 7), c(20, 10))),
    few_cases = list(cases_mean = 8),
    dependent = list(death_from = "report", recording = f_delay(6, 5)),
    Rt_late = list(Rt = f_step(51, 1, 1.5)),
    dated_ignored = list(dated = dated),
    dated_fraction_low = list(dated = dated, fit_dated = f_fit(list(fraction = 0.1))),
    dated_fraction_high = list(dated = dated, fit_dated = f_fit(list(fraction = 0.5))),
    dated_lag_wrong = list(dated = dated, fit_dated = f_fit(list(mean = 12, sd = 6))),
    dated_delay_wrong = list(dated = dated, fit_dated = f_fit(list(reporting = NULL))))
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
#' of the true values for each onset day: Rt, cfr, the means of the reporting
#' delay of other and of fatal cases, the mean and sd of the delay to a death
#' being recorded, and the cases and fatal cases by true day of onset; the
#' delay to a death being recorded is missing where it does not run from
#' onset)
simulate_deaths_dataset <- function(scenario, replicate) {
  settings <- deaths_scenario_settings(scenario)
  n_days <- settings$n_days
  set.seed(replicate)
  serial <- list(mean = 5, sd = 3)
  cases_all <- incidenceinflation::true_cases(
    n_days + 40, function(t) settings$Rt(t - 40), kappa = 1000, serial,
    initial_parameters = list(mean = settings$cases_mean, length = 10))
  days <- seq_len(n_days)
  reporting <- settings$reporting(days)
  recording <- settings$recording(days)
  sim <- incidenceinflation::simulate_cases_deaths(
    cases_all[41:(n_days + 40)], settings$first_report:n_days, reporting,
    settings$cfr(days), recording,
    fatal_reporting_parameters = if(settings$fatal_ratio != 1)
      list(mean = reporting$mean * settings$fatal_ratio,
           sd = reporting$sd * settings$fatal_ratio),
    death_from = settings$death_from,
    dated_by_death = settings$dated, wrong = settings$wrong,
    correction = settings$correction)
  is_from_onset <- settings$death_from == "onset"
  c(sim, list(
    cases_before = cases_all[1:40], serial = serial, n_days = n_days,
    scenario = scenario, replicate = replicate, settings = settings,
    truth_by_day = dplyr::tibble(
      time_onset = days,
      Rt = settings$Rt(days),
      cfr = settings$cfr(days),
      reporting_mean = reporting$mean,
      reporting_fatal_mean = reporting$mean * settings$fatal_ratio,
      recording_mean = if(is_from_onset) recording$mean else NA_real_,
      recording_sd = if(is_from_onset) recording$sd else NA_real_,
      cases_onset = sim$truth$cases_onset,
      deaths_onset = sim$truth$deaths_onset)))
}

#' Fits the joint model of cases and deaths to a simulated dataset
#'
#' The whole model is fitted whatever the scenario: changes in Rt, in both
#' delays and in the case fatality ratio; wrong records; effects of the day
#' of the week; and a delay for fatal cases which can differ from that of
#' others. Progress is written to a file as the chain runs.
#'
#' @param dataset as returned by simulate_deaths_dataset()
#' @param chain the number of the chain, which sets its starting values
#' @param niterations the number of iterations, the first half of which are
#' discarded
#' @param progress_dir the folder to which progress is written
#' @return a named list of the draws kept, with 'scenario', 'replicate',
#' 'chain', 'minutes', 'max_erroneous' and 'error' (NULL unless the fit failed)
fit_deaths_chain <- function(dataset, chain, niterations,
                             progress_dir = "outputs/deaths_simulation/progress") {
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(100 * dataset$replicate + chain)
  # reports made before a report which corrected the records of some onset
  # days are a separate series for those days, or are left out
  snapshots <- dataset$snapshots
  uncorrected <- NULL
  correction <- dataset$settings$correction
  if(!is.null(correction)) {
    parts <- incidenceinflation::split_corrected_reports(
      snapshots, correction$time_reported, correction$onset_times)
    snapshots <- parts$corrected
    if(dataset$settings$fit_uncorrected)
      uncorrected <- parts$uncorrected
  }
  largest <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- dataset$n_days - largest$time_onset
  inflation <- c(2, 1, 3.5)[(chain - 1) %% 3 + 1]
  initial_cases <- largest %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + inflation * exp(-days_before_end / 4)) +
        5 * (days_before_end < 5)))
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
  settings <- list(
    initial_cfr = c(0.5, 0.25, 0.7)[(chain - 1) %% 3 + 1],
    initial_delay = list(list(mean = 14, sd = 8), list(mean = 8, sd = 5),
                         list(mean = 20, sd = 10))[[(chain - 1) %% 3 + 1]],
    delay_changepoints = list(min_length = 14, n_partition_moves = 20))
  # what the model is told about fatal cases dated by death, which need not
  # be what was simulated
  settings["dated_by_death"] <- list(dataset$settings$fit_dated)

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
        list(mean = 7, sd = 4), list(mean = 11, sd = 7),
        list(mean = 4, sd = 2.5))[[(chain - 1) %% 3 + 1]],
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
      deaths = c(list(snapshot = snapshots %>%
                        dplyr::select("time_onset", "time_reported", "deaths_reported"),
                      settings = settings),
                 if(!is.null(uncorrected)) list(uncorrected = uncorrected))),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(scenario = dataset$scenario, replicate = dataset$replicate,
              chain = chain, niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, error = fit$error)
  warmup <- niterations / 2
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "deaths", "deaths_parameters",
    "Rt_changepoints", "reporting_changepoints", "revisions", "reporting_effects",
    "deaths_uncorrected")))
    out[[name]] <- fit[[name]] %>%
    dplyr::filter(.data$iteration > warmup) %>%
    dplyr::mutate(chain = chain)
  out
}

#' The fits of one dataset, with the draws of their chains bound together
#'
#' @param dataset as returned by simulate_deaths_dataset()
#' @param fits a list of results of fit_deaths_chain(), for any datasets
#' @return a named list of 'n_chains', 'minutes', 'errors' and a function
#' 'draws' of the name of a set of draws
deaths_dataset_fits <- function(dataset, fits) {
  fits <- purrr::keep(fits, ~.$scenario == dataset$scenario &
                        .$replicate == dataset$replicate)
  errors <- unlist(purrr::map(fits, "error"))
  fits <- purrr::keep(fits, ~is.null(.$error))
  list(n_chains = length(fits),
       minutes = mean(purrr::map_dbl(fits, "minutes")),
       errors = paste(errors, collapse = "; "),
       draws = function(name) purrr::map_dfr(fits, name))
}

#' Potential scale reduction factor of a quantity sampled by several chains
#'
#' @param x the draws
#' @param chain the chain of each draw
#' @return the factor, or NA with a single chain or no variation
rhat_chains <- function(x, chain) {
  if(length(unique(chain)) < 2)
    return(NA_real_)
  means <- tapply(x, chain, mean)
  variances <- tapply(x, chain, stats::var)
  n <- min(table(chain))
  within <- mean(variances)
  if(within == 0)
    return(NA_real_)
  sqrt(((n - 1) / n * within + stats::var(means)) / within)
}

#' Posterior median and 90% interval of a quantity for each onset day,
#' beside its true value
#'
#' @param draws a tibble with columns time_onset and the quantity
#' @param column the name of the quantity
#' @param truth its true value on each onset day
#' @return a tibble with a row for each onset day: time_onset, lo, mid, hi,
#' truth and is_inside
deaths_day_summary <- function(draws, column, truth) {
  draws %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(lo = stats::quantile(.data[[column]], 0.05),
                     mid = stats::median(.data[[column]]),
                     hi = stats::quantile(.data[[column]], 0.95)) %>%
    dplyr::mutate(truth = truth[.data$time_onset],
                  is_inside = .data$truth >= .data$lo & .data$truth <= .data$hi)
}

#' Measures of how well the fits of one dataset recover the simulated truth
#'
#' For each of the case fatality ratio, the two delays and Rt: the mean
#' absolute error of the posterior median and the share of onset days on
#' which the true value is inside the 90% interval. For cases and fatal
#' cases by day of onset: the same over the latest 14 days and over earlier
#' days. The first and last few onset days are left out for the quantities
#' which are constant within segments.
#'
#' @inheritParams deaths_dataset_fits
#' @return a tibble with one row; if the summary fails, the error is given
summarise_deaths_fits <- function(dataset, fits) {
  out <- dplyr::tibble(scenario = dataset$scenario, replicate = dataset$replicate)
  tryCatch(
    dplyr::bind_cols(out, deaths_fit_measures(dataset, fits)),
    error = function(e) dplyr::mutate(out, chains = 0, error = conditionMessage(e)))
}

#' The measures of summarise_deaths_fits()
#'
#' @inheritParams deaths_dataset_fits
#' @return a tibble with one row
deaths_fit_measures <- function(dataset, fits) {
  fitted <- deaths_dataset_fits(dataset, fits)
  out <- dplyr::tibble(chains = fitted$n_chains, error = fitted$errors)
  if(fitted$n_chains == 0)
    return(out)
  truth <- dataset$truth_by_day
  n_days <- dataset$n_days
  days_middle <- 5:(n_days - 5)
  days_recent <- (n_days - 13):n_days
  deaths <- fitted$draws("deaths")
  parameters <- fitted$draws("deaths_parameters")
  revisions <- fitted$draws("revisions")
  reporting <- fitted$draws("reporting_days")
  f_measures <- function(summary, days, name) {
    rows <- summary[summary$time_onset %in% days & !is.na(summary$truth), ]
    stats::setNames(
      list(if(nrow(rows) == 0) NA_real_ else mean(abs(rows$mid - rows$truth)),
           if(nrow(rows) == 0) NA_real_ else mean(rows$is_inside)),
      paste0(name, c("_error", "_coverage")))
  }
  cfr <- deaths_day_summary(deaths, "cfr", truth$cfr)
  recording <- deaths_day_summary(deaths, "delay_mean", truth$recording_mean)
  reporting_summary <- deaths_day_summary(reporting, "mean", truth$reporting_mean)
  Rt <- deaths_day_summary(fitted$draws("Rt"), "Rt", truth$Rt)
  cases <- deaths_day_summary(fitted$draws("cases"), "cases_true", truth$cases_onset)
  fatal <- deaths_day_summary(deaths, "deaths_true", truth$deaths_onset)
  f_chain_mean <- function(df, days, column) {
    df %>%
      dplyr::filter(.data$time_onset %in% days) %>%
      dplyr::group_by(.data$iteration, .data$chain) %>%
      dplyr::summarise(value = mean(.data[[column]]), .groups = "drop")
  }
  draws_cfr <- f_chain_mean(deaths, 40:55, "cfr")
  draws_recording <- f_chain_mean(deaths, 40:55, "delay_mean")
  draws_reporting <- f_chain_mean(reporting, 20:50, "mean")
  true_ratio <- truth$reporting_fatal_mean[1] / truth$reporting_mean[1]
  n_true_changes <- sum(diff(truth$cfr) != 0)
  dplyr::bind_cols(
    out,
    dplyr::tibble(minutes = fitted$minutes),
    dplyr::as_tibble(c(
      f_measures(cfr, days_middle, "cfr"),
      f_measures(recording, days_middle, "recording"),
      f_measures(reporting_summary, days_middle, "reporting"),
      f_measures(Rt, days_recent, "Rt_recent"),
      f_measures(Rt, 5:(n_days - 14), "Rt_earlier"),
      f_measures(cases, days_recent, "cases_recent"),
      f_measures(cases, 1:(n_days - 14), "cases_earlier"),
      f_measures(fatal, days_recent, "fatal_recent"),
      f_measures(fatal, 1:(n_days - 14), "fatal_earlier"))),
    dplyr::tibble(
      cases_mean = mean(truth$cases_onset),
      cfr_changes_true = n_true_changes,
      cfr_changes_median = stats::median(parameters$n_cfr_changes),
      cfr_p_change = mean(parameters$n_cfr_changes > 0),
      cfr_p_right_number = mean(parameters$n_cfr_changes == n_true_changes),
      recording_p_change = mean(parameters$n_delay_changes > 0),
      fatal_ratio_true = true_ratio,
      fatal_ratio = stats::median(parameters$fatal_delay_ratio),
      fatal_ratio_lo = stats::quantile(parameters$fatal_delay_ratio, 0.05),
      fatal_ratio_hi = stats::quantile(parameters$fatal_delay_ratio, 0.95),
      fatal_ratio_p_one = mean(parameters$fatal_delay_ratio == 1),
      eta = stats::median(revisions$eta),
      rho = stats::median(revisions$rho),
      wrong_dead = stats::median(parameters$wrong_dead),
      dated_share = sum(deaths$dated_by_death) / sum(deaths$deaths_recorded),
      dated_share_true = sum(dataset$truth$n_dated_by_death) /
        sum(dataset$truth$deaths_true),
      rhat_cfr = rhat_chains(draws_cfr$value, draws_cfr$chain),
      rhat_recording = rhat_chains(draws_recording$value, draws_recording$chain),
      rhat_reporting = rhat_chains(draws_reporting$value, draws_reporting$chain)))
}

#' Whether the true cases of each onset day are inside the 90% interval
#'
#' @inheritParams deaths_dataset_fits
#' @return a tibble with a row for each onset day: scenario, replicate,
#' time_onset, days_before_end, truth (cases by true day of onset), lo, mid,
#' hi and is_inside; NULL if no chain was fitted
deaths_cases_coverage <- function(dataset, fits) {
  fitted <- deaths_dataset_fits(dataset, fits)
  if(fitted$n_chains == 0)
    return(NULL)
  deaths_day_summary(fitted$draws("cases"), "cases_true",
                     dataset$truth_by_day$cases_onset) %>%
    dplyr::mutate(scenario = dataset$scenario, replicate = dataset$replicate,
                  days_before_end = dataset$n_days - .data$time_onset) %>%
    dplyr::relocate("scenario", "replicate")
}

#' Coverage of the true cases by how long before the end their onset was
#'
#' @param coverage rows of results of deaths_cases_coverage()
#' @return a tibble with a row for each scenario and band of days before the
#' end: the number of onset days (over all replicates), the share of them on
#' which the truth is inside the 90% interval, the share on which the interval
#' has no width, and the mean width of the interval
summarise_deaths_coverage <- function(coverage) {
  coverage %>%
    dplyr::mutate(band = cut(.data$days_before_end, c(-1, 13, 27, Inf),
                             labels = c("0-13", "14-27", "28 or more"))) %>%
    dplyr::group_by(.data$scenario, days_before_end = .data$band) %>%
    dplyr::summarise(n_days = dplyr::n(),
                     coverage = round(mean(.data$is_inside), 2),
                     no_width = round(mean(.data$lo == .data$hi), 2),
                     mean_width = round(mean(.data$hi - .data$lo), 1),
                     .groups = "drop")
}

#' The measures of each scenario, averaged over its replicates
#'
#' @param summary rows of results of summarise_deaths_fits()
#' @return a tibble with a row for each scenario, in the order of
#' deaths_scenarios(), with its group and the number of datasets fitted
summarise_deaths_scenarios <- function(summary) {
  scenarios <- deaths_scenarios()
  is_fitted <- !is.na(summary$chains) & summary$chains > 0
  summary[is_fitted, ] %>%
    dplyr::group_by(.data$scenario) %>%
    dplyr::summarise(
      datasets = dplyr::n(),
      dplyr::across(dplyr::where(is.numeric) & !dplyr::any_of(c("replicate", "chains")),
                    ~round(mean(., na.rm = TRUE), 3)),
      .groups = "drop") %>%
    dplyr::right_join(scenarios[, c("scenario", "group")], by = "scenario") %>%
    dplyr::arrange(match(.data$scenario, scenarios$scenario)) %>%
    dplyr::relocate("group", "scenario")
}

#' The main measures of every dataset, by scenario
#'
#' Each point is one simulated dataset. Coverage is the share of onset days on
#' which the true value is inside the 90% interval, which should be about 0.9
#' (the dashed line).
#'
#' @param summary rows of results of summarise_deaths_fits()
#' @return a ggplot
plot_deaths_validation <- function(summary) {
  scenarios <- deaths_scenarios()
  measures <- c(cfr_coverage = "Case fatality ratio:\ncoverage",
                cfr_error = "Case fatality ratio:\nerror of median",
                recording_coverage = "Delay to death\nrecorded: coverage",
                reporting_coverage = "Reporting delay:\ncoverage",
                Rt_recent_coverage = "Rt, latest 14 days:\ncoverage",
                cases_recent_coverage = "Cases, latest 14\ndays: coverage",
                cases_earlier_coverage = "Cases, earlier\ndays: coverage",
                fatal_recent_coverage = "Fatal cases, latest\n14 days: coverage")
  df <- summary %>%
    dplyr::filter(!is.na(.data$chains), .data$chains > 0) %>%
    dplyr::select("scenario", "replicate", dplyr::all_of(names(measures))) %>%
    tidyr::pivot_longer(dplyr::all_of(names(measures)), names_to = "measure") %>%
    dplyr::left_join(scenarios, by = "scenario") %>%
    dplyr::mutate(
      measure = factor(measures[.data$measure], levels = measures),
      label = factor(gsub("\n", " ", .data$label),
                     levels = rev(gsub("\n", " ", scenarios$label))),
      group = factor(.data$group, levels = c("Should do well", "Should struggle")))
  targets_df <- dplyr::tibble(
    measure = factor(measures[grepl("coverage", names(measures))], levels = measures),
    value = 0.9)
  ggplot2::ggplot(df, ggplot2::aes(.data$value, .data$label, colour = .data$group)) +
    ggplot2::geom_vline(ggplot2::aes(xintercept = .data$value), data = targets_df,
                        linetype = "dashed", colour = "grey40") +
    ggplot2::geom_point(size = 1.2, alpha = 0.7) +
    ggplot2::facet_grid(group ~ measure, scales = "free", space = "free_y") +
    ggplot2::scale_colour_manual(values = c("Should do well" = "#4C72B0",
                                            "Should struggle" = "#C44E52"),
                                 guide = "none") +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw(base_size = 8) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   strip.background = ggplot2::element_rect(fill = "grey93", colour = NA),
                   axis.text.x = ggplot2::element_text(size = 6))
}

#' The simulated truth and the estimates for a set of scenarios of one
#' replicate
#'
#' A row for each scenario and columns for cases, fatal cases, the
#' reproduction number, the mean delays and the case fatality ratio. Points
#' and dashed lines are the truth; solid lines are posterior medians and bands
#' 90% intervals; black steps are the counts in the latest report.
#'
#' @param datasets a list of results of simulate_deaths_dataset()
#' @param fits a list of results of fit_deaths_chain()
#' @param scenarios the names of the scenarios to show
#' @param replicate the replicate to show
#' @return a ggplot
plot_deaths_simulation <- function(datasets, fits, scenarios, replicate = 1) {
  labels <- stats::setNames(deaths_scenarios()$label, deaths_scenarios()$scenario)
  quantities <- c("Cases by day of onset", "Fatal cases by day of onset",
                  "Reproduction number", "Mean delay (days)", "Case fatality ratio")
  f_summary <- function(df, value, series, quantity) {
    df %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(lo = stats::quantile({{value}}, 0.05),
                       mid = stats::median({{value}}),
                       hi = stats::quantile({{value}}, 0.95), .groups = "drop") %>%
      dplyr::mutate(series = series, quantity = quantity)
  }
  estimates <- list()
  truths <- list()
  reported <- list()
  for(name in scenarios) {
    dataset <- purrr::keep(datasets, ~.$scenario == name & .$replicate == replicate)[[1]]
    fitted <- deaths_dataset_fits(dataset, fits)
    if(fitted$n_chains == 0)
      next
    truth <- dataset$truth_by_day
    delays <- fitted$draws("reporting_days") %>%
      dplyr::left_join(
        fitted$draws("deaths_parameters")[, c("iteration", "chain", "fatal_delay_ratio")],
        by = c("iteration", "chain"))
    estimates[[name]] <- dplyr::bind_rows(
      f_summary(fitted$draws("cases"), .data$cases_true, "Cases", quantities[1]),
      f_summary(fitted$draws("deaths"), .data$deaths_true, "Fatal cases", quantities[2]),
      f_summary(fitted$draws("Rt"), .data$Rt, "Reproduction number", quantities[3]),
      f_summary(delays, .data$mean, "Onset to case reported", quantities[4]),
      f_summary(delays, .data$mean * .data$fatal_delay_ratio,
                "Onset to case reported, fatal cases", quantities[4]),
      f_summary(fitted$draws("deaths"), .data$delay_mean, "Onset to death recorded",
                quantities[4]),
      f_summary(fitted$draws("deaths"), .data$cfr, "Case fatality ratio",
                quantities[5])) %>%
      dplyr::mutate(scenario = name)
    f_truth <- function(value, series, quantity)
      dplyr::tibble(time_onset = truth$time_onset, value = value, series = series,
                    quantity = quantity)
    truths[[name]] <- dplyr::bind_rows(
      f_truth(truth$cases_onset, "Cases", quantities[1]),
      f_truth(truth$deaths_onset, "Fatal cases", quantities[2]),
      f_truth(truth$Rt, "Reproduction number", quantities[3]),
      f_truth(truth$reporting_mean, "Onset to case reported", quantities[4]),
      f_truth(truth$reporting_fatal_mean, "Onset to case reported, fatal cases",
              quantities[4]),
      f_truth(truth$recording_mean, "Onset to death recorded", quantities[4]),
      f_truth(truth$cfr, "Case fatality ratio", quantities[5])) %>%
      dplyr::filter(!is.na(.data$value)) %>%
      dplyr::mutate(scenario = name)
    latest <- dataset$snapshots %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
      dplyr::ungroup()
    reported[[name]] <- dplyr::bind_rows(
      dplyr::tibble(time_onset = latest$time_onset, value = latest$cases_reported,
                    series = "Cases in the latest report", quantity = quantities[1]),
      dplyr::tibble(time_onset = latest$time_onset, value = latest$deaths_reported,
                    series = "Deaths in the latest report", quantity = quantities[2])) %>%
      dplyr::mutate(scenario = name)
  }
  scenarios <- intersect(scenarios, names(estimates))
  f_factors <- function(df) {
    df %>%
      dplyr::mutate(scenario = factor(labels[.data$scenario], levels = labels[scenarios]),
                    quantity = factor(.data$quantity, levels = quantities))
  }
  estimates <- f_factors(dplyr::bind_rows(estimates))
  truths <- f_factors(dplyr::bind_rows(truths))
  reported <- f_factors(dplyr::bind_rows(reported))
  # the counts have their own range in each scenario; the other quantities
  # have ranges which can be compared between scenarios
  fixed <- dplyr::tibble(
    quantity = factor(quantities[3:5], levels = quantities),
    lo = c(0.5, 0, 0), hi = c(1.7, 25, 0.8)) %>%
    tidyr::pivot_longer(c("lo", "hi"), values_to = "y") %>%
    dplyr::select(-"name") %>%
    tidyr::crossing(scenario = factor(labels[scenarios], levels = labels[scenarios])) %>%
    dplyr::mutate(time_onset = 1)
  zero <- tidyr::crossing(
    quantity = factor(quantities[1:2], levels = quantities),
    scenario = factor(labels[scenarios], levels = labels[scenarios])) %>%
    dplyr::mutate(time_onset = 1, y = 0)
  colours <- c("Cases" = "#4C72B0", "Fatal cases" = "#C44E52",
               "Reproduction number" = "#333333",
               "Onset to case reported" = "#4C72B0",
               "Onset to case reported, fatal cases" = "#DD8452",
               "Onset to death recorded" = "#C44E52", "Case fatality ratio" = "#333333",
               "Cases in the latest report" = "#111111",
               "Deaths in the latest report" = "#111111")
  is_counts <- truths$quantity %in% quantities[1:2]
  ggplot2::ggplot(estimates, ggplot2::aes(.data$time_onset)) +
    ggplot2::geom_blank(ggplot2::aes(y = .data$y), data = dplyr::bind_rows(fixed, zero)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi,
                                      fill = .data$series), alpha = 0.25) +
    ggplot2::geom_step(ggplot2::aes(y = .data$value, colour = .data$series),
                       data = reported, direction = "mid", linewidth = 0.35) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid, colour = .data$series),
                       linewidth = 0.5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$value, colour = .data$series),
                        data = truths[is_counts, ], size = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = .data$value, colour = .data$series),
                       data = truths[!is_counts, ], linetype = "dashed",
                       linewidth = 0.4) +
    ggh4x::facet_grid2(scenario ~ quantity, scales = "free_y", independent = "y") +
    ggplot2::scale_colour_manual(values = colours,
                                 breaks = names(colours)[c(1, 2, 8, 9, 4, 5, 6)],
                                 name = NULL) +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2)) +
    ggplot2::labs(x = "Day of onset", y = NULL) +
    ggplot2::theme_bw(base_size = 8) +
    ggplot2::theme(legend.position = "bottom",
                   panel.grid.minor = ggplot2::element_blank(),
                   strip.text.y = ggplot2::element_text(angle = 0, hjust = 0),
                   strip.background = ggplot2::element_rect(fill = "grey93", colour = NA),
                   legend.key.width = ggplot2::unit(0.8, "cm"),
                   legend.margin = ggplot2::margin(0, 0, 0, 0))
}

#' Writes the figures of estimates against the truth, a few scenarios to a page
#'
#' @inheritParams plot_deaths_simulation
#' @param per_page the number of scenarios on each page
#' @param prefix the start of the names of the files
#' @return the paths of the files written
write_deaths_simulation_pages <- function(datasets, fits, per_page = 4,
                                          prefix = "outputs/deaths_validation_page_") {
  scenarios <- deaths_scenarios()$scenario
  pages <- split(scenarios, ceiling(seq_along(scenarios) / per_page))
  purrr::imap_chr(pages, function(names_page, page) {
    path <- paste0(prefix, page, ".png")
    plot <- tryCatch(plot_deaths_simulation(datasets, fits, names_page),
                     error = function(e) NULL)
    if(is.null(plot))
      plot <- ggplot2::ggplot() + ggplot2::labs(title = "No fits to show")
    save_plot(plot, path, 11, 1.2 + 1.9 * length(names_page))
  }) %>% unname()
}

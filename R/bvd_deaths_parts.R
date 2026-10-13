# Bundibugyo virus disease: parts of the joint model of cases and deaths
# fitted on their own, to find which part does not converge.
#
# Three models are fitted to the reports up to a date, all with the same
# treatment of the onset days before the first report and of the correcting
# report as the joint model:
#   "cases"       the reported cases alone;
#   "deaths"      the recorded deaths alone, as if they were cases: fatal
#                 cases follow their own renewal equation and are recorded
#                 after a delay from onset;
#   "fixed cases" the joint model with the true cases of each onset day held
#                 at their posterior medians from "cases".

#' The dates up to which reports are used for the fits of parts of the model
bvd_part_dates <- function() {
  as.Date(c("2026-09-15", "2026-10-01"))
}

#' Dates of the latest report used in the fits which compare forms of the
#' delay to a death being recorded
bvd_form_dates <- function() {
  as.Date(c("2026-09-05", "2026-09-15", "2026-10-01"))
}

#' First onset day of the fits which leave out the early onset days: the
#' first which the report of 6 September did not correct
bvd_form_onset_from <- function() {
  as.Date("2026-06-28")
}

#' A tight prior for the heavier tail of the delay to a death being
#' recorded: about a seventh of deaths (beta(3, 18), 2.5% chance of more
#' than 30%) with a mean delay of 50 days (sd 10)
bvd_form_tail_prior <- function() {
  list(tail_weight_alpha = 3, tail_weight_beta = 18,
       tail_mean_mu = 50, tail_mean_sigma = 10, label = "tight tail")
}

#' Settings for the changes in the delay to a death being recorded which
#' are tried on the reports to 5 September: segments of at least 7 onset
#' days, a prior which expects four changes, and both
bvd_delay_trials <- function() {
  list(list(min_length = 7, label = "7-day segments"),
       list(changes_expected = 4, label = "more changes"),
       list(min_length = 7, changes_expected = 4, label = "7-day segments, more changes"))
}

#' Settings for a delay to a death being recorded which drifts: its mean and
#' sd are constant within each week of onset and the logs of each take a
#' random-walk step from one week to the next, whose sd has a half-normal
#' prior of sd 0.25
bvd_delay_drift <- function() {
  list(drift = 7, spread_sd = 0.25, mean_step = 0.12, sd_step = 0.12,
       n_segment_steps = 2, label = "drift")
}

#' Settings for the changes in a delay as the package takes them, from those
#' given to a fit: 'changes_expected' becomes a beta(2, .) prior on the
#' chance of a change on each of n_days days with that expected number
bvd_delay_settings_given <- function(delay_settings, n_days) {
  if(is.null(delay_settings))
    return(list())
  out <- delay_settings[setdiff(names(delay_settings), c("label", "changes_expected"))]
  if(!is.null(delay_settings$changes_expected))
    out <- c(out, list(alpha = 2,
                       beta = 2 * (n_days / delay_settings$changes_expected - 1)))
  out
}

#' The number of onset days among which no change in the delay to a death
#' being recorded is allowed
#'
#' The onset days corrected by a later report are seen only from that
#' report, months after onset, and say little about the delay. The first
#' segment of the delay must run to at least min_length days after the first
#' onset day which was not corrected. Where no correction applies, the rule
#' for the reporting delay is used.
bvd_delay_first_length <- function(analysis, min_length = bvd_delay_settings()$min_length) {
  if(is.null(analysis$correction))
    return(analysis$reporting_first_length)
  length(analysis$correction$onset_times) + min_length
}

#' Deaths in the latest report used, for the onset days before the first
#' analysed (known earlier fatal cases for the renewal equation)
bvd_deaths_before <- function(snapshots, analysis) {
  known <- snapshots %>%
    dplyr::filter(.data$date_reported <= analysis$date_now) %>%
    dplyr::filter(.data$date_reported == max(.data$date_reported))
  dplyr::tibble(date = analysis$dates_before) %>%
    dplyr::left_join(dplyr::select(known, date = "date_onset", "deaths_reported"),
                     by = "date") %>%
    dplyr::mutate(deaths = dplyr::coalesce(as.numeric(.data$deaths_reported), 0)) %>%
    dplyr::pull("deaths")
}

#' Runs one chain of the model of a single series: cases or deaths
#'
#' The model is that of the cases in the joint model: wrong records, an
#' effect of the day of the week, a heavier tail of the delay, changes in the
#' delay (none among the onset days first seen late) and a negative binomial
#' renewal model. For deaths the prior for the delay is that of the delay to
#' a death being recorded in the joint model. Chains start from different
#' values. With tail FALSE the delay has no heavier tail (the fit is then
#' labelled, for example, "deaths, no tail").
#'
#' Further options, each of which adds to the label of the fit:
#' - onset_from: a date; onset days before it are left out of the fit, and
#'   their counts in the latest report used are taken as known earlier cases
#'   for the renewal equation. Times in the output remain those of the
#'   analysis.
#' - tail_prior: a named list replacing the prior of the heavier tail
#'   ('tail_weight_alpha', 'tail_weight_beta', 'tail_mean_mu',
#'   'tail_mean_sigma'), and 'label'.
#' - family: "gamma" or "lognormal", the family of the delay (the package
#'   option incidenceinflation.delay_family is set for the fit).
#' - delay_settings: a named list of settings for the changes in the delay
#'   which replace those of bvd_delay_settings(), and 'label'. An element
#'   'changes_expected' is turned into the beta prior on the chance of a
#'   change on each day which expects that many changes.
fit_bvd_single_chain <- function(analysis, snapshots_all, model, chain, niterations,
                                 n_draws = 300, tail = TRUE,
                                 serial_parameters = list(mean = 15.3, sd = 9.3),
                                 progress_dir = "outputs/bvd_deaths/progress",
                                 onset_from = NULL, tail_prior = NULL,
                                 family = "gamma", delay_settings = NULL,
                                 starts = "spread") {
  stopifnot(model %in% c("cases", "deaths"))
  old_options <- options(incidenceinflation.delay_family = family)
  on.exit(options(old_options), add = TRUE)
  label <- paste0(
    model, ifelse(tail, "", ", no tail"),
    if(!is.null(tail_prior)) paste0(", ", tail_prior$label),
    if(family != "gamma") paste0(", ", family),
    if(!is.null(delay_settings)) paste0(", ", delay_settings$label),
    if(!is.null(onset_from)) paste0(", from ", trimws(format(as.Date(onset_from), "%e %B"))))
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(1000 * chain + as.integer(analysis$date_now) %% 1000 + 7 * (model == "deaths"))
  settings <- fit_settings()
  is_deaths <- model == "deaths"
  snapshots <- analysis$snapshots %>%
    dplyr::transmute(
      .data$time_onset, .data$time_reported,
      cases_reported = if(is_deaths) .data$deaths_reported else .data$cases_reported)
  before <- if(is_deaths) bvd_deaths_before(snapshots_all, analysis)
  else analysis$cases_before
  first_length <- analysis$reporting_first_length
  weekday_first <- analysis$weekday_first
  time_shift <- 0L
  if(!is.null(onset_from)) {
    time_shift <- as.integer(
      analysis$dates$time_onset[analysis$dates$date == as.Date(onset_from)]) - 1L
    stopifnot(length(time_shift) == 1, time_shift >= 1)
    earlier <- snapshots %>%
      dplyr::filter(.data$time_onset <= time_shift) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
      dplyr::ungroup() %>%
      dplyr::arrange(.data$time_onset)
    stopifnot(identical(as.integer(earlier$time_onset), seq_len(time_shift)))
    before <- c(before, earlier$cases_reported)
    snapshots <- snapshots %>%
      dplyr::filter(.data$time_onset > time_shift) %>%
      dplyr::mutate(time_onset = .data$time_onset - time_shift,
                    time_reported = .data$time_reported - time_shift)
    first_length <- max(bvd_delay_settings()$min_length, first_length - time_shift)
    weekday_first <- (weekday_first - 1L + time_shift) %% 7L + 1L
  }
  largest_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- max(snapshots$time_onset) - largest_reported$time_onset
  start <- bvd_deaths_starts(starts, chain)
  if(chain > 3 && starts == "spread") {
    # a fourth set of starting values: a long, dispersed delay
    start$inflation <- 1.5
    start$delay <- list(mean = 30, sd = 20)
    start$reporting <- list(mean = 9, sd = 9)
    start$overdispersion <- 15
    start$tail <- list(weight = 0.15, mean = 50)
  }
  reporting_effects_prior <- list(tail_weight_alpha = 1, tail_weight_beta = 19,
                                  tail_mean_mu = 40, tail_mean_sigma = 30)
  if(!is.null(tail_prior))
    reporting_effects_prior <- utils::modifyList(
      reporting_effects_prior, tail_prior[names(tail_prior) != "label"])
  initial_cases_true <- largest_reported %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + start$inflation *
                            exp(-days_before_end / start$inflation_days)) +
        5 * (days_before_end < 5)))
  falls <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::summarise(fall = max(c(0, -diff(.data$cases_reported))))
  max_erroneous <- max(3, max(falls$fall) + 1)
  priors <- list(
    Rt = settings$priors$Rt,
    reporting = if(is_deaths) list(mean_mu = 14, mean_sigma = 10, sd_mu = 8, sd_sigma = 8)
    else list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5),
    max_cases = ceiling(4 * max(initial_cases_true$cases_true) + 50),
    overdispersion = list(mean = 20, sd = 20),
    revisions = utils::modifyList(
      settings$priors$revisions[c("eta_mu", "eta_sigma", "rho_alpha", "rho_beta")],
      list(eta_mu = 0.005, eta_sigma = 0.005)),
    max_erroneous = max_erroneous,
    reporting_effects = reporting_effects_prior,
    Rt_changepoints = list(),
    reporting_changepoints = utils::modifyList(
      c(bvd_delay_settings(), list(first_length = first_length)),
      bvd_delay_settings_given(delay_settings, dplyr::n_distinct(snapshots$time_onset))))

  time_start <- Sys.time()
  fit <- tryCatch(
    incidenceinflation::mcmc_single(
      niterations = niterations,
      snapshot_with_Rt_index_df = dplyr::mutate(snapshots, Rt_index = 1),
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = initial_cases_true,
      initial_reporting_parameters = if(is_deaths) start$delay else start$reporting,
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      initial_overdispersion = start$overdispersion,
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 8,
      initial_revision_parameters = c(
        list(eta = settings$initial_revisions$eta, rho = settings$initial_revisions$rho,
             weekday = TRUE, weekday_first = weekday_first),
        if(tail) list(tail = start$tail)),
      revision_metropolis_parameters = settings$revision_metropolis,
      cases_before = before,
      n_parameter_steps = 5,
      progress_file = file.path(progress_dir, sprintf(
        "%s_%s_%d.txt", gsub("[^a-z0-9]+", "_", tolower(sub(model, paste0(model, "_only"), label, fixed = TRUE))),
        analysis$date_now, chain)),
      progress_every = 10),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(model = label, chain = chain, onset_from = onset_from, family = family,
              analysis = analysis,
              date_now = analysis$date_now, niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, error = fit$error)
  if(!is.null(fit$error))
    return(out)
  warmup <- floor(niterations / 2)
  kept <- unique(round(seq(warmup + 1, niterations, length.out = n_draws)))
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "overdispersion", "Rt_changepoints",
    "reporting_changepoints", "revisions", "reporting_effects")))
    out[[name]] <- fit[[name]] %>%
    dplyr::filter(.data$iteration %in% kept) %>%
    dplyr::select(-dplyr::any_of("chain")) %>%
    dplyr::mutate(chain = chain) %>%
    dplyr::mutate(dplyr::across(dplyr::any_of("time_onset"), ~. + time_shift))
  out
}

#' Posterior median of the true cases of each onset day, from the chains of
#' the model of cases alone fitted to the reports up to a date
bvd_cases_median <- function(chains, date_now) {
  chains <- purrr::keep(chains, ~is.null(.$error) & .$model == "cases" &
                          .$date_now == as.Date(date_now))
  if(length(chains) == 0)
    stop("No chain of the model of cases ran for this date.")
  purrr::map_dfr(chains, "cases") %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = round(stats::median(.data$cases_true)))
}

#' Runs one chain of the joint model with the true cases held fixed
#'
#' As fit_bvd_deaths_chain with no fatal cases dated by death, from starting
#' values which differ between chains, but the true cases of each onset day
#' stay at cases_fixed (a tibble with columns time_onset and cases_true).
#' Everything else is sampled given them. The sampler starts with no wrong
#' records, so needs at least as many true cases as the most reported for
#' each onset day: where cases_fixed is below that it is raised to it, and
#' the number of cases added is returned as 'cases_raised'. If
#' delay_first_length is given, no change in the delay to a death being
#' recorded is allowed among the first delay_first_length onset days (the
#' fit is then labelled "fixed cases, delay rule").
fit_bvd_fixed_cases_chain <- function(analysis, cases_fixed, chain, niterations,
                                      n_draws = 300, delay_first_length = NULL,
                                      delay_settings = NULL, starts = "spread",
                                      deaths_prior = NULL,
                                      serial_parameters = list(mean = 15.3, sd = 9.3),
                                      progress_dir = "outputs/bvd_deaths/progress") {
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(1000 * chain + as.integer(analysis$date_now) %% 1000 + 13)
  settings <- fit_settings()
  snapshots <- analysis$snapshots
  cases_fixed <- dplyr::arrange(cases_fixed, .data$time_onset)
  stopifnot(setequal(cases_fixed$time_onset, snapshots$time_onset))
  most_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(most = max(.data$cases_reported)) %>%
    dplyr::arrange(.data$time_onset)
  cases_raised <- sum(pmax(0, most_reported$most - cases_fixed$cases_true))
  cases_fixed$cases_true <- pmax(cases_fixed$cases_true, most_reported$most)
  start <- bvd_deaths_starts(starts, chain)
  f_largest_fall <- function(column) {
    falls <- snapshots %>%
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
    max_cases = ceiling(4 * max(cases_fixed$cases_true) + 50),
    overdispersion = list(mean = 20, sd = 20),
    revisions = utils::modifyList(
      settings$priors$revisions[c("eta_mu", "eta_sigma", "rho_alpha", "rho_beta")],
      list(eta_mu = 0.005, eta_sigma = 0.005)),
    max_erroneous = max_erroneous,
    reporting_effects = list(tail_weight_alpha = 1, tail_weight_beta = 19,
                             tail_mean_mu = 40, tail_mean_sigma = 30),
    Rt_changepoints = list(),
    reporting_changepoints = c(
      bvd_delay_settings(), list(first_length = analysis$reporting_first_length)))
  deaths_settings <- list(
    initial_cfr = start$cfr, initial_delay = start$delay,
    delay_changepoints = utils::modifyList(
      c(bvd_delay_settings(),
        if(!is.null(delay_first_length)) list(first_length = delay_first_length)),
      bvd_delay_settings_given(delay_settings, dplyr::n_distinct(snapshots$time_onset))))
  # settings of the model of deaths which replace the package's (such as
  # 'delay_prior', the prior on the delay to a death being recorded)
  if(!is.null(deaths_prior))
    deaths_settings <- utils::modifyList(
      deaths_settings, deaths_prior[names(deaths_prior) != "label"])
  is_rule <- !is.null(delay_first_length)
  label <- paste0("fixed cases", ifelse(is_rule, ", delay rule", ""),
                  if(!is.null(delay_settings)) paste0(", ", delay_settings$label),
                  if(!is.null(deaths_prior)) paste0(", ", deaths_prior$label))

  time_start <- Sys.time()
  fit <- tryCatch(
    incidenceinflation::mcmc_single(
      niterations = niterations,
      snapshot_with_Rt_index_df = snapshots %>%
        dplyr::select("time_onset", "time_reported", "cases_reported") %>%
        dplyr::mutate(Rt_index = 1),
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = cases_fixed,
      initial_reporting_parameters = start$reporting,
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      initial_overdispersion = start$overdispersion,
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 8,
      initial_revision_parameters = list(
        eta = settings$initial_revisions$eta, rho = settings$initial_revisions$rho,
        weekday = TRUE, weekday_first = analysis$weekday_first,
        tail = start$tail),
      revision_metropolis_parameters = settings$revision_metropolis,
      cases_before = analysis$cases_before,
      n_parameter_steps = 5,
      progress_file = file.path(progress_dir, sprintf(
        "%s_%s_%d.txt", gsub("[^a-z0-9]+", "_", tolower(label)),
        analysis$date_now, chain)),
      progress_every = 10,
      fixed_cases = TRUE,
      deaths = list(snapshot = snapshots %>%
                      dplyr::select("time_onset", "time_reported", "deaths_reported"),
                    settings = deaths_settings)),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(model = label,
              delay_first_length = delay_first_length, variant = "none", chain = chain,
              analysis = analysis, date_now = analysis$date_now,
              niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, cases_raised = cases_raised,
              cases_total = sum(cases_fixed$cases_true), error = fit$error)
  if(!is.null(fit$error))
    return(out)
  warmup <- floor(niterations / 2)
  kept <- unique(round(seq(warmup + 1, niterations, length.out = n_draws)))
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "overdispersion", "deaths", "deaths_parameters",
    "Rt_changepoints", "reporting_changepoints", "revisions", "reporting_effects")))
    out[[name]] <- fit[[name]] %>%
    dplyr::filter(.data$iteration %in% kept) %>%
    dplyr::select(-dplyr::any_of("chain")) %>%
    dplyr::mutate(chain = chain, variant = "none")
  out
}

#' Quantities whose agreement between chains is checked, for the chains of
#' one model and date
bvd_part_monitored <- function(fits, days_recent = 14) {
  model <- sub(",.*", "", fits[[1]]$model)
  if(model == "fixed cases")
    return(bvd_deaths_monitored(fits, "none", days_recent) %>%
             dplyr::filter(!grepl("^Cases, ", .data$quantity)))
  f <- function(name) dplyr::arrange(purrr::map_dfr(fits, name),
                                     .data$chain, .data$iteration)
  cases <- f("cases")
  reporting <- f("reporting_days")
  Rt <- f("Rt")
  day_last <- max(cases$time_onset)
  day_first <- min(cases$time_onset)
  recent <- (day_last - days_recent + 1):day_last
  f_days <- function(df, column, days, fun, quantity) {
    df %>%
      dplyr::filter(.data$time_onset %in% days) %>%
      dplyr::group_by(.data$chain, .data$iteration) %>%
      dplyr::summarise(value = fun(.data[[column]]), .groups = "drop") %>%
      dplyr::mutate(quantity = quantity)
  }
  f_parameter <- function(df, column, quantity)
    dplyr::tibble(chain = df$chain, iteration = df$iteration, value = df[[column]],
                  quantity = quantity)
  what <- if(model == "deaths") "Fatal cases" else "Cases"
  delay <- if(model == "deaths") "Mean delay to death recorded"
  else "Mean delay to case reported"
  dplyr::bind_rows(
    f_days(cases, "cases_true", recent, sum, paste0(what, ", latest 14 onset days")),
    f_days(cases, "cases_true", day_first:day_last, sum, paste0(what, ", all onset days")),
    f_days(reporting, "mean", day_first, mean, paste0(delay, ", first onset day")),
    f_days(reporting, "mean", day_last, mean, paste0(delay, ", latest onset day")),
    f_days(reporting, "sd", day_last, mean,
           paste0(sub("Mean", "Sd of", delay), ", latest onset day")),
    f_days(Rt, "Rt", day_last, mean, "Reproduction number, latest onset day"),
    f_parameter(f("reporting_changepoints"), "n_changes", "Changes in the delay"),
    f_parameter(f("reporting_effects"), "tail_weight", "Share with a long delay"),
    f_parameter(f("reporting_effects"), "tail_mean", "Mean of the long delay (days)"),
    f_parameter(f("overdispersion"), "overdispersion", "Overdispersion"),
    f_parameter(f("revisions"), "eta", "Wrong records per case and report (eta)"),
    f_parameter(f("revisions"), "rho", "Removal of wrong records per report (rho)")) %>%
    dplyr::filter(!is.na(.data$value))
}

#' The chains of the parts grouped by model and date
bvd_part_groups <- function(chains) {
  chains <- purrr::keep(chains, ~is.null(.$error))
  split(chains, purrr::map_chr(chains, ~paste(.$model, .$date_now, sep = "|")))
}

#' Summary of each monitored quantity for each model and date: median, 90%
#' interval, split R-hat and the median of each chain
bvd_part_summary <- function(chains) {
  purrr::map_dfr(bvd_part_groups(chains), function(fits) {
    monitored <- bvd_part_monitored(fits)
    by_chain <- monitored %>%
      dplyr::group_by(.data$quantity, .data$chain) %>%
      dplyr::summarise(median = stats::median(.data$value), .groups = "drop") %>%
      tidyr::pivot_wider(names_from = "chain", values_from = "median",
                         names_prefix = "chain_")
    monitored %>%
      dplyr::group_by(.data$quantity) %>%
      dplyr::summarise(
        median = stats::median(.data$value),
        lo = stats::quantile(.data$value, 0.05),
        hi = stats::quantile(.data$value, 0.95),
        rhat = split_rhat(.data$value, .data$chain), .groups = "drop") %>%
      dplyr::left_join(by_chain, by = "quantity") %>%
      dplyr::mutate(model = fits[[1]]$model, date_now = fits[[1]]$date_now,
                    n_chains = length(fits), .before = 1)
  })
}

#' Which chains of the parts ran, how long they took and any errors
bvd_part_runs <- function(chains) {
  purrr::map_dfr(chains, function(fit) {
    dplyr::tibble(model = fit$model, date_now = fit$date_now, chain = fit$chain,
                  niterations = fit$niterations, minutes = fit$minutes,
                  error = if(is.null(fit$error)) "" else fit$error)
  })
}

#' Estimates by onset day from each chain: fatal cases, the delay to a death
#' being recorded and (with the cases fixed) the case fatality ratio
bvd_part_by_day <- function(chains) {
  purrr::map_dfr(bvd_part_groups(chains), function(fits) {
    model <- fits[[1]]$model
    kind <- sub(",.*", "", model)
    if(kind == "cases")
      return(NULL)
    dates <- dplyr::select(fits[[1]]$analysis$dates, "time_onset", "date")
    f <- function(name, column, quantity) {
      purrr::map_dfr(fits, name) %>%
        dplyr::group_by(.data$chain, .data$time_onset) %>%
        dplyr::summarise(mid = stats::median(.data[[column]]),
                         lo = stats::quantile(.data[[column]], 0.05),
                         hi = stats::quantile(.data[[column]], 0.95),
                         .groups = "drop") %>%
        dplyr::mutate(quantity = quantity)
    }
    out <- if(kind == "deaths") dplyr::bind_rows(
      f("cases", "cases_true", "Fatal cases by day of onset"),
      f("reporting_days", "mean", "Mean delay to death recorded (days)"))
    else dplyr::bind_rows(
      f("deaths", "deaths_true", "Fatal cases by day of onset"),
      f("deaths", "delay_mean", "Mean delay to death recorded (days)"),
      f("deaths", "cfr", "Case fatality ratio"))
    reported <- fits[[1]]$analysis$snapshots %>%
      dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
      dplyr::transmute(.data$time_onset, reported = .data$deaths_reported,
                       quantity = "Fatal cases by day of onset")
    out %>%
      dplyr::left_join(reported, by = c("time_onset", "quantity")) %>%
      dplyr::left_join(dates, by = "time_onset") %>%
      dplyr::mutate(model = model, date_now = fits[[1]]$date_now, .before = 1)
  })
}

#' Each chain's estimates by onset day, for the deaths-only and fixed-cases
#' models at each date
plot_bvd_parts <- function(by_day) {
  labels <- c(deaths = "Deaths alone", `deaths, no tail` = "Deaths alone, no tail",
              `fixed cases` = "Cases fixed",
              `fixed cases, delay rule` = "Cases fixed, delay rule")
  by_day <- by_day %>%
    dplyr::mutate(
      panel = paste0(dplyr::coalesce(unname(labels[.data$model]), .data$model), "\nreports to",
                     format(.data$date_now, "%e %B")),
      panel = factor(.data$panel, unique(.data$panel[order(.data$date_now, .data$model)])),
      quantity = factor(.data$quantity, c(
        "Fatal cases by day of onset", "Mean delay to death recorded (days)",
        "Case fatality ratio")),
      chain = factor(.data$chain))
  ggplot2::ggplot(by_day, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_col(ggplot2::aes(y = .data$reported), fill = "grey80",
                      data = dplyr::filter(by_day, .data$chain == dplyr::first(.data$chain),
                                           !is.na(.data$reported))) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi,
                                      fill = .data$chain), alpha = 0.15) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid, colour = .data$chain)) +
    ggplot2::facet_grid(.data$quantity ~ .data$panel, scales = "free", switch = "y") +
    ggplot2::labs(x = "Date of onset", y = NULL, colour = "Chain", fill = "Chain") +
    ggplot2::theme_bw() +
    ggplot2::theme(strip.placement = "outside",
                   strip.background = ggplot2::element_blank(),
                   legend.position = "bottom")
}

# Tests of the joint model of cases and deaths (docs/bvd_deaths.tex) on
# simulated data: one simulated outbreak for each replicate, reported in
# several ways, each fitted by several chains.

#' The ways in which a simulated outbreak is reported
#'
#' @return a tibble with a row for each scenario: its name and the label used
#' in figures
deaths_scenarios <- function() {
  dplyr::tibble(
    scenario = c("base", "cfr", "sooner", "wrong", "dated", "dated_ignored", "all"),
    label = c("Nothing changes", "Case fatality\nratio halves",
              "Fatal cases reported\ntwice as fast", "Wrong records",
              "30% dated\nby death", "30% dated by death,\nfitted as if none",
              "All together"))
}

#' What each scenario changes from the base case
#'
#' @param scenario the name of a scenario
#' @return a named list which can contain: 'cfr' (a function of onset day),
#' 'fatal_reporting', 'wrong' and 'dated' (as the arguments of
#' incidenceinflation::simulate_cases_deaths) and 'fit_dated' (FALSE if the
#' model is fitted as if no cases were dated by death)
deaths_scenario_settings <- function(scenario) {
  f_step <- function(day, before, after) function(t) ifelse(t < day, before, after)
  dated <- list(fraction = 0.3, mean = 7, sd = 4, reporting = list(mean = 2, sd = 1.5))
  wrong <- list(eta = 0.03, rho = 0.3, delta = 0.4)
  list(
    base = list(),
    cfr = list(cfr = f_step(33, 0.5, 0.25)),
    sooner = list(fatal_reporting = list(mean = 4, sd = 3)),
    wrong = list(wrong = wrong),
    dated = list(dated = dated),
    dated_ignored = list(dated = dated, fit_dated = FALSE),
    all = list(cfr = f_step(33, 0.5, 0.25), fatal_reporting = list(mean = 4, sd = 3),
               wrong = wrong, dated = dated))[[scenario]]
}

#' Simulates an outbreak and the reports of its cases and deaths
#'
#' The reporting delay has mean 8 and sd 6 days, and the delay from onset to a
#' death being recorded mean 12 and sd 7 days. Replicates differ in the
#' outbreak; the scenarios of a replicate share it.
#'
#' @param scenario the name of a scenario
#' @param replicate the number of the replicate, which sets the seed
#' @param n_days the number of onset days
#' @return a named list of 'snapshots' and 'truth' (see
#' incidenceinflation::simulate_cases_deaths), 'cases_before', 'serial',
#' 'n_days', 'scenario', 'replicate', 'settings' and 'true_delays'
simulate_deaths_dataset <- function(scenario, replicate, n_days = 60) {
  settings <- deaths_scenario_settings(scenario)
  set.seed(replicate)
  serial <- list(mean = 5, sd = 3)
  cases_all <- incidenceinflation::true_cases(
    n_days + 40, function(t) 1, kappa = 1000, serial,
    initial_parameters = list(mean = 40, length = 10))
  days <- seq_len(n_days)
  cfr <- if(is.null(settings$cfr)) rep(0.4, n_days) else settings$cfr(days)
  sim <- incidenceinflation::simulate_cases_deaths(
    cases_all[41:(n_days + 40)], days, list(mean = 8, sd = 6), cfr,
    list(mean = 12, sd = 7),
    fatal_reporting_parameters = settings$fatal_reporting,
    dated_by_death = settings$dated, wrong = settings$wrong)
  c(sim, list(
    cases_before = cases_all[1:40], serial = serial, n_days = n_days,
    scenario = scenario, replicate = replicate, settings = settings,
    true_delays = list(
      reporting = 8,
      reporting_fatal = if(is.null(settings$fatal_reporting)) 8
      else settings$fatal_reporting$mean,
      recording = 12, recording_sd = 7)))
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
  snapshots <- dataset$snapshots
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
  settings <- list(
    initial_cfr = c(0.5, 0.25, 0.7)[(chain - 1) %% 3 + 1],
    initial_delay = list(list(mean = 14, sd = 8), list(mean = 8, sd = 5),
                         list(mean = 20, sd = 10))[[(chain - 1) %% 3 + 1]],
    delay_changepoints = list(min_length = 14, n_partition_moves = 20))
  if(!is.null(dataset$settings$dated) && !identical(dataset$settings$fit_dated, FALSE))
    settings$dated_by_death <- dataset$settings$dated

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
      deaths = list(snapshot = snapshots %>%
                      dplyr::select("time_onset", "time_reported", "deaths_reported"),
                    settings = settings)),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(scenario = dataset$scenario, replicate = dataset$replicate,
              chain = chain, niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, error = fit$error)
  warmup <- niterations / 2
  for(name in intersect(names(fit), c(
    "cases", "Rt", "reporting_days", "deaths", "deaths_parameters",
    "Rt_changepoints", "reporting_changepoints", "revisions", "reporting_effects")))
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

#' Estimates from the fits of one dataset beside the simulated truth
#'
#' @inheritParams deaths_dataset_fits
#' @return a tibble with one row
summarise_deaths_fits <- function(dataset, fits) {
  fitted <- deaths_dataset_fits(dataset, fits)
  out <- dplyr::tibble(scenario = dataset$scenario, replicate = dataset$replicate,
                       chains = fitted$n_chains, error = fitted$errors)
  if(fitted$n_chains == 0)
    return(out)
  f_interval <- function(x) sprintf("%.2f (%.2f-%.2f)", stats::median(x),
                                    stats::quantile(x, 0.05), stats::quantile(x, 0.95))
  truth <- dataset$truth
  n_days <- dataset$n_days
  early <- 5:25
  late <- 40:55
  deaths <- fitted$draws("deaths")
  parameters <- fitted$draws("deaths_parameters")
  cases <- fitted$draws("cases")
  revisions <- fitted$draws("revisions")
  f_mean_over <- function(df, days, column) {
    df %>%
      dplyr::filter(.data$time_onset %in% days) %>%
      dplyr::group_by(.data$iteration, .data$chain) %>%
      dplyr::summarise(value = mean(.data[[column]]), .groups = "drop")
  }
  draws_cfr_early <- f_mean_over(deaths, early, "cfr")
  draws_cfr_late <- f_mean_over(deaths, late, "cfr")
  draws_recording_mean <- f_mean_over(deaths, late, "delay_mean")
  draws_recording_sd <- f_mean_over(deaths, late, "delay_sd")
  draws_reporting_mean <- f_mean_over(fitted$draws("reporting_days"), 20:50, "mean")
  draws_Rt_recent <- f_mean_over(fitted$draws("Rt"), (n_days - 13):n_days, "Rt")
  draws_dated_share <- deaths %>%
    dplyr::filter(.data$time_onset %in% 10:50) %>%
    dplyr::group_by(.data$iteration, .data$chain) %>%
    dplyr::summarise(value = sum(.data$dated_by_death) / sum(.data$deaths_recorded),
                     .groups = "drop")
  coverage <- deaths_cases_coverage(dataset, fits)
  recent <- coverage$days_before_end < 14
  dplyr::bind_cols(out, dplyr::tibble(
    minutes = round(fitted$minutes, 1),
    cfr_early = f_interval(draws_cfr_early$value),
    cfr_late = f_interval(draws_cfr_late$value),
    cfr_realised = sprintf(
      "%.2f / %.2f",
      sum(truth$deaths_onset[early]) / sum(truth$cases_onset[early]),
      sum(truth$deaths_onset[late]) / sum(truth$cases_onset[late])),
    p_cfr_change = round(mean(parameters$n_cfr_changes > 0), 2),
    recording_mean = f_interval(draws_recording_mean$value),
    recording_sd = f_interval(draws_recording_sd$value),
    p_recording_change = round(mean(parameters$n_delay_changes > 0), 2),
    reporting_mean = f_interval(draws_reporting_mean$value),
    fatal_delay_ratio = f_interval(parameters$fatal_delay_ratio),
    p_ratio_one = round(mean(parameters$fatal_delay_ratio == 1), 2),
    eta = f_interval(revisions$eta),
    rho = f_interval(revisions$rho),
    wrong_dead = f_interval(parameters$wrong_dead),
    dated_share = f_interval(draws_dated_share$value),
    dated_share_truth = round(
      sum(truth$n_dated_by_death[10:50]) / sum(truth$deaths_true[10:50]), 2),
    Rt_recent = f_interval(draws_Rt_recent$value),
    cases_recent_coverage = round(mean(coverage$is_inside[recent]), 2),
    cases_recent_bias = round(mean((coverage$mid - coverage$truth)[recent]), 1),
    cases_earlier_coverage = round(mean(coverage$is_inside[!recent]), 2),
    rhat_cfr = round(rhat_chains(draws_cfr_late$value, draws_cfr_late$chain), 2),
    rhat_recording = round(rhat_chains(draws_recording_mean$value, draws_recording_mean$chain), 2),
    rhat_reporting = round(rhat_chains(draws_reporting_mean$value, draws_reporting_mean$chain), 2)))
}

#' Whether the true cases of each onset day are inside the 90% interval
#'
#' @inheritParams deaths_dataset_fits
#' @return a tibble with a row for each onset day: scenario, replicate,
#' time_onset, days_before_end, truth (cases by true day of onset), lo, mid,
#' hi, is_inside and is_exact (the interval has no width and is at the truth)
deaths_cases_coverage <- function(dataset, fits) {
  fitted <- deaths_dataset_fits(dataset, fits)
  if(fitted$n_chains == 0)
    return(NULL)
  fitted$draws("cases") %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(lo = stats::quantile(.data$cases_true, 0.05),
                     mid = stats::median(.data$cases_true),
                     hi = stats::quantile(.data$cases_true, 0.95)) %>%
    dplyr::mutate(scenario = dataset$scenario, replicate = dataset$replicate,
                  days_before_end = dataset$n_days - .data$time_onset,
                  truth = dataset$truth$cases_onset[.data$time_onset],
                  is_inside = .data$truth >= .data$lo & .data$truth <= .data$hi,
                  is_exact = .data$lo == .data$hi & .data$lo == .data$truth) %>%
    dplyr::relocate("scenario", "replicate")
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
    truth <- dataset$truth
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
    days <- truth$time_onset
    f_truth <- function(value, series, quantity)
      dplyr::tibble(time_onset = days, value = value, series = series,
                    quantity = quantity)
    truths[[name]] <- dplyr::bind_rows(
      f_truth(truth$cases_onset, "Cases", quantities[1]),
      f_truth(truth$deaths_onset, "Fatal cases", quantities[2]),
      f_truth(1, "Reproduction number", quantities[3]),
      f_truth(dataset$true_delays$reporting, "Onset to case reported", quantities[4]),
      f_truth(dataset$true_delays$reporting_fatal,
              "Onset to case reported, fatal cases", quantities[4]),
      f_truth(dataset$true_delays$recording, "Onset to death recorded", quantities[4]),
      f_truth(truth$cfr, "Case fatality ratio", quantities[5])) %>%
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
  f_factors <- function(df) {
    df %>%
      dplyr::mutate(scenario = factor(labels[.data$scenario], levels = labels[scenarios]),
                    quantity = factor(.data$quantity, levels = quantities))
  }
  estimates <- f_factors(dplyr::bind_rows(estimates))
  truths <- f_factors(dplyr::bind_rows(truths))
  reported <- f_factors(dplyr::bind_rows(reported))
  # the same vertical range for each quantity in every scenario
  ranges <- dplyr::bind_rows(
    dplyr::transmute(estimates, .data$quantity, y = .data$hi),
    dplyr::transmute(estimates, .data$quantity, y = .data$lo),
    dplyr::transmute(truths, .data$quantity, y = .data$value)) %>%
    dplyr::group_by(.data$quantity) %>%
    dplyr::summarise(lo = min(.data$y), hi = max(.data$y)) %>%
    dplyr::mutate(lo = ifelse(.data$quantity == quantities[3], 0.8, 0),
                  hi = ifelse(.data$quantity == quantities[3], 1.2, .data$hi)) %>%
    tidyr::pivot_longer(c("lo", "hi"), values_to = "y") %>%
    dplyr::select(-"name") %>%
    tidyr::crossing(scenario = factor(labels[scenarios], levels = labels[scenarios])) %>%
    dplyr::mutate(time_onset = 1)
  colours <- c("Cases" = "#4C72B0", "Fatal cases" = "#C44E52",
               "Reproduction number" = "#333333",
               "Onset to case reported" = "#4C72B0",
               "Onset to case reported, fatal cases" = "#DD8452",
               "Onset to death recorded" = "#C44E52", "Case fatality ratio" = "#333333",
               "Cases in the latest report" = "#111111",
               "Deaths in the latest report" = "#111111")
  is_counts <- truths$quantity %in% quantities[1:2]
  ggplot2::ggplot(estimates, ggplot2::aes(.data$time_onset)) +
    ggplot2::geom_blank(ggplot2::aes(y = .data$y), data = ranges) +
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

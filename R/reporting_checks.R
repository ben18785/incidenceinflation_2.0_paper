# Checks of the model for reporting delays, made with hindsight.
#
# For onset times whose reporting is complete, the count in the latest report
# is taken as the true count. Given this, the model says that the cases
# reported between successive reports are binomial, with probabilities
# determined by a delay distribution. A model is fitted by maximum likelihood,
# datasets are simulated from the fitted model, and features of the simulated
# datasets are compared with those of the data. Because the true counts are
# taken as known, these checks concern the reporting model alone, apart from
# the renewal model.
#
# Three mechanisms can be added to the basic model, each of which can be
# switched on or off (see reporting_model_spec()):
#
# - a delay distribution with a heavier tail than the gamma;
# - an effect of the day of the week of a report on the rate at which cases
#   not yet reported come to be reported;
# - a random effect of each report on that rate, shared by all onset times.
#
# With multiplier m for a report, the probability that a case not yet reported
# is reported in the interval ending at that report is
#   1 - (S(delay_2) / S(delay_1))^m
# where S is the probability of remaining unreported under the delay
# distribution. m is the product of the effect of the report's day of the week
# and the report's random effect; m = 1 gives the basic model.

#' Specifies which mechanisms a reporting model includes
#'
#' @param family delay distribution: "gamma"; "lognormal"; or "gamma_tail", a
#' gamma distribution mixed with a small proportion of cases whose delay is
#' exponential with a long mean
#' @param weekday whether the reporting rate depends on the day of the week of
#' the report (which needs the date of each report)
#' @param report_effects whether each report has a random effect on the
#' reporting rate, log-normal with median one
reporting_model_spec <- function(family = "gamma", weekday = FALSE,
                                 report_effects = FALSE) {
  if(!family %in% c("gamma", "lognormal", "gamma_tail"))
    stop("family must be 'gamma', 'lognormal' or 'gamma_tail'.")
  list(family = family, weekday = weekday, report_effects = report_effects)
}

#' Prepares snapshots for checks of the reporting model
#'
#' @param snapshots a tibble with columns time_onset, time_reported and
#' cases_reported (times in days or weeks), restricted to onset times whose
#' reporting is complete
#' @param date_origin the date of time 1, if times are in days and the day of
#' the week of each report is wanted; otherwise NULL
#' @return a tibble with a row for each interval between successive reports
#' of an onset time: delay_1 and delay_2 (from onset to the two reports),
#' cases newly reported, and cases remaining to be reported at its start
reporting_intervals <- function(snapshots, date_origin = NULL) {
  intervals <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    # remove records which are later withdrawn, so that counts do not fall
    dplyr::mutate(cases = rev(cummin(rev(.data$cases_reported))),
                  cases_final = dplyr::last(.data$cases),
                  cases_first = dplyr::first(.data$cases),
                  delay_1 = dplyr::lag(.data$time_reported - .data$time_onset),
                  delay_2 = .data$time_reported - .data$time_onset,
                  newly_reported = .data$cases - dplyr::lag(.data$cases),
                  remaining = .data$cases_final - dplyr::lag(.data$cases)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(!is.na(.data$delay_1))
  intervals$weekday <- NA_integer_
  if(!is.null(date_origin))
    intervals$weekday <- as.integer(format(
      as.Date(date_origin) + intervals$time_reported - 1, "%u"))
  intervals
}

#' Names of the parameters of a reporting model (on the scale optimised over)
reporting_parameter_names <- function(spec, weekdays_present) {
  names <- c("log_mean", "log_sd")
  if(spec$family == "gamma_tail")
    names <- c(names, "logit_tail_weight", "log_tail_mean")
  if(spec$weekday)
    names <- c(names, paste0("log_weekday_", weekdays_present[-1]))
  if(spec$report_effects)
    names <- c(names, "log_sigma")
  names
}

#' Log-probability of remaining unreported at a delay
log_unreported <- function(delay, parameters, family) {
  mean <- exp(parameters[["log_mean"]])
  sd <- exp(parameters[["log_sd"]])
  x <- delay + 0.5
  if(family == "lognormal") {
    sdlog <- sqrt(log1p(sd^2 / mean^2))
    return(stats::plnorm(x, meanlog = log(mean) - sdlog^2 / 2, sdlog = sdlog,
                         lower.tail = FALSE, log.p = TRUE))
  }
  log_gamma <- stats::pgamma(x, shape = mean^2 / sd^2, rate = mean / sd^2,
                             lower.tail = FALSE, log.p = TRUE)
  if(family == "gamma")
    return(log_gamma)
  weight <- stats::plogis(parameters[["logit_tail_weight"]])
  log_tail <- -x / exp(parameters[["log_tail_mean"]])
  a <- log1p(-weight) + log_gamma
  b <- log(weight) + log_tail
  pmax(a, b) + log1p(exp(-abs(a - b)))
}

#' Effect of the day of the week of each interval's report on the reporting rate
#'
#' Effects are constrained so that their logarithms sum to zero across the
#' days of the week on which reports were made.
weekday_multiplier <- function(intervals, parameters, spec, weekdays_present) {
  if(!spec$weekday)
    return(rep(1, nrow(intervals)))
  log_effects <- unlist(parameters[paste0("log_weekday_", weekdays_present[-1])])
  log_effects <- c(-sum(log_effects), log_effects)
  exp(log_effects[match(intervals$weekday, weekdays_present)])
}

#' Rate of reporting accumulated over each interval, apart from random effects
interval_hazard <- function(intervals, parameters, spec, weekdays_present) {
  hazard <- log_unreported(intervals$delay_1, parameters, spec$family) -
    log_unreported(intervals$delay_2, parameters, spec$family)
  pmax(hazard, 1e-12) *
    weekday_multiplier(intervals, parameters, spec, weekdays_present)
}

#' Grid of multipliers used to sum over each report's random effect numerically
report_effect_grid <- function(n = 100) exp(seq(log(0.01), log(100), length.out = n))

#' Log-likelihood of a reporting model, with the random effects of reports
#' summed over
#'
#' @return a list of the log-likelihood and, if the model has report effects,
#' the posterior mean of the effect of each report
reporting_logl <- function(intervals, parameters, spec, weekdays_present) {
  used <- intervals$remaining > 0
  hazard <- interval_hazard(intervals[used, ], parameters, spec, weekdays_present)
  newly <- intervals$newly_reported[used]
  remaining <- intervals$remaining[used]
  log_choose <- lchoose(remaining, newly)
  f_cell <- function(multiplier) {
    log_not <- -multiplier * hazard
    ifelse(newly == 0, log_choose + remaining * log_not,
           log_choose + newly * log(-expm1(log_not)) + (remaining - newly) * log_not)
  }
  if(!spec$report_effects)
    return(list(logl = sum(f_cell(1)), effects = NULL))

  sigma <- exp(parameters[["log_sigma"]])
  grid <- report_effect_grid()
  reports <- intervals$time_reported[used]
  logl <- do.call(cbind, purrr::map(grid, ~tapply(f_cell(.), reports, sum)))
  log_grid <- log(grid)
  widths <- c(diff(log_grid)[1], utils::head(diff(log_grid), -1) + diff(log_grid)[-1],
              utils::tail(diff(log_grid), 1)) / 2
  # log-normal density on the log scale, by the trapezium rule
  log_weights <- stats::dnorm(log_grid, 0, sigma, log = TRUE) + log(widths)
  log_terms <- sweep(logl, 2, log_weights, "+")
  log_marginal <- matrixStats::rowLogSumExps(log_terms)
  list(logl = sum(log_marginal),
       effects = dplyr::tibble(
         time_reported = as.numeric(rownames(logl)),
         effect = as.vector(exp(log_terms - log_marginal) %*% grid)))
}

#' Fits a reporting model by maximum likelihood
#'
#' @param start a named vector of starting values, usually the estimates from
#' a simpler model; parameters not in it start at neutral values
#' @return a list of the estimates, the maximised log-likelihood, the number
#' of parameters and (if applicable) the effects of each report
fit_reporting_model <- function(intervals, spec, start = NULL) {
  weekdays_present <- sort(unique(intervals$weekday))
  names_all <- reporting_parameter_names(spec, weekdays_present)
  initial <- stats::setNames(rep(0, length(names_all)), names_all)
  initial[c("log_mean", "log_sd")] <- c(log(6), log(4))
  if(spec$family == "gamma_tail")
    initial[c("logit_tail_weight", "log_tail_mean")] <- c(stats::qlogis(0.05), log(30))
  if(spec$report_effects)
    initial["log_sigma"] <- log(0.3)
  shared <- intersect(names(start), names_all)
  initial[shared] <- start[shared]

  f_negative_logl <- function(values) {
    parameters <- as.list(stats::setNames(values, names_all))
    value <- tryCatch(-reporting_logl(intervals, parameters, spec, weekdays_present)$logl,
                      error = function(e) NA)
    if(is.finite(value)) value else 1e12
  }
  best <- stats::optim(initial, f_negative_logl, control = list(maxit = 4000))
  polished <- tryCatch(
    stats::optim(best$par, f_negative_logl, method = "BFGS"),
    error = function(e) best)
  if(polished$value < best$value)
    best <- polished
  parameters <- as.list(stats::setNames(best$par, names_all))
  list(spec = spec, parameters = parameters, logl = -best$value,
       n_parameters = length(names_all), weekdays_present = weekdays_present,
       effects = reporting_logl(intervals, parameters, spec, weekdays_present)$effects)
}

#' Features of reporting data which are compared between data and simulations
#'
#' @param intervals as returned by reporting_intervals()
#' @param hazard the fitted rate of reporting over each interval, apart from
#' random effects, relative to which dispersion is measured
#' @param delays delays at which the mean proportion reported is calculated
#' @return a named vector
reporting_statistics <- function(intervals, hazard, delays) {
  p <- -expm1(-hazard)
  used <- intervals$remaining > 0 & p > 1e-8 & p < 1 - 1e-8
  expected <- intervals$remaining * p
  variance <- intervals$remaining * p * (1 - p)
  residual <- (intervals$newly_reported - expected) / sqrt(variance)
  # all cases newly reported in each report, across onset times
  by_report <- dplyr::tibble(time = intervals$time_reported[used],
                             difference = (intervals$newly_reported - expected)[used],
                             variance = variance[used]) %>%
    dplyr::group_by(.data$time) %>%
    dplyr::summarise(z = sum(.data$difference) / sqrt(sum(.data$variance)))
  proportions <- purrr::map_dbl(delays, function(delay) {
    at_delay <- intervals$delay_2 == delay & intervals$cases_final > 0
    mean((intervals$cases_final[at_delay] - intervals$remaining[at_delay] +
            intervals$newly_reported[at_delay]) / intervals$cases_final[at_delay])
  })
  c(dispersion = mean(residual[used]^2),
    dispersion_by_report = mean(by_report$z^2),
    proportion_zero = mean(intervals$newly_reported[used] == 0),
    stats::setNames(proportions, paste0("reported_by_", delays)))
}

#' Simulates reporting data from a fitted reporting model
simulate_reporting <- function(intervals, fit) {
  hazard <- interval_hazard(intervals, fit$parameters, fit$spec, fit$weekdays_present)
  if(fit$spec$report_effects) {
    reports <- sort(unique(intervals$time_reported))
    effects <- stats::rlnorm(length(reports), 0, exp(fit$parameters[["log_sigma"]]))
    hazard <- hazard * effects[match(intervals$time_reported, reports)]
  }
  intervals$hazard_simulation <- hazard
  intervals %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::group_modify(function(df, key) {
      unreported <- exp(-cumsum(df$hazard_simulation))
      probs <- pmax(c(-diff(c(1, unreported)), unreported[length(unreported)]), 0)
      to_report <- df$cases_final[1] - df$cases_first[1]
      draws <- as.vector(stats::rmultinom(1, to_report, probs))[seq_len(nrow(df))]
      df$newly_reported <- draws
      df$remaining <- to_report - c(0, cumsum(draws)[-nrow(df)])
      df
    }) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"hazard_simulation")
}

#' Compares features of the data with their distribution under a fitted model
#'
#' @return a tibble with a row for each feature: its value in the data, the
#' median and 5% and 95% quantiles of its value in simulated datasets, and
#' whether the value in the data lies between those quantiles
check_reporting_fit <- function(intervals, fit, delays, n_simulations = 200) {
  # simulated data are in a different row order, so match rows by position
  intervals <- dplyr::arrange(intervals, .data$time_onset, .data$time_reported)
  hazard <- interval_hazard(intervals, fit$parameters, fit$spec, fit$weekdays_present)
  observed <- reporting_statistics(intervals, hazard, delays)
  simulated <- purrr::map_dfr(seq_len(n_simulations), function(i) {
    replicate <- simulate_reporting(intervals, fit) %>%
      dplyr::arrange(.data$time_onset, .data$time_reported)
    dplyr::as_tibble(as.list(reporting_statistics(replicate, hazard, delays)))
  })
  statistics <- names(observed)
  f_simulated <- function(f) purrr::map_dbl(statistics, ~f(simulated[[.]]))
  out <- dplyr::tibble(
    statistic = statistics,
    value_observed = unname(observed[statistics]),
    simulated_median = f_simulated(function(x) stats::median(x, na.rm = TRUE)),
    simulated_q05 = f_simulated(function(x) stats::quantile(x, 0.05, na.rm = TRUE)),
    simulated_q95 = f_simulated(function(x) stats::quantile(x, 0.95, na.rm = TRUE)))
  out$consistent <- out$value_observed >= out$simulated_q05 &
    out$value_observed <= out$simulated_q95
  out
}

#' The sequence of reporting models compared for each dataset
#'
#' The first three differ only in the delay distribution; the rest add the
#' effects of reports one at a time.
reporting_model_sequence <- function(has_dates) {
  specs <- list(
    "gamma" = reporting_model_spec("gamma"),
    "lognormal" = reporting_model_spec("lognormal"),
    "gamma + tail" = reporting_model_spec("gamma_tail"))
  if(has_dates) {
    specs[["gamma + weekday"]] <- reporting_model_spec("gamma", weekday = TRUE)
    specs[["gamma + weekday + report"]] <-
      reporting_model_spec("gamma", weekday = TRUE, report_effects = TRUE)
    specs[["gamma + tail + weekday + report"]] <-
      reporting_model_spec("gamma_tail", weekday = TRUE, report_effects = TRUE)
  } else {
    specs[["gamma + report"]] <-
      reporting_model_spec("gamma", report_effects = TRUE)
    specs[["gamma + tail + report"]] <-
      reporting_model_spec("gamma_tail", report_effects = TRUE)
  }
  specs
}

#' Fits and checks the sequence of reporting models for one dataset
#'
#' @param snapshots complete reporting data (see reporting_intervals())
#' @param date_origin the date of time 1 (NULL if times are not in days)
#' @param delays delays at which to compare the proportion reported
#' @return a list of a summary of each model's fit and of its checks
compare_reporting_models <- function(snapshots, date_origin, delays,
                                     n_simulations = 200, seed = 1) {
  set.seed(seed)
  intervals <- reporting_intervals(snapshots, date_origin)
  specs <- reporting_model_sequence(!is.null(date_origin))
  fits <- list()
  start <- NULL
  for(name in names(specs)) {
    fits[[name]] <- fit_reporting_model(intervals, specs[[name]], start)
    # each model starts from the estimates of those before it, the most recent
    # taking precedence, except that the delay starts from the gamma fit
    start <- unlist(c(fits[["gamma"]]$parameters[c("log_mean", "log_sd")],
                      rev(purrr::map(fits, ~unlist(.$parameters)))))
    start <- start[!duplicated(sub(".*\\.", "", names(start)))]
    names(start) <- sub(".*\\.", "", names(start))
  }
  summary <- purrr::map_dfr(names(fits), function(name) {
    fit <- fits[[name]]
    parameters <- fit$parameters
    dplyr::tibble(
      model = name,
      n_parameters = fit$n_parameters,
      logl = fit$logl,
      aic = 2 * fit$n_parameters - 2 * fit$logl,
      delay_mean = exp(parameters$log_mean),
      delay_sd = exp(parameters$log_sd),
      tail_weight = if(is.null(parameters$logit_tail_weight)) NA_real_
      else stats::plogis(parameters$logit_tail_weight),
      tail_mean = if(is.null(parameters$log_tail_mean)) NA_real_
      else exp(parameters$log_tail_mean),
      sigma = if(is.null(parameters$log_sigma)) NA_real_ else exp(parameters$log_sigma))
  })
  checks <- purrr::map_dfr(names(fits), function(name) {
    dplyr::mutate(check_reporting_fit(intervals, fits[[name]], delays, n_simulations),
                  model = name, .before = 1)
  })
  weekday_effects <- purrr::map_dfr(names(fits), function(name) {
    fit <- fits[[name]]
    if(!fit$spec$weekday)
      return(NULL)
    log_effects <- unlist(fit$parameters[paste0("log_weekday_", fit$weekdays_present[-1])])
    dplyr::tibble(model = name, weekday = fit$weekdays_present,
                  effect = exp(c(-sum(log_effects), log_effects)))
  })
  list(summary = summary, checks = checks, weekday_effects = weekday_effects,
       n_onset_times = dplyr::n_distinct(intervals$time_onset),
       n_cases = sum(tapply(intervals$cases_final, intervals$time_onset, max)))
}

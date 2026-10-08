# Bundibugyo virus disease analysed with the model in which both Rt and the
# reporting delay change at times which are inferred, from the date of the
# first situation report.

#' Prepares the snapshots as of a date, from the date of the first situation
#' report
#'
#' Onset days before the first report are not analysed, since nothing is known
#' of how they were reported soon after onset. Their counts, as given in the
#' report of the analysis date, are kept as known earlier cases for the
#' renewal equation (for the serial_max days before the first onset day
#' analysed).
prepare_bvd_changepoint_analysis <- function(snapshots, date_now, serial_max = 40) {
  date_now <- as.Date(date_now)
  analysis <- prepare_bvd_analysis(snapshots, date_now,
                                   date_earliest = min(snapshots$date_reported),
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
  analysis
}

#' Settings for the segments of the reporting delay
#'
#' Segments of the delay have at least 14 onset days (those of Rt have at
#' least 7), and splits, merges and shifts are proposed 50 times in each
#' iteration, to help the chains move between numbers of changes. These moves
#' are cheap: 50 of them add about a tenth to the time of an iteration.
bvd_delay_settings <- function() {
  list(min_length = 14, n_partition_moves = 50)
}

#' Runs one chain of the model with changes in Rt and in the delay
#'
#' The model has sporadic revisions, an effect of the day of the week of each
#' report and a negative binomial renewal model, with the cases of earlier
#' onset days supplied as known. Chains differ in their seed and in the
#' values from which they start. Draws of all quantities after the first half
#' are kept, thinned to at most n_draws.
fit_bvd_changepoint_chain <- function(analysis, chain, niterations, n_draws = 300,
                                      serial_parameters = list(mean = 15.3, sd = 9.3),
                                      delay_settings = bvd_delay_settings()) {
  set.seed(1000 * chain + as.integer(analysis$date_now) %% 1000)
  settings <- fit_settings()
  snapshots <- analysis$snapshots
  onset_times <- sort(unique(snapshots$time_onset))
  data <- dplyr::mutate(snapshots, Rt_index = 1)
  largest_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- max(onset_times) - largest_reported$time_onset
  # starting values which differ between chains
  inflation <- c(2, 1, 3.5)[(chain - 1) %% 3 + 1]
  initial_cases_true <- largest_reported %>%
    dplyr::mutate(cases_true = ceiling(
      .data$cases_true * (1 + inflation * exp(-days_before_end / 4)) +
        5 * (days_before_end < 5)))
  initial_reporting <- list(list(mean = 7, sd = 4), list(mean = 4, sd = 2.5),
                            list(mean = 11, sd = 7))[[(chain - 1) %% 3 + 1]]
  initial_overdispersion <- c(10, 3, 30)[(chain - 1) %% 3 + 1]

  largest_fall <- incidenceinflation::max_downward_revision(snapshots)
  initial <- settings$initial_revisions
  initial$weekday <- TRUE
  initial$weekday_first <- analysis$weekday_first
  priors <- list(
    Rt = settings$priors$Rt,
    reporting = list(mean_mu = 7, mean_sigma = 10, sd_mu = 5, sd_sigma = 5),
    max_cases = ceiling(4 * max(initial_cases_true$cases_true) + 50),
    overdispersion = list(mean = 20, sd = 20),
    revisions = utils::modifyList(settings$priors$revisions,
                                  list(eta_mu = 0.005, eta_sigma = 0.005)),
    max_erroneous = max(3, largest_fall + 1),
    Rt_changepoints = list(),
    reporting_changepoints = delay_settings)

  time_start <- Sys.time()
  fit <- tryCatch(
    incidenceinflation::mcmc_single(
      niterations = niterations,
      snapshot_with_Rt_index_df = data,
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = initial_cases_true,
      initial_reporting_parameters = initial_reporting,
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      # step sizes chosen from earlier runs, in which smaller steps were
      # nearly always accepted and the parameters moved slowly
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      initial_overdispersion = initial_overdispersion,
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 8,
      initial_revision_parameters = initial,
      revision_metropolis_parameters = settings$revision_metropolis,
      cases_before = analysis$cases_before,
      n_parameter_steps = 5),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(chain = chain, analysis = analysis, niterations = niterations,
              seconds = as.numeric(Sys.time() - time_start, units = "secs"),
              largest_fall = largest_fall, serial_parameters = serial_parameters,
              error = fit$error)
  if(!is.null(fit$error))
    return(out)

  warmup <- floor(niterations / 2)
  kept <- unique(round(seq(warmup + 1, niterations, length.out = n_draws)))
  f_keep <- function(df) {
    df %>%
      dplyr::filter(.data$iteration %in% kept) %>%
      dplyr::select(-dplyr::any_of("chain")) %>%
      dplyr::mutate(chain = chain)
  }
  out$draws <- list(
    cases = f_keep(fit$cases),
    Rt = f_keep(fit$Rt),
    reporting = f_keep(fit$reporting_days),
    overdispersion = f_keep(fit$overdispersion),
    revisions = f_keep(fit$revisions),
    reporting_effects = f_keep(fit$reporting_effects),
    Rt_changepoints = f_keep(fit$Rt_changepoints),
    reporting_changepoints = f_keep(fit$reporting_changepoints))
  out
}

#' Potential scale reduction factor (split R-hat) of a quantity
#'
#' @param values draws of the quantity, in order within each chain
#' @param chain the chain of each draw
#' Each chain is split in half, so that a drift within chains is detected as
#' well as a difference between them. Values near 1 indicate agreement;
#' values above about 1.1 indicate that the chains have not converged.
split_rhat <- function(values, chain) {
  halves <- unlist(lapply(split(values, chain), function(x) {
    n <- floor(length(x) / 2)
    list(x[seq_len(n)], x[n + seq_len(n)])
  }), recursive = FALSE)
  n <- min(lengths(halves))
  if(n < 2)
    return(NA_real_)
  halves <- lapply(halves, function(x) x[seq_len(n)])
  means <- vapply(halves, mean, numeric(1))
  within <- mean(vapply(halves, stats::var, numeric(1)))
  between <- n * stats::var(means)
  if(within == 0)
    return(ifelse(between == 0, 1, Inf))
  sqrt(((n - 1) / n * within + between / n) / within)
}

#' The quantities whose convergence is monitored, for each kept draw
bvd_monitored_draws <- function(draws) {
  day_last <- max(draws$Rt$time_onset)
  f_key <- function(df) dplyr::arrange(df, .data$chain, .data$iteration)
  delay <- f_key(dplyr::filter(draws$reporting, .data$time_onset == day_last))
  Rt <- f_key(dplyr::filter(draws$Rt, .data$time_onset == day_last))
  cases <- draws$cases %>%
    dplyr::filter(.data$time_onset > day_last - 14) %>%
    dplyr::group_by(.data$chain, .data$iteration) %>%
    dplyr::summarise(value = sum(.data$cases_true), .groups = "drop") %>%
    f_key()
  weekdays <- f_key(draws$reporting_effects)
  out <- dplyr::bind_rows(
    dplyr::transmute(Rt, .data$chain, .data$iteration,
                     quantity = "Rt, latest onset day", value = .data$Rt),
    dplyr::transmute(cases, .data$chain, .data$iteration,
                     quantity = "Cases, latest 14 onset days", .data$value),
    dplyr::transmute(delay, .data$chain, .data$iteration,
                     quantity = "Mean delay, latest onset day", value = .data$mean),
    dplyr::transmute(delay, .data$chain, .data$iteration,
                     quantity = "Sd of delay, latest onset day", value = .data$sd),
    dplyr::transmute(f_key(draws$reporting_changepoints), .data$chain, .data$iteration,
                     quantity = "Number of changes in delay", value = .data$n_changes),
    dplyr::transmute(f_key(draws$Rt_changepoints), .data$chain, .data$iteration,
                     quantity = "Number of changes in Rt", value = .data$n_changes),
    dplyr::transmute(f_key(draws$overdispersion), .data$chain, .data$iteration,
                     quantity = "Overdispersion (kappa)", value = .data$overdispersion),
    dplyr::transmute(f_key(draws$revisions), .data$chain, .data$iteration,
                     quantity = "eta", value = .data$eta),
    dplyr::transmute(f_key(draws$revisions), .data$chain, .data$iteration,
                     quantity = "rho", value = .data$rho))
  for(name in grep("^weekday_", names(weekdays), value = TRUE))
    out <- dplyr::bind_rows(out, dplyr::transmute(
      weekdays, .data$chain, .data$iteration,
      quantity = paste("Day of week effect", sub("weekday_", "", name)),
      value = .data[[name]]))
  dplyr::mutate(out, quantity = factor(.data$quantity, levels = unique(.data$quantity)))
}

#' Combines the chains run for one analysis
#'
#' @param chains a list of results of fit_bvd_changepoint_chain() for the same
#' analysis
#' @return a result holding summaries over all chains, the pooled draws and
#' the convergence diagnostics
combine_bvd_chains <- function(chains) {
  analysis <- chains[[1]]$analysis
  failed <- purrr::keep(chains, ~!is.null(.$error))
  chains <- purrr::keep(chains, ~is.null(.$error))
  out <- list(model = "Rt and delay changes", analysis = analysis,
              largest_fall = chains[[1]]$largest_fall,
              serial_parameters = chains[[1]]$serial_parameters,
              n_chains = length(chains),
              errors = purrr::map_chr(failed, "error"))
  if(length(chains) == 0) {
    out$summary <- list(error = paste(out$errors, collapse = "; "), seconds = NA)
    return(out)
  }
  names_draws <- names(chains[[1]]$draws)
  draws <- stats::setNames(lapply(names_draws, function(name) {
    purrr::map_dfr(chains, ~.$draws[[name]])
  }), names_draws)
  # iterations are numbered within chains: give each draw its own number
  draws <- lapply(draws, function(df) {
    dplyr::mutate(df, iteration_chain = .data$iteration,
                  iteration = .data$chain * 1e6 + .data$iteration)
  })

  f_starts <- function(df, index) {
    df %>%
      dplyr::group_by(.data$iteration) %>%
      dplyr::arrange(.data$time_onset, .by_group = TRUE) %>%
      dplyr::mutate(is_start = c(FALSE, diff(.data[[index]]) != 0)) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(probability = mean(.data$is_start))
  }
  out$summary <- list(
    model = out$model, error = NULL,
    seconds = sum(purrr::map_dbl(chains, "seconds")),
    niterations = chains[[1]]$niterations,
    cases = summarise_draws_by(draws$cases, .data$cases_true, .data$time_onset),
    Rt = summarise_draws_by(draws$Rt, .data$Rt, .data$time_onset))
  out$changes <- list(
    Rt_n = draws$Rt_changepoints$n_changes,
    Rt_starts = f_starts(draws$Rt, "Rt_index"),
    reporting_n = draws$reporting_changepoints$n_changes,
    reporting_starts = f_starts(draws$reporting, "reporting_piece_index"),
    reporting_days = summarise_draws_by(draws$reporting, .data$mean, .data$time_onset))
  out$draws <- draws

  monitored <- bvd_monitored_draws(draws)
  out$monitored <- monitored
  by_chain <- monitored %>%
    dplyr::group_by(.data$quantity, .data$chain) %>%
    dplyr::summarise(median = stats::median(.data$value), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = "chain", values_from = "median",
                       names_prefix = "median_chain_")
  out$diagnostics <- monitored %>%
    dplyr::arrange(.data$chain, .data$iteration) %>%
    dplyr::group_by(.data$quantity) %>%
    dplyr::summarise(rhat = split_rhat(.data$value, .data$chain),
                     median = stats::median(.data$value), .groups = "drop") %>%
    dplyr::left_join(by_chain, by = "quantity")
  # every onset day's cases, of which the worst is reported
  rhat_cases <- draws$cases %>%
    dplyr::arrange(.data$chain, .data$iteration) %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(rhat = split_rhat(.data$cases_true, .data$chain))
  out$rhat_cases <- rhat_cases
  out
}

#' Traces of the monitored quantities in each chain
plot_bvd_changepoint_convergence <- function(result) {
  quantities <- c("Rt, latest onset day", "Cases, latest 14 onset days",
                  "Mean delay, latest onset day", "Sd of delay, latest onset day",
                  "Number of changes in delay", "Number of changes in Rt",
                  "Overdispersion (kappa)", "eta", "rho")
  labels <- result$diagnostics %>%
    dplyr::filter(.data$quantity %in% quantities) %>%
    dplyr::mutate(label = sprintf("%s (R-hat %.2f)", .data$quantity, .data$rhat))
  df <- result$monitored %>%
    dplyr::filter(.data$quantity %in% quantities) %>%
    dplyr::left_join(dplyr::select(labels, "quantity", "label"), by = "quantity") %>%
    dplyr::mutate(label = factor(.data$label, levels = labels$label[
      match(quantities, labels$quantity)]),
      iteration_chain = .data$iteration - .data$chain * 1e6)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$iteration_chain, y = .data$value,
                                   colour = factor(.data$chain))) +
    ggplot2::geom_line(linewidth = 0.3, alpha = 0.85) +
    ggplot2::facet_wrap(~label, scales = "free_y", ncol = 3,
                        labeller = ggplot2::label_wrap_gen(34)) +
    ggplot2::scale_colour_manual(values = c("#0072B2", "#D55E00", "#009E73",
                                            "#CC79A7", "#E69F00")) +
    ggplot2::labs(x = "Iteration (after the first half)", y = NULL, colour = "Chain") +
    theme_paper() +
    ggplot2::theme(strip.text = ggplot2::element_text(size = 8, colour = "grey10"))
}

#' Weights of the serial interval over a number of days
serial_weights <- function(serial_parameters, serial_max = 40) {
  shape <- (serial_parameters$mean / serial_parameters$sd)^2
  rate <- serial_parameters$mean / serial_parameters$sd^2
  days <- seq_len(serial_max)
  w <- stats::pgamma(days + 0.5, shape, rate) - stats::pgamma(days - 0.5, shape, rate)
  w / sum(w)
}

#' Projects cases forward from each draw under the renewal model
#'
#' Rt is held at its value for the latest onset day in each draw, and cases
#' are negative binomial given those before them.
#'
#' @return a tibble of quantiles of projected cases for each day ahead
project_cases <- function(draws, serial_parameters, days_ahead = 14,
                          serial_max = 40, cases_before = NULL) {
  w <- serial_weights(serial_parameters, serial_max)
  day_last <- max(draws$cases$time_onset)
  projections <- purrr::map_dfr(unique(draws$cases$iteration), function(i) {
    cases <- draws$cases %>%
      dplyr::filter(.data$iteration == i) %>%
      dplyr::arrange(.data$time_onset) %>%
      dplyr::pull(.data$cases_true)
    Rt <- draws$Rt$Rt[draws$Rt$iteration == i & draws$Rt$time_onset == day_last]
    kappa <- draws$overdispersion$overdispersion[draws$overdispersion$iteration == i]
    cases <- c(rep(0, serial_max), cases_before, cases)
    for(h in seq_len(days_ahead)) {
      n <- length(cases)
      infectiousness <- sum(w * rev(cases[(n - serial_max + 1):n]))
      cases <- c(cases, stats::rnbinom(1, mu = Rt * infectiousness, size = kappa))
    }
    dplyr::tibble(iteration = i, time_onset = day_last + seq_len(days_ahead),
                  cases_true = utils::tail(cases, days_ahead))
  })
  summarise_draws_by(projections, .data$cases_true, .data$time_onset)
}

#' Summaries of the parameters of the latest analysis, for the text
summarise_bvd_changepoint_parameters <- function(result) {
  draws <- result$draws
  f_row <- function(parameter, values) {
    dplyr::tibble(parameter = parameter, q05 = stats::quantile(values, 0.05),
                  q50 = stats::quantile(values, 0.5),
                  q95 = stats::quantile(values, 0.95), mean = mean(values))
  }
  day_last <- max(draws$Rt$time_onset)
  latest_delay <- dplyr::filter(draws$reporting, .data$time_onset == day_last)
  weekdays <- dplyr::select(draws$reporting_effects, dplyr::starts_with("weekday_"))
  dplyr::bind_rows(
    f_row("Rt, latest onset day", draws$Rt$Rt[draws$Rt$time_onset == day_last]),
    f_row("mean delay, latest onset day", latest_delay$mean),
    f_row("sd of delay, latest onset day", latest_delay$sd),
    f_row("overdispersion", draws$overdispersion$overdispersion),
    f_row("eta", draws$revisions$eta),
    f_row("rho", draws$revisions$rho),
    f_row("number of changes in Rt", draws$Rt_changepoints$n_changes),
    f_row("number of changes in delay", draws$reporting_changepoints$n_changes),
    f_row("spread of delay parameters", draws$reporting_changepoints$spread),
    purrr::imap_dfr(weekdays, ~f_row(.y, .x)))
}

#' Panels describing one analysis: cases with a projection, Rt, the reporting
#' delay and the other parameters of the model
#'
#' @return a named list of plots, without titles
bvd_changepoint_panels <- function(result, days_ahead = 14, day_first = 1) {
  draws <- result$draws
  dates <- result$analysis$dates
  date_origin <- min(dates$date) - 1
  date_now <- result$analysis$date_now
  blue <- "#0072B2"
  red <- "#D55E00"
  f_band <- function(colour = blue) {
    list(ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                              fill = colour, alpha = 0.25),
         ggplot2::geom_line(ggplot2::aes(y = .data$q50), colour = colour))
  }

  # (a) cases by onset date: reported, estimated and projected
  reported <- result$analysis$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::summarise(cases_reported = dplyr::last(.data$cases_reported))
  cases <- result$summary$cases %>%
    dplyr::left_join(reported, by = "time_onset") %>%
    dplyr::mutate(date = date_origin + .data$time_onset)
  projected <- project_cases(draws, result$serial_parameters, days_ahead,
                             cases_before = result$analysis$cases_before) %>%
    dplyr::mutate(date = date_origin + .data$time_onset)
  # joined to the last estimate so that the bands meet
  projected <- dplyr::bind_rows(
    dplyr::slice_max(dplyr::select(cases, dplyr::all_of(names(projected))),
                     .data$time_onset, n = 1),
    projected)
  panel_cases <- ggplot2::ggplot(cases, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_col(ggplot2::aes(y = .data$cases_reported), fill = "grey75",
                      width = 1) +
    f_band() +
    ggplot2::geom_ribbon(data = projected,
                         ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                         fill = red, alpha = 0.2) +
    ggplot2::geom_line(data = projected, ggplot2::aes(y = .data$q50),
                       colour = red, linetype = 2) +
    ggplot2::geom_vline(xintercept = date_now + 0.5, linetype = 3) +
    ggplot2::labs(
      x = "Onset date", y = "Confirmed cases",
      subtitle = paste0(
        "Grey: reported in the situation report of ", format(date_now, "%d %B %Y"),
        ". Blue: estimated cases. Red: projected for ", days_ahead,
        " days if Rt stays at its latest value.")) +
    theme_paper()

  # (b) Rt, and (c) the mean delay, with the probability of a change on each day
  f_changes <- function(starts) {
    starts %>%
      dplyr::filter(.data$time_onset >= day_first, .data$probability >= 0.02) %>%
      dplyr::mutate(date = date_origin + .data$time_onset)
  }
  Rt <- result$summary$Rt %>%
    dplyr::filter(.data$time_onset >= day_first) %>%
    dplyr::mutate(date = date_origin + .data$time_onset)
  Rt_changes <- f_changes(result$changes$Rt_starts)
  panel_Rt <- ggplot2::ggplot(Rt, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 3) +
    f_band() +
    ggplot2::geom_rug(data = Rt_changes, ggplot2::aes(alpha = .data$probability),
                      sides = "b", linewidth = 1.2, length = grid::unit(0.08, "npc")) +
    ggplot2::scale_alpha(range = c(0.15, 1), limits = c(0, 1), guide = "none") +
    ggplot2::labs(x = "Onset date", y = "Rt",
                  subtitle = "Marks below: probability of a change on the day (darker is higher).") +
    theme_paper()

  delay <- result$changes$reporting_days %>%
    dplyr::mutate(date = date_origin + .data$time_onset)
  delay_changes <- result$changes$reporting_starts %>%
    dplyr::filter(.data$probability >= 0.02) %>%
    dplyr::mutate(date = date_origin + .data$time_onset)
  panel_delay <- ggplot2::ggplot(delay, ggplot2::aes(x = .data$date)) +
    f_band() +
    ggplot2::geom_rug(data = delay_changes, ggplot2::aes(alpha = .data$probability),
                      sides = "b", linewidth = 1.2, length = grid::unit(0.08, "npc")) +
    ggplot2::scale_alpha(range = c(0.15, 1), limits = c(0, 1), guide = "none") +
    ggplot2::labs(x = "Onset date", y = "Mean delay, days",
                  subtitle = "Marks below: probability of a change on the day.") +
    theme_paper()

  # (d) the delay distribution for the earliest and latest onset days
  days <- seq(0, 35, by = 0.5)
  f_cdf <- function(time_onset, label) {
    parameters <- dplyr::filter(draws$reporting, .data$time_onset == !!time_onset)
    purrr::map_dfr(days, function(day) {
      p <- stats::pgamma(day, shape = (parameters$mean / parameters$sd)^2,
                         rate = parameters$mean / parameters$sd^2)
      dplyr::tibble(day = day, q05 = stats::quantile(p, 0.05),
                    q50 = stats::quantile(p, 0.5), q95 = stats::quantile(p, 0.95))
    }) %>%
      dplyr::mutate(onset = label)
  }
  day_last <- max(draws$reporting$time_onset)
  labels <- paste("Onset on", format(date_origin + c(1, day_last), "%d %b"))
  cdf <- dplyr::bind_rows(f_cdf(1, labels[1]), f_cdf(day_last, labels[2])) %>%
    dplyr::mutate(onset = factor(.data$onset, levels = labels))
  panel_cdf <- ggplot2::ggplot(cdf, ggplot2::aes(x = .data$day)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95,
                                      fill = .data$onset), alpha = 0.25) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50, colour = .data$onset)) +
    ggplot2::scale_colour_manual(values = c("#CC79A7", blue)) +
    ggplot2::scale_fill_manual(values = c("#CC79A7", blue)) +
    ggplot2::scale_y_continuous(labels = function(x) paste0(100 * x, "%"),
                                limits = c(0, 1)) +
    ggplot2::labs(x = "Days since onset", y = "Reported",
                  subtitle = "Proportion of cases reported within a number of days of onset.",
                  colour = NULL, fill = NULL) +
    theme_paper() +
    ggplot2::theme(legend.position = "inside",
                   legend.position.inside = c(0.75, 0.2))

  # (e) how complete the latest report is for each onset day
  completeness <- draws$cases %>%
    dplyr::left_join(reported, by = "time_onset") %>%
    dplyr::mutate(proportion = ifelse(.data$cases_true > 0,
                                      pmin(.data$cases_reported / .data$cases_true, 1),
                                      1)) %>%
    summarise_draws_by(.data$proportion, .data$time_onset) %>%
    dplyr::mutate(date = date_origin + .data$time_onset) %>%
    dplyr::filter(.data$date > date_now - 42)
  panel_complete <- ggplot2::ggplot(completeness, ggplot2::aes(x = .data$date)) +
    f_band() +
    ggplot2::scale_y_continuous(labels = function(x) paste0(100 * x, "%"),
                                limits = c(0, 1)) +
    ggplot2::labs(x = "Onset date", y = "Already reported",
                  subtitle = "Cases reported as a proportion of those estimated, last six weeks.") +
    theme_paper()

  # (f) effect of the day of the week of a report
  weekday_names <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  weekdays <- draws$reporting_effects %>%
    dplyr::select("iteration", dplyr::starts_with("weekday_")) %>%
    tidyr::pivot_longer(-"iteration", names_to = "weekday", values_to = "effect") %>%
    dplyr::mutate(weekday = as.integer(sub("weekday_", "", .data$weekday))) %>%
    summarise_draws_by(.data$effect, .data$weekday) %>%
    dplyr::mutate(weekday = factor(weekday_names[.data$weekday], levels = weekday_names))
  panel_weekday <- ggplot2::ggplot(weekdays, ggplot2::aes(x = .data$weekday)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 3) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                            colour = blue, linewidth = 0.8) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$q25, ymax = .data$q75),
                            colour = blue, linewidth = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$q50), colour = "white", size = 1.2) +
    ggplot2::scale_y_log10() +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::labs(x = "Day of the report", y = "Rate of reporting\n(relative, log scale)") +
    theme_paper()

  # (g) number of changes
  f_counts <- function(n, label) {
    dplyr::count(dplyr::tibble(n = n), .data$n, name = "draws") %>%
      dplyr::mutate(probability = .data$draws / sum(.data$draws), quantity = label)
  }
  counts <- dplyr::bind_rows(
    f_counts(draws$Rt_changepoints$n_changes, "Rt"),
    f_counts(draws$reporting_changepoints$n_changes, "Reporting delay")) %>%
    dplyr::mutate(quantity = factor(.data$quantity, levels = c("Rt", "Reporting delay")))
  panel_counts <- ggplot2::ggplot(counts, ggplot2::aes(x = factor(.data$n),
                                                       y = .data$probability)) +
    ggplot2::geom_col(fill = blue, alpha = 0.7) +
    ggplot2::facet_wrap(~quantity, scales = "free_x") +
    ggplot2::labs(x = "Number of changes", y = "Probability") +
    theme_paper()

  # (h) the remaining parameters, each on its own scale
  others <- dplyr::bind_rows(
    dplyr::tibble(parameter = "Overdispersion of\ntransmission (kappa)",
                  value = draws$overdispersion$overdispersion),
    dplyr::tibble(parameter = "Erroneous records per\n100 cases reported",
                  value = 100 * draws$revisions$eta),
    dplyr::tibble(parameter = "Days for which an erroneous\nrecord lasts (mean)",
                  value = 1 / draws$revisions$rho),
    dplyr::tibble(parameter = "Sd of delay, latest\nonset day (days)",
                  value = draws$reporting$sd[draws$reporting$time_onset == day_last])) %>%
    dplyr::mutate(parameter = factor(.data$parameter, levels = unique(.data$parameter)))
  panel_others <- ggplot2::ggplot(others, ggplot2::aes(x = .data$value)) +
    ggplot2::geom_density(fill = blue, colour = blue, alpha = 0.3) +
    ggplot2::facet_wrap(~parameter, scales = "free", nrow = 1) +
    ggplot2::labs(x = NULL, y = "Posterior density") +
    theme_paper() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank())

  list(cases = panel_cases, Rt = panel_Rt, delay = panel_delay, cdf = panel_cdf,
       complete = panel_complete, weekday = panel_weekday, counts = panel_counts,
       others = panel_others)
}

#' Titles panels in order and applies a common style
title_panels <- function(panels, titles) {
  purrr::map2(panels, seq_along(panels), function(panel, k) {
    panel + ggplot2::labs(title = paste0("(", letters[k], ") ", titles[k])) +
      ggplot2::theme(plot.title = ggplot2::element_text(face = "bold", size = 11),
                     plot.subtitle = ggplot2::element_text(size = 8.5))
  })
}

#' Main figure of one analysis: cases with a projection, Rt and the reporting
#' delay distribution
plot_bvd_changepoint_main <- function(result, ...) {
  panels <- bvd_changepoint_panels(result, ...)
  panels <- title_panels(
    panels[c("cases", "Rt", "cdf")],
    c("Cases by onset date", "Reproduction number", "Reporting delay distribution"))
  patchwork::wrap_plots(
    panels[[1]],
    patchwork::wrap_plots(panels[[2]], panels[[3]], nrow = 1),
    ncol = 1, heights = c(1.2, 1))
}

#' Further figure of one analysis: the mean delay over onset date, the
#' completeness of the latest report and the other parameters of the model
plot_bvd_changepoint_parameters <- function(result, ...) {
  panels <- bvd_changepoint_panels(result, ...)
  panels <- title_panels(
    panels[c("delay", "complete", "weekday", "counts", "others")],
    c("Mean reporting delay", "Completeness of the latest report",
      "Day of the week", "Changes found", "Other parameters"))
  patchwork::wrap_plots(
    patchwork::wrap_plots(panels[[1]], panels[[2]], nrow = 1),
    patchwork::wrap_plots(panels[[3]], panels[[4]], nrow = 1),
    panels[[5]],
    ncol = 1, heights = c(1, 0.9, 0.8))
}

#' Estimated cases as of each analysis date, as plot_bvd_cases(), for the model
#' with changes in Rt and in the delay
plot_bvd_changepoint_cases <- function(results) {
  df <- purrr::map_dfr(results, function(result) {
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
      dplyr::mutate(date_now = result$analysis$date_now)
  })
  df$panel <- format_date_now(df$date_now)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                         fill = "#009E73", alpha = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_later), colour = "black",
                       linewidth = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$cases_reported), colour = "#E69F00",
                       linewidth = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50), colour = "#009E73",
                       linewidth = 0.4) +
    ggplot2::facet_wrap(~panel, scales = "free_x", nrow = 2) +
    ggplot2::labs(
      x = "Onset date", y = "Confirmed cases",
      caption = paste("Orange: reported in the situation report of the analysis date.",
                      "Black: reported in the latest situation report.",
                      "Green line and band: posterior median and 90% interval.")) +
    theme_paper() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Scores of the estimates of recent counts at each analysis date
score_bvd_changepoints <- function(results, days_recent = 14) {
  purrr::map_dfr(results, function(result) {
    out <- dplyr::tibble(date_now = result$analysis$date_now,
                         failed = !is.null(result$summary$error),
                         minutes = result$summary$seconds / 60)
    if(out$failed)
      return(dplyr::mutate(out, error = result$summary$error))
    cases <- dplyr::left_join(result$summary$cases, result$analysis$later,
                              by = "time_onset")
    recent <- dplyr::filter(cases, .data$time_onset > max(cases$time_onset) - days_recent)
    scale <- mean(recent$cases_later)
    Rt <- dplyr::slice_max(result$summary$Rt, .data$time_onset, n = 1)
    delay <- dplyr::slice_max(result$changes$reporting_days, .data$time_onset, n = 1)
    dplyr::mutate(
      out,
      wis = mean(weighted_interval_score(recent$cases_later, recent$q05, recent$q25,
                                         recent$q50, recent$q75, recent$q95)) / scale,
      coverage_90 = mean(recent$cases_later >= recent$q05 &
                           recent$cases_later <= recent$q95),
      bias = mean(recent$q50 - recent$cases_later) / scale,
      Rt_latest = sprintf("%.2f (%.2f, %.2f)", Rt$q50[1], Rt$q05[1], Rt$q95[1]),
      delay_latest = sprintf("%.1f (%.1f, %.1f)", delay$q50[1], delay$q05[1],
                             delay$q95[1]),
      n_Rt_changes = mean(result$changes$Rt_n),
      n_delay_changes = mean(result$changes$reporting_n))
  })
}

# ---- posterior predictive checks ------------------------------------------------

#' Simulates the reported counts of every onset day on every later day
#'
#' Follows the simulator of the package (incidenceinflation::generate_snapshots)
#' day by day: genuine cases are newly reported, erroneous records are entered
#' and erroneous records are withdrawn.
#'
#' @param cases_true true cases for each onset day
#' @param reporting a tibble with columns mean and sd for each onset day
#' @param revision_parameters a list of eta, rho and report_multipliers
#' @return a matrix of reported counts by onset day (rows) and day (columns)
simulate_reported_matrix <- function(cases_true, reporting, revision_parameters) {
  n_days <- length(cases_true)
  log_undetected <- matrix(NA_real_, n_days, n_days)
  for(t in seq_len(n_days))
    log_undetected[t, t:n_days] <- incidenceinflation:::log_undetected_days(
      t:n_days, t, list(mean = reporting$mean[t], sd = reporting$sd[t]),
      revision_parameters)
  genuine <- rep(0, n_days)
  erroneous <- rep(0, n_days)
  reported <- matrix(NA_real_, n_days, n_days)
  diag(reported) <- 0
  for(day in seq_len(n_days)[-1]) {
    onsets <- seq_len(day - 1)
    before <- log_undetected[onsets, day - 1]
    after <- log_undetected[onsets, day]
    withdrawn <- stats::rbinom(length(onsets), erroneous[onsets],
                               revision_parameters$rho)
    entered <- stats::rpois(length(onsets), revision_parameters$eta *
                              cases_true[onsets] * (exp(before) - exp(after)))
    newly <- stats::rbinom(length(onsets), pmax(cases_true[onsets] - genuine[onsets], 0),
                           -expm1(after - before))
    genuine[onsets] <- genuine[onsets] + newly
    erroneous[onsets] <- erroneous[onsets] + entered - withdrawn
    reported[onsets, day] <- genuine[onsets] + erroneous[onsets]
  }
  reported
}

#' Statistics of a set of snapshots used in the checks of reporting
#'
#' @param df a tibble with columns time_onset, time_reported, cases_reported,
#' holding the same onset and report days for the data and for each replicate
reporting_check_statistics <- function(df) {
  increments <- df %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::mutate(increment = .data$cases_reported - dplyr::lag(.data$cases_reported),
                  latest = dplyr::last(.data$cases_reported),
                  delay = .data$time_reported - .data$time_onset) %>%
    dplyr::ungroup()
  steps <- dplyr::filter(increments, !is.na(.data$increment))
  by_report <- steps %>%
    dplyr::group_by(.data$time_reported) %>%
    dplyr::summarise(added = sum(.data$increment))
  # onset days old enough to be almost completely reported
  old <- dplyr::filter(increments,
                       .data$time_onset <= max(df$time_reported) - 28)
  f_within <- function(days) {
    within <- old %>%
      dplyr::filter(.data$delay <= days) %>%
      dplyr::group_by(.data$time_onset) %>%
      dplyr::summarise(cases = dplyr::last(.data$cases_reported),
                       latest = dplyr::first(.data$latest))
    sum(within$cases) / sum(within$latest)
  }
  list(
    by_report = by_report,
    scalars = c(
      "Proportion reported within 3 days of onset" = f_within(3),
      "Proportion reported within 7 days of onset" = f_within(7),
      "Proportion reported within 14 days of onset" = f_within(14),
      "Variation between reports in cases added (sd / mean)" =
        stats::sd(by_report$added) / mean(by_report$added),
      "Largest number of cases added to one onset day in one report" =
        max(steps$increment),
      "Proportion of updates in which a count does not change" =
        mean(steps$increment == 0),
      "Number of updates in which a count falls" = sum(steps$increment < 0)))
}

#' Variation in cases between the days of the week of onset
#'
#' The standard deviation, across the days of the week, of the mean number of
#' cases relative to the overall mean.
weekday_onset_variation <- function(cases, weekday) {
  means <- tapply(cases, weekday, mean)
  stats::sd(means) / mean(cases)
}

#' Posterior predictive checks of the model fitted to one analysis
#'
#' Reporting: for each draw, reported counts are simulated from the model
#' given the true cases, the delay parameters, the effects of the day of the
#' week and the revision parameters of that draw, and compared with the
#' counts in the situation reports. Transmission: for each draw, the cases of
#' each onset day are simulated from the renewal model given the cases before
#' it, Rt and the overdispersion of that draw, and compared with the true
#' cases of that draw.
#'
#' @return a list of: the counts in the latest report and the cases added in
#' each report, each with the quantiles of their replicates; and the scalar
#' statistics with the proportion of replicates which exceed them
bvd_changepoint_checks <- function(result, seed = 1) {
  set.seed(seed)
  draws <- result$draws
  observed <- result$analysis$snapshots %>%
    dplyr::filter(.data$time_reported > .data$time_onset) %>%
    dplyr::select("time_onset", "time_reported", "cases_reported")
  report_days <- sort(unique(result$analysis$snapshots$time_reported))
  weekday_first <- result$analysis$weekday_first
  n_days <- max(draws$cases$time_onset)
  cells <- cbind(observed$time_onset, observed$time_reported)
  weekday_onset <- (weekday_first - 1 + seq_len(n_days) - 1) %% 7 + 1
  w <- serial_weights(result$serial_parameters)

  statistics_observed <- reporting_check_statistics(observed)
  iterations <- unique(draws$cases$iteration)
  replicates <- purrr::map(iterations, function(i) {
    cases <- dplyr::arrange(dplyr::filter(draws$cases, .data$iteration == i),
                            .data$time_onset)$cases_true
    reporting <- dplyr::arrange(dplyr::filter(draws$reporting, .data$iteration == i),
                                .data$time_onset)
    effects <- dplyr::filter(draws$reporting_effects, .data$iteration == i) %>%
      dplyr::select(dplyr::starts_with("weekday_"))
    weekday_log_effects <- stats::setNames(
      log(as.numeric(effects[1, ])), sub("weekday_", "", names(effects)))
    revisions <- dplyr::filter(draws$revisions, .data$iteration == i)
    revision_parameters <- list(
      eta = revisions$eta, rho = revisions$rho,
      report_multipliers = incidenceinflation:::report_multipliers(
        report_days, weekday_log_effects, NULL, weekday_first))
    reported <- simulate_reported_matrix(cases, reporting, revision_parameters)
    replicate_df <- dplyr::mutate(observed, cases_reported = reported[cells])
    statistics <- reporting_check_statistics(replicate_df)

    # transmission: each onset day given the cases before it
    Rt <- dplyr::arrange(dplyr::filter(draws$Rt, .data$iteration == i),
                         .data$time_onset)$Rt
    kappa <- draws$overdispersion$overdispersion[draws$overdispersion$iteration == i]
    before <- result$analysis$cases_before
    padded <- c(rep(0, length(w)), before, cases)
    infectiousness <- purrr::map_dbl(seq_len(n_days), function(t) {
      sum(w * rev(padded[length(before) + t:(t + length(w) - 1)]))
    })
    informative <- infectiousness > 0
    cases_replicate <- stats::rnbinom(n_days, mu = Rt * infectiousness, size = kappa)
    f_dispersion <- function(x) {
      mean((x[informative] - Rt[informative] * infectiousness[informative])^2 /
             (Rt[informative] * infectiousness[informative]))
    }
    transmission <- c(
      "Variation in cases between days of the week of onset" =
        weekday_onset_variation(cases[informative], weekday_onset[informative]),
      "Dispersion of cases about the renewal mean (variance / mean)" =
        f_dispersion(cases))
    transmission_replicate <- c(
      weekday_onset_variation(cases_replicate[informative], weekday_onset[informative]),
      f_dispersion(cases_replicate))
    list(latest = dplyr::tibble(iteration = i, time_onset = seq_len(n_days),
                                cases_reported = reported[, n_days]),
         by_report = dplyr::mutate(statistics$by_report, iteration = i),
         scalars = statistics$scalars,
         transmission = transmission,
         transmission_replicate = transmission_replicate)
  })

  latest_observed <- result$analysis$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::summarise(observed = dplyr::last(.data$cases_reported),
                     time_latest = dplyr::last(.data$time_reported))
  latest <- purrr::map_dfr(replicates, "latest") %>%
    summarise_draws_by(.data$cases_reported, .data$time_onset) %>%
    dplyr::left_join(latest_observed, by = "time_onset")
  by_report <- purrr::map_dfr(replicates, "by_report") %>%
    summarise_draws_by(.data$added, .data$time_reported) %>%
    dplyr::left_join(dplyr::rename(statistics_observed$by_report, observed = "added"),
                     by = "time_reported")

  scalars_replicate <- do.call(rbind, purrr::map(replicates, "scalars"))
  scalars <- purrr::map_dfr(seq_along(statistics_observed$scalars), function(k) {
    dplyr::tibble(part = "Reporting",
                  statistic = names(statistics_observed$scalars)[k],
                  iteration = iterations,
                  observed = statistics_observed$scalars[[k]],
                  replicate = scalars_replicate[, k])
  })
  # for transmission the 'observed' value is that of the true cases of the
  # draw, which differs between draws
  transmission <- do.call(rbind, purrr::map(replicates, "transmission"))
  transmission_replicate <- do.call(rbind, purrr::map(replicates, "transmission_replicate"))
  scalars <- dplyr::bind_rows(scalars, purrr::map_dfr(
    seq_len(ncol(transmission)), function(k) {
      dplyr::tibble(part = "Transmission", statistic = colnames(transmission)[k],
                    iteration = iterations, observed = transmission[, k],
                    replicate = transmission_replicate[, k])
    }))
  summary <- scalars %>%
    dplyr::group_by(.data$part, .data$statistic) %>%
    dplyr::summarise(
      observed = stats::median(.data$observed),
      replicate_q05 = stats::quantile(.data$replicate, 0.05),
      replicate_q50 = stats::quantile(.data$replicate, 0.5),
      replicate_q95 = stats::quantile(.data$replicate, 0.95),
      # proportion of replicates at least as large as the observed value
      p_value = mean(.data$replicate >= .data$observed),
      .groups = "drop")
  list(latest = latest, by_report = by_report, scalars = scalars, summary = summary,
       dates = result$analysis$dates, date_now = result$analysis$date_now)
}

#' Figure of the posterior predictive checks
plot_bvd_changepoint_checks <- function(checks) {
  date_origin <- min(checks$dates$date) - 1
  blue <- "#0072B2"
  latest <- dplyr::mutate(checks$latest, date = date_origin + .data$time_onset)
  panel_latest <- ggplot2::ggplot(latest, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                         fill = blue, alpha = 0.25) +
    ggplot2::geom_line(ggplot2::aes(y = .data$q50), colour = blue) +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed), size = 0.8) +
    ggplot2::labs(x = "Onset date", y = "Confirmed cases",
                  subtitle = "Points: counts in the latest report. Blue: median and 90% interval of replicated counts.") +
    theme_paper()
  by_report <- dplyr::mutate(checks$by_report, date = date_origin + .data$time_reported)
  panel_report <- ggplot2::ggplot(by_report, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$q05, ymax = .data$q95),
                            colour = blue, alpha = 0.4, linewidth = 2) +
    ggplot2::geom_point(ggplot2::aes(y = .data$q50), colour = blue, shape = 95, size = 5) +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed), size = 1) +
    ggplot2::labs(x = "Date of situation report", y = "Cases added since the report before",
                  subtitle = "Points: cases added in each report. Blue: median and 90% interval of replicates.") +
    theme_paper()
  scalars <- checks$scalars %>%
    dplyr::mutate(statistic = factor(.data$statistic, levels = unique(.data$statistic)))
  observed <- scalars %>%
    dplyr::group_by(.data$statistic) %>%
    dplyr::summarise(observed = stats::median(.data$observed),
                     p_value = mean(.data$replicate >= .data$observed))
  panel_scalars <- ggplot2::ggplot(scalars, ggplot2::aes(x = .data$replicate)) +
    ggplot2::geom_histogram(bins = 25, fill = blue, alpha = 0.5) +
    ggplot2::geom_vline(data = observed, ggplot2::aes(xintercept = .data$observed)) +
    ggplot2::geom_text(data = observed,
                       ggplot2::aes(x = Inf, y = Inf,
                                    label = sprintf("p = %.2f", .data$p_value)),
                       hjust = 1.1, vjust = 1.5, size = 3) +
    ggplot2::facet_wrap(~statistic, scales = "free", ncol = 3,
                        labeller = ggplot2::label_wrap_gen(34)) +
    ggplot2::labs(x = NULL, y = "Replicates",
                  subtitle = "Histogram: replicates. Line: observed value. p: proportion of replicates at least as large.") +
    theme_paper() +
    ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                   axis.ticks.y = ggplot2::element_blank(),
                   strip.text = ggplot2::element_text(size = 8, colour = "grey10"))
  panels <- title_panels(
    list(panel_latest, panel_report, panel_scalars),
    c("Counts in the latest report", "Cases added in each report",
      "Summary statistics"))
  patchwork::wrap_plots(panels, ncol = 1, heights = c(1, 1, 2))
}

# ---- tables and numbers for the write-up -----------------------------------------
# The note (docs/bvd_changepoints.tex) reads its tables and the numbers quoted
# in its text from files written here, so that they change with the results.

#' Formats a median and 90% interval as "m (lo to hi)"
format_interval <- function(values, digits = 2, sep = " to ") {
  q <- stats::quantile(values, c(0.5, 0.05, 0.95))
  f <- function(x) formatC(x, format = "f", digits = digits)
  paste0(f(q[1]), " (", f(q[2]), sep, f(q[3]), ")")
}

#' A LaTeX command holding a value
tex_command <- function(name, value) {
  paste0("\\newcommand{\\", name, "}{", value, "}")
}

#' Writes the tables and numbers used by the note
#'
#' @param results the combined results for each analysis date
#' @param scores as returned by score_bvd_changepoints()
#' @param diagnostics convergence diagnostics for every date
#' @param checks as returned by bvd_changepoint_checks() for the latest date
#' @return the paths of the files written
write_bvd_tables <- function(results, scores, diagnostics, checks,
                             dir = "outputs/tables") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  f_number <- function(x, digits) formatC(x, format = "f", digits = digits)
  f_date <- function(date) trimws(format(as.Date(date), "%e %B"))
  latest <- results[[which.max(purrr::map_dbl(results, ~as.numeric(.$analysis$date_now)))]]
  date_latest <- latest$analysis$date_now

  # estimates made on each analysis date
  scores <- dplyr::arrange(scores, .data$date_now)
  f_tex_interval <- function(x) gsub("%", "\\\\%", x)
  rows <- purrr::map_chr(seq_len(nrow(scores)), function(i) {
    row <- scores[i, ]
    scored <- row$date_now < date_latest
    paste(
      f_date(row$date_now),
      ifelse(scored, f_number(row$wis, 3), ""),
      ifelse(scored, paste0(round(100 * row$coverage_90), "\\%"), ""),
      ifelse(scored, sprintf("$%+d\\%%$", as.integer(round(100 * row$bias))), ""),
      row$Rt_latest, row$delay_latest, sep = " & ")
  })
  path_dates <- file.path(dir, "bvd_dates.tex")
  writeLines(c(
    "\\begin{tabular}{lccccc}", "\\toprule",
    "Analysis date & Score & Coverage of & Bias & $R_t$, latest onset day & Mean delay, latest \\\\",
    " & & 90\\% intervals & & & onset day (days) \\\\", "\\midrule",
    paste0(rows, " \\\\"), "\\bottomrule", "\\end{tabular}"), path_dates)

  # posterior predictive checks
  order_checks <- c(
    "Proportion reported within 3 days of onset",
    "Proportion reported within 7 days of onset",
    "Proportion reported within 14 days of onset",
    "Variation between reports in cases added (sd / mean)",
    "Largest number of cases added to one onset day in one report",
    "Proportion of updates in which a count does not change",
    "Number of updates in which a count falls",
    "Dispersion of cases about the renewal mean (variance / mean)",
    "Variation in cases between days of the week of onset")
  digits_checks <- c(3, 3, 3, 3, 0, 3, 0, 1, 3)
  summary <- checks$summary[match(order_checks, checks$summary$statistic), ]
  rows <- purrr::map_chr(seq_len(nrow(summary)), function(i) {
    d <- digits_checks[i]
    paste0(summary$statistic[i], " & ", f_number(summary$observed[i], d), " & ",
           f_number(summary$replicate_q50[i], d), " (",
           f_number(summary$replicate_q05[i], d), ", ",
           f_number(summary$replicate_q95[i], d), ") & ",
           f_number(summary$p_value[i], 2), " \\\\")
  })
  path_checks <- file.path(dir, "bvd_checks.tex")
  writeLines(c(
    "\\begin{tabular}{lccc}", "\\toprule",
    "Statistic & Observed & Replicates (median, 90\\% interval) & $p$ \\\\",
    "\\midrule", "\\emph{Reporting} \\\\", rows[1:7], "\\addlinespace",
    "\\emph{Transmission} \\\\", rows[8:9], "\\bottomrule", "\\end{tabular}"),
    path_checks)

  # convergence
  dates <- sort(unique(as.Date(diagnostics$date_now)))
  f_rhat <- function(quantity) {
    values <- purrr::map_dbl(dates, function(date) {
      rows <- diagnostics[as.Date(diagnostics$date_now) == date &
                            grepl(quantity, diagnostics$quantity), ]
      max(rows$rhat)
    })
    stats::setNames(values, dates)
  }
  rhat <- list(
    "$R_t$, latest onset day" = f_rhat("^Rt, latest"),
    "Cases, latest 14 onset days in total" = f_rhat("^Cases, latest"),
    "Cases, worst single onset day" = purrr::map_dbl(dates, function(date) {
      diagnostics$rhat_cases_max[as.Date(diagnostics$date_now) == date][1]
    }),
    "Number of changes in $R_t$" = f_rhat("^Number of changes in Rt"),
    "$\\kappa$" = f_rhat("^Overdispersion"),
    "$\\eta$" = f_rhat("^eta$"),
    "$\\rho$" = f_rhat("^rho$"),
    "Mean delay, latest onset day" = f_rhat("^Mean delay"),
    "Standard deviation of delay, latest onset day" = f_rhat("^Sd of delay"),
    "Number of changes in delay" = f_rhat("^Number of changes in delay"),
    "Effects of day of week (worst)" = f_rhat("^Day of week"))
  rows <- purrr::imap_chr(rhat, ~paste0(.y, " & ", paste(f_number(.x, 2), collapse = " & "),
                                        " \\\\"))
  path_rhat <- file.path(dir, "bvd_rhat.tex")
  writeLines(c(
    paste0("\\begin{tabular}{l", strrep("c", length(dates)), "}"), "\\toprule",
    paste0(" & \\multicolumn{", length(dates), "}{c}{Analysis date} \\\\"),
    paste0("Quantity & ", paste(trimws(format(dates, "%e %b")), collapse = " & "), " \\\\"),
    "\\midrule", rows[1:7], "\\addlinespace", rows[8:11], "\\bottomrule",
    "\\end{tabular}"), path_rhat)

  # numbers quoted in the text
  draws <- latest$draws
  day_last <- max(draws$Rt$time_onset)
  delay <- dplyr::filter(draws$reporting, .data$time_onset == day_last)
  weekdays <- draws$reporting_effects
  weekday_names <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  projected <- project_cases(draws, latest$serial_parameters,
                             cases_before = latest$analysis$cases_before)
  recent <- dplyr::slice_max(latest$summary$cases, .data$time_onset, n = 5)
  f_p <- function(statistic) {
    f_number(checks$summary$p_value[checks$summary$statistic == statistic], 2)
  }
  scored <- dplyr::filter(scores, .data$date_now < date_latest)
  core <- c(rhat[[1]], rhat[[3]], rhat[[4]], rhat[[6]], rhat[[7]])
  kappa <- stats::median(draws$overdispersion$overdispersion)
  numbers <- c(
    tex_command("bvdChains", latest$n_chains),
    tex_command("bvdIterations", latest$summary$niterations),
    tex_command("bvdDraws", length(unique(draws$cases$iteration))),
    tex_command("bvdRt", format_interval(draws$Rt$Rt[draws$Rt$time_onset == day_last])),
    tex_command("bvdRtFirst", f_number(stats::median(
      draws$Rt$Rt[draws$Rt$time_onset == 1]), 2)),
    tex_command("bvdRtChanges", f_number(mean(draws$Rt_changepoints$n_changes), 1)),
    tex_command("bvdRtNoChange", f_number(mean(draws$Rt_changepoints$n_changes == 0), 2)),
    tex_command("bvdDelayMean", format_interval(delay$mean, 1)),
    tex_command("bvdDelaySd", format_interval(delay$sd, 1)),
    tex_command("bvdDelayChanges", f_number(mean(draws$reporting_changepoints$n_changes), 1)),
    tex_command("bvdDelayNoChange", f_number(
      mean(draws$reporting_changepoints$n_changes == 0), 2)),
    tex_command("bvdKappa", format_interval(draws$overdispersion$overdispersion, 0)),
    tex_command("bvdVarianceRatio", f_number(1 + 50 / kappa, 1)),
    tex_command("bvdEta", format_interval(draws$revisions$eta, 3)),
    tex_command("bvdErroneousPerHundred", f_number(
      100 * stats::median(draws$revisions$eta), 0)),
    tex_command("bvdRho", format_interval(draws$revisions$rho, 3)),
    tex_command("bvdErroneousDays", f_number(stats::median(1 / draws$revisions$rho), 0)),
    tex_command("bvdRecentMedians", paste(round(min(recent$q50)), "and",
                                          round(max(recent$q50)))),
    tex_command("bvdRecentInterval", paste(round(min(recent$q05)), "to",
                                           round(max(recent$q95)))),
    tex_command("bvdProjection", round(stats::median(projected$q50))),
    tex_command("bvdProjectionInterval", paste(round(stats::median(projected$q05)), "to",
                                               round(stats::median(projected$q95)))),
    tex_command("bvdCoverageMin", paste0(round(100 * min(scored$coverage_90)), "\\%")),
    tex_command("bvdCoverageMax", paste0(round(100 * max(scored$coverage_90)), "\\%")),
    tex_command("bvdBiasMax", paste0(round(100 * max(abs(scored$bias))), "\\%")),
    tex_command("bvdPthree", f_p(order_checks[1])),
    tex_command("bvdPseven", f_p(order_checks[2])),
    tex_command("bvdPfourteen", f_p(order_checks[3])),
    tex_command("bvdPvariation", f_p(order_checks[4])),
    tex_command("bvdPdispersion", f_p(order_checks[8])),
    tex_command("bvdPweekdayOnset", f_p(order_checks[9])),
    tex_command("bvdRhatCoreMax", f_number(max(core), 2)),
    tex_command("bvdRhatDelayChangesMax", f_number(max(rhat[[10]]), 2)),
    tex_command("bvdRhatDelayMeanMax", f_number(max(rhat[[8]], rhat[[9]]), 2)),
    tex_command("bvdRhatWeekdayMax", f_number(max(rhat[[11]]), 2)),
    tex_command("bvdRhatKappaMax", f_number(max(rhat[[5]]), 2)))
  for(k in seq_along(weekday_names)) {
    column <- paste0("weekday_", k)
    if(column %in% names(weekdays))
      numbers <- c(numbers, tex_command(paste0("bvdPsi", weekday_names[k]),
                                        format_interval(weekdays[[column]])))
  }
  path_numbers <- file.path(dir, "bvd_numbers.tex")
  writeLines(c("% written by the pipeline (write_bvd_tables): do not edit by hand",
               numbers), path_numbers)
  c(path_dates, path_checks, path_rhat, path_numbers)
}

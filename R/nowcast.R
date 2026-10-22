# A data-driven nowcast of the counts by onset day (stan/nowcast.stan),
# beside the mechanistic model: the delay from onset to a count is learned
# from the reporting triangle and may change smoothly over onset time, each
# report has an effect of its own (which takes up a report clearing a
# backlog), and the new counts between reports are additions less removals,
# so that the downward revisions are part of the model.

#' The new counts of each onset day between consecutive reports
#'
#' The first report of an onset day gives its count for the delays from 0
#' to that report (for the onset days the correction relabelled, the first
#' report of the corrected series); each later report the change since the
#' report before.
#'
#' @param snapshots a tibble with columns time_onset, time_reported and the
#'   count named by column (as analysis$snapshots)
#' @param column the name of the count
#' @return a tibble of t, lo, hi (the first and last delay of the interval),
#'   time_reported and n (the new count, which may be negative)
nowcast_triangle <- function(snapshots, column) {
  snapshots %>%
    dplyr::arrange(.data$time_onset, .data$time_reported) %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::mutate(
      count = .data[[column]],
      n = .data$count - dplyr::lag(.data$count, default = 0L),
      lo = dplyr::if_else(dplyr::row_number() == 1, 0L,
                          dplyr::lag(.data$time_reported) - .data$time_onset + 1L),
      hi = .data$time_reported - .data$time_onset) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(t = .data$time_onset, lo = .data$lo, hi = .data$hi,
                     time_reported = .data$time_reported, n = .data$n,
                     count = .data$count)
}

#' Knots of the basis in delay: quantiles of the delays at which records were added
#'
#' Each rise in a count between consecutive reports is taken as records added
#' at the delay of the later report, weighted by the size of the rise. First
#' counts of onset days made more than first_max days after onset are left
#' out, since the delays of their records are not known.
#'
#' @param tri as nowcast_triangle
#' @param probs the quantiles
#' @param first_max the longest delay of a first count which is used
#' @return the delays (in days) of the interior knots
nowcast_delay_knots <- function(tri, probs = c(0.25, 0.5, 0.75), first_max = 7) {
  added <- dplyr::filter(tri, .data$n > 0, !(.data$lo == 0 & .data$hi > first_max))
  o <- order(added$hi)
  cumulative <- cumsum(added$n[o]) / sum(added$n)
  knots <- vapply(probs, function(p) added$hi[o][which(cumulative >= p)[1]], numeric(1))
  knots <- unique(knots)
  knots[knots > 0 & knots < max(tri$hi)]
}

#' The data for stan/nowcast.stan
#'
#' The basis in delay is cubic in log(1 + d), with interior knots at quantiles
#' of the delays at which records were added (nowcast_delay_knots); the basis
#' in onset time is cubic, with interior knots every onset_knot_days days.
#'
#' @inheritParams nowcast_triangle
#' @param day_target the day (counted as the onset days are) to which counts
#'   are projected, or 0 for none
#' @param onset_knot_days the days of onset time between knots of h
#' @param priors a named list of the prior scales
#' @return a named list
nowcast_stan_data <- function(snapshots, column, day_target = 0L, onset_knot_days = 14,
                              priors = nowcast_priors(column)) {
  tri <- nowcast_triangle(snapshots, column)
  n_days <- max(tri$t)
  stopifnot(identical(sort(unique(tri$t)), seq_len(n_days)))
  delay_max <- max(tri$hi)
  reports <- sort(unique(tri$time_reported))
  delay_knots <- nowcast_delay_knots(tri)
  Bd <- splines::bs(log1p(0:delay_max), knots = log1p(delay_knots), degree = 3,
                    intercept = TRUE, Boundary.knots = c(0, log1p(delay_max)))
  onset_knots <- seq(1 + onset_knot_days, n_days - 1, by = onset_knot_days)
  Bt <- splines::bs(seq_len(n_days), knots = onset_knots, degree = 3, intercept = TRUE,
                    Boundary.knots = c(1, n_days))
  last <- tri %>% dplyr::group_by(.data$t) %>%
    dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
    dplyr::ungroup() %>% dplyr::arrange(.data$t)
  c(list(
    T = n_days, D = delay_max, Kt = ncol(Bt), Kd = ncol(Bd),
    Bt = unclass(Bt), Bd = unclass(Bd),
    R = length(reports), N = nrow(tri), t = tri$t, lo = tri$lo, hi = tri$hi,
    r = match(tri$time_reported, reports), report_day = as.integer(reports), n = tri$n,
    # the removals summed over, enough for removals of up to about half of
    # the additions
    w_max = pmax(0L, -tri$n) + 6L + as.integer(ceiling(0.5 * abs(tri$n))),
    count_last = last$count, delay_last = last$hi,
    day_target = as.integer(day_target),
    log_p_ref = nowcast_reference_delay(delay_max, priors$reference_mean, priors$reference_sd),
    delay_knots = delay_knots, onset_knots = onset_knots),
    priors[setdiff(names(priors), c("reference_mean", "reference_sd"))])
}

#' The log probabilities of the reference delay distribution
#'
#' A gamma distribution, discretised to whole days as the reporting delay of
#' the mechanistic model is (the probability of (d - 1/2, d + 1/2], from 0),
#' and renormalised over the delays 0 to D.
#'
#' @param D the longest delay
#' @param mean,sd of the gamma distribution, in days
#' @return a vector of log probabilities for the delays 0 to D
nowcast_reference_delay <- function(D, mean, sd) {
  shape <- mean^2 / sd^2
  rate <- mean / sd^2
  p <- diff(stats::pgamma(c(0, seq_len(D + 1) - 0.5), shape, rate))
  log(p / sum(p))
}

#' Priors of the nowcast
#'
#' The scales of the half-normal priors; the prior on the departures of the
#' delay distribution from a reference (beta_g_scale), which is a gamma
#' distribution with the mean and sd of the prior centre of the reporting
#' delay of the mechanistic model (7 and 10 days) for cases, and, for deaths,
#' with a mean of 13 days (the time from onset to death of 9.3 days and the
#' prior centre of 4 days of the delay from death to recording); and a
#' log-normal prior on the overdispersion phi, centred on 20 (the prior mean
#' of the overdispersion of transmission in the mechanistic model).
#'
#' @param column the count: "cases_reported" or "deaths_reported"
#' @return a named list
nowcast_priors <- function(column = "cases_reported") {
  is_deaths <- column == "deaths_reported"
  list(sigma_lambda_scale = 0.3, sigma_g_scale = 0.03, tau_s_scale = 0.05,
       kappa_scale = 2,
       # the delay of deaths changed more over the outbreak (the backlog)
       tau_t_scale = if(is_deaths) 0.5 else 0.2,
       sigma_u_scale = 0.5, rho_scale = 0.25,
       beta_g_scale = 3, log_phi_mu = log(20), log_phi_sd = 1.5,
       reference_mean = if(is_deaths) 13 else 7, reference_sd = 10,
       # stan/nowcast_tail.stan: the cut-off delay, beyond which about 5% of
       # cases and 8% of deaths are added, and the prior on that share
       d_c = if(is_deaths) 42L else 28L,
       q_alpha = 2, q_beta = if(is_deaths) 23 else 38)
}

#' Initial values of the nowcast
#'
#' Stan's default (uniform on (-2, 2) unconstrained) can start the walk of
#' the growth rate with a sd of several per day, which summed twice over the
#' onset days overflows lambda; so the chains start near the level of the
#' first counts, with the scales at their prior scales and small z.
#'
#' @param data as nowcast_stan_data
#' @param chains the number of chains
#' @param seed for the jitter
#' @param parameters the names of the model's parameters: the values of
#'   others are left out (stan/nowcast_simple.stan has fewer)
#' @return a list of lists, one for each chain
nowcast_inits <- function(data, chains, seed = 1, parameters = NULL) {
  withr::with_seed(seed, lapply(seq_len(chains), function(k) {
    f_z <- function(n) stats::rnorm(n, 0, 0.1)
    first <- data$n[data$t <= 7 & data$lo == 0]
    list(log_lambda_1 = log(mean(c(first, 1)) + 1), g_1 = 0,
         z_lambda = f_z(data$T - 1), z_g = f_z(data$T - 2),
         sigma_lambda = data$sigma_lambda_scale / 2, sigma_g = data$sigma_g_scale / 2,
         beta_g_free = f_z(data$Kd - 1),
         z_h = matrix(f_z(data$Kt * (data$Kd - 1)), data$Kt),
         tau_t = data$tau_t_scale / 2, z_s = f_z(data$R - 1),
         tau_s = data$tau_s_scale / 2, z_u = f_z(data$R),
         sigma_u = data$sigma_u_scale / 2, kappa = 1, log_phi = data$log_phi_mu, rho = 0.05,
         q = data$q_alpha / (data$q_alpha + data$q_beta))
  }) %>% lapply(function(x) if(is.null(parameters)) x else x[intersect(names(x), parameters)]))
}

#' Fits the nowcast to the reports up to a date
#'
#' @param analysis as prepare_bvd_deaths_analysis
#' @inheritParams nowcast_stan_data
#' @param date_target the date to which counts are projected
#' @param chains,iter_warmup,iter_sampling,seed,adapt_delta as cmdstanr's sample
#' @return a named list: 'by_day' (the projected count of each onset day,
#'   with the count now, and the mean delay), 'parameters' (summaries of the
#'   scalar parameters), 'diagnostics' and 'draws_total' (the projected total)
fit_nowcast <- function(analysis, column, date_target, chains = 4,
                        iter_warmup = 500, iter_sampling = 500, seed = 1, adapt_delta = 0.95,
                        model_file = "stan/nowcast.stan", output_dir = NULL) {
  day_target <- as.integer(as.Date(date_target) - analysis$dates$date[1]) + 1L
  data <- nowcast_stan_data(analysis$snapshots, column, day_target)
  model <- cmdstanr::cmdstan_model(model_file)
  time_start <- Sys.time()
  fit <- model$sample(data = data, chains = chains, parallel_chains = chains,
                      iter_warmup = iter_warmup, iter_sampling = iter_sampling,
                      adapt_delta = adapt_delta,
                      init = nowcast_inits(data, chains, seed, names(model$variables()$parameters)),
                      seed = seed, refresh = 0, show_messages = FALSE,
                      output_dir = output_dir)
  if(any(fit$return_codes() != 0))
    stop("A chain of the nowcast failed: ", paste(fit$return_codes(), collapse = " "))
  minutes <- as.numeric(Sys.time() - time_start, units = "mins")
  summarise_nowcast(fit, data, analysis, column, date_target, minutes)
}

#' Summarises a fit of the nowcast
#'
#' @param fit a cmdstanr fit of stan/nowcast.stan (or one read back from its
#'   files with cmdstanr::as_cmdstan_fit)
#' @param data its data, as nowcast_stan_data
#' @inheritParams fit_nowcast
#' @param minutes the time it took
#' @return as fit_nowcast
summarise_nowcast <- function(fit, data, analysis, column, date_target, minutes = NA,
                              suffix = "", extra = character(0)) {
  draws_projected <- posterior::as_draws_matrix(fit$draws(paste0("projected", suffix)))
  draws_delay <- posterior::as_draws_matrix(fit$draws(paste0("mean_delay", suffix)))
  f_q <- function(m, p) apply(m, 2, stats::quantile, p, names = FALSE)
  by_day <- dplyr::tibble(
    time_onset = seq_len(data$T),
    date = analysis$dates$date[seq_len(data$T)],
    now = data$count_last,
    p05 = f_q(draws_projected, 0.05), p50 = f_q(draws_projected, 0.5),
    p95 = f_q(draws_projected, 0.95),
    mean_delay = f_q(draws_delay, 0.5), mean_delay_p05 = f_q(draws_delay, 0.05),
    mean_delay_p95 = f_q(draws_delay, 0.95))
  # the forms of the model have different parameters; in the joint model
  # those of each series end in its suffix, and some are shared
  variables <- fit$metadata()$stan_variables
  f_named <- function(names) intersect(c(names, paste0(names, suffix)), variables)
  scalars <- c(f_named(c("sigma_lambda", "sigma_g", "tau_t", "tau_s", "sigma_u", "kappa",
                         "phi", "rho", "q")), intersect(extra, variables))
  diagnostics <- fit$diagnostic_summary(quiet = TRUE)
  summary_all <- fit$summary(c(scalars, f_named(c("log_lambda", "z_h", "s", "logit_cfr")),
                               intersect(extra, variables)))
  # the projected count of each onset week (weeks from Monday), for the case
  # fatality ratio
  week <- as.Date(cut(analysis$dates$date[seq_len(data$T)], "week"))
  draws_weekly <- t(rowsum(t(unclass(draws_projected)), week))
  colnames(draws_weekly) <- as.character(sort(unique(week)))
  list(column = column, date_now = analysis$date_now, date_target = as.Date(date_target),
       by_day = by_day,
       parameters = fit$summary(scalars) %>%
         dplyr::mutate(variable = sub(paste0(suffix, "(\\[|$)"), "\\1", .data$variable)),
       draws_total = rowSums(draws_projected),
       draws_weekly = draws_weekly,
       diagnostics = list(minutes = minutes,
                          divergences = sum(diagnostics$num_divergent),
                          max_treedepth = sum(diagnostics$num_max_treedepth),
                          rhat_max = max(summary_all$rhat, na.rm = TRUE),
                          ess_bulk_min = min(summary_all$ess_bulk, na.rm = TRUE)))
}

#' Scores a nowcast against the counts of a later report
#'
#' @param nowcast as fit_nowcast, projected to the date of the later report
#' @param snapshots_later the snapshots of an analysis to that date
#' @return a named list: 'by_day' (the nowcast with the count shown later)
#'   and 'summary' (the coverage of the 90% intervals and the totals)
score_nowcast <- function(nowcast, snapshots_later) {
  later <- snapshots_later %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(time_onset = .data$time_onset, later = .data[[nowcast$column]])
  by_day <- dplyr::left_join(nowcast$by_day, later, by = "time_onset") %>%
    dplyr::mutate(inside = .data$later >= .data$p05 & .data$later <= .data$p95)
  recent <- by_day$time_onset > max(by_day$time_onset) - 28
  q <- stats::quantile(nowcast$draws_total, c(0.05, 0.5, 0.95), names = FALSE)
  list(by_day = by_day,
       summary = dplyr::tibble(
         column = nowcast$column, date_now = nowcast$date_now,
         total_now = sum(by_day$now), total_p05 = q[1], total_p50 = q[2],
         total_p95 = q[3], total_later = sum(by_day$later),
         coverage_all = mean(by_day$inside), coverage_recent = mean(by_day$inside[recent]),
         minutes = nowcast$diagnostics$minutes,
         divergences = nowcast$diagnostics$divergences,
         rhat_max = nowcast$diagnostics$rhat_max))
}

#' Writes the scores of the nowcasts and plots them against the later counts
#'
#' @param scores a list of results of score_nowcast
#' @param out the folder
#' @return the paths of the files written
write_nowcast_outputs <- function(scores, out) {
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  summary <- dplyr::bind_rows(lapply(scores, `[[`, "summary"))
  by_day <- dplyr::bind_rows(lapply(scores, function(s)
    dplyr::mutate(s$by_day, column = s$summary$column, date_now = s$summary$date_now)))
  paths <- file.path(out, c("summary.csv", "by_day.csv"))
  utils::write.csv(summary, paths[1], row.names = FALSE)
  utils::write.csv(by_day, paths[2], row.names = FALSE)
  for(col in unique(by_day$column)) {
    df <- dplyr::filter(by_day, .data$column == col) %>%
      dplyr::mutate(fit = factor(format(.data$date_now, "Fit to %d %b"),
                                 levels = format(sort(unique(.data$date_now)), "Fit to %d %b")))
    g <- ggplot2::ggplot(df, ggplot2::aes(.data$date)) +
      ggplot2::geom_col(ggplot2::aes(y = .data$now, fill = "Shown in the last report fitted"),
                        width = 1) +
      ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$p05, ymax = .data$p95,
                                        fill = "Nowcast to the last report (90% interval)"),
                           alpha = 0.6) +
      ggplot2::geom_line(ggplot2::aes(y = .data$p50, colour = "Nowcast (median)")) +
      ggplot2::geom_line(ggplot2::aes(y = .data$later, colour = "Shown in the last report")) +
      ggplot2::facet_wrap(~fit, ncol = 1, scales = "free_y") +
      ggplot2::scale_fill_manual(NULL, values = c("#a6c8f0", "grey80")) +
      ggplot2::scale_colour_manual(NULL, values = c("#1f4e9c", "black")) +
      ggplot2::labs(x = "Onset date", y = sub("_reported$", "", col)) +
      ggplot2::theme_bw() + ggplot2::theme(legend.position = "bottom")
    path <- file.path(out, paste0("nowcast_", sub("_reported$", "", col), ".png"))
    ggplot2::ggsave(path, g, width = 9, height = 2.6 * dplyr::n_distinct(df$fit) + 1)
    paths <- c(paths, path)
  }
  paths
}

#' The data for stan/nowcast_joint.stan
#'
#' Those of nowcast_stan_data for cases and for deaths, with the suffixes _c
#' and _d, and the onset days, longest delay, reports and basis in onset time
#' shared. Cases have the common tail beyond their d_c; deaths have none (d_c
#' set to the longest delay).
#'
#' @inheritParams nowcast_stan_data
#' @return a named list, with elements 'cases' and 'deaths' holding the data
#'   of each series as nowcast_stan_data gives them
nowcast_joint_stan_data <- function(snapshots, day_target = 0L, onset_knot_days = 14) {
  cases <- nowcast_stan_data(snapshots, "cases_reported", day_target, onset_knot_days)
  deaths <- nowcast_stan_data(snapshots, "deaths_reported", day_target, onset_knot_days)
  deaths$d_c <- deaths$D
  stopifnot(cases$T == deaths$T, cases$D == deaths$D, cases$R == deaths$R,
            isTRUE(all.equal(cases$Bt, deaths$Bt)))
  shared <- c("T", "D", "Kt", "Bt", "R", "day_target")
  own <- c("Kd", "Bd", "N", "t", "lo", "hi", "r", "n", "w_max", "count_last",
           "delay_last", "log_p_ref", "d_c", "q_alpha", "q_beta", "beta_g_scale",
           "log_phi_mu", "log_phi_sd", "tau_t_scale", "sigma_u_scale", "rho_scale")
  f_own <- function(x, suffix) stats::setNames(x[own], paste0(own, suffix))
  c(cases[shared], f_own(cases, "_c"), list(sigma_lambda_scale_c = cases$sigma_lambda_scale),
    f_own(deaths, "_d"), nowcast_joint_priors(),
    list(cases = cases, deaths = deaths))
}

#' Priors of the case fatality ratio of the joint nowcast
#'
#' The logit of the ratio of the first onset day is normal, centred on a
#' ratio of 0.5 with sd 1.5 (from about 0.08 to 0.92, 90%), and it follows a
#' random walk over onset days whose sd has a half-normal prior of scale 0.05:
#' at that scale, over four weeks the logit changes with sd 0.26, a change in
#' a ratio of 0.5 of about 0.07.
#'
#' @return a named list
nowcast_joint_priors <- function() {
  list(logit_cfr_mu = 0, logit_cfr_sd = 1.5, sigma_cfr_scale = 0.05)
}

#' Initial values of the joint nowcast
#'
#' Those of nowcast_inits for each series, with the ratio starting at that of
#' all the deaths to all the cases.
#'
#' @param data as nowcast_joint_stan_data
#' @inheritParams nowcast_inits
#' @return a list of lists, one for each chain
nowcast_joint_inits <- function(data, chains, seed = 1) {
  cases <- nowcast_inits(data$cases, chains, seed)
  deaths <- nowcast_inits(data$deaths, chains, seed + 1)
  own <- c("beta_g_free", "z_h", "tau_t", "z_u", "sigma_u", "log_phi", "rho")
  ratio <- sum(data$count_last_d) / sum(data$count_last_c)
  withr::with_seed(seed, lapply(seq_len(chains), function(k) {
    out <- c(cases[[k]][c("log_lambda_1", "z_lambda", "sigma_lambda")],
             stats::setNames(cases[[k]][own], paste0(own, "_c")),
             stats::setNames(deaths[[k]][own], paste0(own, "_d")),
             list(logit_cfr_1 = stats::qlogis(ratio), z_cfr = stats::rnorm(data$T - 1, 0, 0.1),
                  sigma_cfr = data$sigma_cfr_scale / 2))
    if(data$d_c_c < data$D)
      out$q_c <- array(cases[[k]]$q)
    out
  }))
}

#' Fits the joint nowcast of cases and deaths to the reports up to a date
#'
#' @inheritParams fit_nowcast
#' @return a list of two results as fit_nowcast, for cases_reported and
#'   deaths_reported, whose draws are paired: draw i of each is from the same
#'   draw of the joint posterior
fit_nowcast_joint <- function(analysis, date_target, chains = 4, iter_warmup = 500,
                              iter_sampling = 500, seed = 1, adapt_delta = 0.95,
                              model_file = "stan/nowcast_joint.stan", output_dir = NULL) {
  day_target <- as.integer(as.Date(date_target) - analysis$dates$date[1]) + 1L
  data <- nowcast_joint_stan_data(analysis$snapshots, day_target)
  model <- cmdstanr::cmdstan_model(model_file)
  time_start <- Sys.time()
  fit <- model$sample(data = data[setdiff(names(data), c("cases", "deaths"))],
                      chains = chains, parallel_chains = chains,
                      iter_warmup = iter_warmup, iter_sampling = iter_sampling,
                      adapt_delta = adapt_delta, init = nowcast_joint_inits(data, chains, seed),
                      seed = seed, refresh = 0, show_messages = FALSE,
                      output_dir = output_dir)
  if(any(fit$return_codes() != 0))
    stop("A chain of the joint nowcast failed: ", paste(fit$return_codes(), collapse = " "))
  minutes <- as.numeric(Sys.time() - time_start, units = "mins")
  list(summarise_nowcast(fit, data$cases, analysis, "cases_reported", date_target,
                         minutes, "_c"),
       summarise_nowcast(fit, data$deaths, analysis, "deaths_reported", date_target,
                         minutes, "_d", "sigma_cfr"))
}

#' The case fatality ratio by onset week from separate nowcasts of the cases
#' and the deaths
#'
#' The nowcasts are fitted separately, so their draws are paired by index;
#' the ratio of each week is that of its projected deaths to its projected
#' cases. Weeks whose last day is fewer than min_age days before the fit
#' date are marked as recent: most of their deaths are still to come, so
#' their ratio rests on the delay learned from earlier weeks.
#'
#' @param cases,deaths as fit_nowcast for cases_reported and deaths_reported,
#'   fitted to the same date
#' @param analysis_later an analysis to a later date (as
#'   prepare_bvd_deaths_analysis)
#' @param min_age the days from the end of a week to the fit date below which
#'   it is recent
#' @return a tibble by onset week of the ratio's quantiles, the ratio of the
#'   counts the later report shows, and whether the week is recent
nowcast_cfr <- function(cases, deaths, analysis_later, min_age = 21) {
  stopifnot(identical(cases$date_now, deaths$date_now),
            identical(colnames(cases$draws_weekly), colnames(deaths$draws_weekly)))
  n <- min(nrow(cases$draws_weekly), nrow(deaths$draws_weekly))
  ratio <- deaths$draws_weekly[seq_len(n), , drop = FALSE] /
    pmax(cases$draws_weekly[seq_len(n), , drop = FALSE], 1)
  later <- analysis_later$snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(date_onset = analysis_later$dates$date[.data$time_onset],
                  week = as.character(as.Date(cut(.data$date_onset, "week")))) %>%
    dplyr::group_by(.data$week) %>%
    dplyr::summarise(later = sum(.data$deaths_reported) / pmax(sum(.data$cases_reported), 1))
  week <- as.Date(colnames(ratio))
  dplyr::tibble(
    date_now = cases$date_now, week = week,
    p05 = apply(ratio, 2, stats::quantile, 0.05, names = FALSE),
    p50 = apply(ratio, 2, stats::quantile, 0.5, names = FALSE),
    p95 = apply(ratio, 2, stats::quantile, 0.95, names = FALSE),
    recent = as.numeric(cases$date_now - (week + 6)) < min_age) %>%
    dplyr::left_join(later %>% dplyr::mutate(week = as.Date(.data$week)), by = "week")
}

#' Writes the case fatality ratios of the nowcasts and plots them
#'
#' @param cfr a tibble of the rows of nowcast_cfr for each fit date
#' @param out the folder
#' @return the paths of the files written
write_nowcast_cfr <- function(cfr, out) {
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  paths <- file.path(out, c("cfr.csv", "nowcast_cfr.png"))
  utils::write.csv(cfr, paths[1], row.names = FALSE)
  df <- dplyr::mutate(cfr, fit = factor(format(.data$date_now, "Fit to %d %b"),
                                        levels = format(sort(unique(.data$date_now)), "Fit to %d %b")),
                      weeks = ifelse(.data$recent, "Recent (under 3 weeks old)", "Older"))
  g <- ggplot2::ggplot(df, ggplot2::aes(.data$week)) +
    ggplot2::geom_pointrange(ggplot2::aes(y = .data$p50, ymin = .data$p05, ymax = .data$p95,
                                          colour = .data$weeks), size = 0.25) +
    ggplot2::geom_point(ggplot2::aes(y = .data$later, shape = "Shown in the last report"),
                        size = 1.8) +
    ggplot2::facet_wrap(~fit, ncol = 1) +
    ggplot2::scale_colour_manual(NULL, values = c("Older" = "#1f4e9c",
                                                  "Recent (under 3 weeks old)" = "#e6550d")) +
    ggplot2::scale_shape_manual(NULL, values = 4) +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(x = "Week of onset", y = "Deaths / cases (90% interval)") +
    ggplot2::theme_bw() + ggplot2::theme(legend.position = "bottom")
  ggplot2::ggsave(paths[2], g, width = 9, height = 2.6 * dplyr::n_distinct(df$fit) + 1)
  paths
}

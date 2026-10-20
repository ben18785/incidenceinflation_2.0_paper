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

#' The data for stan/nowcast.stan
#'
#' @inheritParams nowcast_triangle
#' @param day_target the day (counted as the onset days are) to which counts
#'   are projected, or 0 for none
#' @param days_per_knot the days of onset time between knots of h
#' @param Kd the basis functions in log delay
#' @param priors a named list of the prior scales
#' @return a named list
nowcast_stan_data <- function(snapshots, column, day_target = 0L, days_per_knot = 18,
                              Kd = 7, priors = nowcast_priors()) {
  tri <- nowcast_triangle(snapshots, column)
  n_days <- max(tri$t)
  stopifnot(identical(sort(unique(tri$t)), seq_len(n_days)))
  delay_max <- max(tri$hi)
  reports <- sort(unique(tri$time_reported))
  Kt <- max(3L, as.integer(round(n_days / days_per_knot)))
  last <- tri %>% dplyr::group_by(.data$t) %>%
    dplyr::filter(.data$time_reported == max(.data$time_reported)) %>%
    dplyr::ungroup() %>% dplyr::arrange(.data$t)
  c(list(
    T = n_days, D = delay_max, Kt = Kt, Kd = Kd,
    Bt = splines::bs(seq_len(n_days), df = Kt, degree = 3, intercept = TRUE),
    Bd = splines::bs(log1p(0:delay_max), df = Kd, degree = 3, intercept = TRUE),
    R = length(reports), N = nrow(tri), t = tri$t, lo = tri$lo, hi = tri$hi,
    r = match(tri$time_reported, reports), report_day = as.integer(reports), n = tri$n,
    # removals at a rate up to about a twentieth of the additions
    w_max = pmax(0L, -tri$n) + 4L + as.integer(ceiling(0.08 * abs(tri$n))),
    count_last = last$count, delay_last = last$hi,
    day_target = as.integer(day_target)), priors)
}

#' Prior scales of the nowcast (half-normal)
nowcast_priors <- function()
  list(sigma_lambda_scale = 0.3, sigma_g_scale = 0.03, tau_s_scale = 0.05,
       kappa_scale = 2, tau_t_scale = 0.2, sigma_u_scale = 0.5, rho_scale = 0.05)

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
#' @return a list of lists, one for each chain
nowcast_inits <- function(data, chains, seed = 1) {
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
         sigma_u = data$sigma_u_scale / 2, kappa = 1, rho = 0.02)
  }))
}

#' Fits the nowcast to the reports up to a date
#'
#' @param analysis as prepare_bvd_deaths_analysis
#' @inheritParams nowcast_stan_data
#' @param date_target the date to which counts are projected
#' @param chains,iter_warmup,iter_sampling,seed as cmdstanr's sample
#' @return a named list: 'by_day' (the projected count of each onset day,
#'   with the count now, and the mean delay), 'parameters' (summaries of the
#'   scalar parameters), 'diagnostics' and 'draws_total' (the projected total)
fit_nowcast <- function(analysis, column, date_target, chains = 4,
                        iter_warmup = 500, iter_sampling = 500, seed = 1,
                        model_file = "stan/nowcast.stan", output_dir = NULL) {
  day_target <- as.integer(as.Date(date_target) - analysis$dates$date[1]) + 1L
  data <- nowcast_stan_data(analysis$snapshots, column, day_target)
  model <- cmdstanr::cmdstan_model(model_file)
  time_start <- Sys.time()
  fit <- model$sample(data = data, chains = chains, parallel_chains = chains,
                      iter_warmup = iter_warmup, iter_sampling = iter_sampling,
                      init = nowcast_inits(data, chains, seed),
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
summarise_nowcast <- function(fit, data, analysis, column, date_target, minutes = NA) {
  draws_projected <- posterior::as_draws_matrix(fit$draws("projected"))
  draws_delay <- posterior::as_draws_matrix(fit$draws("mean_delay"))
  f_q <- function(m, p) apply(m, 2, stats::quantile, p, names = FALSE)
  by_day <- dplyr::tibble(
    time_onset = seq_len(data$T),
    date = analysis$dates$date[seq_len(data$T)],
    now = data$count_last,
    p05 = f_q(draws_projected, 0.05), p50 = f_q(draws_projected, 0.5),
    p95 = f_q(draws_projected, 0.95),
    mean_delay = f_q(draws_delay, 0.5), mean_delay_p05 = f_q(draws_delay, 0.05),
    mean_delay_p95 = f_q(draws_delay, 0.95))
  scalars <- c("sigma_lambda", "sigma_g", "tau_t", "tau_s", "sigma_u", "kappa", "rho")
  diagnostics <- fit$diagnostic_summary(quiet = TRUE)
  summary_all <- fit$summary(c(scalars, "log_lambda", "z_h", "s"))
  list(column = column, date_now = analysis$date_now, date_target = as.Date(date_target),
       by_day = by_day,
       parameters = fit$summary(scalars),
       draws_total = rowSums(draws_projected),
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

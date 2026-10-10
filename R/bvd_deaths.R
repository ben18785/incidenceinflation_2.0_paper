# Bundibugyo virus disease analysed with the joint model of cases and deaths:
# Rt, the reporting delay, the case fatality ratio and the delay from onset to
# a death being recorded all change at times which are inferred.

#' Prepares the cases and deaths shown in each report, as of a date
#'
#' As prepare_bvd_changepoint_analysis, with the deaths shown in each report
#' added. With days_earlier above zero the first onset day analysed is that
#' many days before the first situation report: those onset days are first
#' seen some days after onset, so say little about the reporting delay, but
#' deaths among their cases go on being recorded from report to report.
prepare_bvd_deaths_analysis <- function(snapshots, date_now, days_earlier = 0,
                                        serial_max = 40) {
  date_now <- as.Date(date_now)
  analysis <- prepare_bvd_analysis(
    snapshots, date_now,
    date_earliest = min(snapshots$date_reported) - days_earlier, Rt_piece_width = 1)
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
  analysis$days_earlier <- days_earlier
  deaths <- snapshots %>%
    dplyr::transmute(
      time_onset = as.integer(.data$date_onset - date_start) + 1L,
      time_reported = as.integer(.data$date_reported - date_start) + 1L,
      deaths_reported = as.integer(.data$deaths_reported))
  analysis$snapshots <- dplyr::left_join(analysis$snapshots, deaths,
                                         by = c("time_onset", "time_reported"))
  if(any(is.na(analysis$snapshots$deaths_reported)))
    stop("Some reports of cases have no count of deaths.")
  if(any(analysis$snapshots$deaths_reported > analysis$snapshots$cases_reported))
    stop("Some reports show more deaths than cases.")
  analysis
}

#' What the model is told about fatal cases dated by death in each fit
#'
#' The reports do not say how many fatal cases are recorded for their day of
#' death, nor how long after onset those deaths were. "none" takes there to be
#' none. "a fifth" is a check of how much the results depend on this: a fifth
#' of fatal cases, dying a mean of 7 days after onset (sd 4) and reported a
#' mean of 2 days after death (sd 1.5). These values are illustrative: they
#' are not estimates for this outbreak.
bvd_deaths_variants <- function() {
  list(
    none = NULL,
    `a fifth` = list(fraction = 0.2, mean = 7, sd = 4,
                     reporting = list(mean = 2, sd = 1.5)))
}

#' Runs one chain of the joint model of cases and deaths
#'
#' As fit_bvd_changepoint_chain (wrong records, an effect of the day of the
#' week of each report, a negative binomial renewal model, earlier cases
#' supplied as known), with the deaths shown in each report.
fit_bvd_deaths_chain <- function(analysis, variant, chain, niterations, n_draws = 300,
                                 serial_parameters = list(mean = 15.3, sd = 9.3),
                                 progress_dir = "outputs/bvd_deaths/progress") {
  dir.create(progress_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(1000 * chain + as.integer(analysis$date_now) %% 1000)
  settings <- fit_settings()
  snapshots <- analysis$snapshots
  largest_reported <- snapshots %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::summarise(cases_true = max(.data$cases_reported))
  days_before_end <- max(snapshots$time_onset) - largest_reported$time_onset
  index <- (chain - 1) %% 3 + 1
  inflation <- c(2, 1, 3.5)[index]
  initial_cases_true <- largest_reported %>%
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
    Rt_changepoints = list(),
    reporting_changepoints = bvd_delay_settings())
  deaths_settings <- list(
    initial_cfr = c(0.5, 0.25, 0.7)[index],
    initial_delay = list(list(mean = 14, sd = 8), list(mean = 8, sd = 5),
                         list(mean = 20, sd = 10))[[index]],
    delay_changepoints = bvd_delay_settings())
  deaths_settings["dated_by_death"] <- list(bvd_deaths_variants()[[variant]])

  time_start <- Sys.time()
  fit <- tryCatch(
    incidenceinflation::mcmc_single(
      niterations = niterations,
      snapshot_with_Rt_index_df = snapshots %>%
        dplyr::select("time_onset", "time_reported", "cases_reported") %>%
        dplyr::mutate(Rt_index = 1),
      priors = priors,
      serial_parameters = serial_parameters,
      initial_cases_true = initial_cases_true,
      initial_reporting_parameters = list(
        list(mean = 7, sd = 4), list(mean = 4, sd = 2.5),
        list(mean = 11, sd = 7))[[index]],
      initial_Rt = dplyr::tibble(Rt_index = 1, Rt = 1),
      reporting_metropolis_parameters = list(mean_step = 0.3, sd_step = 0.25),
      print_to_screen = FALSE,
      initial_overdispersion = c(10, 3, 30)[index],
      is_negative_binomial = TRUE,
      overdispersion_metropolis_sd = 8,
      initial_revision_parameters = list(
        eta = settings$initial_revisions$eta, rho = settings$initial_revisions$rho,
        weekday = TRUE, weekday_first = analysis$weekday_first),
      revision_metropolis_parameters = settings$revision_metropolis,
      cases_before = analysis$cases_before,
      n_parameter_steps = 5,
      progress_file = file.path(progress_dir, sprintf(
        "%s_%s_%d.txt", gsub(" ", "_", variant), analysis$date_now, chain)),
      progress_every = 10,
      deaths = list(snapshot = snapshots %>%
                      dplyr::select("time_onset", "time_reported", "deaths_reported"),
                    settings = deaths_settings)),
    error = function(e) list(error = conditionMessage(e)))
  out <- list(variant = variant, chain = chain, analysis = analysis,
              niterations = niterations,
              minutes = as.numeric(Sys.time() - time_start, units = "mins"),
              max_erroneous = max_erroneous, serial_parameters = serial_parameters,
              error = fit$error)
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
    f_days(reporting, "mean", 1, mean, "Mean delay to case reported, first onset day"),
    f_days(reporting, "mean", day_last, mean,
           "Mean delay to case reported, latest onset day"),
    f_parameter(parameters, "n_cfr_changes", "Changes in the case fatality ratio"),
    f_parameter(parameters, "n_delay_changes", "Changes in the delay to death recorded"),
    f_parameter(parameters, "fatal_delay_ratio",
                "Reporting delay of fatal cases relative to others"),
    f_parameter(parameters, "wrong_dead", "Share of wrong records shown as dead"),
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
  purrr::map_dfr(chains, function(chain) {
    dplyr::tibble(variant = chain$variant, chain = chain$chain,
                  niterations = chain$niterations, minutes = chain$minutes,
                  error = if(is.null(chain$error)) "" else chain$error)
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
              `a fifth` = "A fifth of fatal cases dated by death")
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

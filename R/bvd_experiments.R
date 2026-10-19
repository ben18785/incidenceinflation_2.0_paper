# Experiments with the model of the Bundibugyo virus disease outbreak, which
# run one chain per job on GitHub Actions (or together on one machine)
#
# Each experiment is an entry of experiments/experiments.yml: the reports
# used, the part of the model fitted, the settings of the delay to a death
# being recorded, and the number and length of the chains. The pipeline of
# _targets_experiments.R has one target per chain.

#' The experiments of a file, each a list with every setting filled in
#'
#' @param path the file of experiments
#' @return a named list of experiments: name, model ("cases", "deaths",
#'   "fixed cases" or "joint"), date (the latest report used), chains,
#'   iterations, tail, family, delay (settings of the changes in the delay
#'   to a death being recorded, or NULL), onset_from, variant (joint only),
#'   starts (starting values: "near" one another or "spread" apart),
#'   cases_from (fixed cases only: the date of the fit of cases alone whose
#'   cases are held fixed, if not 'date'), tail_prior (cases and deaths
#'   only: the prior on the heavier tail, with a label)
bvd_experiments <- function(path = "experiments/experiments.yml") {
  file <- yaml::read_yaml(path)
  defaults <- utils::modifyList(
    list(chains = 4, iterations = 600, tail = TRUE, family = "gamma",
         variant = "none", starts = "near"),
    if(is.null(file$defaults)) list() else file$defaults)
  experiments <- purrr::imap(file$experiments, function(experiment, name) {
    experiment <- utils::modifyList(defaults, experiment)
    experiment$name <- name
    stopifnot(experiment$model %in% c("cases", "deaths", "fixed cases", "joint"),
              !is.null(experiment$date),
              grepl("^[A-Za-z][A-Za-z0-9_]*$", name))
    experiment$date <- as.Date(experiment$date)
    experiment
  })
  experiments
}

#' The experiments with the iterations of each replaced (by a batch's line
#' 'iterations: <n>'), to lengthen chains without changing their definitions
#'
#' @param experiments as bvd_experiments returns them
#' @param iterations the iterations every chain is to have, or NULL to keep
#'   those of each experiment
bvd_experiments_iterations <- function(experiments, iterations = NULL) {
  if(is.null(iterations))
    return(experiments)
  iterations <- suppressWarnings(as.integer(iterations))
  if(length(iterations) != 1 || is.na(iterations) || iterations < 1)
    stop("The iterations asked for must be one positive whole number.")
  lapply(experiments, function(experiment) {
    experiment$iterations <- iterations
    experiment
  })
}

#' One row for each chain of each experiment, with the name of its target
#'
#' @param names names of the experiments wanted (all if NULL)
#' @param chain the chain wanted (all if NULL)
bvd_experiment_chains <- function(experiments, names = NULL, chain = NULL) {
  if(!is.null(names)) {
    unknown <- setdiff(names, names(experiments))
    if(length(unknown) > 0)
      stop("No experiment called ", paste(unknown, collapse = ", "), ".")
    experiments <- experiments[names]
  }
  grid <- purrr::map_dfr(experiments, function(settings)
    dplyr::tibble(experiment = settings$name, chain = seq_len(settings$chains)))
  if(!is.null(chain))
    grid <- dplyr::filter(grid, .data$chain == !!chain)
  dplyr::mutate(grid, id = paste(.data$experiment, .data$chain, sep = "_"))
}

#' The posterior median of the true cases of each onset day from the model
#' of cases alone fitted to the reports up to a date, as saved by
#' scripts/export_bvd_cases_median.R
bvd_cases_median_saved <- function(date_now, dir = "data/raw/bvd_derived") {
  path <- file.path(dir, paste0("cases_median_", as.Date(date_now), ".csv"))
  if(!file.exists(path))
    stop("No cases from the model of cases alone are saved for ", date_now,
         " (", path, ").")
  utils::read.csv(path) %>%
    dplyr::as_tibble() %>%
    dplyr::mutate(time_onset = as.integer(.data$time_onset))
}

#' Runs one chain of an experiment
#'
#' @param resume the 'progress' of an earlier run of the chain which stopped
#'   early, to carry it on
#' @param time_limit minutes after which the chain stops, to be carried on
#' @return the fit of the chain, as fit_bvd_single_chain,
#'   fit_bvd_fixed_cases_chain or fit_bvd_deaths_chain return it, with the
#'   name of the experiment. 'niterations' is the iterations done so far,
#'   'niterations_target' those asked for and 'progress' what is needed to
#'   carry the chain on.
run_bvd_experiment_chain <- function(experiment, chain, snapshots, resume = NULL,
                                     time_limit = NULL) {
  analysis <- prepare_bvd_deaths_analysis(snapshots, experiment$date)
  fit <- if(experiment$model %in% c("cases", "deaths"))
    fit_bvd_single_chain(analysis, snapshots, experiment$model, chain,
                         experiment$iterations, tail = experiment$tail,
                         family = experiment$family,
                         onset_from = experiment$onset_from,
                         tail_prior = experiment$tail_prior,
                         delay_settings = experiment$delay,
                         starts = experiment$starts,
                         resume = resume, time_limit = time_limit)
  else if(experiment$model == "fixed cases") {
    # the cases are those of the fit of cases alone to the reports up to
    # 'cases_from' if given, for the onset days of this fit
    cases_from <- if(is.null(experiment$cases_from)) experiment$date
    else as.Date(experiment$cases_from)
    cases_fixed <- bvd_cases_median_saved(cases_from) %>%
      dplyr::filter(.data$time_onset %in% analysis$snapshots$time_onset)
    fit_bvd_fixed_cases_chain(analysis, cases_fixed,
                              chain, experiment$iterations,
                              delay_settings = experiment$delay,
                              starts = experiment$starts,
                              deaths_prior = experiment$deaths_prior,
                              resume = resume, time_limit = time_limit)
  } else {
    fit <- fit_bvd_deaths_chain(analysis, experiment$variant, chain,
                                experiment$iterations, starts = experiment$starts,
                                tail = experiment$tail,
                                tail_prior = experiment$tail_prior,
                                delay_settings = experiment$delay,
                                deaths_prior = experiment$deaths_prior,
                                resume = resume, time_limit = time_limit)
    fit$model <- paste0(
      "joint", ifelse(experiment$tail, "", ", no tail"),
      if(!is.null(experiment$tail_prior)) paste0(", ", experiment$tail_prior$label),
      if(!is.null(experiment$delay)) paste0(", ", experiment$delay$label),
      if(!is.null(experiment$deaths_prior)) paste0(", ", experiment$deaths_prior$label))
    fit$date_now <- analysis$date_now
    fit
  }
  fit$experiment <- experiment$name
  fit
}

#' The chains grouped by experiment, those which failed left out
bvd_experiment_groups <- function(chains) {
  chains <- purrr::keep(chains, ~is.null(.$error))
  split(chains, purrr::map_chr(chains, "experiment"))
}

#' Which chains ran, how long they took and any errors
bvd_experiment_runs <- function(chains) {
  purrr::map_dfr(chains, function(fit) {
    dplyr::tibble(experiment = fit$experiment, model = fit$model,
                  date_now = fit$date_now, chain = fit$chain,
                  niterations = fit$niterations,
                  niterations_target = if(is.null(fit$niterations_target))
                    fit$niterations else fit$niterations_target,
                  minutes = round(fit$minutes),
                  error = if(is.null(fit$error)) "" else as.character(fit$error))
  })
}

#' Summary of each monitored quantity of each experiment: median, 90%
#' interval, split R-hat and the median of each chain
bvd_experiment_summary <- function(chains) {
  purrr::map_dfr(bvd_experiment_groups(chains), function(fits) {
    monitored <- if(sub(",.*", "", fits[[1]]$model) == "joint")
      bvd_deaths_monitored(fits, fits[[1]]$variant)
    else bvd_part_monitored(fits)
    monitored <- dplyr::filter(monitored, !is.na(.data$value))
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
      dplyr::mutate(experiment = fits[[1]]$experiment, model = fits[[1]]$model,
                    date_now = fits[[1]]$date_now, n_chains = length(fits),
                    .before = 1)
  })
}

#' Draws by onset day of the count an experiment estimates (cases for the
#' model of cases alone, otherwise fatal cases) and of the delay to its
#' being recorded. Where some fatal cases are counted on their day of death,
#' the fatal cases are those the reports count for the day, to be compared
#' with the reports.
bvd_experiment_days <- function(fits) {
  single <- sub(",.*", "", fits[[1]]$model) %in% c("cases", "deaths")
  dates <- dplyr::select(fits[[1]]$analysis$dates, "time_onset", "date")
  purrr::map_dfr(fits, function(fit) {
    if(single)
      fit$cases %>%
        dplyr::transmute(.data$chain, .data$iteration, .data$time_onset,
                         count = .data$cases_true) %>%
        dplyr::left_join(
          dplyr::transmute(fit$reporting_days, .data$iteration, .data$time_onset,
                           delay_mean = .data$mean, delay_sd = .data$sd),
          by = c("iteration", "time_onset"))
    else
      dplyr::transmute(fit$deaths, .data$chain, .data$iteration, .data$time_onset,
                       count = if("deaths_recorded" %in% names(fit$deaths))
                         .data$deaths_recorded else .data$deaths_true,
                       .data$delay_mean, .data$delay_sd)
  }) %>%
    dplyr::left_join(dates, by = "time_onset") %>%
    dplyr::mutate(date = as.Date(.data$date))
}

#' The count each experiment estimates over all onset days and over the
#' latest 28 and 14, with what the reports show for the same onset days: at
#' the date of the fit and in each later report asked for
#'
#' @param dates_later later report dates to compare with (the latest report
#'   is always included)
#' @return a tibble, one row per experiment and set of onset days: the
#'   estimate (median, 90% interval, split R-hat) and the counts recorded
bvd_experiment_totals <- function(chains, snapshots_all,
                                  dates_later = as.Date("2026-09-15")) {
  kind <- function(fits) sub(",.*", "", fits[[1]]$model)
  groups <- bvd_experiment_groups(chains)
  # the joint model estimates the cases as well as the fatal cases
  wanted <- purrr::map_dfr(groups, function(fits)
    dplyr::tibble(experiment = fits[[1]]$experiment,
                  column = c(if(kind(fits) %in% c("cases", "joint")) "cases_reported",
                             if(kind(fits) != "cases") "deaths_reported")))
  purrr::pmap_dfr(wanted, function(experiment, column) {
    fits <- groups[[experiment]]
    days <- bvd_experiment_days(fits)
    if(kind(fits) == "joint" && column == "cases_reported")
      days <- purrr::map_dfr(fits, function(fit) {
        # the cases the reports count for a day: those with onset on it, less
        # its fatal cases counted on their day of death, plus those of
        # earlier onset who died on it
        moved <- if("deaths_recorded" %in% names(fit$deaths))
          dplyr::transmute(fit$deaths, .data$iteration, .data$time_onset,
                           moved = .data$deaths_recorded - .data$deaths_true)
        else dplyr::tibble(iteration = integer(0), time_onset = integer(0),
                           moved = numeric(0))
        fit$cases %>%
          dplyr::left_join(moved, by = c("iteration", "time_onset")) %>%
          dplyr::mutate(cases_true = .data$cases_true +
                          ifelse(is.na(.data$moved), 0, .data$moved))
      }) %>%
        dplyr::transmute(.data$chain, .data$iteration, .data$time_onset,
                         count = .data$cases_true) %>%
        dplyr::left_join(dplyr::distinct(days, .data$time_onset, .data$date),
                         by = "time_onset")
    date_now <- as.Date(fits[[1]]$date_now)
    dates_reported <- sort(unique(c(
      date_now, dates_later[dates_later > date_now], max(snapshots_all$date_reported))))
    purrr::map_dfr(c(`all` = Inf, `latest 28` = 28, `latest 14` = 14), function(n_days) {
      from <- if(is.finite(n_days)) date_now - n_days + 1 else min(days$date)
      totals <- days %>%
        dplyr::filter(.data$date >= from) %>%
        dplyr::group_by(.data$chain, .data$iteration) %>%
        dplyr::summarise(value = sum(.data$count), .groups = "drop")
      recorded <- purrr::map_dbl(dates_reported, function(date_reported)
        sum(snapshots_all[[column]][snapshots_all$date_reported == date_reported &
                                      snapshots_all$date_onset >= from &
                                      snapshots_all$date_onset <= date_now]))
      names(recorded) <- paste0("recorded_", format(dates_reported, "%d%b"))
      dplyr::tibble(median = stats::median(totals$value),
                    lo = stats::quantile(totals$value, 0.05),
                    hi = stats::quantile(totals$value, 0.95),
                    rhat = split_rhat(totals$value, totals$chain)) %>%
        dplyr::bind_cols(dplyr::as_tibble(as.list(recorded)))
    }, .id = "onset_days") %>%
      dplyr::mutate(experiment = fits[[1]]$experiment, model = fits[[1]]$model,
                    date_now = date_now, count = sub("_reported", "", column),
                    .before = 1)
  })
}

#' The delay by onset day of each experiment: median and 90% interval over
#' all chains, and the median of each chain
bvd_experiment_delays <- function(chains) {
  purrr::map_dfr(bvd_experiment_groups(chains), function(fits) {
    days <- bvd_experiment_days(fits) %>%
      tidyr::pivot_longer(c("delay_mean", "delay_sd"), names_to = "quantity")
    f <- function(df) df %>%
      dplyr::summarise(mid = stats::median(.data$value),
                       lo = stats::quantile(.data$value, 0.05),
                       hi = stats::quantile(.data$value, 0.95), .groups = "drop")
    dplyr::bind_rows(
      f(dplyr::group_by(days, .data$quantity, .data$date)) %>%
        dplyr::mutate(chain = "all"),
      f(dplyr::group_by(days, .data$quantity, .data$date, .data$chain)) %>%
        dplyr::mutate(chain = as.character(.data$chain))) %>%
      dplyr::mutate(experiment = fits[[1]]$experiment, model = fits[[1]]$model,
                    date_now = fits[[1]]$date_now, .before = 1)
  })
}

#' The delay by onset day of each experiment: the median and 90% interval
#' over all chains (blue) and the median of each chain (grey)
plot_bvd_experiment_delays <- function(delays) {
  delays <- delays %>%
    dplyr::mutate(quantity = ifelse(.data$quantity == "delay_mean",
                                    "Mean delay (days)", "Sd of delay (days)"))
  all <- dplyr::filter(delays, .data$chain == "all")
  ggplot2::ggplot(all, ggplot2::aes(x = .data$date)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$lo, ymax = .data$hi),
                         fill = "steelblue", alpha = 0.25) +
    ggplot2::geom_line(data = dplyr::filter(delays, .data$chain != "all"),
                       ggplot2::aes(y = .data$mid, group = .data$chain),
                       colour = "grey40", linewidth = 0.3) +
    ggplot2::geom_line(ggplot2::aes(y = .data$mid), colour = "steelblue4",
                       linewidth = 0.9) +
    ggplot2::facet_grid(.data$quantity ~ .data$experiment, scales = "free_y") +
    ggplot2::expand_limits(y = 0) +
    ggplot2::labs(x = "Onset day", y = NULL) +
    ggplot2::theme_bw(base_size = 10)
}

#' A table as markdown
bvd_markdown_table <- function(df) {
  df <- dplyr::mutate(df, dplyr::across(dplyr::everything(), as.character))
  df[is.na(df)] <- ""
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(df, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
}

#' Writes the results of a set of chains to a folder: the tables as csv, a
#' plot of the delays, and a summary in markdown
#'
#' @return the paths of the files written
write_bvd_experiment_results <- function(chains, snapshots_all, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  runs <- bvd_experiment_runs(chains)
  paths <- file.path(dir, c("runs.csv", "summary.csv", "totals.csv", "delays.csv",
                            "delays.png", "summary.md"))
  utils::write.csv(runs, paths[1], row.names = FALSE)
  ran <- dplyr::filter(runs, .data$error == "") %>%
    dplyr::group_by(.data$experiment) %>%
    dplyr::summarise(chains = dplyr::n(),
                     iterations = paste(unique(range(.data$niterations)), collapse = "-"),
                     `asked for` = dplyr::first(.data$niterations_target),
                     minutes = round(mean(.data$minutes)), .groups = "drop")
  lines <- c("# Experiments", "", "## Chains run", "", bvd_markdown_table(ran))
  failed <- dplyr::filter(runs, .data$error != "")
  if(nrow(failed) > 0)
    lines <- c(lines, "", "## Chains which failed", "",
               bvd_markdown_table(failed[, c("experiment", "chain", "error")]))
  if(nrow(ran) > 0) {
    summary <- bvd_experiment_summary(chains)
    totals <- bvd_experiment_totals(chains, snapshots_all)
    delays <- bvd_experiment_delays(chains)
    utils::write.csv(summary, paths[2], row.names = FALSE)
    utils::write.csv(totals, paths[3], row.names = FALSE)
    utils::write.csv(delays, paths[4], row.names = FALSE)
    n_experiments <- length(unique(delays$experiment))
    # a figure is not worth losing the results for
    tryCatch(save_plot(plot_bvd_experiment_delays(delays), paths[5],
                       min(48, max(5, 2.6 * n_experiments + 1)), 5.5),
             error = function(e) message("No figure of the delays: ", conditionMessage(e)))
    worst <- summary %>%
      dplyr::group_by(.data$experiment) %>%
      dplyr::summarise(`worst R-hat` = sprintf("%.2f", max(.data$rhat, na.rm = TRUE)),
                       `quantities at 1.2 or more` = sum(.data$rhat >= 1.2, na.rm = TRUE),
                       .groups = "drop")
    f_estimate <- function(mid, lo, hi, digits = 0)
      sprintf(paste0("%.", digits, "f (%.", digits, "f-%.", digits, "f)"), mid, lo, hi)
    totals_shown <- totals %>%
      dplyr::mutate(estimate = f_estimate(.data$median, .data$lo, .data$hi),
                    rhat = sprintf("%.2f", .data$rhat)) %>%
      dplyr::select("experiment", "count", "onset_days", "estimate", "rhat",
                    dplyr::starts_with("recorded_"))
    date_now <- max(as.Date(delays$date_now))
    delays_shown <- delays %>%
      dplyr::filter(.data$chain == "all", .data$quantity == "delay_mean") %>%
      dplyr::group_by(.data$experiment) %>%
      dplyr::filter(.data$date %in% c(min(.data$date), max(.data$date) - c(42, 28, 14, 0))) %>%
      dplyr::ungroup() %>%
      dplyr::transmute(.data$experiment, onset = format(.data$date, "%d %b"),
                       estimate = f_estimate(.data$mid, .data$lo, .data$hi, 1)) %>%
      tidyr::pivot_wider(names_from = "onset", values_from = "estimate")
    lines <- c(
      lines, "", "## Agreement between chains", "", bvd_markdown_table(worst), "",
      "## Totals against the counts recorded", "",
      "Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.",
      "", bvd_markdown_table(totals_shown), "",
      "## Mean delay by onset day (days)", "", bvd_markdown_table(delays_shown))
  }
  writeLines(lines, paths[6])
  paths[file.exists(paths)]
}

#' Runs the sampler for a chain, or carries on a chain which stopped early
#'
#' @param resume the 'progress' of an earlier run of the same chain (all its
#'   draws, the state of the sampler, the iterations done and the minutes
#'   taken), or NULL to start the chain
#' @param time_limit minutes after which sampling stops, or NULL
#' @param niterations the iterations the chain is to have in all
#' @param ... the other arguments of incidenceinflation::mcmc_single
#' @return the draws of all iterations done so far, as mcmc_single returns
#'   them, with 'state', 'iterations' (done so far) and 'minutes_before'
#'   (taken by earlier runs)
bvd_mcmc <- function(resume = NULL, time_limit = NULL, niterations, ...) {
  done <- if(is.null(resume)) 0 else resume$iterations
  minutes_before <- if(is.null(resume)) 0 else resume$minutes
  if(done >= niterations)
    return(c(resume$draws, list(state = resume$state, iterations = done,
                                minutes_before = minutes_before)))
  fit <- incidenceinflation::mcmc_single(
    niterations = niterations - done, ..., return_state = TRUE,
    resume_from = resume$state, time_limit = time_limit)
  names_draws <- setdiff(names(fit), c("state", "iterations_done"))
  draws <- lapply(stats::setNames(names_draws, names_draws), function(name)
    dplyr::bind_rows(resume$draws[[name]], fit[[name]]))
  c(draws, list(state = fit$state, iterations = fit$state$iterations,
                minutes_before = minutes_before))
}

#' What is needed to carry a chain on: all its draws, the state of the
#' sampler, the iterations done and the minutes taken
bvd_progress <- function(fit, minutes) {
  list(draws = fit[setdiff(names(fit), c("state", "iterations", "minutes_before"))],
       state = fit$state, iterations = fit$iterations, minutes = minutes)
}

#' The minutes after which a chain stops to be carried on later, from the
#' environment variable BVD_TIME_LIMIT (NULL if not set)
bvd_time_limit <- function() {
  value <- suppressWarnings(as.numeric(Sys.getenv("BVD_TIME_LIMIT", "")))
  if(is.na(value)) NULL else value
}

#' The progress of an earlier run of a chain, if a file of it is in the
#' folder named by the environment variable BVD_RESUME_DIR (default
#' "states"), as scripts/run_experiment_chain.R saves it
bvd_progress_saved <- function(id) {
  path <- file.path(Sys.getenv("BVD_RESUME_DIR", "states"), paste0(id, ".rds"))
  if(file.exists(path)) readRDS(path)$progress
}

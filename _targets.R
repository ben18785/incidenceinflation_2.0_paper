# Pipeline applying the model of docs/downward_revisions.tex to simulated and
# real data. Run with targets::tar_make().

library(targets)
library(tarchetypes)

# development version of incidenceinflation (see scripts/install_package.R)
.libPaths(c(file.path(getwd(), ".lib"), .libPaths()))

tar_option_set(
  packages = c("dplyr", "tidyr", "purrr", "ggplot2", "rlang", "incidenceinflation"),
  library = .libPaths(),
  controller = crew::crew_controller_local(
    workers = as.integer(Sys.getenv("PIPELINE_WORKERS", "8")),
    seconds_idle = 30))

tar_source("R")

n_replicates <- as.integer(Sys.getenv("PIPELINE_REPLICATES", "5"))
n_iterations <- as.integer(Sys.getenv("PIPELINE_ITERATIONS", "700"))
n_iterations_real <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_REAL", "800"))
n_iterations_bvd <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_BVD", "600"))
n_iterations_demo <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_DEMO", "1500"))
n_chains_bvd <- as.integer(Sys.getenv("PIPELINE_CHAINS_BVD", "3"))
n_iterations_bvd_cp <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_BVD_CP", "3000"))
# tests of the joint model of cases and deaths on simulated data
n_replicates_deaths <- as.integer(Sys.getenv("PIPELINE_REPLICATES_DEATHS", "1"))
n_chains_deaths <- as.integer(Sys.getenv("PIPELINE_CHAINS_DEATHS", "2"))
n_chains_bvd_deaths <- as.integer(Sys.getenv("PIPELINE_CHAINS_BVD_DEATHS", "3"))
n_iterations_bvd_deaths <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_BVD_DEATHS", "1000"))
n_chains_bvd_forms <- as.integer(Sys.getenv("PIPELINE_CHAINS_BVD_FORMS", "4"))
n_iterations_bvd_forms <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_BVD_FORMS", "1500"))
n_iterations_bvd_trials <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_BVD_TRIALS", "800"))
n_iterations_deaths <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_DEATHS", "300"))
# the same with the fraction of fatal cases counted on their day of death
# estimated
n_replicates_misdated <- as.integer(Sys.getenv("PIPELINE_REPLICATES_MISDATED", "3"))
n_chains_misdated <- as.integer(Sys.getenv("PIPELINE_CHAINS_MISDATED", "3"))
n_iterations_misdated <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_MISDATED", "400"))

list(
  # ---- simulated data -------------------------------------------------------
  tar_target(simulation_grid,
             tidyr::expand_grid(simulation_regimes(),
                                replicate = seq_len(n_replicates))),
  tar_target(simulated_dataset,
             simulate_dataset(simulation_grid, simulation_grid$replicate),
             pattern = map(simulation_grid), iteration = "list"),
  tar_target(simulated_revisions,
             dplyr::bind_cols(
               dplyr::tibble(regime = simulated_dataset$regime,
                             replicate = simulated_dataset$replicate),
               summarise_revisions(simulated_dataset$snapshots)),
             pattern = map(simulated_dataset)),
  tar_target(model, model_names()),
  # each model fitted to each dataset, reduced to summaries and scored
  tar_target(simulated_result, {
    fit_summary <- summarise_fit(fit_model(
      simulated_dataset$snapshots, model,
      simulated_dataset$settings$serial_parameters,
      simulated_dataset$settings$Rt_piece_width,
      niterations = n_iterations,
      seed = simulated_dataset$replicate,
      # several misdated records can be held for an onset day at once
      settings = utils::modifyList(fit_settings(), list(max_erroneous = 10))))
    list(regime = simulated_dataset$regime,
         replicate = simulated_dataset$replicate,
         summary = fit_summary,
         score = score_fit(fit_summary, simulated_dataset))
  }, pattern = cross(simulated_dataset, model), iteration = "list"),
  tar_target(simulated_score,
             purrr::map_dfr(simulated_result, "score"),
             deployment = "main"),
  tar_target(simulated_score_summary, summarise_scores(simulated_score),
             deployment = "main"),
  # first replicate of each regime, for illustration
  tar_target(simulated_examples,
             purrr::map(simulation_regimes()$regime, function(regime) {
               is_dataset <- purrr::map_lgl(
                 simulated_dataset, ~.$regime == regime & .$replicate == 1)
               is_result <- purrr::map_lgl(
                 simulated_result, ~.$regime == regime & .$replicate == 1)
               list(dataset = simulated_dataset[is_dataset][[1]],
                    summaries = purrr::map(simulated_result[is_result], "summary"))
             }),
             deployment = "main"),
  tar_target(figure_simulation_examples,
             save_plot(plot_simulation_examples(simulated_examples),
                       "outputs/simulation_examples.png", 9, 10),
             format = "file", deployment = "main"),

  # ---- simulated data: a batch near the analysis date -------------------------
  tar_target(frontier_grid,
             tidyr::expand_grid(frontier_regimes(),
                                replicate = seq_len(n_replicates))),
  tar_target(frontier_dataset,
             simulate_frontier_dataset(frontier_grid, frontier_grid$replicate),
             pattern = map(frontier_grid), iteration = "list"),
  tar_target(frontier_model, frontier_model_names()),
  tar_target(frontier_result,
             fit_frontier_model(frontier_dataset, frontier_model, n_iterations),
             pattern = cross(frontier_dataset, frontier_model), iteration = "list"),
  tar_target(frontier_score, purrr::map_dfr(frontier_result, "score"),
             deployment = "main"),
  tar_target(frontier_score_summary, summarise_frontier_scores(frontier_score),
             deployment = "main"),
  tar_target(files_frontier, {
    utils::write.csv(frontier_score, "outputs/frontier_scores.csv", row.names = FALSE)
    utils::write.csv(frontier_score_summary, "outputs/frontier_score_summary.csv",
                     row.names = FALSE)
    c("outputs/frontier_scores.csv", "outputs/frontier_score_summary.csv",
      save_plot(plot_frontier_examples(frontier_dataset, frontier_result),
                "outputs/frontier_examples.png", 9, 5.5),
      save_plot(plot_frontier_scores(frontier_score),
                "outputs/frontier_scores.png", 9, 3.8))
  }, format = "file", deployment = "main"),

  # ---- Netherlands COVID-19 cases by symptom onset date ----------------------
  tar_target(rivm_file, "data/processed/rivm_onset_snapshots.csv", format = "file"),
  tar_target(rivm_snapshots,
             utils::read.csv(rivm_file) %>%
               dplyr::as_tibble() %>%
               dplyr::mutate(date_onset = as.Date(date_onset),
                             date_reported = as.Date(date_reported))),
  tar_target(rivm_analysis,
             prepare_real_analysis(rivm_snapshots, "2020-07-01", "2020-09-01")),
  tar_target(rivm_revisions, summarise_revisions(rivm_analysis$snapshots)),
  tar_target(rivm_settings, {
    settings <- fit_settings()
    # the largest fall in reported cases must be possible
    settings$max_erroneous <-
      incidenceinflation::max_downward_revision(rivm_analysis$snapshots) + 1
    settings$priors$reporting <- list(mean_mu = 7, mean_sigma = 10,
                                      sd_mu = 5, sd_sigma = 5)
    settings$priors$revisions$eta_mu <- 0.005
    settings$priors$revisions$eta_sigma <- 0.005
    # only falls which are large in total suggest a batch
    settings$priors$batches$min_total_fall <- 3 * settings$max_erroneous
    settings$priors$batches$max_batch <- 30
    settings
  }),
  tar_target(rivm_fit_summary,
             summarise_fit(fit_model(
               rivm_analysis$snapshots, model,
               serial_parameters = list(mean = 5, sd = 3),
               Rt_piece_width = 7,
               niterations = n_iterations_real,
               seed = 1,
               settings = rivm_settings)),
             pattern = map(model), iteration = "list"),
  tar_target(rivm_score,
             score_real_fit(rivm_fit_summary, rivm_analysis),
             pattern = map(rivm_fit_summary)),
  # the full model without batches, to separate the effects of misdating and
  # of batches
  tar_target(rivm_fit_summary_no_batches, {
    settings <- rivm_settings
    settings$priors$batches <- NULL
    fit_summary <- summarise_fit(fit_model(
      rivm_analysis$snapshots, "full",
      serial_parameters = list(mean = 5, sd = 3),
      Rt_piece_width = 7,
      niterations = n_iterations_real,
      seed = 1,
      settings = settings))
    fit_summary$model <- "full without batches"
    fit_summary
  }),
  tar_target(rivm_score_all,
             dplyr::bind_rows(
               rivm_score,
               score_real_fit(rivm_fit_summary_no_batches, rivm_analysis)),
             deployment = "main"),
  tar_target(rivm_batches,
             rivm_fit_summary[[3]]$batches %>%
               dplyr::count(.data$start, .data$width, .data$time_detected,
                            name = "n_draws") %>%
               dplyr::arrange(dplyr::desc(.data$n_draws)) %>%
               dplyr::mutate(
                 proportion_of_draws = .data$n_draws /
                   nrow(rivm_fit_summary[[3]]$batch_parameters)),
             deployment = "main"),

  # ---- Netherlands: a range of analysis dates --------------------------------
  # reporting delays as seen with hindsight
  tar_target(rivm_ecdf,
             reporting_delay_ecdf(rivm_snapshots, "2020-07-01", "2020-09-12")),
  tar_target(figure_rivm_cases_periods,
             save_plot(plot_real_cases_periods(rivm_ecdf),
                       "outputs/rivm_cases_periods.png", 9, 3.2),
             format = "file", deployment = "main"),
  tar_target(figure_rivm_ecdf,
             save_plot(plot_real_ecdf(rivm_ecdf),
                       "outputs/rivm_ecdf.png", 9, 3.6),
             format = "file", deployment = "main"),
  # analysis dates a week apart, chosen so that each falls at the end of one of
  # the seven-day periods over which Rt is constant: otherwise the latest
  # period holds only a few onset days, about which the data say very little
  tar_target(rivm_dates_now,
             as.Date("2020-07-01") + 7 * (5:10) - 1),
  tar_target(rivm_analysis_dates,
             prepare_real_analysis(rivm_snapshots, "2020-07-01", rivm_dates_now),
             pattern = map(rivm_dates_now), iteration = "list"),
  # the original model and the model with sporadic revisions and misdating
  # (batches are left out, since they did not help for these data)
  tar_target(rivm_model_dates, c("original", "full")),
  tar_target(rivm_result_dates, {
    settings <- fit_settings()
    settings$max_erroneous <- max(3, incidenceinflation::max_downward_revision(
      rivm_analysis_dates$snapshots) + 1)
    settings$priors$reporting <- list(mean_mu = 7, mean_sigma = 10,
                                      sd_mu = 5, sd_sigma = 5)
    settings$priors$revisions$eta_mu <- 0.005
    settings$priors$revisions$eta_sigma <- 0.005
    settings$priors$batches <- NULL
    list(model = rivm_model_dates,
         analysis = rivm_analysis_dates,
         summary = summarise_fit(fit_model(
           rivm_analysis_dates$snapshots, rivm_model_dates,
           serial_parameters = list(mean = 5, sd = 3),
           Rt_piece_width = 7,
           niterations = n_iterations_real,
           seed = 1,
           settings = settings)))
  }, pattern = cross(rivm_analysis_dates, rivm_model_dates), iteration = "list"),
  tar_target(rivm_score_dates,
             purrr::map_dfr(rivm_result_dates, function(result) {
               dplyr::bind_cols(
                 dplyr::tibble(date_now = result$analysis$date_now),
                 score_real_fit(result$summary, result$analysis))
             }),
             deployment = "main"),
  tar_target(figure_rivm_cases_dates,
             save_plot(plot_real_cases_dates(rivm_result_dates),
                       "outputs/rivm_cases_dates.png", 10, 6),
             format = "file", deployment = "main"),
  tar_target(figure_rivm_Rt_dates,
             save_plot(plot_real_Rt_dates(rivm_result_dates, 7,
                                          list(mean = 5, sd = 3)),
                       "outputs/rivm_Rt_dates.png", 10, 6),
             format = "file", deployment = "main"),
  tar_target(file_rivm_score_dates, {
    utils::write.csv(rivm_score_dates, "outputs/rivm_scores_dates.csv",
                     row.names = FALSE)
    "outputs/rivm_scores_dates.csv"
  }, format = "file", deployment = "main"),

  # ---- negative binomial renewal model, and further datasets ------------------
  tar_target(renewal_is_nb, c(FALSE, TRUE)),

  # Netherlands with a negative binomial renewal model (the Poisson fits are
  # rivm_result_dates)
  tar_target(rivm_nb_result_dates,
             fit_real_analysis(rivm_analysis_dates, rivm_model_dates,
                               is_negative_binomial = TRUE,
                               dataset = "Netherlands",
                               serial_parameters = list(mean = 5, sd = 3),
                               Rt_piece_width = 7,
                               niterations = n_iterations_real),
             pattern = cross(rivm_analysis_dates, rivm_model_dates),
             iteration = "list"),

  # Hong Kong: cases by onset date during the wave of July and August 2020
  tar_target(hk_file, "data/processed/hk_onset_snapshots.csv", format = "file"),
  tar_target(hk_snapshots, read_snapshots(hk_file)),
  tar_target(hk_dates_now, as.Date("2020-06-29") + 7 * (3:7) - 1),
  tar_target(hk_analysis_dates,
             prepare_real_analysis(hk_snapshots, "2020-06-29", hk_dates_now),
             pattern = map(hk_dates_now), iteration = "list"),
  tar_target(hk_result_dates,
             fit_real_analysis(hk_analysis_dates, rivm_model_dates,
                               is_negative_binomial = renewal_is_nb,
                               dataset = "Hong Kong",
                               serial_parameters = list(mean = 5, sd = 3),
                               Rt_piece_width = 7,
                               niterations = n_iterations_real),
             pattern = cross(hk_analysis_dates, rivm_model_dates, renewal_is_nb),
             iteration = "list"),

  # Sweden: deaths by date of death during autumn 2020
  tar_target(sweden_file, "data/processed/sweden_deaths_snapshots.csv",
             format = "file"),
  tar_target(sweden_snapshots, read_snapshots(sweden_file, "date_event")),
  tar_target(sweden_dates_now, as.Date("2020-10-05") + 7 * (6:10) - 1),
  tar_target(sweden_analysis_dates,
             prepare_real_analysis(sweden_snapshots, "2020-10-05", sweden_dates_now),
             pattern = map(sweden_dates_now), iteration = "list"),
  tar_target(sweden_result_dates,
             fit_real_analysis(sweden_analysis_dates, rivm_model_dates,
                               is_negative_binomial = renewal_is_nb,
                               dataset = "Sweden",
                               serial_parameters = list(mean = 5, sd = 3),
                               Rt_piece_width = 7,
                               niterations = n_iterations_real),
             pattern = cross(sweden_analysis_dates, rivm_model_dates, renewal_is_nb),
             iteration = "list"),

  tar_target(real_scores, {
    netherlands_poisson <- purrr::map(rivm_result_dates, function(result) {
      result$dataset <- "Netherlands"
      result$is_negative_binomial <- FALSE
      result
    })
    score_real_results(c(netherlands_poisson, rivm_nb_result_dates,
                         hk_result_dates, sweden_result_dates))
  }, deployment = "main"),
  tar_target(real_score_summary, summarise_real_scores(real_scores),
             deployment = "main"),
  tar_target(file_real_scores, {
    utils::write.csv(real_scores, "outputs/real_scores.csv", row.names = FALSE)
    utils::write.csv(real_score_summary, "outputs/real_score_summary.csv",
                     row.names = FALSE)
    c("outputs/real_scores.csv", "outputs/real_score_summary.csv")
  }, format = "file", deployment = "main"),
  tar_target(figures_real_nb, {
    serial <- list(mean = 5, sd = 3)
    c(save_plot(plot_real_cases_dates(rivm_nb_result_dates),
                "outputs/rivm_cases_dates_nb.png", 10, 6),
      save_plot(plot_real_Rt_dates(rivm_nb_result_dates, 7, serial),
                "outputs/rivm_Rt_dates_nb.png", 10, 6),
      save_plot(plot_real_cases_dates(filter_results(hk_result_dates, FALSE)),
                "outputs/hk_cases_dates_poisson.png", 10, 6),
      save_plot(plot_real_cases_dates(filter_results(hk_result_dates, TRUE)),
                "outputs/hk_cases_dates_nb.png", 10, 6),
      save_plot(plot_real_Rt_dates(filter_results(hk_result_dates, TRUE), 7, serial),
                "outputs/hk_Rt_dates_nb.png", 10, 6),
      save_plot(plot_real_cases_dates(filter_results(sweden_result_dates, FALSE)),
                "outputs/sweden_cases_dates_poisson.png", 10, 6),
      save_plot(plot_real_cases_dates(filter_results(sweden_result_dates, TRUE)),
                "outputs/sweden_cases_dates_nb.png", 10, 6),
      save_plot(plot_real_Rt_dates(filter_results(sweden_result_dates, TRUE), 7, serial),
                "outputs/sweden_Rt_dates_nb.png", 10, 6))
  }, format = "file", deployment = "main"),

  # ---- Bundibugyo virus disease outbreak, 2026 --------------------------------
  # the raw files are not tracked, so these targets need them to be present;
  # the folder is listed afresh on every run so that files added to it are seen
  tar_target(bvd_files,
             list.files("data/raw/Ebola CFR", pattern = "^Varified.*\\.csv$",
                        full.names = TRUE),
             format = "file", cue = tar_cue(mode = "always")),
  tar_target(bvd_snapshots, build_bvd_snapshots(bvd_files)),
  # reporting delays: cases reported by each delay, for onset dates from the
  # first situation report onwards
  tar_target(figure_bvd_delay_tiles,
             save_plot(plot_delay_tiles(bvd_snapshots),
                       "outputs/bvd_delay_tiles.png", 11, 6),
             format = "file", deployment = "main"),
  # analysis dates either side of the large correction made on 6 September,
  # ending with the latest situation report
  tar_target(bvd_dates_now,
             as.Date(c("2026-08-16", "2026-08-30", "2026-09-05", "2026-09-06",
                       "2026-09-20", "2026-10-01"))),
  tar_target(bvd_analysis,
             prepare_bvd_analysis(bvd_snapshots, bvd_dates_now),
             pattern = map(bvd_dates_now), iteration = "list"),
  tar_target(bvd_model, bvd_model_names()),
  tar_target(bvd_result,
             fit_bvd_analysis(bvd_analysis, bvd_model, n_iterations_bvd),
             pattern = cross(bvd_analysis, bvd_model), iteration = "list",
             priority = 1),
  # sensitivity of the latest analysis to the serial interval assumed: a
  # shorter and less variable alternative
  tar_target(bvd_result_short_serial,
             fit_bvd_analysis(bvd_analysis[[length(bvd_analysis)]],
                              "revisions and batches", n_iterations_bvd,
                              serial_parameters = list(mean = 12, sd = 6))),
  tar_target(bvd_serial_sensitivity, {
    latest <- bvd_result[purrr::map_lgl(bvd_result, function(result) {
      result$analysis$date_now == max(bvd_dates_now) &
        result$model == "revisions and batches"
    })]
    purrr::map_dfr(c(latest, list(bvd_result_short_serial)), function(result) {
      dplyr::bind_cols(
        dplyr::tibble(serial_mean = result$serial_parameters$mean,
                      serial_sd = result$serial_parameters$sd),
        dplyr::select(result$summary$Rt, "time_onset", "q05", "q50", "q95")) %>%
        dplyr::left_join(result$analysis$dates, by = "time_onset")
    })
  }, deployment = "main"),
  tar_target(bvd_scores, score_bvd_results(bvd_result), deployment = "main"),
  tar_target(bvd_batches, summarise_bvd_batches(bvd_result), deployment = "main"),
  tar_target(files_bvd, {
    utils::write.csv(bvd_scores, "outputs/bvd_scores.csv", row.names = FALSE)
    utils::write.csv(bvd_batches, "outputs/bvd_batches.csv", row.names = FALSE)
    utils::write.csv(bvd_serial_sensitivity, "outputs/bvd_serial_sensitivity.csv",
                     row.names = FALSE)
    c("outputs/bvd_scores.csv", "outputs/bvd_batches.csv",
      "outputs/bvd_serial_sensitivity.csv",
      save_plot(plot_bvd_cases(bvd_result), "outputs/bvd_cases.png", 12, 7),
      save_plot(plot_bvd_Rt(bvd_result), "outputs/bvd_Rt.png", 10, 6))
  }, format = "file", deployment = "main"),

  # ---- comparison of mechanisms in the model of reporting ---------------------
  tar_target(comparison_snapshots, list(
    bvd = dplyr::select(bvd_snapshots, "date_onset", "date_reported", "cases_reported"),
    measles = build_measles_snapshots(),
    sweden = sweden_snapshots,
    hk = hk_snapshots)),
  tar_target(comparison_analysis, {
    datasets <- comparison_datasets()
    purrr::flatten(purrr::imap(datasets, function(dataset, name) {
      purrr::map(dataset$dates_now, function(date_now) {
        analysis <- prepare_comparison_analysis(
          comparison_snapshots[[dataset$key]], dataset$date_earliest, date_now)
        analysis$dataset <- name
        analysis$serial_parameters <- dataset$serial_parameters
        analysis
      })
    }))
  }, iteration = "list"),
  tar_target(comparison_model, comparison_models()),
  tar_target(comparison_result,
             fit_comparison_model(comparison_analysis, comparison_model,
                                  comparison_analysis$serial_parameters,
                                  n_iterations_bvd),
             pattern = cross(comparison_analysis, comparison_model),
             iteration = "list"),
  tar_target(comparison_scores,
             purrr::map_dfr(comparison_result,
                            ~score_comparison_result(., .$analysis$dataset)),
             deployment = "main"),
  tar_target(comparison_summary, summarise_comparison(comparison_scores),
             deployment = "main"),
  tar_target(files_comparison, {
    utils::write.csv(comparison_scores, "outputs/comparison_scores.csv", row.names = FALSE)
    utils::write.csv(comparison_summary$by_dataset,
                     "outputs/comparison_by_dataset.csv", row.names = FALSE)
    utils::write.csv(comparison_summary$overall,
                     "outputs/comparison_overall.csv", row.names = FALSE)
    c("outputs/comparison_scores.csv", "outputs/comparison_by_dataset.csv",
      "outputs/comparison_overall.csv",
      save_plot(plot_comparison_scores(comparison_scores),
                "outputs/comparison_scores.png", 10, 7))
  }, format = "file", deployment = "main"),

  # ---- changes at unknown times in Rt and in the reporting delay ---------------
  tar_target(changepoint_grid,
             tidyr::expand_grid(changepoint_regimes(),
                                replicate = seq_len(n_replicates))),
  tar_target(changepoint_dataset,
             simulate_changepoint_dataset(changepoint_grid, changepoint_grid$replicate),
             pattern = map(changepoint_grid), iteration = "list"),
  tar_target(changepoint_model, changepoint_models()),
  tar_target(changepoint_result,
             fit_changepoint_simulation(changepoint_dataset, changepoint_model,
                                        n_iterations),
             pattern = cross(changepoint_dataset, changepoint_model),
             iteration = "list", priority = 1),
  tar_target(changepoint_scores, {
    datasets <- stats::setNames(
      changepoint_dataset,
      purrr::map_chr(changepoint_dataset, ~paste(.$regime, .$replicate)))
    purrr::map_dfr(changepoint_result, function(result) {
      score_changepoint_simulation(
        result, datasets[[paste(result$regime, result$replicate)]])
    })
  }, deployment = "main"),
  tar_target(changepoint_summary, summarise_changepoint_simulation(changepoint_scores),
             deployment = "main"),
  tar_target(changepoint_comparison_result,
             fit_changepoint_comparison(comparison_analysis, changepoint_model,
                                        comparison_analysis$serial_parameters,
                                        n_iterations_bvd),
             pattern = cross(comparison_analysis, changepoint_model),
             iteration = "list"),
  # Bundibugyo virus disease from the date of the first situation report only:
  # for earlier onset dates nothing is known of reporting soon after onset, so
  # the delay then cannot be estimated
  tar_target(changepoint_bvd_analysis, {
    name <- "Bundibugyo virus disease, 2026"
    dataset <- comparison_datasets()[[name]]
    date_first_report <- min(comparison_snapshots$bvd$date_reported)
    purrr::map(dataset$dates_now, function(date_now) {
      analysis <- prepare_comparison_analysis(
        comparison_snapshots$bvd, date_first_report, date_now)
      analysis$dataset <- name
      analysis$serial_parameters <- dataset$serial_parameters
      analysis
    })
  }, iteration = "list"),
  tar_target(changepoint_bvd_result,
             fit_changepoint_comparison(changepoint_bvd_analysis, changepoint_model,
                                        changepoint_bvd_analysis$serial_parameters,
                                        n_iterations_bvd),
             pattern = cross(changepoint_bvd_analysis, changepoint_model),
             iteration = "list"),
  tar_target(changepoint_comparison_combined,
             c(purrr::discard(changepoint_comparison_result,
                              ~grepl("Bundibugyo", .$analysis$dataset)),
               changepoint_bvd_result),
             deployment = "main"),
  tar_target(changepoint_comparison_scores,
             purrr::map_dfr(changepoint_comparison_combined,
                            score_changepoint_comparison),
             deployment = "main"),
  tar_target(changepoint_comparison_summary,
             summarise_changepoint_comparison(changepoint_comparison_scores),
             deployment = "main"),
  tar_target(files_changepoints, {
    utils::write.csv(changepoint_scores, "outputs/changepoint_simulation_scores.csv",
                     row.names = FALSE)
    utils::write.csv(changepoint_summary, "outputs/changepoint_simulation_summary.csv",
                     row.names = FALSE)
    c("outputs/changepoint_simulation_scores.csv",
      "outputs/changepoint_simulation_summary.csv",
      save_plot(plot_changepoint_simulation_scores(changepoint_scores),
                "outputs/changepoint_simulation_scores.png", 11, 9),
      save_plot(plot_changepoint_simulation_examples(changepoint_dataset,
                                                     changepoint_result),
                "outputs/changepoint_simulation_examples.png", 13, 6))
  }, format = "file", deployment = "main"),
  tar_target(files_changepoint_comparison, {
    utils::write.csv(changepoint_comparison_scores,
                     "outputs/changepoint_comparison_scores.csv", row.names = FALSE)
    utils::write.csv(changepoint_comparison_summary$by_dataset,
                     "outputs/changepoint_comparison_by_dataset.csv", row.names = FALSE)
    utils::write.csv(changepoint_comparison_summary$overall,
                     "outputs/changepoint_comparison_overall.csv", row.names = FALSE)
    c("outputs/changepoint_comparison_scores.csv",
      "outputs/changepoint_comparison_by_dataset.csv",
      "outputs/changepoint_comparison_overall.csv",
      save_plot(plot_changepoint_comparison_scores(changepoint_comparison_scores),
                "outputs/changepoint_comparison_scores.png", 10, 7),
      save_plot(plot_changepoint_comparison_trajectories(changepoint_comparison_combined),
                "outputs/changepoint_comparison_trajectories.png", 13, 6.5))
  }, format = "file", deployment = "main"),

  # Bundibugyo virus disease at each analysis date with the model in which both
  # Rt and the delay change, from the date of the first situation report
  tar_target(bvd_cp_analysis,
             prepare_bvd_changepoint_analysis(bvd_snapshots, bvd_dates_now),
             pattern = map(bvd_dates_now), iteration = "list"),
  # several chains for each analysis date, from different starting values
  tar_target(bvd_cp_chain_index, seq_len(n_chains_bvd)),
  tar_target(bvd_cp_chain,
             fit_bvd_changepoint_chain(bvd_cp_analysis, bvd_cp_chain_index,
                                       n_iterations_bvd_cp),
             pattern = cross(bvd_cp_analysis, bvd_cp_chain_index),
             iteration = "list"),
  tar_target(bvd_cp_result, {
    dates <- purrr::map_chr(bvd_cp_chain, ~as.character(.$analysis$date_now))
    purrr::map(split(bvd_cp_chain, dates), combine_bvd_chains)
  }, deployment = "main"),
  tar_target(bvd_cp_diagnostics,
             purrr::map_dfr(bvd_cp_result, function(result) {
               dplyr::bind_cols(
                 dplyr::tibble(date_now = result$analysis$date_now,
                               n_chains = result$n_chains,
                               rhat_cases_max = max(result$rhat_cases$rhat, na.rm = TRUE)),
                 result$diagnostics)
             }), deployment = "main"),
  tar_target(bvd_cp_scores, score_bvd_changepoints(bvd_cp_result),
             deployment = "main"),
  tar_target(files_bvd_cp, {
    latest <- bvd_cp_result[[which.max(purrr::map_dbl(
      bvd_cp_result, ~as.numeric(.$analysis$date_now)))]]
    utils::write.csv(bvd_cp_scores, "outputs/bvd_changepoint_scores.csv",
                     row.names = FALSE)
    utils::write.csv(bvd_cp_diagnostics, "outputs/bvd_changepoint_diagnostics.csv",
                     row.names = FALSE)
    utils::write.csv(summarise_bvd_changepoint_parameters(latest),
                     "outputs/bvd_changepoint_parameters.csv", row.names = FALSE)
    c("outputs/bvd_changepoint_scores.csv", "outputs/bvd_changepoint_parameters.csv",
      save_plot(plot_bvd_changepoint_main(latest),
                "outputs/bvd_changepoint_main.png", 12, 8.5),
      save_plot(plot_bvd_changepoint_parameters(latest),
                "outputs/bvd_changepoint_parameters.png", 12, 10),
      save_plot(plot_bvd_changepoint_cases(bvd_cp_result),
                "outputs/bvd_changepoint_cases.png", 12, 7),
      save_plot(plot_bvd_changepoint_convergence(latest),
                "outputs/bvd_changepoint_convergence.png", 12, 8))
  }, format = "file", deployment = "main"),
  tar_target(bvd_cp_checks,
             bvd_changepoint_checks(bvd_cp_result[[which.max(purrr::map_dbl(
               bvd_cp_result, ~as.numeric(.$analysis$date_now)))]]),
             deployment = "main"),
  # tables and numbers read by docs/bvd_changepoints.tex
  tar_target(files_bvd_tables,
             write_bvd_tables(bvd_cp_result, bvd_cp_scores, bvd_cp_diagnostics,
                              bvd_cp_checks),
             format = "file", deployment = "main"),
  tar_target(files_bvd_cp_checks, {
    utils::write.csv(bvd_cp_checks$summary, "outputs/bvd_changepoint_checks.csv",
                     row.names = FALSE)
    c("outputs/bvd_changepoint_checks.csv",
      save_plot(plot_bvd_changepoint_checks(bvd_cp_checks),
                "outputs/bvd_changepoint_checks.png", 12, 13))
  }, format = "file", deployment = "main"),

  tar_target(figure_bvd_check_added,
             save_plot(plot_bvd_check_added(bvd_cp_checks),
                       "outputs/bvd_changepoint_check_added.png", 11, 4.6),
             format = "file", deployment = "main"),

  # demonstrations that changes are recovered from simulated data
  tar_target(changepoint_demo_scenario, changepoint_demonstration_scenarios()),
  tar_target(changepoint_demo_dataset,
             simulate_changepoint_demonstration(changepoint_demo_scenario),
             pattern = map(changepoint_demo_scenario), iteration = "list"),
  tar_target(changepoint_demo_result,
             fit_changepoint_demonstration(changepoint_demo_dataset,
                                           n_iterations_demo),
             pattern = map(changepoint_demo_dataset), iteration = "list"),
  tar_target(changepoint_demo_summary,
             summarise_changepoint_demonstrations(changepoint_demo_result),
             deployment = "main"),
  tar_target(files_changepoint_demo, {
    utils::write.csv(changepoint_demo_summary,
                     "outputs/changepoint_demonstrations.csv", row.names = FALSE)
    c("outputs/changepoint_demonstrations.csv",
      save_plot(plot_changepoint_demonstrations(changepoint_demo_result),
                "outputs/changepoint_demonstrations.png", 14, 9))
  }, format = "file", deployment = "main"),

  # ---- cases and deaths: validation on simulated data (docs/bvd_deaths.tex) ---
  tar_target(deaths_sim_grid,
             tidyr::expand_grid(scenario = deaths_scenarios()$scenario,
                                replicate = seq_len(n_replicates_deaths))),
  tar_target(deaths_sim_dataset,
             simulate_deaths_dataset(deaths_sim_grid$scenario, deaths_sim_grid$replicate),
             pattern = map(deaths_sim_grid), iteration = "list"),
  tar_target(deaths_sim_chain, seq_len(n_chains_deaths)),
  # progress of each chain is written to outputs/deaths_simulation/progress/
  tar_target(deaths_sim_fit,
             fit_deaths_chain(deaths_sim_dataset, deaths_sim_chain, n_iterations_deaths),
             pattern = cross(deaths_sim_dataset, deaths_sim_chain), iteration = "list"),
  tar_target(deaths_sim_summary,
             purrr::map_dfr(deaths_sim_dataset, summarise_deaths_fits,
                            fits = deaths_sim_fit),
             deployment = "main"),
  tar_target(deaths_sim_coverage,
             purrr::map_dfr(deaths_sim_dataset, deaths_cases_coverage,
                            fits = deaths_sim_fit),
             deployment = "main"),
  tar_target(file_deaths_sim, {
    utils::write.csv(deaths_sim_summary, "outputs/deaths_validation_by_dataset.csv",
                     row.names = FALSE)
    utils::write.csv(summarise_deaths_scenarios(deaths_sim_summary),
                     "outputs/deaths_validation_summary.csv", row.names = FALSE)
    utils::write.csv(summarise_deaths_coverage(deaths_sim_coverage),
                     "outputs/deaths_validation_coverage.csv", row.names = FALSE)
    utils::write.csv(deaths_scenarios(), "outputs/deaths_validation_scenarios.csv",
                     row.names = FALSE)
    c("outputs/deaths_validation_by_dataset.csv", "outputs/deaths_validation_summary.csv",
      "outputs/deaths_validation_coverage.csv", "outputs/deaths_validation_scenarios.csv")
  }, format = "file", deployment = "main"),
  tar_target(figure_deaths_sim_overview,
             save_plot(plot_deaths_validation(deaths_sim_summary),
                       "outputs/deaths_validation_overview.png", 12, 7),
             format = "file", deployment = "main"),
  tar_target(figure_deaths_sim_pages,
             write_deaths_simulation_pages(deaths_sim_dataset, deaths_sim_fit),
             format = "file", deployment = "main"),

  # ---- cases and deaths: the time from onset to death supplied and the -------
  # fraction of fatal cases counted on their day of death estimated, on
  # simulated data. Progress of each chain is written to
  # outputs/misdated_simulation/progress/
  tar_target(misdated_sim_grid,
             tidyr::expand_grid(scenario = misdated_scenarios()$scenario,
                                replicate = seq_len(n_replicates_misdated))),
  tar_target(misdated_sim_dataset,
             simulate_misdated_dataset(misdated_sim_grid$scenario,
                                       misdated_sim_grid$replicate),
             pattern = map(misdated_sim_grid), iteration = "list"),
  tar_target(misdated_sim_chain, seq_len(n_chains_misdated)),
  tar_target(misdated_sim_fit,
             fit_misdated_chain(misdated_sim_dataset, misdated_sim_chain,
                                n_iterations_misdated),
             pattern = cross(misdated_sim_dataset, misdated_sim_chain),
             iteration = "list"),
  tar_target(misdated_sim_summary,
             purrr::map_dfr(misdated_sim_dataset, summarise_misdated_fits,
                            fits = misdated_sim_fit),
             deployment = "main"),
  tar_target(file_misdated_sim, {
    utils::write.csv(misdated_sim_summary, "outputs/misdated_simulation_by_dataset.csv",
                     row.names = FALSE)
    utils::write.csv(summarise_misdated_scenarios(misdated_sim_summary),
                     "outputs/misdated_simulation_summary.csv", row.names = FALSE)
    utils::write.csv(misdated_scenarios(), "outputs/misdated_simulation_scenarios.csv",
                     row.names = FALSE)
    c("outputs/misdated_simulation_by_dataset.csv",
      "outputs/misdated_simulation_summary.csv",
      "outputs/misdated_simulation_scenarios.csv")
  }, format = "file", deployment = "main"),

  # ---- Bundibugyo virus disease: cases and deaths ------------------------------
  # the joint model of cases and deaths fitted to all reports up to the latest,
  # once taking no fatal cases to be dated by death and once taking a fifth to be
  # the same fit to the reports up to each of several dates, with the chains
  # started close together: do the estimates made at earlier dates agree with
  # what the latest report shows?
  tar_target(bvd_nowcast_date, bvd_nowcast_dates()),
  tar_target(bvd_nowcast_analysis,
             prepare_bvd_deaths_analysis(bvd_snapshots, bvd_nowcast_date),
             pattern = map(bvd_nowcast_date), iteration = "list"),
  tar_target(bvd_nowcast_chain,
             fit_bvd_deaths_chain(bvd_nowcast_analysis, "none", bvd_deaths_chain_index,
                                  n_iterations_bvd_deaths, starts = "close"),
             pattern = cross(bvd_nowcast_analysis, bvd_deaths_chain_index),
             iteration = "list"),
  tar_target(bvd_nowcast_days, bvd_nowcast_by_day(bvd_nowcast_chain, bvd_snapshots),
             deployment = "main"),
  tar_target(files_bvd_nowcast, {
    utils::write.csv(bvd_nowcast_runs(bvd_nowcast_chain), "outputs/bvd_nowcast_runs.csv",
                     row.names = FALSE)
    utils::write.csv(bvd_nowcast_summary(bvd_nowcast_chain),
                     "outputs/bvd_nowcast_summary.csv", row.names = FALSE)
    utils::write.csv(bvd_nowcast_days, "outputs/bvd_nowcast_by_day.csv", row.names = FALSE)
    utils::write.csv(bvd_nowcast_comparison(bvd_nowcast_chain, bvd_snapshots),
                     "outputs/bvd_nowcast_comparison.csv", row.names = FALSE)
    c("outputs/bvd_nowcast_runs.csv", "outputs/bvd_nowcast_summary.csv",
      "outputs/bvd_nowcast_by_day.csv", "outputs/bvd_nowcast_comparison.csv",
      save_plot(plot_bvd_nowcasts(bvd_nowcast_days), "outputs/bvd_nowcasts.png", 13, 6),
      save_plot(plot_bvd_nowcast_parameters(bvd_nowcast_days),
                "outputs/bvd_nowcast_parameters.png", 8, 10))
  }, format = "file", deployment = "main"),

  # parts of the joint model fitted on their own: cases alone, deaths alone,
  # and the joint model with the true cases fixed at their posterior medians
  # from the model of cases alone
  tar_target(bvd_part_date, bvd_part_dates()),
  tar_target(bvd_part_analysis,
             prepare_bvd_deaths_analysis(bvd_snapshots, bvd_part_date),
             pattern = map(bvd_part_date), iteration = "list"),
  # The first three sets of chains were run before the options for the
  # second two were added to the functions which fit them. Their defaults
  # give the same fits, so these are not run again when those functions
  # change (cue "never"); delete the targets to rerun them.
  tar_target(bvd_part_cases_chain,
             fit_bvd_single_chain(bvd_part_analysis, bvd_snapshots, "cases",
                                  bvd_deaths_chain_index, n_iterations_bvd_deaths),
             pattern = cross(bvd_part_analysis, bvd_deaths_chain_index),
             iteration = "list", cue = tar_cue(mode = "never")),
  tar_target(bvd_part_deaths_chain,
             fit_bvd_single_chain(bvd_part_analysis, bvd_snapshots, "deaths",
                                  bvd_deaths_chain_index, n_iterations_bvd_deaths),
             pattern = cross(bvd_part_analysis, bvd_deaths_chain_index),
             iteration = "list", cue = tar_cue(mode = "never")),
  tar_target(bvd_part_fixed_chain,
             fit_bvd_fixed_cases_chain(
               bvd_part_analysis,
               bvd_cases_median(bvd_part_cases_chain, bvd_part_analysis$date_now),
               bvd_deaths_chain_index, n_iterations_bvd_deaths),
             pattern = cross(bvd_part_analysis, bvd_deaths_chain_index),
             iteration = "list", cue = tar_cue(mode = "never")),
  # deaths alone with no heavier tail of the delay
  tar_target(bvd_part_deaths_no_tail_chain,
             fit_bvd_single_chain(bvd_part_analysis, bvd_snapshots, "deaths",
                                  bvd_deaths_chain_index, n_iterations_bvd_deaths,
                                  tail = FALSE),
             pattern = cross(bvd_part_analysis, bvd_deaths_chain_index),
             iteration = "list", cue = tar_cue(mode = "never")),
  # cases fixed, with no change in the delay to a death being recorded among
  # the onset days corrected by a later report
  tar_target(bvd_part_fixed_rule_chain,
             fit_bvd_fixed_cases_chain(
               bvd_part_analysis,
               bvd_cases_median(bvd_part_cases_chain, bvd_part_analysis$date_now),
               bvd_deaths_chain_index, n_iterations_bvd_deaths,
               delay_first_length = bvd_delay_first_length(bvd_part_analysis)),
             pattern = cross(bvd_part_analysis, bvd_deaths_chain_index),
             iteration = "list", cue = tar_cue(mode = "never")),
  tar_target(files_bvd_parts, {
    chains <- c(bvd_part_cases_chain, bvd_part_deaths_chain, bvd_part_fixed_chain,
                bvd_part_deaths_no_tail_chain, bvd_part_fixed_rule_chain)
    by_day <- bvd_part_by_day(chains)
    utils::write.csv(bvd_part_runs(chains), "outputs/bvd_part_runs.csv",
                     row.names = FALSE)
    utils::write.csv(bvd_part_summary(chains), "outputs/bvd_part_summary.csv",
                     row.names = FALSE)
    utils::write.csv(by_day, "outputs/bvd_part_by_day.csv", row.names = FALSE)
    c("outputs/bvd_part_runs.csv", "outputs/bvd_part_summary.csv",
      "outputs/bvd_part_by_day.csv",
      save_plot(plot_bvd_parts(by_day), "outputs/bvd_parts.png", 16, 8))
  }, format = "file", deployment = "main"),

  # forms of the delay to a death being recorded, in the model of deaths
  # alone: the early onset days left out, a heavier tail with a tight prior,
  # and a log-normal delay; with the model of no tail and of cases alone for
  # the reports to 5 September
  tar_target(bvd_form_date, bvd_form_dates()),
  tar_target(bvd_form_analysis,
             prepare_bvd_deaths_analysis(bvd_snapshots, bvd_form_date),
             pattern = map(bvd_form_date), iteration = "list"),
  tar_target(bvd_form_analysis_first,
             prepare_bvd_deaths_analysis(bvd_snapshots, min(bvd_form_dates()))),
  tar_target(bvd_form_chain_index, seq_len(n_chains_bvd_forms)),
  tar_target(bvd_form_lognormal_chain,
             fit_bvd_single_chain(bvd_form_analysis, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_forms,
                                  tail = FALSE, family = "lognormal"),
             pattern = cross(bvd_form_analysis, bvd_form_chain_index),
             iteration = "list"),
  tar_target(bvd_form_from_june_chain,
             fit_bvd_single_chain(bvd_form_analysis, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_forms,
                                  tail = FALSE, onset_from = bvd_form_onset_from()),
             pattern = cross(bvd_form_analysis, bvd_form_chain_index),
             iteration = "list"),
  tar_target(bvd_form_tail_chain,
             fit_bvd_single_chain(bvd_form_analysis, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_forms,
                                  tail_prior = bvd_form_tail_prior()),
             pattern = cross(bvd_form_analysis, bvd_form_chain_index),
             iteration = "list"),
  # the early onset days left out and the heavier tail with a tight prior
  tar_target(bvd_form_tail_from_june_chain,
             fit_bvd_single_chain(bvd_form_analysis, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_forms,
                                  tail_prior = bvd_form_tail_prior(),
                                  onset_from = bvd_form_onset_from()),
             pattern = cross(bvd_form_analysis, bvd_form_chain_index),
             iteration = "list"),
  tar_target(bvd_form_base_chain,
             fit_bvd_single_chain(bvd_form_analysis_first, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_forms,
                                  tail = FALSE),
             pattern = map(bvd_form_chain_index), iteration = "list"),
  tar_target(bvd_form_cases_chain,
             fit_bvd_single_chain(bvd_form_analysis_first, bvd_snapshots, "cases",
                                  bvd_form_chain_index, n_iterations_bvd_forms),
             pattern = map(bvd_form_chain_index), iteration = "list",
             cue = tar_cue(mode = "never")),

  # reports to 5 September: settings which let the delay to a death being
  # recorded change more readily, in the model of deaths alone and with the
  # cases fixed (shorter chains)
  tar_target(bvd_delay_trial, bvd_delay_trials(), iteration = "list"),
  tar_target(bvd_trial_deaths_chain,
             fit_bvd_single_chain(bvd_form_analysis_first, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_trials,
                                  tail = FALSE, delay_settings = bvd_delay_trial),
             pattern = cross(bvd_delay_trial, bvd_form_chain_index),
             iteration = "list"),
  tar_target(bvd_trial_cases_fixed,
             bvd_cases_median(bvd_form_cases_chain, bvd_form_analysis_first$date_now)),
  tar_target(bvd_trial_fixed_base_chain,
             fit_bvd_fixed_cases_chain(bvd_form_analysis_first, bvd_trial_cases_fixed,
                                       bvd_form_chain_index, n_iterations_bvd_trials),
             pattern = map(bvd_form_chain_index), iteration = "list"),
  tar_target(bvd_trial_fixed_chain,
             fit_bvd_fixed_cases_chain(bvd_form_analysis_first, bvd_trial_cases_fixed,
                                       bvd_form_chain_index, n_iterations_bvd_trials,
                                       delay_settings = bvd_delay_trial),
             pattern = cross(bvd_delay_trial, bvd_form_chain_index),
             iteration = "list"),

  # the same with a delay to a death being recorded which drifts
  tar_target(bvd_drift_deaths_chain,
             fit_bvd_single_chain(bvd_form_analysis_first, bvd_snapshots, "deaths",
                                  bvd_form_chain_index, n_iterations_bvd_trials,
                                  tail = FALSE, delay_settings = bvd_delay_drift()),
             pattern = map(bvd_form_chain_index), iteration = "list"),
  tar_target(bvd_drift_fixed_chain,
             fit_bvd_fixed_cases_chain(bvd_form_analysis_first, bvd_trial_cases_fixed,
                                       bvd_form_chain_index, n_iterations_bvd_trials,
                                       delay_settings = bvd_delay_drift()),
             pattern = map(bvd_form_chain_index), iteration = "list"),

  tar_target(bvd_deaths_analysis,
             prepare_bvd_deaths_analysis(bvd_snapshots, max(bvd_dates_now))),
  tar_target(bvd_deaths_variant, names(bvd_deaths_variants())),
  tar_target(bvd_deaths_chain_index, seq_len(n_chains_bvd_deaths)),
  tar_target(bvd_deaths_chain,
             fit_bvd_deaths_chain(bvd_deaths_analysis, bvd_deaths_variant,
                                  bvd_deaths_chain_index, n_iterations_bvd_deaths),
             pattern = cross(bvd_deaths_variant, bvd_deaths_chain_index),
             iteration = "list"),
  tar_target(bvd_deaths_summary, summarise_bvd_deaths(bvd_deaths_chain),
             deployment = "main"),
  tar_target(bvd_deaths_days, bvd_deaths_by_day(bvd_deaths_chain),
             deployment = "main"),
  tar_target(files_bvd_deaths, {
    utils::write.csv(bvd_deaths_runs(bvd_deaths_chain), "outputs/bvd_deaths_runs.csv",
                     row.names = FALSE)
    utils::write.csv(bvd_deaths_summary, "outputs/bvd_deaths_summary.csv",
                     row.names = FALSE)
    utils::write.csv(bvd_deaths_days, "outputs/bvd_deaths_by_day.csv",
                     row.names = FALSE)
    c("outputs/bvd_deaths_runs.csv", "outputs/bvd_deaths_summary.csv",
      "outputs/bvd_deaths_by_day.csv",
      save_plot(plot_bvd_deaths(bvd_deaths_days, bvd_deaths_analysis),
                "outputs/bvd_deaths.png", 11, 11))
  }, format = "file", deployment = "main"),

  # ---- outputs ---------------------------------------------------------------
  tar_target(file_scores, {
    dir.create("outputs", showWarnings = FALSE)
    utils::write.csv(simulated_score, "outputs/simulation_scores.csv", row.names = FALSE)
    utils::write.csv(simulated_score_summary, "outputs/simulation_score_summary.csv",
                     row.names = FALSE)
    utils::write.csv(rivm_score_all, "outputs/rivm_scores.csv", row.names = FALSE)
    utils::write.csv(rivm_batches, "outputs/rivm_batches.csv", row.names = FALSE)
    c("outputs/simulation_scores.csv", "outputs/simulation_score_summary.csv",
      "outputs/rivm_scores.csv", "outputs/rivm_batches.csv")
  }, format = "file"),
  tar_target(figure_simulation_scores,
             save_plot(plot_simulation_scores(simulated_score),
                       "outputs/simulation_scores.png", 9, 6),
             format = "file"),
  tar_target(figure_rivm_snapshots,
             save_plot(plot_snapshots(rivm_snapshots),
                       "outputs/rivm_snapshots.png", 8, 4.5),
             format = "file"),
  tar_target(figure_rivm_nowcast,
             save_plot(plot_real_nowcast(rivm_fit_summary, rivm_analysis),
                       "outputs/rivm_nowcast.png", 9, 4),
             format = "file"),
  tar_target(file_report,
             write_report(simulated_score_summary, simulated_score, rivm_score_all,
                          rivm_revisions, "outputs/results.md"),
             format = "file")
)

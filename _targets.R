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
  tar_target(rivm_dates_now,
             as.Date(c("2020-08-03", "2020-08-11", "2020-08-19",
                       "2020-08-27", "2020-09-04", "2020-09-12"))),
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

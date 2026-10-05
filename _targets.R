# Pipeline applying the model of incidenceinflation_2.0/docs/downward_revisions.tex
# to simulated and real data. Run with targets::tar_make().

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
n_iterations_real <- as.integer(Sys.getenv("PIPELINE_ITERATIONS_REAL", "1000"))

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
      seed = simulated_dataset$replicate))
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

  # ---- outputs ---------------------------------------------------------------
  tar_target(file_scores, {
    dir.create("outputs", showWarnings = FALSE)
    utils::write.csv(simulated_score, "outputs/simulation_scores.csv", row.names = FALSE)
    utils::write.csv(simulated_score_summary, "outputs/simulation_score_summary.csv",
                     row.names = FALSE)
    utils::write.csv(rivm_score, "outputs/rivm_scores.csv", row.names = FALSE)
    c("outputs/simulation_scores.csv", "outputs/simulation_score_summary.csv",
      "outputs/rivm_scores.csv")
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
             write_report(simulated_score_summary, simulated_score, rivm_score,
                          rivm_revisions, "outputs/results.md"),
             format = "file")
)

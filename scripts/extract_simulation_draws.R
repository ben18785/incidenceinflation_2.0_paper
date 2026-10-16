# Thins the chains of fits to simulated data saved by
# scripts/run_simulation_scenario.R (the files <scenario>.rds) to draws small
# enough to keep: each day's fatal cases, cases and share in the backlog, and
# the parameters of the deaths, for every 5th iteration kept.
# Usage: Rscript scripts/extract_simulation_draws.R <folder of rds files> <folder of results>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(library(dplyr))
files <- list.files(args[1], pattern = "\\.rds$", full.names = TRUE, recursive = TRUE)
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
thin <- 5
f_keep <- function(fit, name, columns) {
  df <- fit[[name]]
  if(is.null(df) || nrow(df) == 0)
    return(NULL)
  df %>%
    dplyr::filter(.data$iteration %% thin == 0) %>%
    dplyr::select(dplyr::any_of(c("iteration", "chain", columns))) %>%
    dplyr::mutate(scenario = fit$scenario, replicate = fit$replicate, .before = 1)
}
f_parameters <- function(fit) {
  df <- fit$deaths_parameters
  if(is.null(df) || nrow(df) == 0)
    return(NULL)
  df <- df %>% dplyr::filter(.data$iteration %% thin == 0)
  is_number <- vapply(df, is.numeric, logical(1))
  df[, is_number] %>%
    dplyr::mutate(scenario = fit$scenario, replicate = fit$replicate, .before = 1)
}
deaths <- list(); cases <- list(); parameters <- list(); chains <- list()
for(file in files) {
  fits <- readRDS(file)
  for(fit in fits) {
    chains[[length(chains) + 1]] <- dplyr::tibble(
      scenario = fit$scenario, replicate = fit$replicate, chain = fit$chain,
      minutes = fit$minutes, error = if(is.null(fit$error)) NA_character_ else fit$error)
    deaths[[length(deaths) + 1]] <- f_keep(fit, "deaths", c(
      "time_onset", "deaths_true", "deaths_recorded", "cfr", "delay_mean", "backlog_share"))
    cases[[length(cases) + 1]] <- f_keep(fit, "cases", c("time_onset", "cases_true"))
    parameters[[length(parameters) + 1]] <- f_parameters(fit)
  }
}
f_write <- function(rows, name) {
  df <- dplyr::bind_rows(rows)
  utils::write.csv(df, gzfile(file.path(args[2], paste0(name, ".csv.gz"))), row.names = FALSE)
  cat(name, nrow(df), "rows\n")
}
f_write(chains, "chains")
f_write(deaths, "deaths")
f_write(cases, "cases")
f_write(parameters, "deaths_parameters")

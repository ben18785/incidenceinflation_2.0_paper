# Writes the results of the fits to simulated data saved in a folder (GitHub
# Actions): the measures of every dataset, their means by scenario, the
# scenarios and a summary to read.
# Usage: Rscript scripts/collect_simulations.R <folder of csv files> <folder of results>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages({library(dplyr); library(targets)})
tar_source("R")
files <- list.files(args[1], pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
by_dataset <- dplyr::bind_rows(lapply(files, utils::read.csv))
cat(nrow(by_dataset), "datasets read\n")
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
summary <- summarise_misdated_scenarios(by_dataset)
utils::write.csv(by_dataset, file.path(args[2], "by_dataset.csv"), row.names = FALSE)
utils::write.csv(summary, file.path(args[2], "summary.csv"), row.names = FALSE)
utils::write.csv(misdated_scenarios(), file.path(args[2], "scenarios.csv"),
                 row.names = FALSE)
writeLines(misdated_summary_text(summary, by_dataset), file.path(args[2], "summary.md"))

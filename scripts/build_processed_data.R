# Builds the snapshot tables in data/processed/ from the raw downloads.
# Run scripts/download_data.R first.
suppressMessages({
  library(dplyr)
  library(rlang)
})
source("R/data.R")

dir.create("data/processed", showWarnings = FALSE)
rivm <- build_rivm_onset_snapshots("data/raw/rivm_casus", date_onset_min = "2020-06-01")
utils::write.csv(rivm, "data/processed/rivm_onset_snapshots.csv", row.names = FALSE)

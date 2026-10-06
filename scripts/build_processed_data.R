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

# Hong Kong case list (run scripts/download_hk.R first): snapshots by onset
# date, and every change to an individual case's onset date
hk_case_lists <- read_hk_case_lists("data/raw/hk_case_list")
utils::write.csv(build_hk_onset_snapshots(hk_case_lists, date_onset_min = "2020-06-15"),
                 "data/processed/hk_onset_snapshots.csv", row.names = FALSE)
hk_changes <- find_hk_onset_changes(hk_case_lists)
utils::write.csv(dplyr::filter(hk_changes, .data$type != "added"),
                 "data/processed/hk_onset_changes.csv", row.names = FALSE)

# Sweden: deaths by date of death as published on each date, compiled at
# https://github.com/adamaltmejd/covid (data/covid_deaths_latest.csv); kept
# here for deaths in 2020 as published up to the end of March 2021
sweden <- utils::read.csv("data/raw/sweden/covid_deaths_latest.csv") %>%
  dplyr::filter(!is.na(.data$date), .data$date != "") %>%
  dplyr::transmute(date_event = as.Date(.data$date),
                   date_reported = as.Date(.data$publication_date),
                   cases_reported = as.integer(.data$N)) %>%
  dplyr::filter(.data$date_event <= as.Date("2020-12-31"),
                .data$date_reported <= as.Date("2021-03-31"),
                .data$date_reported >= .data$date_event)
utils::write.csv(sweden, "data/processed/sweden_deaths_snapshots.csv", row.names = FALSE)

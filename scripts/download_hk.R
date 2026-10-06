# Downloads every archived version of the Hong Kong COVID-19 case list.
#
# The Centre for Health Protection published a list of every case ("Latest
# local situation of COVID-19: details of probable/confirmed cases"), with a
# case number, the report date and the date of symptom onset. data.gov.hk keeps
# each day's version of the file, which is retrieved here through its
# historical archive API (https://data.gov.hk/en/help/api-spec).

hk_case_list_url <- function() {
  "http://www.chp.gov.hk/files/misc/enhanced_sur_covid_19_eng.csv"
}

#' Lists the timestamps of the versions archived between two dates
hk_list_versions <- function(date_start, date_end) {
  # the API accepts only short ranges, so query a month at a time
  starts <- seq(as.Date(date_start), as.Date(date_end), by = "month")
  timestamps <- c()
  for(i in seq_along(starts)) {
    end <- min(as.Date(date_end), seq(starts[i], by = "month", length.out = 2)[2] - 1)
    query <- paste0(
      "https://api.data.gov.hk/v1/historical-archive/list-file-versions?url=",
      utils::URLencode(hk_case_list_url(), reserved = TRUE),
      "&start=", format(starts[i], "%Y%m%d"), "&end=", format(end, "%Y%m%d"))
    timestamps <- c(timestamps, unlist(jsonlite::fromJSON(query)$timestamps))
  }
  sort(unique(timestamps))
}

#' Downloads the first version archived on each day
download_hk_case_lists <- function(date_start, date_end,
                                   dir_out = "data/raw/hk_case_list") {
  dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
  timestamps <- hk_list_versions(date_start, date_end)
  timestamps <- timestamps[!duplicated(substr(timestamps, 1, 8))]
  for(timestamp in timestamps) {
    destination <- file.path(dir_out, paste0("hk_case_list_",
                                             substr(timestamp, 1, 8), ".csv"))
    if(file.exists(destination) && file.size(destination) > 1000)
      next
    query <- paste0(
      "https://api.data.gov.hk/v1/historical-archive/get-file?url=",
      utils::URLencode(hk_case_list_url(), reserved = TRUE),
      "&time=", timestamp)
    status <- tryCatch(utils::download.file(query, destination, quiet = TRUE, mode = "wb"),
                       error = function(e) 1, warning = function(w) 1)
    if(status != 0) {
      unlink(destination)
      message("Failed: ", timestamp)
    }
  }
  invisible(dir_out)
}

if(sys.nframe() == 0) {
  download_hk_case_lists("2020-04-04", "2021-03-31")
}

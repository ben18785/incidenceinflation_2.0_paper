# Downloads raw data into data/raw/.
#
# Netherlands COVID-19 case file ("casus landelijk"), published daily by RIVM.
# Each file lists every case known on the day of publication, with a date
# (Date_statistics) and what that date represents (Date_statistics_type):
# DOO = day of symptom onset, DPL = day of positive laboratory result,
# DON = day of notification. RIVM kept only the latest file; the daily files
# were archived by volunteers at https://github.com/mzelst/covid-19.

download_rivm_casus <- function(date_start, date_end,
                                dir_out = "data/raw/rivm_casus") {
  dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
  dates <- seq(as.Date(date_start), as.Date(date_end), by = 1)
  base_url <- paste0("https://raw.githubusercontent.com/mzelst/covid-19/master/",
                     "data-rivm/casus-datasets/")
  for(i in seq_along(dates)) {
    filename <- paste0("COVID-19_casus_landelijk_", dates[i], ".csv.gz")
    destination <- file.path(dir_out, filename)
    if(file.exists(destination) && file.size(destination) > 1000)
      next
    status <- tryCatch(
      utils::download.file(paste0(base_url, filename), destination,
                           quiet = TRUE, mode = "wb"),
      error = function(e) 1, warning = function(w) 1)
    if(status != 0) {
      unlink(destination)
      message("Not available: ", filename)
    }
  }
  invisible(dir_out)
}

if(sys.nframe() == 0) {
  download_rivm_casus("2020-07-01", "2020-10-15")
}

# Functions for turning raw downloads into snapshot tables: one row per
# (onset date, reporting date) giving the count of cases with that onset date
# as known on that reporting date.

#' Counts cases by date in a single RIVM case file
#'
#' @param path path to a COVID-19_casus_landelijk_<date>.csv.gz file
#' @return a tibble with columns date_reported, date_statistics, type, cases
count_rivm_casus_file <- function(path) {
  date_reported <- as.Date(sub(".*landelijk_(\\d{4}-\\d{2}-\\d{2})\\.csv\\.gz$", "\\1", path))
  first_line <- readLines(path, n = 1)
  separator <- if(grepl(";", first_line)) ";" else ","
  df <- utils::read.csv(path, sep = separator, stringsAsFactors = FALSE)
  df %>%
    dplyr::count(date_statistics = as.Date(.data$Date_statistics),
                 type = .data$Date_statistics_type,
                 name = "cases") %>%
    dplyr::mutate(date_reported = date_reported) %>%
    dplyr::select("date_reported", "date_statistics", "type", "cases") %>%
    dplyr::as_tibble()
}

#' Builds snapshots of cases by symptom onset date from RIVM case files
#'
#' Only cases whose date is a day of symptom onset (type DOO) are counted. A
#' case whose onset date is not yet known is listed under its laboratory or
#' notification date, and moves to its onset date if this is later learned.
#'
#' @param dir_raw directory holding the daily files
#' @param date_onset_min earliest onset date to retain
#' @return a tibble with columns date_onset, date_reported, cases_reported,
#' with a row for every reporting date on or after each onset date
build_rivm_onset_snapshots <- function(dir_raw, date_onset_min) {
  paths <- sort(list.files(dir_raw, pattern = "\\.csv\\.gz$", full.names = TRUE))
  df <- purrr::map_dfr(paths, count_rivm_casus_file) %>%
    dplyr::filter(.data$type == "DOO",
                  .data$date_statistics >= as.Date(date_onset_min)) %>%
    dplyr::select(date_onset = "date_statistics", "date_reported",
                  cases_reported = "cases")

  # onset dates absent from a file have no cases known at that time
  dates_reported <- sort(unique(df$date_reported))
  dates_onset <- seq(as.Date(date_onset_min), max(dates_reported), by = 1)
  tidyr::expand_grid(date_onset = dates_onset, date_reported = dates_reported) %>%
    dplyr::filter(.data$date_reported >= .data$date_onset) %>%
    dplyr::left_join(df, by = c("date_onset", "date_reported")) %>%
    dplyr::mutate(cases_reported = dplyr::coalesce(.data$cases_reported, 0L))
}

#' Converts dated snapshots to the integer times used by incidenceinflation
#'
#' @param df a tibble with columns date_onset, date_reported, cases_reported
#' @param date_origin date corresponding to time 1
#' @return a tibble with columns time_onset, time_reported, cases_reported
snapshots_to_times <- function(df, date_origin = min(df$date_onset)) {
  df %>%
    dplyr::transmute(
      time_onset = as.integer(.data$date_onset - as.Date(date_origin)) + 1L,
      time_reported = as.integer(.data$date_reported - as.Date(date_origin)) + 1L,
      cases_reported = as.integer(.data$cases_reported)) %>%
    dplyr::arrange(.data$time_onset, .data$time_reported)
}

#' Summarises revisions to reported counts between successive snapshots
#'
#' @param df a tibble with columns time_onset (or date_onset), time_reported
#' (or date_reported) and cases_reported
#' @return a one-row tibble
summarise_revisions <- function(df) {
  if("date_onset" %in% colnames(df))
    df <- dplyr::rename(df, time_onset = "date_onset", time_reported = "date_reported")
  changes <- df %>%
    dplyr::group_by(.data$time_onset) %>%
    dplyr::arrange(.data$time_reported, .by_group = TRUE) %>%
    dplyr::mutate(change = c(NA, diff(.data$cases_reported)),
                  fall_from_peak = cummax(.data$cases_reported) - .data$cases_reported,
                  below_first = .data$cases_reported < .data$cases_reported[1]) %>%
    dplyr::ungroup()
  dplyr::tibble(
    n_onset_days = dplyr::n_distinct(df$time_onset),
    n_intervals = sum(!is.na(changes$change)),
    n_increases = sum(changes$change > 0, na.rm = TRUE),
    n_decreases = sum(changes$change < 0, na.rm = TRUE),
    cases_added = sum(pmax(changes$change, 0), na.rm = TRUE),
    cases_removed = -sum(pmin(changes$change, 0), na.rm = TRUE),
    largest_decrease = -min(changes$change, na.rm = TRUE),
    largest_fall_from_peak = max(changes$fall_from_peak),
    n_onset_days_below_first = dplyr::n_distinct(changes$time_onset[changes$below_first]))
}

# ---- Hong Kong case list -----------------------------------------------------

#' Reads one archived version of the Hong Kong COVID-19 case list
#'
#' @param path path to a hk_case_list_<yyyymmdd>.csv file
#' @return a tibble with columns date_file, case_no, date_report, onset (as
#' given: a date as text, or e.g. "Asymptomatic" or "Unknown") and date_onset
#' (NA unless onset is a date)
read_hk_case_list <- function(path) {
  date_file <- as.Date(sub(".*_(\\d{8})\\.csv$", "\\1", path), format = "%Y%m%d")
  df <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                        fileEncoding = "UTF-8-BOM")
  onset <- trimws(df[["Date of onset"]])
  dplyr::tibble(
    date_file = date_file,
    case_no = suppressWarnings(as.integer(df[["Case no."]])),
    date_report = as.Date(df[["Report date"]], format = "%d/%m/%Y"),
    onset = onset,
    date_onset = as.Date(onset, format = "%d/%m/%Y")) %>%
    dplyr::filter(!is.na(.data$case_no))
}

#' Reads every archived version of the Hong Kong case list in a directory
read_hk_case_lists <- function(dir_raw) {
  paths <- sort(list.files(dir_raw, pattern = "\\.csv$", full.names = TRUE))
  purrr::map_dfr(paths, read_hk_case_list)
}

#' Builds snapshots of cases by symptom onset date from the Hong Kong case lists
#'
#' Only cases with a date of onset are counted: asymptomatic cases, and those
#' whose onset date is unknown or pending, are not.
#'
#' @param case_lists as returned by read_hk_case_lists()
#' @return a tibble with columns date_onset, date_reported, cases_reported
build_hk_onset_snapshots <- function(case_lists, date_onset_min) {
  counts <- case_lists %>%
    dplyr::filter(!is.na(.data$date_onset),
                  .data$date_onset >= as.Date(date_onset_min),
                  .data$date_onset <= .data$date_file) %>%
    dplyr::count(.data$date_onset, date_reported = .data$date_file,
                 name = "cases_reported")
  dates_reported <- sort(unique(case_lists$date_file))
  dates_onset <- seq(as.Date(date_onset_min), max(dates_reported), by = 1)
  tidyr::expand_grid(date_onset = dates_onset, date_reported = dates_reported) %>%
    dplyr::filter(.data$date_reported >= .data$date_onset) %>%
    dplyr::left_join(counts, by = c("date_onset", "date_reported")) %>%
    dplyr::mutate(cases_reported = dplyr::coalesce(.data$cases_reported, 0L))
}

#' Finds every change to a case's onset date between successive versions
#'
#' Because cases keep their case number, each change in the counts by onset
#' date can be traced to individual cases.
#'
#' @param case_lists as returned by read_hk_case_lists()
#' @return a tibble with a row for each change: the date of the file in which
#' it first appears, the case number, the onset recorded before and after, and
#' its type: "added" (a new case), "removed" (a case no longer listed),
#' "moved" (one onset date replaced by another), "onset learned" (a date
#' replaces a non-date), "onset withdrawn" (a non-date replaces a date) or
#' "other" (one non-date replaced by another)
find_hk_onset_changes <- function(case_lists) {
  dates <- sort(unique(case_lists$date_file))
  by_date <- split(case_lists[, c("case_no", "onset", "date_onset")],
                   case_lists$date_file)
  purrr::map_dfr(seq_along(dates)[-1], function(i) {
    before <- by_date[[as.character(dates[i - 1])]]
    after <- by_date[[as.character(dates[i])]]
    joined <- dplyr::full_join(before, after, by = "case_no",
                               suffix = c("_before", "_after"))
    in_before <- joined$case_no %in% before$case_no
    in_after <- joined$case_no %in% after$case_no
    is_date_before <- !is.na(joined$date_onset_before)
    is_date_after <- !is.na(joined$date_onset_after)
    type <- dplyr::case_when(
      !in_before ~ "added",
      !in_after ~ "removed",
      joined$onset_before == joined$onset_after ~ "unchanged",
      # the same date written in a different format
      is_date_before & is_date_after &
        joined$date_onset_before == joined$date_onset_after ~ "unchanged",
      is_date_before & is_date_after ~ "moved",
      !is_date_before & is_date_after ~ "onset learned",
      is_date_before & !is_date_after ~ "onset withdrawn",
      TRUE ~ "other")
    joined %>%
      dplyr::mutate(date_file = dates[i], type = type) %>%
      dplyr::filter(.data$type != "unchanged") %>%
      dplyr::select("date_file", "case_no", "onset_before", "onset_after",
                    "date_onset_before", "date_onset_after", "type")
  })
}

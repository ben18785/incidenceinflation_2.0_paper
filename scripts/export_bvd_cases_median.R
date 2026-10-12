# Saves the posterior median of the true cases of each onset day from the
# fits of the model of cases alone held in the main pipeline's store, for
# the experiments which hold the cases fixed (data/raw/bvd_derived/, which
# scripts/encrypt_bvd_data.sh includes).
library(targets)
suppressMessages(library(dplyr))
tar_source("R")
f_chains <- function(target) {
  meta <- tar_meta(fields = c("name", "parent"))
  names <- meta$name[which(meta$parent == target)]
  Filter(Negate(is.null), lapply(names, function(name)
    tryCatch(tar_read_raw(name), error = function(e) NULL)))
}
chains <- c(f_chains("bvd_part_cases_chain"), f_chains("bvd_form_cases_chain"))
chains <- purrr::keep(chains, ~is.null(.$error) && .$model == "cases")
dir.create("data/raw/bvd_derived", recursive = TRUE, showWarnings = FALSE)
for(date_now in unique(purrr::map_chr(chains, ~as.character(.$date_now)))) {
  median <- bvd_cases_median(chains, date_now)
  path <- file.path("data/raw/bvd_derived", paste0("cases_median_", date_now, ".csv"))
  write.csv(median, path, row.names = FALSE)
  cat(path, ":", sum(median$cases_true), "cases over", nrow(median), "onset days\n")
}

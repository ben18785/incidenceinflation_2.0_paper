# For each fit of option (f): deaths it expects the next reports to add, what
# they added, and the unshown deaths it believes remain against those later shown.
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(targets)}); tar_source("R")
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
model <- readRDS(file.path(S, "delays_fits_f_by_date.rds"))
rd <- sort(unique(snap$date_reported)); fits_at <- sort(unique(model$fit))
files <- Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_*.rds"))
out <- bind_rows(lapply(fits_at, function(fd) {
  fs <- files[grepl(sprintf("_%s_[0-9]+[.]rds$", format(fd, "%m%d")), files)]
  d <- bind_rows(lapply(fs, function(f) { x <- readRDS(f); h <- x$deaths; h[h$iteration > max(h$iteration)/2, ] }))
  day1 <- readRDS(fs[1])$analysis$dates$date[1]
  ev <- d %>% group_by(time_onset) %>% summarise(ev = median(deaths_recorded)) %>% mutate(date_onset = day1 + time_onset - 1)
  sh <- snap %>% filter(date_reported == fd) %>% select(date_onset, shown = deaths_reported)
  fin <- snap %>% filter(date_reported == max(rd)) %>% select(date_onset, final = deaths_reported)
  x <- ev %>% left_join(sh, by = "date_onset") %>% left_join(fin, by = "date_onset") %>% mutate(across(c(shown, final), ~ coalesce(.x, 0L)), age = as.numeric(fd - date_onset))
  m <- model %>% filter(fit == fd); k <- n_distinct(paste(m$chain, m$iteration))
  nxt <- max(m$date_reported)
  o <- snap %>% filter(date_reported == nxt, date_onset <= fd) %>% summarise(n = sum(deaths_reported)) %>% pull(n)
  tibble(fit = fd, to = nxt, expected_added = round(sum(m$added) / k), actual_added = o - sum(x$shown),
         stock_over35_fit = round(sum((x$ev - x$shown)[x$age > 35])), stock_over35_final = sum((x$final - x$shown)[x$age > 35]),
         stock_all_fit = round(sum(x$ev - x$shown)), stock_all_final = sum(x$final - x$shown))
}))
print(as.data.frame(out))

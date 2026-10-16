# Fits of option (f) at the August fit dates, projected to the report of 30
# August, before the reports that added many deaths to old onset days.
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R"); set.seed(1)
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
target <- as.Date("2026-08-30")
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
files <- Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_*.rds"))
files <- files[as.integer(sub(".*_([0-9]{4})_[0-9]+[.]rds$", "\\1", basename(files))) < 830]
ch <- Filter(function(x) is.null(x$error), lapply(files, function(f) {
  x <- readRDS(f)
  for (n in c("deaths", "cases", "reporting_days", "deaths_parameters", "overdispersion", "Rt"))
    if (!is.null(x[[n]])) x[[n]] <- half(x[[n]])
  x }))
by_day <- bvd_experiment_by_day(ch, snap, target, n_draws = 60)
saveRDS(by_day, file.path(S, "by_day_f_aug.rds"))
lab <- c(now = "Deaths reported as of that sitrep",
         projected = "Projected reported deaths for sitrep on 30 August",
         later = "Actual deaths reported on 30 August")
cols <- setNames(c("#E69F00", "#009E73", "black"), lab)
df <- dplyr::filter(by_day, .data$count == "deaths", .data$date >= as.Date("2026-06-15")) %>%
  mutate(date = as.Date(date), panel = format_date_now(date_now))
lines <- bind_rows(
  transmute(df, panel, date, y = shown_now, what = lab[["now"]]),
  transmute(df, panel, date, y = p50, what = lab[["projected"]]),
  transmute(df, panel, date, y = shown_later, what = lab[["later"]])) %>%
  mutate(what = factor(what, levels = lab))
g <- ggplot(df, aes(x = date)) +
  geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3, na.rm = TRUE) +
  geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
  scale_colour_manual(values = cols, name = NULL) +
  guides(colour = guide_legend(override.aes = list(linewidth = 1.2), nrow = 2)) +
  facet_wrap(~panel, scales = "free_x", nrow = 2) +
  labs(x = "Onset date", y = "Deaths") +
  theme_paper() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(size = 14, face = "bold"),
        legend.position = "bottom", legend.text = element_text(size = 12))
save_plot(g, "outputs/bvd_deaths_fits_deaths_f_aug.png", 12, 7)
# totals: projected vs actual on 30 August, all onset days and those up to the fit date
tot <- df %>% group_by(panel) %>% summarise(now = sum(shown_now, na.rm = TRUE),
  projected = sum(p50, na.rm = TRUE), lo = sum(p05, na.rm = TRUE), hi = sum(p95, na.rm = TRUE),
  actual = sum(shown_later, na.rm = TRUE))
print(as.data.frame(tot))
cat("done\n")

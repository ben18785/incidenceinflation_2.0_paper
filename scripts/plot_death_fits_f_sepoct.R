.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R"); set.seed(1)
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
src <- readLines("scripts/plot_death_slides_f.R")
i <- grep("^plot_slide_counts <- function", src); j <- i - 1 + which(src[i:length(src)] == "}")[1]
eval(parse(text = src[i:j]))
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
later <- max(snap$date_reported)
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
files <- Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_*.rds"))
files <- files[as.integer(sub(".*_([0-9]{4})_[0-9]+[.]rds$", "\\1", basename(files))) >= 901]
ch <- Filter(function(x) is.null(x$error), lapply(files, function(f) {
  x <- readRDS(f)
  for (n in c("deaths", "cases", "reporting_days", "deaths_parameters", "overdispersion", "Rt"))
    if (!is.null(x[[n]])) x[[n]] <- half(x[[n]])
  x }))
by_day <- bvd_experiment_by_day(ch, snap, later, n_draws = 60)
cat(sort(unique(format(by_day$date_now))), "\n")
saveRDS(by_day, file.path(S, "by_day_f_sepoct.rds"))
count <- "deaths"
lab <- c(now = "Deaths reported as of that sitrep",
         projected = "Projected reported deaths for sitrep on 7 October",
         later = "Actual deaths reported on 7 October",
         eventual = "Estimated eventual deaths (fit to 7 October)")
cols <- setNames(c("#E69F00", "#009E73", "black", "#CC79A7"), lab)
df <- dplyr::filter(by_day, .data$count == !!count, .data$date >= as.Date("2026-07-10")) %>%
  mutate(date = as.Date(date), panel = format_date_now(date_now))
ev <- df %>% filter(date_now == later)
lines <- bind_rows(
  transmute(df, panel, date, y = shown_now, what = lab[["now"]]),
  transmute(df, panel, date, y = p50, what = lab[["projected"]]),
  transmute(df, panel, date, y = shown_later, what = lab[["later"]]),
  transmute(ev, panel, date, y = q50, what = lab[["eventual"]])) %>%
  mutate(what = factor(what, levels = lab))
g <- ggplot(df, aes(x = date)) +
  geom_ribbon(aes(ymin = p05, ymax = p95), fill = "#009E73", alpha = 0.3, na.rm = TRUE) +
  geom_ribbon(data = ev, aes(ymin = q05, ymax = q95), fill = "#CC79A7", alpha = 0.3) +
  geom_line(data = lines, aes(y = y, colour = what), linewidth = 0.4, na.rm = TRUE) +
  scale_colour_manual(values = cols, name = NULL) +
  guides(colour = guide_legend(override.aes = list(linewidth = 1.2), nrow = 2)) +
  facet_wrap(~panel, scales = "free_x", nrow = 2) +
  labs(x = "Onset date", y = "Deaths") +
  theme_paper() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(size = 14, face = "bold"),
        legend.position = "bottom", legend.text = element_text(size = 12))
save_plot(g, file.path(S, "fits_deaths_f_sepoct.png"), 12, 7)

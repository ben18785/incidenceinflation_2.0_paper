# Estimates by onset day from the fit to the report of 7 October of the
# chosen model, option (f): Rt and the mean delay to a case being reported;
# the case fatality ratio and the mean delay from death to its recording.
# Usage: Rscript scripts/plot_death_estimates_f.R <folder with chains/>
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets)})
tar_source("R")
dir <- commandArgs(TRUE)[1]
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
ch <- lapply(Sys.glob(file.path(dir, "chains", "*_july_tail_reports_1007_*.rds")), readRDS)
dates <- ch[[1]]$analysis$dates
g <- function(n) half(bind_rows(lapply(ch, `[[`, n))) %>% left_join(dates, by = "time_onset")
band <- function(df, value) df %>% group_by(date) %>%
  summarise(q05 = quantile(.data[[value]], .05), q50 = median(.data[[value]]),
            q95 = quantile(.data[[value]], .95), .groups = "drop")
big <- theme(plot.title = element_text(size = 15, face = "bold"), axis.title = element_text(size = 14),
             axis.text = element_text(size = 12))
panel <- function(df, colour, title, ylab, hline = NULL) {
  p <- ggplot(df, aes(x = date)) +
    geom_ribbon(aes(ymin = q05, ymax = q95), fill = colour, alpha = 0.3) +
    geom_line(aes(y = q50), colour = colour, linewidth = 0.6)
  if (!is.null(hline)) p <- p + geom_hline(yintercept = hline, linetype = "dashed", colour = "grey40")
  p + labs(x = "Onset date", y = ylab, title = title) + theme_paper() + big
}
rt <- band(g("Rt"), "Rt"); rd <- band(g("reporting_days"), "mean")
d <- g("deaths"); cfr <- band(d, "cfr"); dd <- band(d, "delay_mean")
p <- patchwork::wrap_plots(
  panel(rt, "#0072B2", expression(bold(A.~R[t])), expression(R[t]~"(log scale)"), hline = 1) +
    scale_y_log10(breaks = c(0.5, 0.75, 1, 1.5, 2, 3, 5, 8)),
  panel(cfr, "#D55E00", "B. Case fatality ratio", "CFR") + coord_cartesian(ylim = c(0, 1)), ncol = 2)
save_plot(p, "outputs/bvd_estimates_rt_cfr.png", 12, 4.8)
f <- function(df, name) { cat(name, ":\n"); x <- df[c(1, which(diff(round(df$q50, 2)) != 0) + 1), ]; print(as.data.frame(head(x, 12)), row.names = FALSE) }
f(rt, "Rt"); f(rd, "reporting delay"); f(cfr, "CFR"); f(dd, "recording delay")

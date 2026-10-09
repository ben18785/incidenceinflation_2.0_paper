# Draws the simulated truth against the estimates for each scenario fitted by
# scripts/deaths_simulation_run.R: outputs/bvd_deaths_simulation_check_1.png
# and _2.png, which docs/bvd_deaths.tex includes.
#
# Run from the root of this repository (open incidenceinflation_2.0_paper.Rproj).
# Results are kept in outputs/deaths_simulation/<study>/, where <study> is set
# by the environment variable DEATHS_STUDY (default "first_check").
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(tidyr)})
S <- file.path("outputs", "deaths_simulation", Sys.getenv("DEATHS_STUDY", "first_check"))
sims <- readRDS(file.path(S, "sims.rds"))
labels <- c(base="Nothing changes", cfr="Case fatality\nratio halves", sooner="Fatal cases reported\ntwice as fast",
            wrong="Wrong records", dated="30% dated\nby death", dated_ignored="30% dated by death,\nfitted as if none",
            all="All together")
quantities <- c("Cases by day of onset", "Reproduction number", "Mean delay (days)", "Case fatality ratio", "Fatal cases by day of onset")
quantity_order <- quantities[c(1, 5, 2, 3, 4)]
f_summary <- function(df, value, series, quantity) {
  df %>% group_by(time_onset) %>%
    summarise(lo=quantile({{value}}, 0.05), mid=median({{value}}), hi=quantile({{value}}, 0.95), .groups="drop") %>%
    mutate(series=series, quantity=quantity)
}
estimates <- list(); truths <- list(); reported <- list()
for(name in names(sims)) {
  fits <- lapply(list.files(S, sprintf("^fit_%s_[0-9].rds$", name), full.names=TRUE), readRDS)
  bind <- function(n) bind_rows(lapply(fits, `[[`, n))
  sim <- sims[[name]]; truth <- sim$truth; sc <- sim$scenario
  delays <- bind("reporting_days") %>%
    left_join(bind("deaths_parameters")[, c("iteration", "chain", "fatal_delay_ratio")], by=c("iteration", "chain"))
  estimates[[name]] <- bind_rows(
    f_summary(bind("cases"), cases_true, "Cases", quantities[1]),
    f_summary(bind("deaths"), deaths_true, "Fatal cases", quantities[5]),
    f_summary(bind("Rt"), Rt, "Reproduction number", quantities[2]),
    f_summary(delays, mean, "Onset to case reported", quantities[3]),
    f_summary(delays, mean * fatal_delay_ratio, "Onset to case reported, fatal cases", quantities[3]),
    f_summary(bind("deaths"), delay_mean, "Onset to death recorded", quantities[3]),
    f_summary(bind("deaths"), cfr, "Case fatality ratio", quantities[4])) %>% mutate(scenario=name)
  # the counts in the latest report
  latest <- sim$snapshots %>% group_by(time_onset) %>% filter(time_reported == max(time_reported)) %>% ungroup()
  reported[[name]] <- bind_rows(
    tibble(time_onset=latest$time_onset, value=latest$cases_reported, series="Cases in the latest report"),
    tibble(time_onset=latest$time_onset, value=latest$deaths_reported, series="Deaths in the latest report")) %>%
    mutate(quantity=quantities[c(1, 5)][1 + (series == "Deaths in the latest report")], scenario=name)
  fatal_mean <- if(is.null(sc$fatal_reporting)) 8 else sc$fatal_reporting$mean
  t <- truth$time_onset
  truths[[name]] <- bind_rows(
    tibble(time_onset=t, value=truth$cases_onset, series="Cases", quantity=quantities[1]),
    tibble(time_onset=t, value=truth$deaths_onset, series="Fatal cases", quantity=quantities[5]),
    tibble(time_onset=t, value=1, series="Reproduction number", quantity=quantities[2]),
    tibble(time_onset=t, value=8, series="Onset to case reported", quantity=quantities[3]),
    tibble(time_onset=t, value=fatal_mean, series="Onset to case reported, fatal cases", quantity=quantities[3]),
    tibble(time_onset=t, value=12, series="Onset to death recorded", quantity=quantities[3]),
    tibble(time_onset=t, value=truth$cfr, series="Case fatality ratio", quantity=quantities[4])) %>% mutate(scenario=name)
}
f_factors <- function(df) df %>% mutate(
  scenario=factor(labels[scenario], levels=labels), quantity=factor(quantity, levels=quantity_order))
estimates <- f_factors(bind_rows(estimates)); truths <- f_factors(bind_rows(truths)); reported <- f_factors(bind_rows(reported))
# the same vertical range for each quantity in every scenario
ranges <- bind_rows(estimates %>% transmute(quantity, scenario, y=hi), estimates %>% transmute(quantity, scenario, y=lo),
                    truths %>% transmute(quantity, scenario, y=value)) %>%
  group_by(quantity) %>% summarise(lo=min(y), hi=max(y)) %>%
  mutate(lo=ifelse(quantity == quantities[2], 0.8, 0), hi=ifelse(quantity == quantities[2], 1.2, hi)) %>%
  pivot_longer(c(lo, hi), values_to="y") %>% select(-name) %>%
  crossing(scenario=factor(labels, levels=labels)) %>% mutate(time_onset=1)
colours <- c("Cases"="#4C72B0", "Fatal cases"="#C44E52", "Reproduction number"="#333333",
             "Onset to case reported"="#4C72B0", "Onset to case reported, fatal cases"="#DD8452",
             "Onset to death recorded"="#C44E52", "Case fatality ratio"="#333333",
             "Cases in the latest report"="#111111", "Deaths in the latest report"="#111111")
is_counts <- function(df) df$quantity %in% quantities[c(1, 5)]
f_plot <- function(names_scenarios) {
  f <- function(df) df[df$scenario %in% labels[names_scenarios], ]
  truths_tmp <- f(truths)
  ggplot(f(estimates), aes(time_onset)) +
    geom_blank(aes(y=y), data=f(ranges)) +
    geom_ribbon(aes(ymin=lo, ymax=hi, fill=series), alpha=0.25) +
    geom_step(aes(y=value, colour=series), data=f(reported), direction="mid", linewidth=0.35) +
    geom_line(aes(y=mid, colour=series), linewidth=0.5) +
    geom_point(aes(y=value, colour=series), data=truths_tmp[is_counts(truths_tmp), ], size=0.5) +
    geom_line(aes(y=value, colour=series), data=truths_tmp[!is_counts(truths_tmp), ], linetype="dashed", linewidth=0.4) +
    ggh4x::facet_grid2(scenario ~ quantity, scales="free_y", independent="y") +
    scale_colour_manual(values=colours, breaks=names(colours)[c(1, 2, 8, 9, 4, 5, 6)], name=NULL) +
    scale_fill_manual(values=colours, guide="none") +
    guides(colour=guide_legend(nrow=2)) +
    labs(x="Day of onset", y=NULL) +
    theme_bw(base_size=8) +
    theme(legend.position="bottom", panel.grid.minor=element_blank(),
          strip.text.y=element_text(angle=0, hjust=0), strip.background=element_rect(fill="grey93", colour=NA),
          legend.key.width=unit(0.8, "cm"), legend.margin=margin(0, 0, 0, 0))
}
out <- file.path("outputs", "bvd_deaths_simulation_check_%d.png")
ggsave(sprintf(out, 1), f_plot(c("base", "cfr", "sooner")), width=11, height=5.6, dpi=200)
ggsave(sprintf(out, 2), f_plot(c("wrong", "dated", "dated_ignored", "all")), width=11, height=7.1, dpi=200)

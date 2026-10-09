# Summarises the fits made by scripts/deaths_simulation_run.R against the
# simulated truth, and writes the summary to summary.txt beside them.
#
# Run from the root of this repository (open incidenceinflation_2.0_paper.Rproj).
# Results are kept in outputs/deaths_simulation/<study>/, where <study> is set
# by the environment variable DEATHS_STUDY (default "first_check").
suppressPackageStartupMessages(library(dplyr))
S <- file.path("outputs", "deaths_simulation", Sys.getenv("DEATHS_STUDY", "first_check"))
sims <- readRDS(file.path(S, "sims.rds"))
q <- function(x) sprintf("%.2f (%.2f-%.2f)", median(x), quantile(x, 0.05), quantile(x, 0.95))
rhat <- function(x, chain) {
  if(length(unique(chain)) < 2) return(NA)
  m <- tapply(x, chain, mean); v <- tapply(x, chain, var); n <- min(table(chain))
  w <- mean(v); if(w == 0) return(NA)
  sqrt(((n - 1) / n * w + var(m)) / w)
}
rows <- list()
for(name in names(sims)) {
  files <- list.files(S, sprintf("^fit_%s_[0-9].rds$", name), full.names=TRUE)
  fits <- lapply(files, readRDS)
  if(length(fits) == 0) next
  errors <- unlist(lapply(fits, function(f) f$error))
  fits <- fits[vapply(fits, function(f) is.null(f$error), logical(1))]
  if(length(fits) == 0) { rows[[name]] <- tibble(scenario=name, error=paste(errors, collapse="; ")); next }
  bind <- function(n) bind_rows(lapply(fits, `[[`, n))
  sim <- sims[[name]]; truth <- sim$truth; sc <- sim$scenario; n_days <- sim$n_days
  d <- bind("deaths"); p <- bind("deaths_parameters"); cs <- bind("cases"); rev <- bind("revisions")
  rd <- bind("reporting_days"); Rt <- bind("Rt")
  early <- d %>% filter(time_onset %in% 5:25) %>% group_by(iteration, chain) %>% summarise(cfr=mean(cfr), .groups="drop")
  late <- d %>% filter(time_onset %in% 40:55) %>% group_by(iteration, chain) %>% summarise(cfr=mean(cfr), dm=mean(delay_mean), ds=mean(delay_sd), .groups="drop")
  # coverage of the true cases by day of onset over the last 14 days
  truth_onset <- if("cases_onset" %in% names(truth)) truth$cases_onset else truth$cases_true
  cover <- cs %>% filter(time_onset > n_days - 14) %>% group_by(time_onset) %>%
    summarise(lo=quantile(cases_true, 0.05), hi=quantile(cases_true, 0.95), mid=median(cases_true)) %>%
    mutate(truth=truth_onset[time_onset])
  rep_late <- rd %>% filter(time_onset %in% 20:50) %>% group_by(iteration, chain) %>% summarise(m=mean(mean), .groups="drop")
  Rt_late <- Rt %>% filter(time_onset > n_days - 14) %>% group_by(iteration, chain) %>% summarise(Rt=mean(Rt), .groups="drop")
  rows[[name]] <- tibble(
    scenario=name, minutes=round(mean(sapply(fits, `[[`, "minutes")), 1), chains=length(fits),
    cfr_early=q(early$cfr), cfr_late=q(late$cfr),
    cfr_truth=sprintf("%.2f / %.2f", mean(truth$cfr[5:25]), mean(truth$cfr[40:55])),
    cfr_realised=sprintf("%.2f / %.2f", sum(truth$deaths_onset[5:25]) / sum(truth$cases_onset[5:25]),
                         sum(truth$deaths_onset[40:55]) / sum(truth$cases_onset[40:55])),
    dated_share=sprintf("%s (truth %.2f)", q((d %>% filter(time_onset %in% 10:50) %>% group_by(iteration, chain) %>%
      summarise(x=sum(dated_by_death) / sum(deaths_recorded), .groups="drop"))$x),
      sum(truth$n_dated_by_death[10:50]) / sum(truth$deaths_true[10:50])),
    cases_early_bias=round(mean((cs %>% filter(time_onset %in% 10:40) %>% group_by(time_onset) %>%
      summarise(m=median(cases_true)))$m - truth_onset[10:40]), 2),
    p_cfr_change=round(mean(p$n_cfr_changes > 0), 2),
    death_delay=sprintf("%s, sd %s", q(late$dm), q(late$ds)),
    p_delay_change=round(mean(p$n_delay_changes > 0), 2),
    reporting_mean=q(rep_late$m),
    fatal_ratio=q(p$fatal_delay_ratio), p_ratio_one=round(mean(p$fatal_delay_ratio == 1), 2),
    eta=q(rev$eta), rho=q(rev$rho), wrong_dead=q(p$wrong_dead),
    Rt_last14=q(Rt_late$Rt),
    cases_cover=sprintf("%d/14", sum(cover$truth >= cover$lo & cover$truth <= cover$hi)),
    cases_bias=round(mean(cover$mid - cover$truth), 1),
    rhat_cfr=round(rhat(late$cfr, late$chain), 2), rhat_delay=round(rhat(late$dm, late$chain), 2),
    rhat_reporting=round(rhat(rep_late$m, rep_late$chain), 2),
    error=paste(errors, collapse="; "))
}
out <- bind_rows(rows)
sink(file.path(S, "summary.txt"), split=TRUE)
for(i in seq_len(nrow(out))) { cat("\n==", out$scenario[i], "==\n"); for(n in names(out)[-1]) cat(sprintf("  %-16s %s\n", n, as.character(out[[n]][i]))) }
sink()

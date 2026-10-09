# Fits the joint model of cases and deaths (docs/bvd_deaths.tex) to simulated
# data: one simulated outbreak reported in seven ways, each fitted by two
# chains. Progress is written to progress_<scenario>_<chain>.txt.
#
# Run from the root of this repository (open incidenceinflation_2.0_paper.Rproj).
# Results are kept in outputs/deaths_simulation/<study>/, where <study> is set
# by the environment variable DEATHS_STUDY (default "first_check").
# The number of iterations is set by DEATHS_ITERATIONS (default 300) and the
# number of chains run at once by DEATHS_CORES (default 7). Needs the package
# in ../incidenceinflation_2.0 on its 'deaths' branch.
suppressPackageStartupMessages({devtools::load_all("../incidenceinflation_2.0", quiet=TRUE); library(dplyr)})
S <- file.path("outputs", "deaths_simulation", Sys.getenv("DEATHS_STUDY", "first_check"))
dir.create(S, recursive=TRUE, showWarnings=FALSE)
n_days <- 60
step <- function(day, before, after) function(t) ifelse(t < day, before, after)
dated <- list(fraction=0.3, mean=7, sd=4, reporting=list(mean=2, sd=1.5))
wrong <- list(eta=0.03, rho=0.3, delta=0.4)
scenarios <- list(
  base=list(),
  cfr=list(cfr=step(33, 0.5, 0.25)),
  sooner=list(fatal_reporting=list(mean=4, sd=3)),
  wrong=list(wrong=wrong),
  dated=list(dated=dated),
  dated_ignored=list(dated=dated, fit_dated=FALSE),
  all=list(cfr=step(33, 0.5, 0.25), fatal_reporting=list(mean=4, sd=3), wrong=wrong, dated=dated))
simulate <- function(name, seed=1) {
  sc <- scenarios[[name]]
  set.seed(seed)
  serial <- list(mean=5, sd=3)
  all <- true_cases(n_days + 40, function(t) 1, kappa=1000, serial, initial_parameters=list(mean=40, length=10))
  t <- seq_len(n_days)
  cfr <- if(is.null(sc$cfr)) rep(0.4, n_days) else sc$cfr(t)
  sim <- simulate_cases_deaths(
    all[41:(n_days + 40)], t, list(mean=8, sd=6), cfr, list(mean=12, sd=7),
    fatal_reporting_parameters=sc$fatal_reporting, dated_by_death=sc$dated, wrong=sc$wrong)
  c(sim, list(cases_before=all[1:40], serial=serial, n_days=n_days, name=name, scenario=sc))
}
largest_fall <- function(snapshots, column) {
  falls <- snapshots %>% group_by(time_onset) %>% arrange(time_reported, .by_group=TRUE) %>%
    summarise(fall=max(c(0, -diff(.data[[column]]))))
  max(falls$fall)
}
fit <- function(sim, niterations, chain) {
  progress_file <- file.path(S, sprintf("progress_%s_%d.txt", sim$name, chain))
  set.seed(100 + chain)
  snapshots <- sim$snapshots
  largest <- snapshots %>% group_by(time_onset) %>% summarise(cases_true=max(cases_reported))
  ago <- sim$n_days - largest$time_onset
  initial_cases <- largest %>% mutate(cases_true=ceiling(cases_true * (1 + c(2, 1)[chain] * exp(-ago / 4)) + 5 * (ago < 5)))
  max_erroneous <- max(2, largest_fall(snapshots, "cases_reported") + 1, largest_fall(snapshots, "deaths_reported") + 1)
  priors <- list(Rt=list(shape=1, rate=1), reporting=list(mean_mu=7, mean_sigma=10, sd_mu=5, sd_sigma=5),
                 max_cases=ceiling(4 * max(initial_cases$cases_true) + 50), Rt_changepoints=list(),
                 reporting_changepoints=list(min_length=14, n_partition_moves=20),
                 revisions=list(eta_mu=0.01, eta_sigma=0.02, rho_alpha=2, rho_beta=4),
                 max_erroneous=max_erroneous)
  settings <- list(initial_cfr=c(0.5, 0.25)[chain],
                   initial_delay=list(list(mean=14, sd=8), list(mean=8, sd=5))[[chain]],
                   delay_changepoints=list(min_length=14, n_partition_moves=20))
  if(!is.null(sim$scenario$dated) && !identical(sim$scenario$fit_dated, FALSE))
    settings$dated_by_death <- sim$scenario$dated
  t0 <- Sys.time()
  out <- tryCatch(mcmc_single(
    niterations=niterations,
    snapshot_with_Rt_index_df=snapshots %>% select(time_onset, time_reported, cases_reported) %>% mutate(Rt_index=1),
    priors=priors, serial_parameters=sim$serial, initial_cases_true=initial_cases,
    initial_reporting_parameters=list(list(mean=7, sd=4), list(mean=11, sd=7))[[chain]],
    initial_Rt=tibble(Rt_index=1, Rt=1), reporting_metropolis_parameters=list(mean_step=0.3, sd_step=0.25),
    print_to_screen=FALSE, cases_before=sim$cases_before, n_parameter_steps=3,
    initial_revision_parameters=list(eta=0.01, rho=0.3, weekday=TRUE, weekday_first=1),
    progress_file=progress_file, progress_every=10,
    deaths=list(snapshot=snapshots %>% select(time_onset, time_reported, deaths_reported), settings=settings)),
    error=function(e) list(error=conditionMessage(e)))
  out$minutes <- as.numeric(Sys.time() - t0, units="mins")
  out$max_erroneous <- max_erroneous
  warmup <- niterations / 2
  for(name in intersect(names(out), c("cases", "Rt", "reporting_days", "deaths", "deaths_parameters", "Rt_changepoints",
                                      "reporting_changepoints", "revisions", "reporting_effects")))
    out[[name]] <- out[[name]] %>% filter(iteration > warmup) %>% mutate(chain=chain)
  out$reporting <- NULL
  out
}
niterations <- as.integer(Sys.getenv("DEATHS_ITERATIONS", "300"))
jobs <- expand.grid(scenario=names(scenarios), chain=1:2, stringsAsFactors=FALSE)
sims <- lapply(setNames(names(scenarios), names(scenarios)), simulate)
saveRDS(sims, file.path(S, "sims.rds"))
results <- parallel::mclapply(seq_len(nrow(jobs)), function(i) {
  out <- fit(sims[[jobs$scenario[i]]], niterations, jobs$chain[i])
  saveRDS(out, file.path(S, sprintf("fit_%s_%d.rds", jobs$scenario[i], jobs$chain[i])))
  c(jobs[i, ], minutes=out$minutes, error=if(is.null(out$error)) "" else out$error)
}, mc.cores=as.integer(Sys.getenv("DEATHS_CORES", "7")), mc.preschedule=FALSE)
print(do.call(rbind, lapply(results, as.data.frame)))

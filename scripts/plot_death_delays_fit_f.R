# Deaths first shown in each report, by delay from onset: what the reports
# show against what option (f), fitted to 7 October, expects. Expected counts
# per onset day and report are the fitted fatal cases times the increase in
# the probability of being shown as dead, with and without the fitted effects
# of each report on the tail (effects of the day of the week left out).
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation); library(patchwork)})
tar_source("R"); set.seed(1)
ii <- asNamespace("incidenceinflation")
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
fits <- lapply(Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_1007_*.rds")), function(f) {
  x <- readRDS(f); for (n in c("deaths", "cases", "deaths_parameters")) x[[n]] <- half(x[[n]]); x })
a <- fits[[1]]$analysis; day1 <- a$dates$date[1]; t_now <- as.numeric(a$date_now - day1) + 1
rep_days <- as.numeric(sort(unique(snap$date_reported[snap$date_reported <= a$date_now])) - day1) + 1
lags <- ii$lag_probabilities_gamma(9.3, 5.5)
tail_only <- grepl("report effects on recording tail", fits[[1]]$model)

# expected deaths first shown at each report, for one draw
expected <- function(fit, iteration, with_reports) {
  deaths <- fit$deaths %>% filter(iteration == !!iteration) %>% arrange(time_onset)
  p <- fit$deaths_parameters[which.min(abs(fit$deaths_parameters$iteration - iteration)), ]
  eff <- list(tail = list(weight = p$recording_tail_weight, mean = p$recording_tail_mean),
              before = list(lag_probabilities = lags))
  if (with_reports) {
    cols <- grep("^recording_report_[0-9]+$", names(p), value = TRUE)
    eff <- ii$update_report_multipliers(c(eff, list(report_tail_only = tail_only,
      report_days = as.numeric(sub("recording_report_", "", cols)),
      report_log_effects = log(unlist(p[cols])))))
  }
  tau <- p$triggered
  bind_rows(lapply(seq_len(t_now), function(t) {
    days <- rep_days[rep_days >= t]; if (!length(days)) return(NULL)
    s <- ii$joint_survivals(days, t, list(mean = 5, sd = 3),
                            list(mean = deaths$delay_mean[t], sd = deaths$delay_sd[t]),
                            dated_reporting_parameters = "recording", recording_effects = eff)
    Sr <- exp(s$log_recorded)
    # a fatal case is taken as reported by the time its death is recorded
    dead <- (1 - Sr); dated <- -expm1(s$log_dated)
    n_f <- deaths$deaths_recorded[t] - deaths$dated_by_death[t]; n_d <- deaths$dated_by_death[t]
    cum <- n_f * dead + n_d * dated
    tibble(time_onset = t, day = days, added = diff(c(0, cum)))
  })) %>% mutate(iteration = iteration, chain = fit$chain)
}
draws <- function(with_reports) bind_rows(lapply(fits, function(fit) {
  its <- sample(unique(fit$deaths$iteration), 15)
  bind_rows(lapply(its, function(i) expected(fit, i, with_reports)))
})) %>% mutate(date_onset = day1 + time_onset - 1, date_reported = day1 + day - 1)
m_rep <- draws(TRUE); m_no <- draws(FALSE)

# observed, as in plot_death_delays_by_month.R
first <- min(snap$date_reported)
obs <- tidyr::expand_grid(date_onset = sort(unique(snap$date_onset)), date_reported = sort(unique(snap$date_reported))) %>%
  filter(date_reported >= date_onset) %>%
  left_join(select(snap, date_onset, date_reported, deaths_reported), by = c("date_onset", "date_reported")) %>%
  mutate(deaths_reported = coalesce(deaths_reported, 0L)) %>% arrange(date_onset, date_reported) %>%
  group_by(date_onset) %>% mutate(added = deaths_reported - lag(deaths_reported, default = 0L)) %>% ungroup() %>%
  filter(added > 0)
bin <- function(df, by, w) df %>% filter(date_reported > first) %>%
  mutate(delay = as.numeric(date_reported - date_onset), bin = floor(delay / 6) * 6 + 3,
         panel = factor(format(.data[[by]], "%B"), levels = month.name)) %>%
  filter(panel %in% c("May", "June", "July", "August", "September", "October")) %>%
  group_by(panel, bin, across(any_of(c("chain", "iteration")))) %>% summarise(n = sum(.data[[w]]), .groups = "drop")
summ <- function(df) df %>% group_by(panel, bin) %>% summarise(n = sum(n) / n_distinct(paste(df$chain, df$iteration)), .groups = "drop")
plot_by <- function(by, title) {
  o <- bin(obs, by, "added")
  m <- bind_rows(summ(bin(m_rep, by, "added")) %>% mutate(what = "Fit (f), with the effects of each report"),
                 summ(bin(m_no, by, "added")) %>% mutate(what = "Fit (f), without them"))
  ggplot() + geom_col(data = o, aes(bin, n), width = 6, fill = "grey70") +
    geom_step(data = m, aes(bin - 3, n, colour = what), direction = "hv", linewidth = 0.7) +
    scale_colour_manual(values = c("#D55E00", "#0072B2"), name = NULL) +
    facet_wrap(~panel, nrow = 1, scales = "free_y", drop = TRUE) +
    labs(x = "Days from onset to the report first showing the death", y = "Deaths", title = title) +
    theme_paper() + theme(legend.position = "bottom", strip.text = element_text(size = 12))
}
g1 <- plot_by("date_onset", "By month of onset (grey: the reports)")
g2 <- plot_by("date_reported", "By month of report (grey: the reports)")
save_plot(g1 / g2, "outputs/bvd_death_delays_fit_f.png", 15, 9)
tot <- function(df, w) df %>% filter(date_reported > first) %>% mutate(d = as.numeric(date_reported - date_onset)) %>%
  summarise(all = sum(.data[[w]]), over21 = sum(.data[[w]][d > 21]), over60 = sum(.data[[w]][d > 60]))
k <- function(df) n_distinct(paste(df$chain, df$iteration))
print(rbind(reports = unlist(tot(obs, "added")), with_effects = unlist(tot(m_rep, "added")) / k(m_rep),
            without = unlist(tot(m_no, "added")) / k(m_no)))

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

# --- comparable versions ------------------------------------------------------
# (a) by month of onset: share of the eventual deaths (fit (f)) shown by each
# number of days after onset, over the delays at which every onset day of the
# month was covered by the reports (12 July to 7 October)
rd <- sort(unique(snap$date_reported))
eventual <- bind_rows(lapply(fits, function(f) f$deaths %>% select(chain, iteration, time_onset, n = deaths_recorded))) %>%
  mutate(date_onset = day1 + time_onset - 1)
ev_med <- eventual %>% group_by(date_onset) %>% summarise(n = median(n), .groups = "drop")
shown_at <- function(cum_df) {  # cum_df: date_onset, date_reported, cum (one set of draws or the reports)
  tidyr::expand_grid(date_onset = unique(cum_df$date_onset), age = 0:160) %>%
    mutate(date = date_onset + age) %>% filter(date >= first, date <= max(rd)) %>%
    mutate(date_reported = rd[findInterval(as.numeric(date), as.numeric(rd))]) %>%
    left_join(cum_df, by = c("date_onset", "date_reported")) %>% mutate(cum = coalesce(cum, 0))
}
months <- c("May", "June", "July", "August", "September")
covered <- function(df) {  # keep the delays at which every onset day of the month is covered
  df <- df %>% mutate(month = factor(format(date_onset, "%B"), levels = months)) %>% filter(!is.na(month))
  days_in <- df %>% group_by(month) %>% summarise(days_in = n_distinct(date_onset), .groups = "drop")
  ok <- df %>% group_by(month, age) %>% summarise(k = n_distinct(date_onset), .groups = "drop") %>%
    inner_join(days_in, by = "month") %>% filter(k == days_in) %>% select(month, age)
  inner_join(df, ok, by = c("month", "age"))
}
obs_cum <- snap %>% filter(date_onset >= max(day1, as.Date("2026-05-01"))) %>% group_by(date_onset, date_reported) %>%
  summarise(cum = sum(deaths_reported), .groups = "drop")
o_a <- shown_at(obs_cum) %>% covered() %>% left_join(ev_med, by = "date_onset") %>%
  group_by(month, age) %>% summarise(share = sum(cum) / sum(n), .groups = "drop") %>% mutate(what = "Reports")
mod_a <- function(m, label) {
  cum <- m %>% filter(date_onset >= as.Date("2026-05-01")) %>% arrange(date_reported) %>%
    group_by(chain, iteration, date_onset) %>% mutate(cum = cumsum(added)) %>% ungroup()
  cum %>% group_by(chain, iteration) %>% group_modify(~ shown_at(select(.x, date_onset, date_reported, cum))) %>% ungroup() %>%
    covered() %>% left_join(eventual %>% select(chain, iteration, date_onset, ev = n),
                                          by = c("chain", "iteration", "date_onset")) %>%
    group_by(month, age, chain, iteration) %>% summarise(share = sum(cum) / sum(ev), .groups = "drop") %>%
    group_by(month, age) %>% summarise(share = median(share), .groups = "drop") %>% mutate(what = label)
}
a_df <- bind_rows(o_a, mod_a(m_rep, "Fit (f), with the effects of each report"), mod_a(m_no, "Fit (f), without them"))
cols3 <- c("Reports" = "black", "Fit (f), with the effects of each report" = "#D55E00", "Fit (f), without them" = "#0072B2")
ga <- ggplot(a_df, aes(age, share, colour = what)) + geom_line(linewidth = 0.7) +
  facet_wrap(~month, nrow = 1, labeller = as_labeller(c(May = "May (from 11 May)", June = "June", July = "July",
                                                       August = "August", September = "September"))) +
  scale_colour_manual(values = cols3, name = NULL) +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.25)) +
  labs(x = "Days from onset", y = "Share of eventual deaths shown",
       title = "By month of onset: share of the eventual deaths (as fitted) already shown") +
  theme_paper() + theme(legend.position = "bottom", strip.text = element_text(size = 12))
# (b) by month of report: each month's additions as shares, by delay
bin_b <- function(df) df %>% filter(date_reported > first) %>%
  mutate(delay = as.numeric(date_reported - date_onset), bin = floor(delay / 6) * 6 + 3,
         panel = factor(format(date_reported, "%B"), levels = month.name) %>% droplevels())
o_b <- bin_b(obs) %>% group_by(panel, bin) %>% summarise(n = sum(added), .groups = "drop") %>%
  group_by(panel) %>% mutate(share = n / sum(n))
m_b <- function(m, label) bin_b(m) %>% group_by(panel, bin) %>% summarise(n = sum(added), .groups = "drop") %>%
  group_by(panel) %>% mutate(share = n / sum(n), what = label)
mb <- bind_rows(m_b(m_rep, "Fit (f), with the effects of each report"), m_b(m_no, "Fit (f), without them"))
gb <- ggplot() + geom_col(data = o_b, aes(bin, share), width = 6, fill = "grey70") +
  geom_step(data = mb, aes(bin - 3, share, colour = what), direction = "hv", linewidth = 0.7) +
  scale_colour_manual(values = cols3[-1], name = NULL) +
  facet_wrap(~panel, nrow = 1, labeller = as_labeller(c(July = "July (from 14 July)", August = "August",
                                                        September = "September", October = "October (to 7 October)"))) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Days from onset to the report first showing the death", y = "Share of the month's additions",
       title = "By month of report: delays of the deaths each month's reports added (grey: the reports)") +
  theme_paper() + theme(legend.position = "bottom", strip.text = element_text(size = 12))
save_plot(ga / gb, "outputs/bvd_death_delays_fit_f_shares.png", 15, 9.5)
print(as.data.frame(a_df %>% filter(age %in% c(30, 45, 60, 75, 90, 120)) %>%
  tidyr::pivot_wider(names_from = what, values_from = share) %>% mutate(across(where(is.numeric) & !age, ~ round(.x, 2)))))

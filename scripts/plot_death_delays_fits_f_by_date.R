# Delays of the deaths first shown by each report, against what option (f)
# expected from the latest fit before that report: for each fit date, the
# deaths not yet shown in that date's report are shown by the reports up to
# the next fit date with the probabilities the fit gives (as in
# bvd_projection_draws, with effects of later reports drawn from their prior;
# effects of the day of the week and wrong records left out).
.libPaths(c(".lib", .libPaths()))
suppressMessages({library(dplyr); library(ggplot2); library(targets); library(incidenceinflation)})
tar_source("R"); set.seed(1)
ii <- asNamespace("incidenceinflation")
S <- "/private/tmp/claude-502/-Users-bcl206-Documents-GitHub/d87fe644-4221-4005-ac03-00a1f03fb158/scratchpad"
snap <- build_bvd_snapshots(list.files("data/raw/Ebola CFR", pattern = "^Varified.*[.]csv$", full.names = TRUE))
rd <- sort(unique(snap$date_reported))
half <- function(d) d %>% group_by(chain) %>% filter(iteration > max(iteration) / 2) %>% ungroup()
files <- Sys.glob(file.path(S, "b13", "chains", "*_july_tail_reports_*.rds"))
fit_dates <- sort(unique(sub(".*_([0-9]{4})_[0-9]+[.]rds$", "\\1", basename(files))))
lags <- ii$lag_probabilities_gamma(9.3, 5.5)
n_draws <- 15

expected_after <- function(fits, next_date) {
  a <- fits[[1]]$analysis; day1 <- a$dates$date[1]; t_now <- as.numeric(a$date_now - day1) + 1
  later <- rd[rd > a$date_now & rd <= next_date]; if (!length(later)) return(NULL)
  t_later <- as.numeric(later - day1) + 1
  shown <- snap %>% filter(date_reported == a$date_now) %>%
    transmute(time_onset = as.numeric(date_onset - day1) + 1, deaths_reported)
  shown <- shown$deaths_reported[match(seq_len(t_now), shown$time_onset)]; shown[is.na(shown)] <- 0
  tail_only <- grepl("report effects on recording tail", fits[[1]]$model)
  bind_rows(lapply(fits, function(fit) {
    its <- sample(unique(fit$deaths$iteration), n_draws)
    bind_rows(lapply(its, function(it) {
      deaths <- fit$deaths %>% filter(iteration == it) %>% arrange(time_onset)
      reporting <- fit$reporting_days %>% filter(iteration == it) %>% arrange(time_onset)
      p <- fit$deaths_parameters[which.min(abs(fit$deaths_parameters$iteration - it)), ]
      eff <- list(tail = list(weight = p$recording_tail_weight, mean = p$recording_tail_mean),
                  before = list(lag_probabilities = lags))
      cols <- grep("^recording_report_[0-9]+$", names(p), value = TRUE)
      fitted_days <- as.numeric(sub("recording_report_", "", cols))
      new_days <- setdiff(t_later, fitted_days)
      eff <- ii$update_report_multipliers(c(eff, list(report_tail_only = tail_only,
        report_days = c(fitted_days, new_days),
        report_log_effects = c(log(unlist(p[cols])), rnorm(length(new_days), 0, p$recording_report_sd)))))
      tau <- p$triggered
      bind_rows(lapply(seq_len(t_now), function(t) {
        s <- ii$joint_survivals(c(t_now, t_later), t, list(mean = reporting$mean[t], sd = reporting$sd[t]),
                                list(mean = deaths$delay_mean[t], sd = deaths$delay_sd[t]),
                                dated_reporting_parameters = "recording", recording_effects = eff)
        Srep <- exp(s$log_reported); Sr <- exp(s$log_recorded)
        dead <- (1 - Sr) * (tau + (1 - tau) * (1 - Srep)); dated <- -expm1(s$log_dated)
        n_d <- deaths$dated_by_death[t]; n_f <- deaths$deaths_recorded[t] - n_d
        num <- n_f * (dead[-1] - dead[1]) + n_d * (dated[-1] - dated[1])
        den <- max(n_f * (1 - dead[1]) + n_d * (1 - dated[1]), 1e-12)
        cum <- max(n_f + n_d - shown[t], 0) * pmin(pmax(num / den, 0), 1)
        tibble(time_onset = t, date_reported = later, added = diff(c(0, cum)))
      })) %>% mutate(chain = fit$chain, iteration = it)
    }))
  })) %>% mutate(date_onset = day1 + time_onset - 1, fit = a$date_now)
}
rds_file <- file.path(S, "delays_fits_f_by_date.rds")
if (file.exists(rds_file)) model <- readRDS(rds_file) else {
model <- bind_rows(lapply(seq_along(fit_dates), function(i) {
  fs <- files[grepl(sprintf("_%s_[0-9]+[.]rds$", fit_dates[i]), files)]
  fits <- Filter(function(x) is.null(x$error), lapply(fs, function(f) {
    x <- readRDS(f); for (n in c("deaths", "reporting_days", "deaths_parameters")) x[[n]] <- half(x[[n]]); x }))
  next_date <- if (i < length(fit_dates)) fits[[1]]$analysis$date_now + 
    as.numeric(as.Date(paste0("2026", fit_dates[i + 1]), "%Y%m%d") - fits[[1]]$analysis$date_now) else max(rd)
  cat(fit_dates[i], "\n"); expected_after(fits, next_date)
}))
saveRDS(model, file.path(S, "delays_fits_f_by_date.rds"))
}
first_fit <- min(model$fit)
obs <- tidyr::expand_grid(date_onset = sort(unique(snap$date_onset)), date_reported = rd) %>%
  filter(date_reported >= date_onset) %>%
  left_join(select(snap, date_onset, date_reported, deaths_reported), by = c("date_onset", "date_reported")) %>%
  mutate(deaths_reported = coalesce(deaths_reported, 0L)) %>% arrange(date_onset, date_reported) %>%
  group_by(date_onset) %>% mutate(added = deaths_reported - lag(deaths_reported, default = 0L)) %>% ungroup() %>%
  filter(added > 0, date_reported > first_fit, date_reported <= max(model$date_reported))
# only onset days up to the fit date before each report: those the fit covers
fits_at <- sort(unique(model$fit))
obs <- obs %>% mutate(fit = fits_at[findInterval(as.numeric(date_reported) - 1, as.numeric(fits_at))]) %>%
  filter(date_onset <= fit)
bin_b <- function(df) df %>% mutate(delay = as.numeric(date_reported - date_onset), bin = floor(delay / 6) * 6 + 3,
  panel = factor(format(date_reported, "%B"), levels = month.name) %>% droplevels())
k <- n_distinct(paste(model$chain, model$iteration))
o_b <- bin_b(obs) %>% group_by(panel, bin) %>% summarise(n = sum(added), .groups = "drop") %>%
  group_by(panel) %>% mutate(share = n / sum(n))
m_fit <- bin_b(model) %>% group_by(fit, panel, bin) %>%
  summarise(n = sum(added) / n_distinct(paste(chain, iteration)), .groups = "drop")
m_b <- m_fit %>% group_by(fit, panel) %>% mutate(share = n / sum(n)) %>% ungroup()
windows <- model %>% group_by(fit) %>% summarise(from = min(date_reported), to = max(date_reported))
lev <- with(windows, sprintf("Fit to %s (reports %s to %s)", format(fit, "%d %b"), format(from, "%d %b"), format(to, "%d %b")))
m_b <- m_b %>% left_join(windows, by = "fit") %>%
  mutate(line = factor(sprintf("Fit to %s (reports %s to %s)", format(fit, "%d %b"), format(from, "%d %b"), format(to, "%d %b")), levels = lev))
tot <- full_join(o_b %>% group_by(panel) %>% summarise(reports = sum(n)),
                 m_fit %>% group_by(panel) %>% summarise(expected = round(sum(n))), by = "panel")
lab <- tot %>% mutate(text = sprintf("Reports: %d deaths\nExpected: %d", reports, expected))
g <- ggplot() + geom_col(data = o_b, aes(bin, share), width = 6, fill = "grey70") +
  geom_step(data = m_b, aes(bin - 3, share, colour = line, group = interaction(line, panel)),
            direction = "hv", linewidth = 0.7) +
  geom_text(data = lab, aes(x = Inf, y = Inf, label = text), hjust = 1.05, vjust = 1.3, size = 3.6) +
  scale_colour_viridis_d(name = NULL, end = 0.9) +
  guides(colour = guide_legend(ncol = 3)) +
  facet_wrap(~panel, nrow = 1, labeller = as_labeller(c(August = "Reports from 3 to 30 August",
    September = "Reports in September", October = "Reports from 1 to 7 October"))) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Days from onset to the report first showing the death", y = "Share of the deaths added") +
  theme_paper() + theme(legend.position = "bottom", strip.text = element_text(size = 12))
save_plot(g, "outputs/bvd_death_delays_fits_f_by_date.png", 14, 6)
print(as.data.frame(tot))
over <- function(df) df %>% mutate(d = as.numeric(date_reported - date_onset)) %>%
  group_by(panel = format(date_reported, "%B"), fit) %>%
  summarise(all = sum(added), over21 = sum(added[d > 21]), over60 = sum(added[d > 60]),
            draws = if ("chain" %in% names(df)) n_distinct(paste(chain, iteration)) else 1, .groups = "drop") %>%
  group_by(panel) %>% summarise(across(all:over60, ~ round(sum(.x / draws))))
cat("reports:\n"); print(as.data.frame(over(obs))); cat("expected:\n"); print(as.data.frame(over(model)))

# --- one panel per fit: the reports of its window against what it expected,
# both divided by the deaths those reports added (so the line sums to
# expected / added)
bin_f <- function(df) df %>% mutate(delay = as.numeric(date_reported - date_onset), bin = floor(delay / 6) * 6 + 3)
o_f <- bin_f(obs) %>% group_by(fit, bin) %>% summarise(n = sum(added), .groups = "drop")
e_f <- bin_f(model) %>% group_by(fit, bin) %>%
  summarise(n = sum(added) / n_distinct(paste(chain, iteration)), .groups = "drop")
totals <- o_f %>% group_by(fit) %>% summarise(observed = sum(n)) %>%
  left_join(e_f %>% group_by(fit) %>% summarise(expected = sum(n)), by = "fit") %>% left_join(windows, by = "fit")
o_f <- o_f %>% left_join(totals, by = "fit") %>% mutate(share = n / observed)
e_f <- e_f %>% left_join(totals, by = "fit") %>% mutate(share = n / observed)
strip <- function(f) with(totals[match(f, totals$fit), ],
  sprintf("Fit to %s: reports %s to %s", format(fit, "%d %b"), format(from, "%d %b"), format(to, "%d %b")))
o_f$panel <- factor(strip(o_f$fit), levels = strip(sort(totals$fit)))
e_f$panel <- factor(strip(e_f$fit), levels = strip(sort(totals$fit)))
lab_f <- totals %>% mutate(panel = factor(strip(fit), levels = strip(sort(totals$fit))),
  text = sprintf("Added: %d\nExpected: %.0f", observed, expected))
gf <- ggplot() + geom_col(data = o_f, aes(bin, share), width = 6, fill = "grey70") +
  geom_step(data = e_f, aes(bin - 3, share, colour = "Expected by the fit"), direction = "hv", linewidth = 0.8) +
  geom_text(data = lab_f, aes(x = Inf, y = Inf, label = text), hjust = 1.05, vjust = 1.3, size = 3.4) +
  scale_colour_manual(values = "#D55E00", name = NULL) +
  facet_wrap(~panel, ncol = 3) + coord_cartesian(xlim = c(0, 150)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Days from onset to the report first showing the death",
       y = "Share of the deaths the reports added",
       title = "Grey: deaths the reports added (onset up to the fit date). Line: deaths the fit expected, on the same scale") +
  theme_paper() + theme(legend.position = "bottom", strip.text = element_text(size = 11))
save_plot(gf, "outputs/bvd_death_delays_fits_f_each.png", 14, 10)
print(as.data.frame(totals %>% mutate(expected = round(expected))))

Batch 08_dated_form. Commit 1038708792ad77d37b79bafe91b542b9e6087ea7 of changepoints; model github::ben18785/incidenceinflation_2.0@backlog; 2 datasets for each scenario, 3 chains of 500 iterations; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/simulations/2026-10-18_9_08_dated_form)

# Fits to simulated data

Estimates are means over datasets of the posterior medians. Fatal cases are those the reports will come to count for the days. 'Truth inside' is the share of datasets in which the true value is inside the 90% interval.

| Scenario group | Scenario | Datasets | Fraction counted on day of death: estimate (truth) | Truth inside 90% interval | Share reported at death: estimate (truth) | Fatal cases, all days: estimate (truth) | Truth inside | Fatal cases, latest 14 days: estimate (truth) | Truth inside | Fatal cases, onset before the first report: estimate (truth) | Truth inside | Backlog share: error / coverage | Clearing rate: log error / coverage | Share, onsets before the first report: error / coverage | Share, latest 14 days: error / coverage | Correlation of share and rate (within chains) | Truth less end of chain: log-likelihood / log-posterior | Deaths shown in the last report | Worst R-hat | Minutes per chain |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Right model | Base: 30% counted on day of death, half of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | No death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | A quarter of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | Three quarters of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | Every death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | None counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | 10% counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Right model | 50% counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| An option left out | Base, fitted with no death bringing the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| An option left out | Base, fitted with the fraction held at 10% | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| An option left out | Base, fitted with a free delay from onset to death recorded | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| How well determined | Deaths recorded 1.5 days after death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| How well determined | Deaths recorded 6 days after death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| How well determined | CFR 0.1 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| How well determined | Eight cases a day | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Changes | CFR halves | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Changes | Delay from death to recording falls from 8 to 3 days | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Changes | CFR halves as the delay from death falls | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Changes | Fraction rises from 10% to 50% | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Changes | Share rises from 0.2 to 0.8 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Wrong inputs | Time to death: sd 5.5, fitted with 4.5 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Wrong inputs | Time to death: sd 5.5, fitted with 8 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Wrong inputs | Time to death: 9.3 (sd 5.5), fitted with 12 (sd 7) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Another mechanism | Fatal cases reported twice as fast, no death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Another mechanism | 15% of deaths recorded after a long delay, fitted with a tail | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Another mechanism | 15% of deaths recorded after a long delay, fitted without a tail | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Structure of the outbreak data | Wrong records | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Structure of the outbreak data | First report on day 25 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Structure of the outbreak data | Report of day 45 corrects onset days 1 to 20, earlier reports of them left out | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog: share falls from 0.4 to 0.1, cleared mostly on days 51 to 75, fitted with the backlog | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted with a tail and an effect of each report on it (option f) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 63, part way through the clearing | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 63 with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 50, before the clearing | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 50 with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted with a tail alone | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog cleared only from day 80 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | Backlog with a constant share (0.2) and rate (1/40), fitted with the backlog | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog of deaths | No backlog, fitted with the backlog | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days after death, fitted with the holding period | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days, fitted with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days, fitted on day 63 with the holding period | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days, fitted on day 63 with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days, fitted on day 50 with the holding period | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days and cleared only from day 80 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog held 21 days, constant share (0.2) and rate (1/40) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | No backlog, fitted with the holding period | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| A backlog with a holding period | Backlog with no holding period, fitted with one of 21 days | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, chains started at the true share and rate | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, fitted on day 63, started at the truth | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, fitted on day 50, started at the truth | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, CFR held near its true value | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, fitted on day 63, CFR held near its true value | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, fitted on day 50, CFR held near its true value | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, constant rate 0.04 a day, fitted on day 90 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Backlog held 21 days, constant rate 0.04 a day, fitted on day 55 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Cleared backlog, none counted on day of death and no death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Cleared backlog, none counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Cleared backlog, no death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | Cleared backlog, no death brings the report, fitted without | 2 | 0.29 (0.30) | 1.00 | 0.00 (0.00) | 1643 (1738) | 0.00 | 270 (276) | 1.00 | 696 (746) | 0.00 | 0.05 / 0.79 | 0.59 / 0.22 | 0.05 / 0.82 | 0.03 / 1.00 | 0.00 | -61.6 / -29.5 | 1390 | 1.18 | 78 |
| Is the backlog identified? | The same, fitted with the exact form of the cases dated by death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Like the outbreak | Like the outbreak (the fit to 7 October as truth), fitted to all reports | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Like the outbreak | Like the outbreak, fitted to the reports to 1 August (day 83) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |

## Errors

- cleared_dated_exact, dataset 1: NA/NaN argument (in incidenceinflation::mcmc_single > sample_cases_history > sample_true_cases_single_onset > conditional_cases_revisions_logp > f_observation > joint_cases_deaths_logp); The true cases of an onset time are fewer than the cases reported. (in tryCatchList > tryCatchOne > doTryCatch > withCallingHandlers > incidenceinflation::mcmc_single > deaths_true_step); The true cases of an onset time are fewer than the cases reported. (in tryCatchList > tryCatchOne > doTryCatch > withCallingHandlers > incidenceinflation::mcmc_single > deaths_true_step)
- cleared_dated_exact, dataset 2: The true cases of an onset time are fewer than the cases reported. (in tryCatchList > tryCatchOne > doTryCatch > withCallingHandlers > incidenceinflation::mcmc_single > deaths_true_step); NA/NaN argument (in incidenceinflation::mcmc_single > sample_cases_history > sample_true_cases_single_onset > conditional_cases_revisions_logp > f_observation > joint_cases_deaths_logp); The true cases of an onset time are fewer than the cases reported. (in tryCatchList > tryCatchOne > doTryCatch > withCallingHandlers > incidenceinflation::mcmc_single > deaths_true_step)
- cleared_dated_relaxed, dataset 2: missing value where TRUE/FALSE needed (in withCallingHandlers > incidenceinflation::mcmc_single > deaths_parameters_step > deaths_recording_backlog_step > backlog_slice_steps > elliptical_slice)

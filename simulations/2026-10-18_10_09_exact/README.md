Batch 09_exact. Commit db3704996303f306dd69fa308da373b0073fa33b of changepoints; model github::ben18785/incidenceinflation_2.0@backlog; 2 datasets for each scenario, 3 chains of 500 iterations; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/simulations/2026-10-18_10_09_exact)

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
| Is the backlog identified? | Cleared backlog, no death brings the report, fitted without | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Is the backlog identified? | The same, fitted with the exact form of the cases dated by death | 2 | 0.28 (0.30) | 1.00 | 0.00 (0.00) | 1797 (1738) | 0.50 | 284 (276) | 1.00 | 787 (746) | 0.00 | 0.04 / 0.91 | 0.20 / 0.55 | 0.04 / 1.00 | 0.03 / 1.00 | -0.16 | -7.4 / 28.6 | 1390 | 1.77 | 89 |
| Is the backlog identified? | Cleared backlog, fitted with the exact form of the cases dated by death | 2 | 0.28 (0.30) | 1.00 | 0.57 (0.50) | 1793 (1738) | 0.50 | 286 (276) | 1.00 | 786 (746) | 0.00 | 0.04 / 0.81 | 0.20 / 0.59 | 0.03 / 0.99 | 0.06 / 0.96 | -0.13 | -16.9 / 8.3 | 1394 | 1.84 | 136 |
| The exact form | Backlog held 21 days, fitted with the holding period and the exact form | 2 | 0.27 (0.30) | 0.50 | 0.59 (0.50) | 1747 (1738) | 1.00 | 275 (276) | 1.00 | 776 (746) | 0.50 | 0.04 / 0.92 | 0.44 / 0.73 | 0.03 / 1.00 | 0.05 / 1.00 | -0.23 | -14.4 / -46.1 | 1359 | 1.65 | 72 |
| The exact form | Backlog held 21 days, fitted on day 63 in the exact form | 2 | 0.29 (0.30) | 1.00 | 0.60 (0.50) | 1045 (1214) | 0.00 | 244 (273) | 0.50 | 624 (746) | 0.00 | 0.10 / 0.31 | 1.25 / 0.06 | 0.10 / 0.27 | 0.05 / 0.79 | -0.18 | -76.7 / -106.3 | 790 | 1.73 | 71 |
| The exact form | Backlog held 21 days, fitted on day 50 in the exact form | 2 | 0.38 (0.30) | 1.00 | 0.53 (0.50) | 605 (964) | 0.00 | 180 (275) | 0.00 | 460 (746) | 0.00 | 0.32 / 0.00 | 3.23 / 0.00 | 0.34 / 0.00 | 0.22 / 0.00 | 0.11 | -162.7 / -160.0 | 479 | 3.29 | 36 |
| The exact form | No backlog, fitted with the holding period in the exact form | 2 | 0.32 (0.30) | 1.00 | 0.50 (0.50) | 1840 (1738) | 0.00 | 285 (276) | 1.00 | 830 (746) | 0.00 | 0.05 / 0.00 |  /  | 0.10 / 0.00 | 0.02 / 0.00 | -0.07 |  /  | 1528 | 2.37 | 134 |
| The exact form | Like the outbreak, fitted to all reports in the exact form | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| The exact form | Like the outbreak, fitted to the reports to 1 August in the exact form | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Like the outbreak | Like the outbreak (the fit to 7 October as truth), fitted to all reports | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |
| Like the outbreak | Like the outbreak, fitted to the reports to 1 August (day 83) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  /  |  /  |  |  /  |  |  |  |

## Errors

- hold_mid_exact, dataset 1: The reports of cases and deaths are impossible given the true cases and deaths (onset time 52: 31 cases, 12 fatal, 2 of them dated by death, 2 dated by death into the day). (in tryCatchList > tryCatchOne > doTryCatch > withCallingHandlers > incidenceinflation::mcmc_single > deaths_paths_step)

# Fits to simulated data

Estimates are means over datasets of the posterior medians. Fatal cases are those the reports will come to count for the days. 'Truth inside' is the share of datasets in which the true value is inside the 90% interval.

| Scenario group | Scenario | Datasets | Fraction counted on day of death: estimate (truth) | Truth inside 90% interval | Share reported at death: estimate (truth) | Fatal cases, all days: estimate (truth) | Truth inside | Fatal cases, latest 14 days: estimate (truth) | Truth inside | Fatal cases, onset before the first report: estimate (truth) | Truth inside | Backlog share: error / coverage | Clearing rate: log error / coverage | Deaths shown in the last report | Worst R-hat | Minutes per chain |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Right model | Base: 30% counted on day of death, half of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | No death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | A quarter of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | Three quarters of deaths bring the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | Every death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | None counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | 10% counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Right model | 50% counted on day of death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| An option left out | Base, fitted with no death bringing the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| An option left out | Base, fitted with the fraction held at 10% | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| An option left out | Base, fitted with a free delay from onset to death recorded | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| How well determined | Deaths recorded 1.5 days after death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| How well determined | Deaths recorded 6 days after death | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| How well determined | CFR 0.1 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| How well determined | Eight cases a day | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Changes | CFR halves | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Changes | Delay from death to recording falls from 8 to 3 days | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Changes | CFR halves as the delay from death falls | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Changes | Fraction rises from 10% to 50% | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Changes | Share rises from 0.2 to 0.8 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Wrong inputs | Time to death: sd 5.5, fitted with 4.5 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Wrong inputs | Time to death: sd 5.5, fitted with 8 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Wrong inputs | Time to death: 9.3 (sd 5.5), fitted with 12 (sd 7) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Another mechanism | Fatal cases reported twice as fast, no death brings the report | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Another mechanism | 15% of deaths recorded after a long delay, fitted with a tail | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Another mechanism | 15% of deaths recorded after a long delay, fitted without a tail | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Structure of the outbreak data | Wrong records | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Structure of the outbreak data | First report on day 25 | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| Structure of the outbreak data | Report of day 45 corrects onset days 1 to 20, earlier reports of them left out | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| A backlog of deaths | Backlog: share falls from 0.4 to 0.1, cleared mostly on days 51 to 75, fitted with the backlog | 2 | 0.29 (0.30) | 1.00 | 0.82 (0.50) | 1640 (1738) | 0.00 | 262 (276) | 0.50 | 693 (746) | 0.00 | 0.09 / 0.80 | 1.25 / 0.07 | 1425 | 1.36 | 100 |
| A backlog of deaths | Backlog, fitted with a tail and an effect of each report on it (option f) | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 63, part way through the clearing | 2 | 0.30 (0.30) | 1.00 | 0.84 (0.50) | 1030 (1214) | 0.00 | 240 (273) | 0.50 | 620 (746) | 0.00 | 0.07 / 0.86 | 1.47 / 0.00 | 866 | 1.16 | 56 |
| A backlog of deaths | Backlog, fitted on day 63 with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted on day 50, before the clearing | 2 | 0.41 (0.30) | 0.50 | 0.51 (0.50) | 614 (964) | 0.00 | 179 (275) | 0.00 | 470 (746) | 0.00 | 0.12 / 0.98 | 4.05 / 0.00 | 498 | 1.98 | 42 |
| A backlog of deaths | Backlog, fitted on day 50 with option f | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| A backlog of deaths | Backlog, fitted with a tail alone | 0 |  () |  |  () |  () |  |  () |  |  |  |  /  |  /  |  |  |  |
| A backlog of deaths | Backlog cleared only from day 80 | 2 | 0.28 (0.30) | 1.00 | 0.68 (0.50) | 1528 (1738) | 0.00 | 245 (276) | 0.50 | 620 (746) | 0.00 | 0.07 / 0.68 | 1.11 / 0.27 | 1341 | 1.38 | 92 |
| A backlog of deaths | Backlog with a constant share (0.2) and rate (1/40), fitted with the backlog | 2 | 0.33 (0.30) | 1.00 | 0.56 (0.50) | 1619 (1738) | 0.00 | 250 (276) | 1.00 | 708 (746) | 0.00 | 0.02 / 1.00 | 0.79 / 0.39 | 1401 | 1.24 | 101 |
| A backlog of deaths | No backlog, fitted with the backlog | 2 | 0.34 (0.30) | 0.50 | 0.50 (0.50) | 1735 (1738) | 1.00 | 275 (276) | 1.00 | 746 (746) | 1.00 | 0.72 / 0.00 |  /  | 1528 | 1.49 | 69 |

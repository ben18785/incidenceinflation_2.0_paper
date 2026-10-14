Batch 01_all_scenarios. Commit e8d6b9666b7304befc79bc506a38afdb90ee92fa of changepoints; model github::ben18785/incidenceinflation_2.0@misdated; 3 datasets for each scenario, 3 chains of 400 iterations; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/simulations/2026-10-14_1_01_all_scenarios)

# Fits to simulated data

Estimates are means over datasets of the posterior medians. Fatal cases are those the reports will come to count for the days. 'Truth inside' is the share of datasets in which the true value is inside the 90% interval.

| Scenario group | Scenario | Datasets | Fraction counted on day of death: estimate (truth) | Truth inside 90% interval | Share reported at death: estimate (truth) | Fatal cases, all days: estimate (truth) | Truth inside | Fatal cases, latest 14 days: estimate (truth) | Truth inside | Deaths shown in the last report | Worst R-hat | Minutes per chain |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Right model | Base: 30% counted on day of death, half of deaths bring the report | 3 | 0.28 (0.30) | 0.67 | 0.36 (0.50) | 1124 (1128) | 1.00 | 278 (282) | 1.00 | 926 | 1.33 | 31 |
| Right model | No death brings the report | 3 | 0.27 (0.30) | 0.33 | 0.08 (0.00) | 1118 (1128) | 1.00 | 273 (282) | 1.00 | 915 | 1.11 | 29 |
| Right model | A quarter of deaths bring the report | 3 | 0.28 (0.30) | 0.33 | 0.19 (0.25) | 1121 (1128) | 1.00 | 275 (282) | 1.00 | 920 | 1.22 | 37 |
| Right model | Three quarters of deaths bring the report | 3 | 0.28 (0.30) | 0.67 | 0.64 (0.75) | 1120 (1128) | 1.00 | 273 (282) | 1.00 | 928 | 1.37 | 36 |
| Right model | Every death brings the report | 3 | 0.28 (0.30) | 0.67 | 0.89 (1.00) | 1120 (1128) | 1.00 | 273 (282) | 1.00 | 933 | 1.29 | 25 |
| Right model | None counted on day of death | 3 | 0.04 (0.00) | 0.00 | 0.65 (0.50) | 1193 (1182) | 1.00 | 286 (278) | 1.00 | 919 | 1.75 | 33 |
| Right model | 10% counted on day of death | 3 | 0.11 (0.10) | 0.67 | 0.45 (0.50) | 1164 (1163) | 1.00 | 274 (279) | 1.00 | 922 | 1.23 | 35 |
| Right model | 50% counted on day of death | 3 | 0.46 (0.50) | 1.00 | 0.57 (0.50) | 1082 (1087) | 1.00 | 268 (276) | 1.00 | 925 | 1.15 | 25 |
| An option left out | Base, fitted with no death bringing the report | 3 | 0.31 (0.30) | 0.67 | 0.00 (0.50) | 1129 (1128) | 1.00 | 280 (282) | 1.00 | 926 | 1.29 | 21 |
| An option left out | Base, fitted with the fraction held at 10% | 3 | 0.10 (0.30) | 0.00 | 0.66 (0.50) | 1120 (1128) | 1.00 | 279 (282) | 1.00 | 926 | 1.06 | 18 |
| An option left out | Base, fitted with a free delay from onset to death recorded | 3 | 0.00 (0.30) | 0.00 | 0.63 (0.50) | 1146 (1128) | 1.00 | 278 (282) | 1.00 | 926 | 1.06 | 25 |
| How well determined | Deaths recorded 1.5 days after death | 3 | 0.30 (0.30) | 1.00 | 0.44 (0.50) | 1116 (1128) | 1.00 | 271 (282) | 1.00 | 948 | 1.26 | 25 |
| How well determined | Deaths recorded 6 days after death | 3 | 0.26 (0.30) | 0.33 | 0.49 (0.50) | 1123 (1128) | 1.00 | 276 (282) | 1.00 | 865 | 1.07 | 31 |
| How well determined | CFR 0.1 | 3 | 0.42 (0.30) | 0.33 | 0.56 (0.50) | 278 (239) | 0.33 | 69 (55) | 0.67 | 201 | 1.46 | 25 |
| How well determined | Eight cases a day | 3 | 0.28 (0.30) | 0.67 | 0.59 (0.50) | 243 (240) | 1.00 | 49 (52) | 1.00 | 204 | 1.33 | 21 |
| Changes | CFR halves | 3 | 0.30 (0.30) | 1.00 | 0.19 (0.50) | 911 (911) | 1.00 | 145 (147) | 1.00 | 802 | 1.18 | 18 |
| Changes | Delay from death to recording falls from 8 to 3 days | 3 | 0.28 (0.30) | 0.67 | 0.49 (0.50) | 1114 (1128) | 1.00 | 270 (282) | 1.00 | 911 | 1.17 | 39 |
| Changes | CFR halves as the delay from death falls | 3 | 0.29 (0.30) | 0.67 | 0.67 (0.50) | 890 (890) | 1.00 | 141 (147) | 1.00 | 772 | 1.24 | 28 |
| Changes | Fraction rises from 10% to 50% | 3 | 0.26 (0.30) | 0.67 | 0.60 (0.50) | 1099 (1087) | 1.00 | 279 (271) | 1.00 | 927 | 1.32 | 35 |
| Changes | Share rises from 0.2 to 0.8 | 3 | 0.29 (0.30) | 0.67 | 0.29 (0.50) | 1127 (1128) | 1.00 | 278 (282) | 1.00 | 928 | 1.84 | 36 |
| Wrong inputs | Time to death: sd 5.5, fitted with 4.5 | 3 | 0.33 (0.30) | 0.67 | 0.50 (0.50) | 1124 (1128) | 1.00 | 278 (282) | 1.00 | 926 | 1.16 | 37 |
| Wrong inputs | Time to death: sd 5.5, fitted with 8 | 3 | 0.22 (0.30) | 0.00 | 0.10 (0.50) | 1134 (1128) | 1.00 | 275 (282) | 1.00 | 926 | 1.46 | 35 |
| Wrong inputs | Time to death: 9.3 (sd 5.5), fitted with 12 (sd 7) | 3 | 0.23 (0.30) | 0.33 | 0.87 (0.50) | 1159 (1128) | 0.67 | 295 (282) | 1.00 | 926 | 1.16 | 27 |
| Another mechanism | Fatal cases reported twice as fast, no death brings the report | 3 | 0.24 (0.30) | 0.00 | 0.82 (0.00) | 1122 (1128) | 1.00 | 277 (282) | 1.00 | 931 | 1.06 | 35 |
| Another mechanism | 15% of deaths recorded after a long delay, fitted with a tail | 3 | 0.27 (0.30) | 0.67 | 0.47 (0.50) | 1058 (1128) | 0.00 | 252 (282) | 0.67 | 843 | 1.08 | 39 |
| Another mechanism | 15% of deaths recorded after a long delay, fitted without a tail | 3 | 0.32 (0.30) | 0.67 | 0.40 (0.50) | 1036 (1128) | 0.00 | 247 (282) | 0.33 | 843 | 1.20 | 35 |
| Structure of the outbreak data | Wrong records | 3 | 0.28 (0.30) | 0.33 | 0.40 (0.50) | 1124 (1128) | 1.00 | 276 (282) | 1.00 | 928 | 1.51 | 37 |
| Structure of the outbreak data | First report on day 25 | 3 | 0.31 (0.30) | 1.00 | 0.43 (0.50) | 1120 (1128) | 1.00 | 275 (282) | 1.00 | 926 | 1.26 | 36 |
| Structure of the outbreak data | Report of day 45 corrects onset days 1 to 20, earlier reports of them left out | 3 | 0.31 (0.30) | 1.00 | 0.62 (0.50) | 1115 (1123) | 1.00 | 265 (273) | 1.00 | 918 | 1.11 | 17 |

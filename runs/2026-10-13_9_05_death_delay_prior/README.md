Batch 05_death_delay_prior. Commit e801d37e9d09f4ec61d2782846dc97fa5b0b246f of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-13_9_05_death_delay_prior)

# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| fixed_october_cases_0915 | 4 | 600 | 74 |
| fixed_october_cases_tight_delay_0905 | 4 | 600 | 98 |
| fixed_october_cases_tight_delay_drift_0905 | 4 | 600 | 96 |
| joint_no_tail_tight_delay_0905 | 4 | 800 | 108 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| fixed_october_cases_0915 | 3.31 | 7 |
| fixed_october_cases_tight_delay_0905 | 4.50 | 10 |
| fixed_october_cases_tight_delay_drift_0905 | 1.60 | 5 |
| joint_no_tail_tight_delay_0905 | 2.45 | 8 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_15Sep | recorded_01Oct | recorded_05Sep |
|---|---|---|---|---|---|---|---|
| fixed_october_cases_0915 | deaths | all | 3574 (3370-4077) | 2.95 | 2482 | 2711 |  |
| fixed_october_cases_0915 | deaths | latest 28 | 1024 (954-1308) | 2.96 | 523 | 726 |  |
| fixed_october_cases_0915 | deaths | latest 14 | 494 (451-653) | 2.56 | 154 | 315 |  |
| fixed_october_cases_tight_delay_0905 | deaths | all | 3087 (2875-3388) | 2.45 | 2407 | 2502 | 2111 |
| fixed_october_cases_tight_delay_0905 | deaths | latest 28 | 1007 (902-1132) | 1.88 | 720 | 794 | 499 |
| fixed_october_cases_tight_delay_0905 | deaths | latest 14 | 507 (450-575) | 1.61 | 344 | 407 | 169 |
| fixed_october_cases_tight_delay_drift_0905 | deaths | all | 2961 (2808-3107) | 1.60 | 2407 | 2502 | 2111 |
| fixed_october_cases_tight_delay_drift_0905 | deaths | latest 28 | 935 (875-998) | 1.35 | 720 | 794 | 499 |
| fixed_october_cases_tight_delay_drift_0905 | deaths | latest 14 | 462 (428-497) | 1.20 | 344 | 407 | 169 |
| joint_no_tail_tight_delay_0905 | cases | all | 5558 (5490-5628) | 1.01 | 5391 | 5504 | 5079 |
| joint_no_tail_tight_delay_0905 | cases | latest 28 | 1732 (1664-1802) | 1.01 | 1608 | 1699 | 1252 |
| joint_no_tail_tight_delay_0905 | cases | latest 14 | 880 (820-944) | 1.01 | 748 | 830 | 430 |
| joint_no_tail_tight_delay_0905 | deaths | all | 3072 (2870-3244) | 1.48 | 2407 | 2502 | 2111 |
| joint_no_tail_tight_delay_0905 | deaths | latest 28 | 986 (912-1085) | 1.24 | 720 | 794 | 499 |
| joint_no_tail_tight_delay_0905 | deaths | latest 14 | 508 (457-568) | 1.13 | 344 | 407 | 169 |

## Mean delay by onset day (days)

| experiment | 11 May | 04 Aug | 18 Aug | 01 Sep | 15 Sep | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|---|---|---|---|
| fixed_october_cases_0915 | 66.7 (49.1-84.4) | 38.1 (22.3-84.4) | 39.7 (21.8-84.4) | 32.1 (17.9-84.4) | 32.2 (17.9-84.4) |  |  |  |  |
| fixed_october_cases_tight_delay_0905 | 57.2 (46.2-83.0) |  |  |  |  | 36.9 (23.1-45.0) | 36.9 (23.1-45.0) | 36.9 (23.1-45.0) | 36.9 (23.1-45.0) |
| fixed_october_cases_tight_delay_drift_0905 | 33.5 (27.9-38.7) |  |  |  |  | 36.0 (25.2-60.5) | 32.8 (22.1-54.1) | 32.6 (20.7-47.8) | 29.4 (17.5-45.6) |
| joint_no_tail_tight_delay_0905 | 71.6 (55.4-91.7) |  |  |  |  | 43.1 (29.1-56.8) | 43.1 (28.5-56.8) | 43.2 (28.4-56.9) | 43.2 (28.3-56.9) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-13_9_05_death_delay_prior/delays.png)

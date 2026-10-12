Commit 0ceceaa3a7a64ae2e513868bef6fc9dcd4f03f0a of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-12_4)

# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| fixed_0905 | 4 | 600 | 110 |
| fixed_drift_0905 | 4 | 600 | 120 |
| fixed_more_changes_0905 | 4 | 600 | 90 |
| fixed_seven_day_0905 | 4 | 600 | 122 |
| fixed_seven_day_more_0905 | 4 | 600 | 90 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| fixed_0905 | 2.35 | 5 |
| fixed_drift_0905 | 1.80 | 5 |
| fixed_more_changes_0905 | 2.22 | 10 |
| fixed_seven_day_0905 | 4.34 | 10 |
| fixed_seven_day_more_0905 | 2.48 | 7 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|
| fixed_0905 | deaths | all | 4148 (3850-4508) | 2.15 | 2111 | 2407 | 2502 |
| fixed_0905 | deaths | latest 28 | 1330 (1189-1534) | 1.98 | 499 | 720 | 794 |
| fixed_0905 | deaths | latest 14 | 687 (610-800) | 1.83 | 169 | 344 | 407 |
| fixed_drift_0905 | deaths | all | 4102 (3855-4355) | 1.57 | 2111 | 2407 | 2502 |
| fixed_drift_0905 | deaths | latest 28 | 1289 (1204-1403) | 1.36 | 499 | 720 | 794 |
| fixed_drift_0905 | deaths | latest 14 | 661 (611-725) | 1.31 | 169 | 344 | 407 |
| fixed_more_changes_0905 | deaths | all | 4286 (3989-4583) | 1.77 | 2111 | 2407 | 2502 |
| fixed_more_changes_0905 | deaths | latest 28 | 1352 (1236-1471) | 1.49 | 499 | 720 | 794 |
| fixed_more_changes_0905 | deaths | latest 14 | 695 (634-770) | 1.38 | 169 | 344 | 407 |
| fixed_seven_day_0905 | deaths | all | 4273 (4090-4730) | 1.69 | 2111 | 2407 | 2502 |
| fixed_seven_day_0905 | deaths | latest 28 | 1334 (1257-1482) | 1.41 | 499 | 720 | 794 |
| fixed_seven_day_0905 | deaths | latest 14 | 686 (638-763) | 1.38 | 169 | 344 | 407 |
| fixed_seven_day_more_0905 | deaths | all | 4257 (3965-4476) | 1.63 | 2111 | 2407 | 2502 |
| fixed_seven_day_more_0905 | deaths | latest 28 | 1341 (1219-1462) | 1.56 | 499 | 720 | 794 |
| fixed_seven_day_more_0905 | deaths | latest 14 | 687 (620-759) | 1.46 | 169 | 344 | 407 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| fixed_0905 | 71.0 (61.9-90.3) | 39.7 (27.4-56.8) | 39.2 (25.2-56.8) | 39.4 (24.9-57.0) | 39.4 (24.9-57.0) |
| fixed_drift_0905 | 61.4 (48.7-82.3) | 45.9 (35.2-64.3) | 43.2 (31.5-62.0) | 42.8 (29.7-59.7) | 39.9 (25.9-59.5) |
| fixed_more_changes_0905 | 96.7 (68.5-134.4) | 50.3 (39.6-68.2) | 49.5 (38.5-68.2) | 47.8 (21.8-68.0) | 47.6 (21.6-67.7) |
| fixed_seven_day_0905 | 103.3 (77.7-150.7) | 48.9 (40.8-75.8) | 48.9 (40.6-75.8) | 48.9 (40.2-75.9) | 47.1 (7.5-76.0) |
| fixed_seven_day_more_0905 | 88.6 (70.1-114.5) | 55.1 (30.0-66.4) | 54.8 (29.5-66.3) | 54.1 (27.8-66.4) | 38.8 (13.0-65.6) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-12_4/delays.png)

Batch 06_deaths_bring_reports. Commit f4ac4505f9526b84ce892e3cc63f2d4d574644fd of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-13_12_06_deaths_bring_reports)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| fixed_cases_triggered_1001 | 4 | 600 | 600 | 112 |
| fixed_october_cases_triggered_0905 | 4 | 600 | 600 | 75 |
| fixed_october_cases_triggered_0915 | 4 | 600 | 600 | 98 |
| fixed_october_cases_triggered_drift_0905 | 4 | 600 | 600 | 100 |
| joint_no_tail_triggered_0905 | 4 | 800 | 800 | 126 |
| joint_no_tail_triggered_0915 | 4 | 800 | 800 | 80 |
| joint_no_tail_triggered_1001 | 4 | 800 | 800 | 114 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| fixed_cases_triggered_1001 | 1.92 | 8 |
| fixed_october_cases_triggered_0905 | 2.15 | 8 |
| fixed_october_cases_triggered_0915 | 2.09 | 5 |
| fixed_october_cases_triggered_drift_0905 | 3.35 | 10 |
| joint_no_tail_triggered_0905 | 1.77 | 5 |
| joint_no_tail_triggered_0915 | 1.86 | 9 |
| joint_no_tail_triggered_1001 | 1.78 | 4 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Oct | recorded_05Sep | recorded_15Sep |
|---|---|---|---|---|---|---|---|
| fixed_cases_triggered_1001 | deaths | all | 3218 (3137-3279) | 1.36 | 2821 |  |  |
| fixed_cases_triggered_1001 | deaths | latest 28 | 678 (598-711) | 1.29 | 379 |  |  |
| fixed_cases_triggered_1001 | deaths | latest 14 | 316 (260-340) | 1.23 | 87 |  |  |
| fixed_october_cases_triggered_0905 | deaths | all | 2770 (2606-2917) | 2.10 | 2502 | 2111 | 2407 |
| fixed_october_cases_triggered_0905 | deaths | latest 28 | 849 (753-907) | 1.87 | 794 | 499 | 720 |
| fixed_october_cases_triggered_0905 | deaths | latest 14 | 422 (375-458) | 1.49 | 407 | 169 | 344 |
| fixed_october_cases_triggered_0915 | deaths | all | 3074 (2991-3171) | 1.47 | 2711 |  | 2482 |
| fixed_october_cases_triggered_0915 | deaths | latest 28 | 850 (811-888) | 1.04 | 726 |  | 523 |
| fixed_october_cases_triggered_0915 | deaths | latest 14 | 415 (388-442) | 1.04 | 315 |  | 154 |
| fixed_october_cases_triggered_drift_0905 | deaths | all | 3052 (2713-3346) | 2.62 | 2502 | 2111 | 2407 |
| fixed_october_cases_triggered_drift_0905 | deaths | latest 28 | 1032 (833-1264) | 2.49 | 794 | 499 | 720 |
| fixed_october_cases_triggered_drift_0905 | deaths | latest 14 | 516 (418-678) | 2.24 | 407 | 169 | 344 |
| joint_no_tail_triggered_0905 | cases | all | 5556 (5485-5622) | 1.02 | 5504 | 5079 | 5391 |
| joint_no_tail_triggered_0905 | cases | latest 28 | 1729 (1659-1794) | 1.02 | 1699 | 1252 | 1608 |
| joint_no_tail_triggered_0905 | cases | latest 14 | 879 (815-940) | 1.01 | 830 | 430 | 748 |
| joint_no_tail_triggered_0905 | deaths | all | 2711 (2631-2812) | 1.04 | 2502 | 2111 | 2407 |
| joint_no_tail_triggered_0905 | deaths | latest 28 | 838 (789-894) | 1.05 | 794 | 499 | 720 |
| joint_no_tail_triggered_0905 | deaths | latest 14 | 434 (397-476) | 1.02 | 407 | 169 | 344 |
| joint_no_tail_triggered_0915 | cases | all | 6097 (6032-6174) | 1.03 | 6044 |  | 5619 |
| joint_no_tail_triggered_0915 | cases | latest 28 | 1676 (1612-1754) | 1.03 | 1599 |  | 1199 |
| joint_no_tail_triggered_0915 | cases | latest 14 | 861 (798-930) | 1.02 | 761 |  | 410 |
| joint_no_tail_triggered_0915 | deaths | all | 3049 (2909-3158) | 1.68 | 2711 |  | 2482 |
| joint_no_tail_triggered_0915 | deaths | latest 28 | 850 (797-907) | 1.18 | 726 |  | 523 |
| joint_no_tail_triggered_0915 | deaths | latest 14 | 435 (393-482) | 1.09 | 315 |  | 154 |
| joint_no_tail_triggered_1001 | cases | all | 6844 (6762-6914) | 1.15 | 6428 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 28 | 1458 (1377-1528) | 1.15 | 1043 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 14 | 680 (614-743) | 1.09 | 305 |  |  |
| joint_no_tail_triggered_1001 | deaths | all | 3229 (3172-3289) | 1.15 | 2821 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 28 | 694 (650-739) | 1.04 | 379 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 14 | 332 (297-373) | 1.03 | 87 |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Aug | 03 Sep | 17 Sep | 01 Oct | 25 Jul | 08 Aug | 22 Aug | 05 Sep | 04 Aug | 18 Aug | 01 Sep | 15 Sep |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fixed_cases_triggered_1001 | 48.3 (26.4-59.3) | 8.9 (8.0-10.2) | 8.9 (8.0-9.9) | 12.7 (8.7-15.2) | 12.7 (8.7-15.2) |  |  |  |  |  |  |  |  |
| fixed_october_cases_triggered_0905 | 60.8 (53.7-101.3) |  |  |  |  | 23.0 (19.1-29.2) | 22.9 (15.8-29.2) | 10.8 (8.5-12.7) | 10.8 (8.5-12.6) |  |  |  |  |
| fixed_october_cases_triggered_0915 | 54.8 (49.0-62.4) |  |  |  |  |  |  |  |  | 25.0 (15.6-28.6) | 10.5 (8.7-27.7) | 9.4 (8.2-11.2) | 9.4 (8.2-11.2) |
| fixed_october_cases_triggered_drift_0905 | 53.8 (44.2-65.0) |  |  |  |  | 39.1 (19.8-48.3) | 36.7 (16.7-47.2) | 35.6 (13.6-48.8) | 35.3 (10.8-48.4) |  |  |  |  |
| joint_no_tail_triggered_0905 | 60.0 (51.0-75.6) |  |  |  |  | 22.0 (18.5-25.7) | 19.9 (11.8-24.4) | 12.1 (9.9-13.6) | 12.1 (9.9-13.6) |  |  |  |  |
| joint_no_tail_triggered_0915 | 60.5 (46.2-105.2) |  |  |  |  |  |  |  |  | 21.2 (13.1-29.2) | 10.1 (8.3-19.7) | 9.8 (8.0-11.1) | 9.8 (8.0-11.1) |
| joint_no_tail_triggered_1001 | 38.5 (30.4-50.3) | 9.4 (8.6-10.2) | 9.4 (8.6-10.2) | 15.4 (13.5-17.6) | 15.4 (13.5-17.6) |  |  |  |  |  |  |  |  |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-13_12_06_deaths_bring_reports/delays.png)

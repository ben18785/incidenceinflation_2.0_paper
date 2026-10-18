Batch 15_backlog_hold_exact. Commit affefd7c12ba0df32283d7fec48d192acf0190de of changepoints; model github::ben18785/incidenceinflation_2.0@backlog; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-18_26_15_backlog_hold_exact)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | 4 | 1500 | 1500 | 122 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | 4 | 891-1500 | 1500 | 308 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | 1.27 | 2 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | 1.80 | 7 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Aug | recorded_15Sep | recorded_07Oct |
|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | cases | all | 3420 (3301-3542) | 1.10 | 2875 | 3388 | 3411 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | cases | latest 28 | 1577 (1458-1696) | 1.11 | 1037 | 1511 | 1520 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | cases | latest 14 | 870 (758-974) | 1.12 | 403 | 831 | 837 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | deaths | all | 1243 (1179-1341) | 1.14 | 956 | 1497 | 1533 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | deaths | latest 28 | 623 (561-710) | 1.13 | 348 | 694 | 709 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | deaths | latest 14 | 343 (294-402) | 1.12 | 126 | 391 | 400 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | cases | all | 7212 (7158-7281) | 1.07 |  |  | 6782 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | cases | latest 28 | 1432 (1382-1502) | 1.03 |  |  | 1018 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | cases | latest 14 | 732 (687-793) | 1.04 |  |  | 363 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | deaths | all | 3400 (3301-3476) | 1.69 |  |  | 3031 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | deaths | latest 28 | 679 (634-722) | 1.23 |  |  | 382 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | deaths | latest 14 | 348 (318-381) | 1.08 |  |  | 120 |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 26 Aug | 09 Sep | 23 Sep | 07 Oct |
|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0801 | 3.5 (2.9-4.3) | 3.5 (2.9-4.3) | 3.5 (2.9-4.3) | 3.5 (2.9-4.3) | 3.5 (2.9-4.3) |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1007 | 4.2 (3.8-5.7) |  |  |  |  | 4.0 (3.6-4.5) | 4.0 (3.6-4.5) | 4.1 (3.7-5.3) | 4.1 (3.7-5.3) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-18_26_15_backlog_hold_exact/delays.png)

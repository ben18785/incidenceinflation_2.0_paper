Batch 21_ridge_0801_0819. Commit 34aff022f856d93bf088fda75997a6ba70ed0330 of changepoints; model github::ben18785/incidenceinflation_2.0@ridge-move; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-23_53_21_ridge_0801_0819)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | 4 | 3000 | 3000 | 232 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | 3 | 2160-2851 | 3000 | 320 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | 1.20 | 1 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | 1.28 | 2 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Aug | recorded_15Sep | recorded_14Oct | recorded_19Aug |
|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | cases | all | 3385 (3264-3509) | 1.02 | 2875 | 3388 | 3479 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | cases | latest 28 | 1542 (1423-1666) | 1.02 | 1037 | 1511 | 1553 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | cases | latest 14 | 841 (729-951) | 1.02 | 403 | 831 | 855 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | deaths | all | 1232 (1151-1371) | 1.20 | 956 | 1497 | 1559 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | deaths | latest 28 | 610 (535-734) | 1.18 | 348 | 694 | 717 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | deaths | latest 14 | 333 (279-414) | 1.13 | 126 | 391 | 401 |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | cases | all | 4568 (4480-4667) | 1.05 |  | 4461 | 4581 | 4043 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | cases | latest 28 | 1720 (1633-1819) | 1.05 |  | 1636 | 1686 | 1195 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | cases | latest 14 | 949 (870-1033) | 1.04 |  | 850 | 873 | 458 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | deaths | all | 1740 (1695-1793) | 1.06 |  | 1978 | 2070 | 1462 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | deaths | latest 28 | 686 (642-738) | 1.07 |  | 746 | 784 | 414 |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | deaths | latest 14 | 375 (337-420) | 1.05 |  | 370 | 395 | 147 |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 08 Jul | 22 Jul | 05 Aug | 19 Aug |
|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0801 | 3.9 (3.0-5.2) | 3.9 (3.0-5.2) | 3.9 (3.0-5.2) | 3.9 (3.0-5.2) | 3.9 (3.0-5.2) |  |  |  |  |
| joint_no_tail_misdated_ridge_triggered_fixed_july_backlog_exact_0819 | 6.1 (5.0-7.0) |  |  |  |  | 6.1 (5.0-7.0) | 6.1 (5.0-7.0) | 6.1 (4.9-7.0) | 6.1 (4.9-7.0) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-23_53_21_ridge_0801_0819/delays.png)

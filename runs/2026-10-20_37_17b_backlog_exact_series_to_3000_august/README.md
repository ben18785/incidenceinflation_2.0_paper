Batch 17b_backlog_exact_series_to_3000_august. Commit b9c4fb71a9b2eb4d9f7e067b3117cefccf6a216e of changepoints; model github::ben18785/incidenceinflation_2.0@logl-trace; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-20_37_17b_backlog_exact_series_to_3000_august)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | 4 | 3000 | 3000 | 263 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | 4 | 3000 | 3000 | 453 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | 4 | 3000 | 3000 | 536 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | 2.32 | 5 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | 1.80 | 6 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | 1.51 | 4 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_09Aug | recorded_15Sep | recorded_14Oct | recorded_19Aug | recorded_26Aug |
|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | cases | all | 3908 (3767-4077) | 1.08 | 3322 | 3853 | 3953 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | cases | latest 28 | 1679 (1541-1847) | 1.09 | 1099 | 1607 | 1645 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | cases | latest 14 | 894 (771-1045) | 1.08 | 383 | 832 | 853 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | deaths | all | 1372 (1317-1433) | 1.05 | 1129 | 1716 | 1786 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | deaths | latest 28 | 612 (563-671) | 1.06 | 380 | 744 | 765 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | deaths | latest 14 | 322 (281-370) | 1.07 | 126 | 384 | 398 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | cases | all | 4580 (4489-4685) | 1.09 |  | 4461 | 4581 | 4043 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | cases | latest 28 | 1732 (1642-1835) | 1.09 |  | 1636 | 1686 | 1195 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | cases | latest 14 | 956 (876-1049) | 1.09 |  | 850 | 873 | 458 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | deaths | all | 1738 (1695-1790) | 1.14 |  | 1978 | 2070 | 1462 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | deaths | latest 28 | 684 (644-736) | 1.13 |  | 746 | 784 | 414 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | deaths | latest 14 | 375 (339-417) | 1.11 |  | 370 | 395 | 147 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | cases | all | 4914 (4838-4993) | 1.03 |  | 4887 | 5045 |  | 4461 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | cases | latest 28 | 1688 (1612-1767) | 1.03 |  | 1689 | 1765 |  | 1235 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | cases | latest 14 | 834 (765-907) | 1.03 |  | 819 | 876 |  | 409 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | deaths | all | 1976 (1931-2028) | 1.07 |  | 2174 | 2291 |  | 1712 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | deaths | latest 28 | 723 (679-773) | 1.06 |  | 764 | 822 |  | 466 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | deaths | latest 14 | 350 (314-391) | 1.05 |  | 357 | 397 |  | 142 |

## Mean delay by onset day (days)

| experiment | 11 May | 28 Jun | 12 Jul | 26 Jul | 09 Aug | 08 Jul | 22 Jul | 05 Aug | 19 Aug | 15 Jul | 29 Jul | 12 Aug | 26 Aug |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0809 | 4.0 (3.0-5.4) | 4.0 (3.0-5.4) | 4.0 (3.0-5.4) | 4.0 (3.0-5.4) | 4.0 (3.0-5.4) |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0819 | 5.2 (4.2-6.6) |  |  |  |  | 5.2 (4.2-6.6) | 5.2 (4.2-6.6) | 5.2 (4.2-6.6) | 5.2 (4.2-6.6) |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0826 | 5.2 (4.3-6.1) |  |  |  |  |  |  |  |  | 5.2 (4.3-6.1) | 5.2 (4.3-6.1) | 5.2 (4.3-6.1) | 5.2 (4.3-6.1) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-20_37_17b_backlog_exact_series_to_3000_august/delays.png)

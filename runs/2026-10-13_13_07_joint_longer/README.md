Batch 07_joint_longer. Commit 05d4e4b6f147e619564c7a5706afc0d01e52c9c3 of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-13_13_07_joint_longer)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_triggered_0801 | 4 | 3000 | 3000 | 232 |
| joint_no_tail_triggered_0820 | 4 | 2490-3000 | 3000 | 303 |
| joint_no_tail_triggered_0905 | 4 | 2615-3000 | 3000 | 411 |
| joint_no_tail_triggered_0915 | 4 | 3000 | 3000 | 346 |
| joint_no_tail_triggered_1001 | 4 | 2747-3000 | 3000 | 384 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_triggered_0801 | 2.01 | 8 |
| joint_no_tail_triggered_0820 | 1.34 | 2 |
| joint_no_tail_triggered_0905 | 2.46 | 10 |
| joint_no_tail_triggered_0915 | 1.67 | 5 |
| joint_no_tail_triggered_1001 | 1.47 | 3 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Aug | recorded_15Sep | recorded_01Oct | recorded_20Aug | recorded_05Sep |
|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_triggered_0801 | cases | all | 3493 (3369-3613) | 1.00 | 2875 | 3388 | 3409 |  |  |
| joint_no_tail_triggered_0801 | cases | latest 28 | 1642 (1522-1761) | 1.00 | 1037 | 1511 | 1521 |  |  |
| joint_no_tail_triggered_0801 | cases | latest 14 | 922 (810-1022) | 1.00 | 403 | 831 | 838 |  |  |
| joint_no_tail_triggered_0801 | deaths | all | 1314 (1215-1670) | 1.99 | 956 | 1497 | 1516 |  |  |
| joint_no_tail_triggered_0801 | deaths | latest 28 | 628 (556-796) | 1.55 | 348 | 694 | 703 |  |  |
| joint_no_tail_triggered_0801 | deaths | latest 14 | 344 (285-447) | 1.38 | 126 | 391 | 397 |  |  |
| joint_no_tail_triggered_0820 | cases | all | 4570 (4496-4656) | 1.01 |  | 4543 | 4573 | 4099 |  |
| joint_no_tail_triggered_0820 | cases | latest 28 | 1672 (1598-1758) | 1.01 |  | 1668 | 1682 | 1201 |  |
| joint_no_tail_triggered_0820 | cases | latest 14 | 903 (834-979) | 1.01 |  | 873 | 881 | 456 |  |
| joint_no_tail_triggered_0820 | deaths | all | 1978 (1852-2132) | 1.15 |  | 2021 | 2050 | 1488 |  |
| joint_no_tail_triggered_0820 | deaths | latest 28 | 715 (651-791) | 1.08 |  | 762 | 775 | 411 |  |
| joint_no_tail_triggered_0820 | deaths | latest 14 | 382 (334-435) | 1.05 |  | 385 | 393 | 146 |  |
| joint_no_tail_triggered_0905 | cases | all | 5551 (5478-5620) | 1.00 |  | 5391 | 5504 |  | 5079 |
| joint_no_tail_triggered_0905 | cases | latest 28 | 1724 (1652-1794) | 1.00 |  | 1608 | 1699 |  | 1252 |
| joint_no_tail_triggered_0905 | cases | latest 14 | 874 (811-939) | 1.00 |  | 748 | 830 |  | 430 |
| joint_no_tail_triggered_0905 | deaths | all | 2827 (2672-3083) | 1.81 |  | 2407 | 2502 |  | 2111 |
| joint_no_tail_triggered_0905 | deaths | latest 28 | 858 (766-951) | 1.35 |  | 720 | 794 |  | 499 |
| joint_no_tail_triggered_0905 | deaths | latest 14 | 440 (369-498) | 1.23 |  | 344 | 407 |  | 169 |
| joint_no_tail_triggered_0915 | cases | all | 6097 (6027-6171) | 1.00 |  | 5619 | 6044 |  |  |
| joint_no_tail_triggered_0915 | cases | latest 28 | 1677 (1607-1753) | 1.00 |  | 1199 | 1599 |  |  |
| joint_no_tail_triggered_0915 | cases | latest 14 | 860 (795-928) | 1.00 |  | 410 | 761 |  |  |
| joint_no_tail_triggered_0915 | deaths | all | 3078 (2967-3242) | 1.67 |  | 2482 | 2711 |  |  |
| joint_no_tail_triggered_0915 | deaths | latest 28 | 856 (799-916) | 1.12 |  | 523 | 726 |  |  |
| joint_no_tail_triggered_0915 | deaths | latest 14 | 439 (394-486) | 1.08 |  | 154 | 315 |  |  |
| joint_no_tail_triggered_1001 | cases | all | 6842 (6759-6910) | 1.02 |  |  | 6428 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 28 | 1457 (1374-1523) | 1.02 |  |  | 1043 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 14 | 678 (609-739) | 1.01 |  |  | 305 |  |  |
| joint_no_tail_triggered_1001 | deaths | all | 3189 (3099-3259) | 1.08 |  |  | 2821 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 28 | 674 (570-732) | 1.15 |  |  | 379 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 14 | 321 (242-370) | 1.13 |  |  | 87 |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 09 Jul | 23 Jul | 06 Aug | 20 Aug | 25 Jul | 08 Aug | 22 Aug | 05 Sep | 04 Aug | 18 Aug | 01 Sep | 15 Sep | 03 Sep | 17 Sep | 01 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_triggered_0801 | 52.6 (34.7-103.4) | 21.8 (10.6-51.5) | 14.7 (9.4-33.1) | 15.5 (5.7-33.2) | 15.5 (5.7-33.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0820 | 55.5 (40.7-80.9) |  |  |  |  | 24.7 (15.0-46.6) | 25.0 (15.1-46.7) | 25.0 (15.1-46.7) | 25.0 (15.1-46.7) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0905 | 84.3 (59.5-146.0) |  |  |  |  |  |  |  |  | 27.5 (19.3-43.1) | 27.2 (19.1-42.8) | 11.9 (7.1-16.2) | 11.9 (7.1-16.2) |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0915 | 58.0 (40.8-70.7) |  |  |  |  |  |  |  |  |  |  |  |  | 21.1 (16.0-33.4) | 10.1 (8.7-24.7) | 9.7 (8.5-11.4) | 9.7 (8.5-11.4) |  |  |  |
| joint_no_tail_triggered_1001 | 43.4 (28.5-60.7) |  |  |  |  |  |  |  | 9.4 (8.5-10.3) |  |  |  |  |  |  |  |  | 9.3 (8.5-10.3) | 13.3 (9.3-16.4) | 13.3 (9.3-16.4) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-13_13_07_joint_longer/delays.png)

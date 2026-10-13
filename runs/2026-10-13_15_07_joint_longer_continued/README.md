Batch 07_joint_longer_continued. Commit d18d8d3bc8ed96ed643c461bca3e594cbc74cb4d of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-13_15_07_joint_longer_continued)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_triggered_0801 | 4 | 3000 | 3000 | 232 |
| joint_no_tail_triggered_0820 | 4 | 3000 | 3000 | 320 |
| joint_no_tail_triggered_0905 | 4 | 3000 | 3000 | 436 |
| joint_no_tail_triggered_0915 | 4 | 3000 | 3000 | 346 |
| joint_no_tail_triggered_1001 | 4 | 3000 | 3000 | 400 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_triggered_0801 | 2.01 | 8 |
| joint_no_tail_triggered_0820 | 1.23 | 2 |
| joint_no_tail_triggered_0905 | 2.26 | 8 |
| joint_no_tail_triggered_0915 | 1.67 | 5 |
| joint_no_tail_triggered_1001 | 1.49 | 3 |

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
| joint_no_tail_triggered_0820 | cases | all | 4570 (4494-4659) | 1.00 |  | 4543 | 4573 | 4099 |  |
| joint_no_tail_triggered_0820 | cases | latest 28 | 1673 (1596-1762) | 1.00 |  | 1668 | 1682 | 1201 |  |
| joint_no_tail_triggered_0820 | cases | latest 14 | 902 (833-980) | 1.00 |  | 873 | 881 | 456 |  |
| joint_no_tail_triggered_0820 | deaths | all | 1980 (1856-2131) | 1.10 |  | 2021 | 2050 | 1488 |  |
| joint_no_tail_triggered_0820 | deaths | latest 28 | 717 (652-793) | 1.06 |  | 762 | 775 | 411 |  |
| joint_no_tail_triggered_0820 | deaths | latest 14 | 381 (337-436) | 1.03 |  | 385 | 393 | 146 |  |
| joint_no_tail_triggered_0905 | cases | all | 5551 (5479-5618) | 1.00 |  | 5391 | 5504 |  | 5079 |
| joint_no_tail_triggered_0905 | cases | latest 28 | 1724 (1652-1792) | 1.00 |  | 1608 | 1699 |  | 1252 |
| joint_no_tail_triggered_0905 | cases | latest 14 | 874 (812-939) | 1.00 |  | 748 | 830 |  | 430 |
| joint_no_tail_triggered_0905 | deaths | all | 2844 (2681-3078) | 1.68 |  | 2407 | 2502 |  | 2111 |
| joint_no_tail_triggered_0905 | deaths | latest 28 | 858 (766-953) | 1.33 |  | 720 | 794 |  | 499 |
| joint_no_tail_triggered_0905 | deaths | latest 14 | 441 (369-499) | 1.23 |  | 344 | 407 |  | 169 |
| joint_no_tail_triggered_0915 | cases | all | 6097 (6027-6171) | 1.00 |  | 5619 | 6044 |  |  |
| joint_no_tail_triggered_0915 | cases | latest 28 | 1677 (1607-1753) | 1.00 |  | 1199 | 1599 |  |  |
| joint_no_tail_triggered_0915 | cases | latest 14 | 860 (795-928) | 1.00 |  | 410 | 761 |  |  |
| joint_no_tail_triggered_0915 | deaths | all | 3078 (2967-3242) | 1.67 |  | 2482 | 2711 |  |  |
| joint_no_tail_triggered_0915 | deaths | latest 28 | 856 (799-916) | 1.12 |  | 523 | 726 |  |  |
| joint_no_tail_triggered_0915 | deaths | latest 14 | 439 (394-486) | 1.08 |  | 154 | 315 |  |  |
| joint_no_tail_triggered_1001 | cases | all | 6841 (6757-6911) | 1.01 |  |  | 6428 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 28 | 1455 (1373-1525) | 1.01 |  |  | 1043 |  |  |
| joint_no_tail_triggered_1001 | cases | latest 14 | 677 (608-740) | 1.01 |  |  | 305 |  |  |
| joint_no_tail_triggered_1001 | deaths | all | 3192 (3098-3266) | 1.12 |  |  | 2821 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 28 | 675 (570-734) | 1.16 |  |  | 379 |  |  |
| joint_no_tail_triggered_1001 | deaths | latest 14 | 322 (241-371) | 1.14 |  |  | 87 |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 09 Jul | 23 Jul | 06 Aug | 20 Aug | 25 Jul | 08 Aug | 22 Aug | 05 Sep | 04 Aug | 18 Aug | 01 Sep | 15 Sep | 03 Sep | 17 Sep | 01 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_triggered_0801 | 52.6 (34.7-103.4) | 21.8 (10.6-51.5) | 14.7 (9.4-33.1) | 15.5 (5.7-33.2) | 15.5 (5.7-33.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0820 | 54.8 (41.2-81.4) |  |  |  |  | 25.7 (15.1-47.4) | 26.3 (15.1-47.6) | 26.3 (15.2-47.7) | 26.3 (15.2-47.7) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0905 | 85.6 (59.8-145.3) |  |  |  |  |  |  |  |  | 27.4 (19.3-43.1) | 27.0 (19.1-42.8) | 11.9 (7.1-16.3) | 11.9 (7.1-16.2) |  |  |  |  |  |  |  |
| joint_no_tail_triggered_0915 | 58.0 (40.8-70.7) |  |  |  |  |  |  |  |  |  |  |  |  | 21.1 (16.0-33.4) | 10.1 (8.7-24.7) | 9.7 (8.5-11.4) | 9.7 (8.5-11.4) |  |  |  |
| joint_no_tail_triggered_1001 | 43.1 (28.5-59.3) |  |  |  |  |  |  |  | 9.3 (8.4-10.3) |  |  |  |  |  |  |  |  | 9.3 (8.4-10.3) | 13.3 (9.3-16.7) | 13.3 (9.3-16.7) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-13_15_07_joint_longer_continued/delays.png)

Batch 16t_backlog_hold_exact_series_log_likelihood. Commit 3881d45babda98d61de205a117c1b400dc263b74 of changepoints; model github::ben18785/incidenceinflation_2.0@logl-trace; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-19_31_16t_backlog_hold_exact_series_log_likelihood)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | 4 | 1550 | 1550 | 310 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | 4 | 1550 | 1550 | 284 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | 4 | 1550 | 1550 | 368 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | 4 | 1550 | 1550 | 357 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | 4 | 1550 | 1550 | 392 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | 4 | 1550 | 1550 | 599 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | 1.68 | 8 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | 3.20 | 5 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | 1.81 | 5 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | 1.82 | 5 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | 2.44 | 6 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | 1.50 | 3 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_02Sep | recorded_15Sep | recorded_14Oct | recorded_09Sep | recorded_16Sep | recorded_24Sep | recorded_30Sep |
|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | cases | all | 5348 (5271-5439) | 1.05 | 4895 | 5253 | 5469 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | cases | latest 28 | 1696 (1619-1787) | 1.05 | 1243 | 1642 | 1761 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | cases | latest 14 | 846 (771-930) | 1.05 | 427 | 792 | 888 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | deaths | all | 2265 (2207-2388) | 1.47 | 1972 | 2348 | 2518 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | deaths | latest 28 | 774 (718-896) | 1.47 | 495 | 740 | 843 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | deaths | latest 14 | 398 (353-517) | 1.51 | 173 | 370 | 448 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | cases | all | 5728 (5660-5797) | 1.04 |  | 5536 | 5899 | 5226 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | cases | latest 28 | 1666 (1598-1734) | 1.04 |  | 1468 | 1730 | 1187 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | cases | latest 14 | 826 (764-890) | 1.05 |  | 649 | 854 | 391 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | deaths | all | 2632 (2566-2712) | 1.19 |  | 2449 | 2706 | 2231 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | deaths | latest 28 | 798 (753-858) | 1.11 |  | 632 | 812 | 489 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | deaths | latest 14 | 403 (368-448) | 1.12 |  | 275 | 415 | 158 |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | cases | all | 6101 (6036-6168) | 1.10 |  |  | 6302 |  | 5654 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | cases | latest 28 | 1639 (1574-1706) | 1.10 |  |  | 1721 |  | 1193 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | cases | latest 14 | 811 (753-874) | 1.09 |  |  | 833 |  | 398 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | deaths | all | 2786 (2740-2837) | 1.18 |  |  | 2876 |  | 2491 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | deaths | latest 28 | 795 (755-839) | 1.13 |  |  | 806 |  | 513 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | deaths | latest 14 | 382 (348-420) | 1.11 |  |  | 358 |  | 144 |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | cases | all | 6500 (6440-6570) | 1.16 |  |  | 6669 |  |  | 6098 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | cases | latest 28 | 1536 (1476-1606) | 1.17 |  |  | 1565 |  |  | 1134 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | cases | latest 14 | 708 (655-771) | 1.13 |  |  | 677 |  |  | 339 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | deaths | all | 2985 (2938-3054) | 1.39 |  |  | 3010 |  |  | 2686 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | deaths | latest 28 | 745 (701-818) | 1.47 |  |  | 686 |  |  | 457 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | deaths | latest 14 | 321 (288-374) | 1.39 |  |  | 254 |  |  | 90 |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | cases | all | 6820 (6757-6888) | 1.03 |  |  | 6966 |  |  |  | 6377 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | cases | latest 28 | 1486 (1423-1553) | 1.04 |  |  | 1497 |  |  |  | 1044 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | cases | latest 14 | 700 (641-763) | 1.04 |  |  | 664 |  |  |  | 303 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | deaths | all | 3126 (3073-3174) | 1.07 |  |  | 3114 |  |  |  | 2795 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | deaths | latest 28 | 684 (635-728) | 1.09 |  |  | 596 |  |  |  | 372 |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | deaths | latest 14 | 321 (287-357) | 1.10 |  |  | 238 |  |  |  | 78 |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | cases | all | 7860 (7783-7971) | 1.16 |  |  | 7343 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | cases | latest 28 | 1554 (1479-1658) | 1.13 |  |  | 1041 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | cases | latest 14 | 823 (760-911) | 1.10 |  |  | 377 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | deaths | all | 3625 (3532-3729) | 1.38 |  |  | 3258 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | deaths | latest 28 | 712 (646-779) | 1.20 |  |  | 382 |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | deaths | latest 14 | 393 (348-439) | 1.14 |  |  | 144 |  |  |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 22 Jul | 05 Aug | 19 Aug | 02 Sep | 29 Jul | 12 Aug | 26 Aug | 09 Sep | 16 Sep | 13 Aug | 27 Aug | 10 Sep | 24 Sep | 30 Sep | 14 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_july_backlog_exact_0902 | 4.2 (3.6-5.2) | 4.2 (3.6-5.2) | 4.2 (3.6-5.2) | 4.2 (3.6-5.2) | 4.2 (3.6-5.2) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0909 | 3.8 (3.1-4.8) |  |  |  |  | 3.8 (3.1-4.8) | 3.8 (3.1-4.8) | 3.8 (3.1-4.8) | 3.8 (3.1-4.8) |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0916 | 3.9 (3.4-5.2) |  | 3.9 (3.4-5.2) | 3.8 (3.3-4.3) | 3.8 (3.3-4.3) |  |  |  |  | 3.8 (3.3-4.3) |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0924 | 5.4 (4.1-6.8) |  |  |  |  |  |  |  |  |  | 4.2 (3.8-4.7) | 4.2 (3.8-4.7) | 4.2 (3.8-4.7) | 4.2 (3.8-4.7) |  |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_0930 | 5.0 (3.7-6.1) |  |  | 3.8 (3.3-4.7) | 3.8 (3.3-4.7) |  |  |  |  | 6.0 (3.7-8.0) |  |  |  |  | 6.0 (3.7-8.0) |  |
| joint_no_tail_misdated_triggered_july_backlog_exact_1014 | 6.5 (5.0-7.6) |  |  |  | 4.7 (4.3-5.1) |  |  |  |  | 4.7 (4.4-5.2) |  |  |  |  | 4.7 (4.4-5.2) | 4.7 (4.4-5.2) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-19_31_16t_backlog_hold_exact_series_log_likelihood/delays.png)

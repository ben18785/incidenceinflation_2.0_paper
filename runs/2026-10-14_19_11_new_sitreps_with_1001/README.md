Batch 11_new_sitreps_with_1001. Commit a9b84d5dd63483c1366893ed946ac13e3f9bced7 of changepoints; model github::ben18785/incidenceinflation_2.0@misdated; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-14_19_11_new_sitreps_with_1001)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_early_0801 | 4 | 1500 | 1500 | 214 |
| joint_no_tail_misdated_triggered_early_0809 | 4 | 1500 | 1500 | 216 |
| joint_no_tail_misdated_triggered_early_0816 | 4 | 1500 | 1500 | 244 |
| joint_no_tail_misdated_triggered_early_0824 | 3 | 1450-1500 | 1500 | 311 |
| joint_no_tail_misdated_triggered_early_0902 | 4 | 1262-1500 | 1500 | 310 |
| joint_no_tail_misdated_triggered_early_0909 | 4 | 1397-1500 | 1500 | 292 |
| joint_no_tail_misdated_triggered_early_0916 | 4 | 1446-1500 | 1500 | 269 |
| joint_no_tail_misdated_triggered_early_0924 | 4 | 1184-1500 | 1500 | 295 |
| joint_no_tail_misdated_triggered_early_1001 | 4 | 1172-1500 | 1500 | 310 |
| joint_no_tail_misdated_triggered_early_1007 | 4 | 1041-1500 | 1500 | 320 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_early_0801 | 1.36 | 7 |
| joint_no_tail_misdated_triggered_early_0809 | 1.16 | 0 |
| joint_no_tail_misdated_triggered_early_0816 | 2.10 | 11 |
| joint_no_tail_misdated_triggered_early_0824 | 1.30 | 2 |
| joint_no_tail_misdated_triggered_early_0902 | 1.19 | 0 |
| joint_no_tail_misdated_triggered_early_0909 | 6.07 | 11 |
| joint_no_tail_misdated_triggered_early_0916 | 10.69 | 11 |
| joint_no_tail_misdated_triggered_early_0924 | 11.65 | 11 |
| joint_no_tail_misdated_triggered_early_1001 | 11.03 | 11 |
| joint_no_tail_misdated_triggered_early_1007 | 8.36 | 3 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Aug | recorded_15Sep | recorded_07Oct | recorded_09Aug | recorded_16Aug | recorded_24Aug | recorded_02Sep | recorded_09Sep | recorded_16Sep | recorded_24Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_early_0801 | cases | all | 3528 (3389-3667) | 1.04 | 2875 | 3388 | 3411 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0801 | cases | latest 28 | 1669 (1532-1803) | 1.04 | 1037 | 1511 | 1520 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0801 | cases | latest 14 | 929 (801-1049) | 1.03 | 403 | 831 | 837 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0801 | deaths | all | 1586 (1417-1729) | 1.33 | 956 | 1497 | 1533 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0801 | deaths | latest 28 | 857 (720-964) | 1.36 | 348 | 694 | 709 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0801 | deaths | latest 14 | 479 (387-554) | 1.27 | 126 | 391 | 400 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | cases | all | 4024 (3848-4221) | 1.12 |  | 3853 | 3877 | 3322 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | cases | latest 28 | 1779 (1608-1964) | 1.12 |  | 1607 | 1614 | 1099 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | cases | latest 14 | 970 (823-1128) | 1.11 |  | 832 | 837 | 383 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | deaths | all | 1608 (1491-1774) | 1.15 |  | 1716 | 1757 | 1129 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | deaths | latest 28 | 774 (688-904) | 1.13 |  | 744 | 761 | 380 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | deaths | latest 14 | 423 (357-521) | 1.11 |  | 384 | 394 | 126 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | cases | all | 4319 (4212-4493) | 1.19 |  | 4311 | 4346 |  | 3797 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | cases | latest 28 | 1667 (1566-1820) | 1.18 |  | 1699 | 1717 |  | 1156 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | cases | latest 14 | 826 (742-944) | 1.14 |  | 850 | 862 |  | 368 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | deaths | all | 1681 (1604-1851) | 1.70 |  | 1916 | 1971 |  | 1333 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | deaths | latest 28 | 686 (626-804) | 1.63 |  | 785 | 813 |  | 403 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | deaths | latest 14 | 335 (294-410) | 1.39 |  | 382 | 400 |  | 119 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | cases | all | 4832 (4746-4912) | 1.04 |  | 4757 | 4809 |  |  | 4331 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | cases | latest 28 | 1726 (1641-1804) | 1.04 |  | 1680 | 1713 |  |  | 1227 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | cases | latest 14 | 871 (792-941) | 1.02 |  | 818 | 846 |  |  | 418 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | deaths | all | 2064 (1969-2207) | 1.17 |  | 2114 | 2186 |  |  | 1614 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | deaths | latest 28 | 779 (717-892) | 1.16 |  | 759 | 798 |  |  | 441 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | deaths | latest 14 | 386 (345-457) | 1.10 |  | 353 | 382 |  |  | 136 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | cases | all | 5416 (5330-5545) | 1.07 |  | 5253 | 5364 |  |  |  | 4895 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | cases | latest 28 | 1757 (1671-1877) | 1.07 |  | 1642 | 1729 |  |  |  | 1243 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | cases | latest 14 | 886 (808-991) | 1.05 |  | 792 | 862 |  |  |  | 427 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | deaths | all | 2586 (2480-2721) | 1.17 |  | 2348 | 2474 |  |  |  | 1972 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | deaths | latest 28 | 943 (860-1036) | 1.10 |  | 740 | 826 |  |  |  | 495 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | deaths | latest 14 | 488 (432-565) | 1.07 |  | 370 | 436 |  |  |  | 173 |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | cases | all | 5739 (5654-5839) | 1.13 |  | 5536 | 5764 |  |  |  |  | 5226 |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | cases | latest 28 | 1694 (1611-1791) | 1.13 |  | 1468 | 1672 |  |  |  |  | 1187 |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | cases | latest 14 | 848 (773-931) | 1.09 |  | 649 | 811 |  |  |  |  | 391 |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | deaths | all | 2812 (2562-2965) | 2.03 |  | 2449 | 2649 |  |  |  |  | 2231 |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | deaths | latest 28 | 976 (772-1121) | 1.92 |  | 632 | 786 |  |  |  |  | 489 |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | deaths | latest 14 | 516 (387-629) | 1.69 |  | 275 | 397 |  |  |  |  | 158 |  |  |  |
| joint_no_tail_misdated_triggered_early_0916 | cases | all | 6164 (6071-6244) | 1.20 |  |  | 6143 |  |  |  |  |  | 5654 |  |  |
| joint_no_tail_misdated_triggered_early_0916 | cases | latest 28 | 1698 (1609-1776) | 1.19 |  |  | 1641 |  |  |  |  |  | 1193 |  |  |
| joint_no_tail_misdated_triggered_early_0916 | cases | latest 14 | 851 (776-920) | 1.08 |  |  | 779 |  |  |  |  |  | 398 |  |  |
| joint_no_tail_misdated_triggered_early_0916 | deaths | all | 3249 (2857-3414) | 2.83 |  |  | 2806 |  |  |  |  |  | 2491 |  |  |
| joint_no_tail_misdated_triggered_early_0916 | deaths | latest 28 | 1081 (798-1198) | 2.64 |  |  | 768 |  |  |  |  |  | 513 |  |  |
| joint_no_tail_misdated_triggered_early_0916 | deaths | latest 14 | 545 (379-633) | 2.10 |  |  | 332 |  |  |  |  |  | 144 |  |  |
| joint_no_tail_misdated_triggered_early_0924 | cases | all | 6530 (6453-6605) | 1.19 |  |  | 6462 |  |  |  |  |  |  | 6098 |  |
| joint_no_tail_misdated_triggered_early_0924 | cases | latest 28 | 1563 (1487-1636) | 1.19 |  |  | 1454 |  |  |  |  |  |  | 1134 |  |
| joint_no_tail_misdated_triggered_early_0924 | cases | latest 14 | 724 (655-794) | 1.16 |  |  | 606 |  |  |  |  |  |  | 339 |  |
| joint_no_tail_misdated_triggered_early_0924 | deaths | all | 3192 (3034-3408) | 3.13 |  |  | 2923 |  |  |  |  |  |  | 2686 |  |
| joint_no_tail_misdated_triggered_early_0924 | deaths | latest 28 | 847 (728-987) | 2.39 |  |  | 639 |  |  |  |  |  |  | 457 |  |
| joint_no_tail_misdated_triggered_early_0924 | deaths | latest 14 | 386 (305-454) | 1.56 |  |  | 226 |  |  |  |  |  |  | 90 |  |
| joint_no_tail_misdated_triggered_early_1001 | cases | all | 6883 (6818-6948) | 1.07 |  |  | 6714 |  |  |  |  |  |  |  | 6428 |
| joint_no_tail_misdated_triggered_early_1001 | cases | latest 28 | 1494 (1428-1557) | 1.07 |  |  | 1299 |  |  |  |  |  |  |  | 1043 |
| joint_no_tail_misdated_triggered_early_1001 | cases | latest 14 | 704 (646-766) | 1.05 |  |  | 523 |  |  |  |  |  |  |  | 305 |
| joint_no_tail_misdated_triggered_early_1001 | deaths | all | 3311 (3174-3510) | 2.71 |  |  | 3003 |  |  |  |  |  |  |  | 2821 |
| joint_no_tail_misdated_triggered_early_1001 | deaths | latest 28 | 759 (674-877) | 1.88 |  |  | 510 |  |  |  |  |  |  |  | 379 |
| joint_no_tail_misdated_triggered_early_1001 | deaths | latest 14 | 364 (315-426) | 1.35 |  |  | 183 |  |  |  |  |  |  |  | 87 |
| joint_no_tail_misdated_triggered_early_1007 | cases | all | 7231 (7169-7299) | 1.04 |  |  | 6782 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1007 | cases | latest 28 | 1457 (1398-1526) | 1.03 |  |  | 1018 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1007 | cases | latest 14 | 748 (691-812) | 1.02 |  |  | 363 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1007 | deaths | all | 3581 (3454-3689) | 1.51 |  |  | 3031 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1007 | deaths | latest 28 | 760 (692-844) | 1.29 |  |  | 382 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1007 | deaths | latest 14 | 388 (344-454) | 1.16 |  |  | 120 |  |  |  |  |  |  |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 28 Jun | 12 Jul | 26 Jul | 09 Aug | 05 Jul | 19 Jul | 02 Aug | 16 Aug | 13 Jul | 27 Jul | 10 Aug | 24 Aug | 22 Jul | 05 Aug | 19 Aug | 02 Sep | 29 Jul | 12 Aug | 26 Aug | 09 Sep | 16 Sep | 13 Aug | 27 Aug | 10 Sep | 24 Sep | 20 Aug | 03 Sep | 17 Sep | 01 Oct | 23 Sep | 07 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_early_0801 | 2.9 (2.3-3.5) | 2.9 (2.3-3.5) | 2.9 (2.3-3.5) | 2.9 (2.3-3.5) | 2.9 (2.3-3.5) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0809 | 2.8 (2.3-3.6) |  |  |  |  | 2.8 (2.3-3.6) | 2.8 (2.3-3.6) | 2.8 (2.3-3.6) | 2.8 (2.3-3.6) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0816 | 3.4 (2.6-4.4) |  |  |  |  |  |  |  |  | 3.4 (2.6-4.4) | 3.4 (2.6-4.4) | 3.4 (2.6-4.4) | 3.4 (2.6-4.4) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0824 | 2.9 (2.4-3.7) |  |  |  |  |  |  |  |  |  |  |  |  | 2.9 (2.4-3.7) | 2.9 (2.4-3.7) | 2.9 (2.4-3.8) | 2.9 (2.4-3.8) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0902 | 2.3 (2.0-2.8) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 2.3 (2.0-2.8) | 2.3 (1.9-2.8) | 2.4 (2.0-2.9) | 2.4 (2.0-2.9) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0909 | 2.8 (2.1-14.6) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 2.8 (2.1-8.2) | 2.8 (2.2-4.7) | 3.1 (2.4-4.7) | 3.1 (2.4-4.7) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0916 | 2.3 (2.0-20.9) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 2.3 (2.0-9.6) | 2.3 (2.0-4.2) | 2.4 (2.0-4.2) |  |  |  |  | 2.4 (2.0-4.2) |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_0924 | 9.6 (2.2-22.5) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 3.2 (2.2-4.6) | 3.3 (2.2-4.6) | 3.4 (2.3-4.6) | 3.4 (2.3-12.6) |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_early_1001 | 9.8 (2.2-23.0) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 3.1 (2.2-5.1) | 3.1 (2.2-5.1) | 5.8 (2.6-10.5) | 5.8 (2.7-10.5) |  |  |
| joint_no_tail_misdated_triggered_early_1007 | 2.9 (2.3-16.9) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 2.9 (2.4-3.7) | 2.9 (2.4-3.7) |  |  |  |  |  |  |  |  |  | 3.1 (2.5-4.2) | 3.1 (2.5-4.2) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-14_19_11_new_sitreps_with_1001/delays.png)

Batch 19_triggered_fixed_series. Commit 390ca5e2fef791f807bc0dded2c8e7892eaf5398 of changepoints; model github::ben18785/incidenceinflation_2.0@sampler-speed; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-22_47_19_triggered_fixed_series)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 4 | 3000 | 3000 | 262 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 4 | 3000 | 3000 | 289 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 4 | 2104-2203 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 3 | 1986-3000 | 3000 | 310 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 4 | 1837-2987 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 4 | 1620-2812 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 4 | 1459-2539 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 4 | 1397-2391 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 4 | 1370-2323 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 4 | 1190-1620 | 3000 | 320 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 4 | 927-1540 | 3000 | 320 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 2.27 | 9 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 1.55 | 4 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 2.08 | 7 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 1.32 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 1.26 | 3 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 1.35 | 6 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 1.63 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 2.12 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 2.98 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 2.76 | 8 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 2.49 | 9 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Aug | recorded_15Sep | recorded_14Oct | recorded_09Aug | recorded_19Aug | recorded_26Aug | recorded_02Sep | recorded_09Sep | recorded_16Sep | recorded_24Sep | recorded_30Sep | recorded_07Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | cases | all | 3398 (3289-3507) | 1.03 | 2875 | 3388 | 3479 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | cases | latest 28 | 1556 (1448-1663) | 1.03 | 1037 | 1511 | 1553 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | cases | latest 14 | 858 (755-951) | 1.04 | 403 | 831 | 855 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | deaths | all | 1207 (1152-1321) | 1.43 | 956 | 1497 | 1559 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | deaths | latest 28 | 590 (537-690) | 1.41 | 348 | 694 | 717 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | deaths | latest 14 | 324 (282-387) | 1.28 | 126 | 391 | 401 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | cases | all | 3857 (3743-4030) | 1.09 |  | 3853 | 3953 | 3322 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | cases | latest 28 | 1628 (1515-1798) | 1.09 |  | 1607 | 1645 | 1099 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | cases | latest 14 | 852 (753-999) | 1.09 |  | 832 | 853 | 383 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | deaths | all | 1356 (1302-1439) | 1.18 |  | 1716 | 1786 | 1129 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | deaths | latest 28 | 597 (550-659) | 1.13 |  | 744 | 765 | 380 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | deaths | latest 14 | 312 (272-358) | 1.07 |  | 384 | 398 | 126 |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | all | 4569 (4487-4674) | 1.06 |  | 4461 | 4581 |  | 4043 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | latest 28 | 1721 (1641-1823) | 1.07 |  | 1636 | 1686 |  | 1195 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | latest 14 | 947 (877-1035) | 1.09 |  | 850 | 873 |  | 458 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | all | 1741 (1698-1793) | 1.15 |  | 1978 | 2070 |  | 1462 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | latest 28 | 687 (647-738) | 1.17 |  | 746 | 784 |  | 414 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | latest 14 | 375 (341-417) | 1.18 |  | 370 | 395 |  | 147 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | all | 4910 (4844-4988) | 1.09 |  | 4887 | 5045 |  |  | 4461 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | latest 28 | 1684 (1618-1762) | 1.08 |  | 1689 | 1765 |  |  | 1235 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | latest 14 | 833 (769-901) | 1.07 |  | 819 | 876 |  |  | 409 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | all | 1974 (1933-2023) | 1.15 |  | 2174 | 2291 |  |  | 1712 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | latest 28 | 720 (681-769) | 1.16 |  | 764 | 822 |  |  | 466 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | latest 14 | 348 (316-389) | 1.13 |  | 357 | 397 |  |  | 142 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | all | 5362 (5259-5453) | 1.07 |  | 5253 | 5469 |  |  |  | 4895 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | latest 28 | 1710 (1608-1802) | 1.07 |  | 1642 | 1761 |  |  |  | 1243 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | latest 14 | 862 (769-949) | 1.07 |  | 792 | 888 |  |  |  | 427 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | all | 2244 (2192-2325) | 1.14 |  | 2348 | 2518 |  |  |  | 1972 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | latest 28 | 758 (707-842) | 1.15 |  | 740 | 843 |  |  |  | 495 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | latest 14 | 391 (350-465) | 1.14 |  | 370 | 448 |  |  |  | 173 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | all | 5713 (5644-5793) | 1.07 |  | 5536 | 5899 |  |  |  |  | 5226 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | latest 28 | 1651 (1584-1731) | 1.06 |  | 1468 | 1730 |  |  |  |  | 1187 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | latest 14 | 814 (749-888) | 1.05 |  | 649 | 854 |  |  |  |  | 391 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | all | 2624 (2556-2732) | 1.23 |  | 2449 | 2706 |  |  |  |  | 2231 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | latest 28 | 794 (747-889) | 1.15 |  | 632 | 812 |  |  |  |  | 489 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | latest 14 | 397 (361-477) | 1.16 |  | 275 | 415 |  |  |  |  | 158 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | all | 6098 (6043-6160) | 1.04 |  |  | 6302 |  |  |  |  |  | 5654 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | latest 28 | 1637 (1581-1699) | 1.04 |  |  | 1721 |  |  |  |  |  | 1193 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | latest 14 | 811 (760-867) | 1.03 |  |  | 833 |  |  |  |  |  | 398 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | all | 2780 (2740-2825) | 1.08 |  |  | 2876 |  |  |  |  |  | 2491 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | latest 28 | 791 (754-835) | 1.08 |  |  | 806 |  |  |  |  |  | 513 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | latest 14 | 379 (346-415) | 1.04 |  |  | 358 |  |  |  |  |  | 144 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | all | 6494 (6435-6567) | 1.09 |  |  | 6669 |  |  |  |  |  |  | 6098 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | latest 28 | 1530 (1471-1604) | 1.09 |  |  | 1565 |  |  |  |  |  |  | 1134 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | latest 14 | 703 (649-772) | 1.10 |  |  | 677 |  |  |  |  |  |  | 339 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | all | 2986 (2936-3045) | 1.16 |  |  | 3010 |  |  |  |  |  |  | 2686 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | latest 28 | 745 (699-795) | 1.15 |  |  | 686 |  |  |  |  |  |  | 457 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | latest 14 | 319 (284-363) | 1.19 |  |  | 254 |  |  |  |  |  |  | 90 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | all | 6839 (6775-6908) | 1.07 |  |  | 6966 |  |  |  |  |  |  |  | 6377 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | latest 28 | 1504 (1441-1574) | 1.07 |  |  | 1497 |  |  |  |  |  |  |  | 1044 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | latest 14 | 715 (659-781) | 1.05 |  |  | 664 |  |  |  |  |  |  |  | 303 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | all | 3147 (3098-3202) | 1.17 |  |  | 3114 |  |  |  |  |  |  |  | 2795 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | latest 28 | 704 (662-751) | 1.14 |  |  | 596 |  |  |  |  |  |  |  | 372 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | latest 14 | 334 (303-377) | 1.09 |  |  | 238 |  |  |  |  |  |  |  | 78 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | all | 7219 (7157-7286) | 1.04 |  |  | 7241 |  |  |  |  |  |  |  |  | 6782 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | latest 28 | 1453 (1392-1517) | 1.03 |  |  | 1342 |  |  |  |  |  |  |  |  | 1018 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | latest 14 | 752 (698-814) | 1.02 |  |  | 621 |  |  |  |  |  |  |  |  | 363 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | all | 3357 (3302-3439) | 1.38 |  |  | 3225 |  |  |  |  |  |  |  |  | 3031 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | latest 28 | 686 (642-774) | 1.41 |  |  | 519 |  |  |  |  |  |  |  |  | 382 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | latest 14 | 358 (325-446) | 1.54 |  |  | 230 |  |  |  |  |  |  |  |  | 120 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | all | 7847 (7771-7935) | 1.26 |  |  | 7343 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | latest 28 | 1539 (1467-1621) | 1.19 |  |  | 1041 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | latest 14 | 807 (749-874) | 1.12 |  |  | 377 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | all | 3635 (3542-3729) | 1.75 |  |  | 3258 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | latest 28 | 709 (653-768) | 1.41 |  |  | 382 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | latest 14 | 385 (349-425) | 1.24 |  |  | 144 |  |  |  |  |  |  |  |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 28 Jun | 12 Jul | 26 Jul | 09 Aug | 08 Jul | 22 Jul | 05 Aug | 19 Aug | 15 Jul | 29 Jul | 12 Aug | 26 Aug | 02 Sep | 09 Sep | 16 Sep | 13 Aug | 27 Aug | 10 Sep | 24 Sep | 30 Sep | 23 Sep | 07 Oct | 14 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 4.3 (3.3-5.6) |  |  |  |  | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 6.0 (4.6-7.1) |  |  |  |  |  |  |  |  | 6.0 (4.6-7.1) | 6.0 (4.6-7.1) | 5.9 (4.6-7.1) | 5.9 (4.6-7.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 5.2 (4.4-6.0) |  |  |  |  |  |  |  |  |  |  |  |  | 5.2 (4.4-6.0) | 5.2 (4.4-6.0) | 5.2 (4.3-6.0) | 5.2 (4.3-6.0) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 4.9 (4.3-6.0) |  |  |  |  |  |  |  |  |  | 4.9 (4.3-6.0) | 4.9 (4.3-6.0) | 4.7 (3.8-5.4) |  |  |  |  | 4.7 (3.8-5.4) |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 4.0 (3.4-4.7) |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.0 (3.4-4.7) | 4.0 (3.4-4.7) | 4.0 (3.4-4.7) |  | 4.0 (3.4-4.7) |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 4.0 (3.4-5.0) |  |  |  |  |  |  |  |  |  |  | 4.0 (3.4-5.0) | 3.9 (3.4-4.5) |  |  |  |  | 3.9 (3.4-4.5) |  | 3.9 (3.4-4.5) |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 4.6 (3.7-6.0) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.2 (3.5-5.0) | 4.2 (3.5-5.0) | 4.2 (3.5-5.1) | 4.2 (3.5-5.1) |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 4.9 (3.8-6.0) |  |  |  |  |  |  |  |  |  |  |  | 3.8 (3.2-4.5) |  |  |  |  | 3.8 (3.2-4.5) |  | 7.2 (4.8-9.1) |  |  |  |  | 7.2 (4.9-9.1) |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 4.9 (3.9-6.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.1 (3.6-4.8) |  | 4.2 (3.6-4.8) |  |  |  |  |  |  | 4.4 (3.7-5.9) | 4.4 (3.7-5.9) |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 6.0 (5.0-7.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.5 (4.0-5.1) |  | 4.5 (4.0-5.1) |  |  |  |  | 4.5 (4.0-5.2) |  |  | 4.5 (4.0-5.2) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-22_47_19_triggered_fixed_series/delays.png)

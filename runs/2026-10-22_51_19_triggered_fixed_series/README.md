Batch 19_triggered_fixed_series. Commit ba26974de285dfd4a98eff22371a5ffbefe1d6da of changepoints; model github::ben18785/incidenceinflation_2.0@sampler-speed; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-22_51_19_triggered_fixed_series)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 4 | 3000 | 3000 | 262 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 4 | 3000 | 3000 | 289 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 4 | 3000 | 3000 | 416 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 4 | 3000 | 3000 | 397 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 4 | 3000 | 3000 | 414 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 3 | 3000 | 3000 | 558 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 3 | 3000 | 3000 | 589 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 4 | 3000 | 3000 | 483 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 4 | 3000 | 3000 | 550 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 4 | 2379-3000 | 3000 | 670 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 4 | 3000 | 3000 | 868 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 2.27 | 9 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 1.55 | 4 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 2.48 | 6 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 1.19 | 0 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 1.58 | 3 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 2.73 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 2.01 | 5 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 1.93 | 6 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 1.39 | 6 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 3.40 | 10 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 1.44 | 3 |

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
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | all | 4577 (4489-4677) | 1.03 |  | 4461 | 4581 |  | 4043 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | latest 28 | 1729 (1642-1829) | 1.03 |  | 1636 | 1686 |  | 1195 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | cases | latest 14 | 955 (878-1043) | 1.04 |  | 850 | 873 |  | 458 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | all | 1744 (1704-1796) | 1.09 |  | 1978 | 2070 |  | 1462 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | latest 28 | 690 (652-740) | 1.09 |  | 746 | 784 |  | 414 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | deaths | latest 14 | 378 (346-419) | 1.10 |  | 370 | 395 |  | 147 |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | all | 4911 (4842-4987) | 1.06 |  | 4887 | 5045 |  |  | 4461 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | latest 28 | 1686 (1617-1762) | 1.06 |  | 1689 | 1765 |  |  | 1235 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | cases | latest 14 | 834 (770-901) | 1.06 |  | 819 | 876 |  |  | 409 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | all | 1974 (1933-2027) | 1.08 |  | 2174 | 2291 |  |  | 1712 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | latest 28 | 720 (682-773) | 1.09 |  | 764 | 822 |  |  | 466 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | deaths | latest 14 | 348 (319-389) | 1.09 |  | 357 | 397 |  |  | 142 |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | all | 5356 (5251-5445) | 1.01 |  | 5253 | 5469 |  |  |  | 4895 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | latest 28 | 1704 (1601-1795) | 1.01 |  | 1642 | 1761 |  |  |  | 1243 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | cases | latest 14 | 856 (753-936) | 1.01 |  | 792 | 888 |  |  |  | 427 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | all | 2253 (2194-2402) | 1.53 |  | 2348 | 2518 |  |  |  | 1972 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | latest 28 | 767 (710-916) | 1.52 |  | 740 | 843 |  |  |  | 495 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | deaths | latest 14 | 398 (346-517) | 1.47 |  | 370 | 448 |  |  |  | 173 |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | all | 5717 (5652-5798) | 1.03 |  | 5536 | 5899 |  |  |  |  | 5226 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | latest 28 | 1660 (1594-1741) | 1.03 |  | 1468 | 1730 |  |  |  |  | 1187 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | cases | latest 14 | 825 (763-898) | 1.02 |  | 649 | 854 |  |  |  |  | 391 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | all | 2603 (2550-2674) | 1.11 |  | 2449 | 2706 |  |  |  |  | 2231 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | latest 28 | 794 (750-851) | 1.08 |  | 632 | 812 |  |  |  |  | 489 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | deaths | latest 14 | 402 (364-446) | 1.07 |  | 275 | 415 |  |  |  |  | 158 |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | all | 6091 (6037-6158) | 1.02 |  |  | 6302 |  |  |  |  |  | 5654 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | latest 28 | 1629 (1575-1697) | 1.02 |  |  | 1721 |  |  |  |  |  | 1193 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | cases | latest 14 | 803 (752-868) | 1.02 |  |  | 833 |  |  |  |  |  | 398 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | all | 2780 (2744-2821) | 1.05 |  |  | 2876 |  |  |  |  |  | 2491 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | latest 28 | 790 (755-828) | 1.07 |  |  | 806 |  |  |  |  |  | 513 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | deaths | latest 14 | 377 (346-411) | 1.06 |  |  | 358 |  |  |  |  |  | 144 |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | all | 6508 (6441-6579) | 1.10 |  |  | 6669 |  |  |  |  |  |  | 6098 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | latest 28 | 1544 (1478-1614) | 1.10 |  |  | 1565 |  |  |  |  |  |  | 1134 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | cases | latest 14 | 715 (652-779) | 1.11 |  |  | 677 |  |  |  |  |  |  | 339 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | all | 2991 (2944-3049) | 1.15 |  |  | 3010 |  |  |  |  |  |  | 2686 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | latest 28 | 753 (706-809) | 1.16 |  |  | 686 |  |  |  |  |  |  | 457 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | deaths | latest 14 | 325 (287-374) | 1.22 |  |  | 254 |  |  |  |  |  |  | 90 |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | all | 6834 (6771-6898) | 1.01 |  |  | 6966 |  |  |  |  |  |  |  | 6377 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | latest 28 | 1498 (1437-1563) | 1.02 |  |  | 1497 |  |  |  |  |  |  |  | 1044 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | cases | latest 14 | 714 (654-773) | 1.02 |  |  | 664 |  |  |  |  |  |  |  | 303 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | all | 3142 (3094-3191) | 1.02 |  |  | 3114 |  |  |  |  |  |  |  | 2795 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | latest 28 | 699 (656-742) | 1.05 |  |  | 596 |  |  |  |  |  |  |  | 372 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | deaths | latest 14 | 334 (298-370) | 1.04 |  |  | 238 |  |  |  |  |  |  |  | 78 |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | all | 7226 (7146-7401) | 1.55 |  |  | 7241 |  |  |  |  |  |  |  |  | 6782 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | latest 28 | 1459 (1381-1635) | 1.56 |  |  | 1342 |  |  |  |  |  |  |  |  | 1018 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | cases | latest 14 | 756 (691-917) | 1.53 |  |  | 621 |  |  |  |  |  |  |  |  | 363 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | all | 3366 (3307-3907) | 2.53 |  |  | 3225 |  |  |  |  |  |  |  |  | 3031 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | latest 28 | 695 (642-1236) | 2.67 |  |  | 519 |  |  |  |  |  |  |  |  | 382 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | deaths | latest 14 | 363 (325-823) | 2.70 |  |  | 230 |  |  |  |  |  |  |  |  | 120 |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | all | 7860 (7780-7953) | 1.05 |  |  | 7343 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | latest 28 | 1554 (1477-1642) | 1.04 |  |  | 1041 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | cases | latest 14 | 819 (754-893) | 1.02 |  |  | 377 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | all | 3638 (3580-3725) | 1.28 |  |  | 3258 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | latest 28 | 719 (674-780) | 1.15 |  |  | 382 |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | deaths | latest 14 | 392 (359-433) | 1.03 |  |  | 144 |  |  |  |  |  |  |  |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Jun | 04 Jul | 18 Jul | 01 Aug | 28 Jun | 12 Jul | 26 Jul | 09 Aug | 08 Jul | 22 Jul | 05 Aug | 19 Aug | 15 Jul | 29 Jul | 12 Aug | 26 Aug | 02 Sep | 09 Sep | 16 Sep | 13 Aug | 27 Aug | 10 Sep | 24 Sep | 30 Sep | 23 Sep | 07 Oct | 14 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0801 | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) | 3.7 (2.8-5.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0809 | 4.3 (3.3-5.6) |  |  |  |  | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) | 4.3 (3.3-5.6) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0819 | 6.2 (4.8-7.4) |  |  |  |  |  |  |  |  | 6.2 (4.8-7.4) | 6.2 (4.8-7.4) | 6.2 (4.7-7.4) | 6.2 (4.7-7.4) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0826 | 5.2 (4.5-6.0) |  |  |  |  |  |  |  |  |  |  |  |  | 5.2 (4.5-6.0) | 5.2 (4.5-6.0) | 5.2 (4.5-6.0) | 5.2 (4.5-6.0) |  |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0902 | 4.9 (4.3-5.6) |  |  |  |  |  |  |  |  |  | 4.9 (4.3-5.6) | 4.9 (4.3-5.6) | 4.8 (3.9-5.4) |  |  |  |  | 4.8 (3.9-5.4) |  |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0909 | 4.5 (3.5-5.4) |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.5 (3.5-5.4) | 4.4 (3.5-5.3) | 4.4 (3.5-5.3) |  | 4.4 (3.5-5.3) |  |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0916 | 4.2 (3.3-5.9) |  |  |  |  |  |  |  |  |  |  | 4.2 (3.3-5.9) | 4.1 (3.3-4.7) |  |  |  |  | 4.1 (3.3-4.7) |  | 4.1 (3.3-4.7) |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0924 | 4.7 (3.9-6.1) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.3 (3.7-5.1) | 4.3 (3.7-5.1) | 4.3 (3.7-5.1) | 4.3 (3.7-5.2) |  |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_0930 | 5.4 (4.0-6.5) |  |  |  |  |  |  |  |  |  |  |  | 3.9 (3.5-4.4) |  |  |  |  | 3.9 (3.5-4.4) |  | 7.7 (5.8-10.2) |  |  |  |  | 7.7 (5.8-10.2) |  |  |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1007 | 4.8 (4.0-5.8) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.3 (3.8-5.0) |  | 4.3 (3.8-5.0) |  |  |  |  |  |  | 4.8 (3.9-6.5) | 4.8 (3.9-6.5) |  |
| joint_no_tail_misdated_triggered_fixed_july_backlog_exact_1014 | 6.2 (5.3-7.2) |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 4.7 (4.3-5.2) |  | 4.8 (4.3-5.7) |  |  |  |  | 4.8 (4.3-5.9) |  |  | 4.8 (4.3-5.9) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-22_51_19_triggered_fixed_series/delays.png)

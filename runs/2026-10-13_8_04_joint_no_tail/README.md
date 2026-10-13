Batch 04_joint_no_tail. Commit 7d8cbc33e57d0f21152136237ad3a8ca302449fb of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-13_8_04_joint_no_tail)

# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| joint_1001 | 4 | 800 | 149 |
| joint_no_tail_0905 | 4 | 800 | 125 |
| joint_no_tail_0915 | 4 | 800 | 75 |
| joint_no_tail_1001 | 4 | 800 | 104 |
| joint_no_tail_drift_0905 | 4 | 800 | 105 |
| joint_no_tail_drift_0915 | 4 | 800 | 80 |
| joint_no_tail_drift_1001 | 4 | 800 | 76 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_1001 | 1.43 | 5 |
| joint_no_tail_0905 | 1.98 | 7 |
| joint_no_tail_0915 | 3.00 | 9 |
| joint_no_tail_1001 | 1.90 | 7 |
| joint_no_tail_drift_0905 | 1.47 | 4 |
| joint_no_tail_drift_0915 | 2.65 | 7 |
| joint_no_tail_drift_1001 | 2.11 | 5 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_01Oct | recorded_05Sep | recorded_15Sep |
|---|---|---|---|---|---|---|---|
| joint_1001 | cases | all | 7323 (7156-7510) | 1.20 | 6428 |  |  |
| joint_1001 | cases | latest 28 | 1574 (1495-1657) | 1.03 | 1043 |  |  |
| joint_1001 | cases | latest 14 | 716 (647-786) | 1.01 | 305 |  |  |
| joint_1001 | deaths | all | 3758 (3613-3955) | 1.36 | 2821 |  |  |
| joint_1001 | deaths | latest 28 | 810 (724-884) | 1.20 | 379 |  |  |
| joint_1001 | deaths | latest 14 | 367 (304-418) | 1.13 | 87 |  |  |
| joint_no_tail_0905 | cases | all | 5556 (5492-5622) | 1.01 | 5504 | 5079 | 5391 |
| joint_no_tail_0905 | cases | latest 28 | 1730 (1665-1795) | 1.01 | 1699 | 1252 | 1608 |
| joint_no_tail_0905 | cases | latest 14 | 878 (820-941) | 1.00 | 830 | 430 | 748 |
| joint_no_tail_0905 | deaths | all | 3130 (2937-3351) | 1.70 | 2502 | 2111 | 2407 |
| joint_no_tail_0905 | deaths | latest 28 | 1007 (918-1112) | 1.35 | 794 | 499 | 720 |
| joint_no_tail_0905 | deaths | latest 14 | 521 (463-585) | 1.21 | 407 | 169 | 344 |
| joint_no_tail_0915 | cases | all | 6101 (6030-6184) | 1.01 | 6044 |  | 5619 |
| joint_no_tail_0915 | cases | latest 28 | 1681 (1610-1764) | 1.01 | 1599 |  | 1199 |
| joint_no_tail_0915 | cases | latest 14 | 861 (797-936) | 1.01 | 761 |  | 410 |
| joint_no_tail_0915 | deaths | all | 3596 (3406-4135) | 3.00 | 2711 |  | 2482 |
| joint_no_tail_0915 | deaths | latest 28 | 1048 (954-1282) | 2.06 | 726 |  | 523 |
| joint_no_tail_0915 | deaths | latest 14 | 534 (464-673) | 1.65 | 315 |  | 154 |
| joint_no_tail_1001 | cases | all | 6808 (6743-6871) | 1.04 | 6428 |  |  |
| joint_no_tail_1001 | cases | latest 28 | 1423 (1359-1485) | 1.04 | 1043 |  |  |
| joint_no_tail_1001 | cases | latest 14 | 651 (594-708) | 1.03 | 305 |  |  |
| joint_no_tail_1001 | deaths | all | 3550 (3405-3750) | 1.90 | 2821 |  |  |
| joint_no_tail_1001 | deaths | latest 28 | 753 (678-831) | 1.37 | 379 |  |  |
| joint_no_tail_1001 | deaths | latest 14 | 342 (284-397) | 1.28 | 87 |  |  |
| joint_no_tail_drift_0905 | cases | all | 5552 (5481-5616) | 1.02 | 5504 | 5079 | 5391 |
| joint_no_tail_drift_0905 | cases | latest 28 | 1725 (1654-1791) | 1.02 | 1699 | 1252 | 1608 |
| joint_no_tail_drift_0905 | cases | latest 14 | 875 (812-934) | 1.01 | 830 | 430 | 748 |
| joint_no_tail_drift_0905 | deaths | all | 3048 (2889-3215) | 1.46 | 2502 | 2111 | 2407 |
| joint_no_tail_drift_0905 | deaths | latest 28 | 972 (895-1060) | 1.19 | 794 | 499 | 720 |
| joint_no_tail_drift_0905 | deaths | latest 14 | 495 (443-553) | 1.09 | 407 | 169 | 344 |
| joint_no_tail_drift_0915 | cases | all | 6101 (6031-6175) | 1.02 | 6044 |  | 5619 |
| joint_no_tail_drift_0915 | cases | latest 28 | 1681 (1611-1756) | 1.02 | 1599 |  | 1199 |
| joint_no_tail_drift_0915 | cases | latest 14 | 861 (798-931) | 1.02 | 761 |  | 410 |
| joint_no_tail_drift_0915 | deaths | all | 3534 (3314-3851) | 2.29 | 2711 |  | 2482 |
| joint_no_tail_drift_0915 | deaths | latest 28 | 1018 (927-1117) | 1.40 | 726 |  | 523 |
| joint_no_tail_drift_0915 | deaths | latest 14 | 511 (450-578) | 1.19 | 315 |  | 154 |
| joint_no_tail_drift_1001 | cases | all | 6810 (6745-6873) | 1.02 | 6428 |  |  |
| joint_no_tail_drift_1001 | cases | latest 28 | 1424 (1360-1489) | 1.02 | 1043 |  |  |
| joint_no_tail_drift_1001 | cases | latest 14 | 653 (593-713) | 1.02 | 305 |  |  |
| joint_no_tail_drift_1001 | deaths | all | 3592 (3426-3782) | 1.56 | 2821 |  |  |
| joint_no_tail_drift_1001 | deaths | latest 28 | 771 (703-835) | 1.16 | 379 |  |  |
| joint_no_tail_drift_1001 | deaths | latest 14 | 353 (306-397) | 1.05 | 87 |  |  |

## Mean delay by onset day (days)

| experiment | 11 May | 20 Aug | 03 Sep | 17 Sep | 01 Oct | 25 Jul | 08 Aug | 22 Aug | 05 Sep | 04 Aug | 18 Aug | 01 Sep | 15 Sep |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_1001 | 42.0 (33.5-57.3) | 19.1 (13.7-27.9) | 19.0 (13.7-27.7) | 20.8 (14.4-33.0) | 20.8 (14.4-33.0) |  |  |  |  |  |  |  |  |
| joint_no_tail_0905 | 76.5 (66.0-103.6) |  |  |  |  | 47.4 (35.7-74.5) | 46.0 (32.7-74.5) | 45.9 (32.2-74.5) | 45.8 (32.2-74.5) |  |  |  |  |
| joint_no_tail_0915 | 69.1 (60.2-80.8) |  |  |  |  |  |  |  |  | 47.3 (24.6-95.2) | 38.1 (24.3-95.2) | 36.8 (24.3-95.2) | 36.8 (24.3-95.2) |
| joint_no_tail_1001 | 43.2 (36.3-61.9) | 21.7 (12.9-37.8) | 22.0 (13.0-37.8) | 31.7 (17.2-48.6) | 31.8 (17.2-48.6) |  |  |  |  |  |  |  |  |
| joint_no_tail_drift_0905 | 62.6 (49.0-79.4) |  |  |  |  | 49.3 (37.0-59.1) | 47.8 (32.2-58.5) | 47.2 (32.9-60.3) | 45.0 (28.0-57.7) |  |  |  |  |
| joint_no_tail_drift_0915 | 56.0 (42.2-75.7) |  |  |  |  |  |  |  |  | 43.6 (28.3-64.3) | 43.5 (23.2-60.2) | 43.3 (20.5-56.3) | 42.4 (20.0-57.5) |
| joint_no_tail_drift_1001 | 46.1 (32.9-60.7) | 29.5 (19.3-39.6) | 27.6 (17.1-40.2) | 33.2 (20.9-46.6) | 31.6 (17.6-47.6) |  |  |  |  |  |  |  |  |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-13_8_04_joint_no_tail/delays.png)

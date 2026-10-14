Batch 08_counted_on_day_of_death. Commit 132515b7293b8d8c9ae06a20990ba7d53347c48d of changepoints; model github::ben18785/incidenceinflation_2.0@misdated; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-14_14_08_counted_on_day_of_death)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| joint_no_tail_misdated_0905 | 4 | 1362-1500 | 1500 | 250 |
| joint_no_tail_misdated_0915 | 4 | 1493-1500 | 1500 | 275 |
| joint_no_tail_misdated_1001 | 4 | 1364-1500 | 1500 | 286 |
| joint_no_tail_misdated_triggered_0905 | 4 | 1269-1500 | 1500 | 286 |
| joint_no_tail_misdated_triggered_0915 | 4 | 1500 | 1500 | 261 |
| joint_no_tail_misdated_triggered_1001 | 4 | 1199-1500 | 1500 | 292 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| joint_no_tail_misdated_0905 | 4.21 | 4 |
| joint_no_tail_misdated_0915 | 1.15 | 0 |
| joint_no_tail_misdated_1001 | 1.80 | 6 |
| joint_no_tail_misdated_triggered_0905 | 8.25 | 7 |
| joint_no_tail_misdated_triggered_0915 | 2.91 | 11 |
| joint_no_tail_misdated_triggered_1001 | 2.48 | 8 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_0905 | cases | all | 5576 (5513-5641) | 1.02 | 5079 | 5391 | 5504 |
| joint_no_tail_misdated_0905 | cases | latest 28 | 1747 (1683-1810) | 1.02 | 1252 | 1608 | 1699 |
| joint_no_tail_misdated_0905 | cases | latest 14 | 883 (821-940) | 1.02 | 430 | 748 | 830 |
| joint_no_tail_misdated_0905 | deaths | all | 2714 (2608-2827) | 1.03 | 2111 | 2407 | 2502 |
| joint_no_tail_misdated_0905 | deaths | latest 28 | 990 (882-1088) | 1.13 | 499 | 720 | 794 |
| joint_no_tail_misdated_0905 | deaths | latest 14 | 554 (454-649) | 1.16 | 169 | 344 | 407 |
| joint_no_tail_misdated_0915 | cases | all | 6193 (6121-6272) | 1.02 |  | 5619 | 6044 |
| joint_no_tail_misdated_0915 | cases | latest 28 | 1771 (1699-1849) | 1.02 |  | 1199 | 1599 |
| joint_no_tail_misdated_0915 | cases | latest 14 | 916 (853-988) | 1.02 |  | 410 | 761 |
| joint_no_tail_misdated_0915 | deaths | all | 3248 (3135-3383) | 1.06 |  | 2482 | 2711 |
| joint_no_tail_misdated_0915 | deaths | latest 28 | 1155 (1054-1269) | 1.08 |  | 523 | 726 |
| joint_no_tail_misdated_0915 | deaths | latest 14 | 622 (538-716) | 1.11 |  | 154 | 315 |
| joint_no_tail_misdated_1001 | cases | all | 6892 (6830-6968) | 1.02 |  |  | 6428 |
| joint_no_tail_misdated_1001 | cases | latest 28 | 1503 (1441-1578) | 1.02 |  |  | 1043 |
| joint_no_tail_misdated_1001 | cases | latest 14 | 714 (659-779) | 1.02 |  |  | 305 |
| joint_no_tail_misdated_1001 | deaths | all | 3212 (3150-3287) | 1.29 |  |  | 2821 |
| joint_no_tail_misdated_1001 | deaths | latest 28 | 728 (676-779) | 1.11 |  |  | 379 |
| joint_no_tail_misdated_1001 | deaths | latest 14 | 350 (314-387) | 1.03 |  |  | 87 |
| joint_no_tail_misdated_triggered_0905 | cases | all | 5586 (5516-5655) | 1.03 | 5079 | 5391 | 5504 |
| joint_no_tail_misdated_triggered_0905 | cases | latest 28 | 1754 (1686-1821) | 1.03 | 1252 | 1608 | 1699 |
| joint_no_tail_misdated_triggered_0905 | cases | latest 14 | 889 (824-952) | 1.02 | 430 | 748 | 830 |
| joint_no_tail_misdated_triggered_0905 | deaths | all | 2802 (2678-2962) | 1.24 | 2111 | 2407 | 2502 |
| joint_no_tail_misdated_triggered_0905 | deaths | latest 28 | 1014 (902-1151) | 1.29 | 499 | 720 | 794 |
| joint_no_tail_misdated_triggered_0905 | deaths | latest 14 | 553 (462-675) | 1.34 | 169 | 344 | 407 |
| joint_no_tail_misdated_triggered_0915 | cases | all | 6133 (6054-6217) | 1.18 |  | 5619 | 6044 |
| joint_no_tail_misdated_triggered_0915 | cases | latest 28 | 1711 (1633-1793) | 1.16 |  | 1199 | 1599 |
| joint_no_tail_misdated_triggered_0915 | cases | latest 14 | 877 (807-951) | 1.09 |  | 410 | 761 |
| joint_no_tail_misdated_triggered_0915 | deaths | all | 3088 (2878-3394) | 2.98 |  | 2482 | 2711 |
| joint_no_tail_misdated_triggered_0915 | deaths | latest 28 | 998 (824-1219) | 3.06 |  | 523 | 726 |
| joint_no_tail_misdated_triggered_0915 | deaths | latest 14 | 517 (405-659) | 2.53 |  | 154 | 315 |
| joint_no_tail_misdated_triggered_1001 | cases | all | 6882 (6814-6951) | 1.06 |  |  | 6428 |
| joint_no_tail_misdated_triggered_1001 | cases | latest 28 | 1494 (1427-1562) | 1.05 |  |  | 1043 |
| joint_no_tail_misdated_triggered_1001 | cases | latest 14 | 708 (645-771) | 1.04 |  |  | 305 |
| joint_no_tail_misdated_triggered_1001 | deaths | all | 3242 (3173-3320) | 1.39 |  |  | 2821 |
| joint_no_tail_misdated_triggered_1001 | deaths | latest 28 | 731 (679-790) | 1.18 |  |  | 379 |
| joint_no_tail_misdated_triggered_1001 | deaths | latest 14 | 349 (311-392) | 1.06 |  |  | 87 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep | 04 Aug | 18 Aug | 01 Sep | 15 Sep | 20 Aug | 03 Sep | 17 Sep | 01 Oct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| joint_no_tail_misdated_0905 | 46.8 (0.6-74.9) | 3.6 (3.0-4.3) | 3.7 (3.0-4.3) | 3.7 (3.2-4.6) | 3.7 (3.2-4.6) |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_0915 | 3.7 (2.5-4.5) |  |  |  |  | 3.7 (3.2-4.2) | 3.8 (3.3-4.3) | 3.8 (3.4-4.4) | 3.8 (3.4-4.4) |  |  |  |  |
| joint_no_tail_misdated_1001 | 65.8 (44.9-82.3) |  |  |  |  |  |  |  |  | 5.0 (4.2-5.6) | 5.0 (4.2-5.6) | 9.3 (7.5-12.6) | 9.3 (7.5-12.6) |
| joint_no_tail_misdated_triggered_0905 | 69.2 (1.0-124.9) | 2.3 (2.0-2.8) | 2.3 (2.0-2.8) | 2.4 (2.0-3.0) | 2.4 (2.0-3.0) |  |  |  |  |  |  |  |  |
| joint_no_tail_misdated_triggered_0915 | 54.0 (2.2-62.9) |  |  |  |  | 4.7 (2.1-11.9) | 2.8 (2.1-4.1) | 2.9 (2.1-4.1) | 2.9 (2.1-4.1) |  |  |  |  |
| joint_no_tail_misdated_triggered_1001 | 55.4 (41.6-94.4) |  |  |  |  |  |  |  |  | 3.5 (2.5-4.8) | 3.5 (2.5-4.8) | 7.9 (3.3-10.8) | 7.9 (4.0-10.8) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-14_14_08_counted_on_day_of_death/delays.png)

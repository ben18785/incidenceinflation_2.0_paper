# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| fixed_october_cases_0905 | 4 | 600 | 86 |
| fixed_october_cases_drift_0905 | 4 | 600 | 68 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| fixed_october_cases_0905 | 2.44 | 10 |
| fixed_october_cases_drift_0905 | 1.80 | 4 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|
| fixed_october_cases_0905 | deaths | all | 3178 (3013-3436) | 2.09 | 2111 | 2407 | 2502 |
| fixed_october_cases_0905 | deaths | latest 28 | 1010 (935-1132) | 1.69 | 499 | 720 | 794 |
| fixed_october_cases_0905 | deaths | latest 14 | 507 (463-570) | 1.49 | 169 | 344 | 407 |
| fixed_october_cases_drift_0905 | deaths | all | 3156 (3023-3302) | 1.26 | 2111 | 2407 | 2502 |
| fixed_october_cases_drift_0905 | deaths | latest 28 | 991 (930-1081) | 1.26 | 499 | 720 | 794 |
| fixed_october_cases_drift_0905 | deaths | latest 14 | 490 (456-537) | 1.18 | 169 | 344 | 407 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| fixed_october_cases_0905 | 74.6 (60.4-95.0) | 46.9 (30.1-67.8) | 46.9 (30.0-67.8) | 46.8 (30.0-67.8) | 46.8 (29.9-67.8) |
| fixed_october_cases_drift_0905 | 66.9 (53.9-80.9) | 50.7 (40.4-64.3) | 49.0 (38.3-64.9) | 48.8 (37.6-67.2) | 45.7 (32.6-63.6) |

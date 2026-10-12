# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| check | 2 | 20 | 1 |
| check_fixed | 2 | 10 | 2 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| check | 1.53 | 4 |
| check_fixed | 30.73 | 11 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|
| check | deaths | all | 2442 (2382-2523) | 1.39 | 2111 | 2407 | 2502 |
| check | deaths | latest 28 | 810 (748-864) | 1.33 | 499 | 720 | 794 |
| check | deaths | latest 14 | 422 (368-465) | 1.35 | 169 | 344 | 407 |
| check_fixed | deaths | all | 3406 (3330-3469) | 2.38 | 2111 | 2407 | 2502 |
| check_fixed | deaths | latest 28 | 1183 (1115-1216) | 3.45 | 499 | 720 | 794 |
| check_fixed | deaths | latest 14 | 644 (594-678) | 2.82 | 169 | 344 | 407 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| check | 17.5 (13.0-19.8) | 15.8 (15.3-17.1) | 15.5 (13.9-16.8) | 12.8 (11.5-13.4) | 11.1 (10.2-12.5) |
| check_fixed | 8.1 (6.8-9.6) | 8.5 (6.5-10.6) | 7.4 (6.3-9.5) | 8.3 (6.0-9.4) | 7.4 (5.0-9.4) |

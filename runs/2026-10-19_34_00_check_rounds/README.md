Batch 00_check_rounds. Commit c8633fc8c97c3898015e5e92b1becf85cbe6555e of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-19_34_00_check_rounds)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| check | 2 | 18-19 | 30 | 1 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| check | 2.55 | 6 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_14Oct |
|---|---|---|---|---|---|---|---|
| check | deaths | all | 2666 (2549-2831) | 2.55 | 2111 | 2407 | 2604 |
| check | deaths | latest 28 | 963 (858-1109) | 2.96 | 499 | 720 | 847 |
| check | deaths | latest 14 | 533 (448-635) | 2.43 | 169 | 344 | 438 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| check | 20.4 (18.9-25.0) | 18.7 (17.0-21.4) | 16.2 (13.8-18.6) | 16.0 (14.8-17.9) | 16.6 (15.7-19.5) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-19_34_00_check_rounds/delays.png)

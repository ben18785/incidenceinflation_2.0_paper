Batch 00_check_rounds. Commit c8633fc8c97c3898015e5e92b1becf85cbe6555e of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-19_32_00_check_rounds)

# Experiments

## Chains run

| experiment | chains | iterations | asked for | minutes |
|---|---|---|---|---|
| check | 2 | 6-8 | 30 | 0 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| check | -Inf | 0 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_14Oct |
|---|---|---|---|---|---|---|---|
| check | deaths | all | 2696 (2506-2780) | NA | 2111 | 2407 | 2604 |
| check | deaths | latest 28 | 1029 (841-1102) | NA | 499 | 720 | 847 |
| check | deaths | latest 14 | 569 (428-642) | NA | 169 | 344 | 438 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| check | 15.9 (13.9-18.4) | 15.8 (14.8-17.0) | 17.2 (14.9-18.1) | 16.4 (14.5-17.6) | 17.2 (13.4-18.1) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-19_32_00_check_rounds/delays.png)

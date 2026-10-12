Batch 02_cases_tail_0905. Commit 963166c46138ea416d86e07cf15ef4a6598eed4f of changepoints; model github::ben18785/incidenceinflation_2.0@deaths; [files](https://github.com/ben18785/incidenceinflation_2.0_paper/tree/experiment-results/runs/2026-10-12_6_02_cases_tail_0905)

# Experiments

## Chains run

| experiment | chains | iterations | minutes |
|---|---|---|---|
| cases_no_tail_0905 | 4 | 1000 | 50 |
| cases_tight_tail_0905 | 4 | 1000 | 89 |

## Agreement between chains

| experiment | worst R-hat | quantities at 1.2 or more |
|---|---|---|
| cases_no_tail_0905 | 1.14 | 0 |
| cases_tight_tail_0905 | 1.02 | 0 |

## Totals against the counts recorded

Median and 90% interval of the total over the onset days, and what the reports of each date show for the same onset days.

| experiment | count | onset_days | estimate | rhat | recorded_05Sep | recorded_15Sep | recorded_01Oct |
|---|---|---|---|---|---|---|---|
| cases_no_tail_0905 | cases | all | 5562 (5483-5640) | 1.04 | 5079 | 5391 | 5504 |
| cases_no_tail_0905 | cases | latest 28 | 1735 (1656-1812) | 1.04 | 1252 | 1608 | 1699 |
| cases_no_tail_0905 | cases | latest 14 | 884 (815-953) | 1.03 | 430 | 748 | 830 |
| cases_tight_tail_0905 | cases | all | 5918 (5799-6062) | 1.01 | 5079 | 5391 | 5504 |
| cases_tight_tail_0905 | cases | latest 28 | 1882 (1801-1974) | 1.01 | 1252 | 1608 | 1699 |
| cases_tight_tail_0905 | cases | latest 14 | 961 (894-1035) | 1.01 | 430 | 748 | 830 |

## Mean delay by onset day (days)

| experiment | 11 May | 25 Jul | 08 Aug | 22 Aug | 05 Sep |
|---|---|---|---|---|---|
| cases_no_tail_0905 | 10.1 (9.0-11.1) | 8.6 (8.3-9.0) | 8.6 (7.9-8.9) | 8.5 (7.8-8.9) | 8.5 (7.8-8.9) |
| cases_tight_tail_0905 | 7.8 (7.5-8.0) | 7.8 (7.5-8.0) | 7.8 (7.5-8.0) | 7.8 (7.5-8.0) | 7.8 (7.5-8.0) |

![Delay by onset day](https://raw.githubusercontent.com/ben18785/incidenceinflation_2.0_paper/experiment-results/runs/2026-10-12_6_02_cases_tail_0905/delays.png)

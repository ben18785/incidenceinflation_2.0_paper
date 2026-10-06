# incidenceinflation 2.0: paper pipeline

A [targets](https://books.ropensci.org/targets/) pipeline applying the model
described in `incidenceinflation_2.0/docs/downward_revisions.tex` to simulated
and real data.

## Setup

The pipeline uses the development version of the `incidenceinflation` package,
installed into a project-local library so that it does not replace any other
installed version:

```
Rscript scripts/install_package.R   # installs ../incidenceinflation_2.0 into .lib/
Rscript -e 'targets::tar_make()'
```

The package must be on a branch which includes misdating and batches
(`compiled-kernel` or `batches` at the time of writing). The snapshot table for
the real-data example is tracked in `data/processed/`, so nothing needs to be
downloaded to run the pipeline. To rebuild it from the raw files:

```
Rscript scripts/download_data.R          # fetches raw files into data/raw/ (about 40MB)
Rscript scripts/build_processed_data.R
```

The size of the run is set by environment variables: `PIPELINE_REPLICATES`
(default 5), `PIPELINE_ITERATIONS` (700), `PIPELINE_ITERATIONS_REAL` (1000) and
`PIPELINE_WORKERS` (8).

## What the pipeline does

### Simulated data

Data are simulated for 60 onset days under five regimes (`R/simulate.R`):

| Regime | Mechanisms present |
|---|---|
| `none` | reporting delays only |
| `sporadic` | spurious records entered and later deleted, one at a time |
| `misdating` | genuine cases recorded under a nearby onset day and later moved |
| `batch` | a batch of erroneous records covering seven onset days, all withdrawn on one day |
| `combined` | all of the above |

Three models are fitted to each dataset (`R/fit.R`):

| Model | Description |
|---|---|
| `original` | the published model, in which counts can only rise; fitted after replacing each onset day's counts by their running maximum |
| `sporadic` | adds spurious records which are entered and withdrawn one at a time |
| `full` | adds misdated onset days and batches |

Each fit is scored against the truth (`R/summarise.R`): coverage, error and
width of nowcasts for the latest 14 onset days; bias and coverage for the
latest Rt; and estimates of the parameters.

### Netherlands COVID-19 cases by symptom onset date

RIVM published a case file each day listing every case known, with a date and
what that date represents; the daily files were archived by volunteers at
<https://github.com/mzelst/covid-19>. Counting the cases whose date is a day of
symptom onset in each daily file gives snapshots of cases by onset date which
contain real downward revisions. The models are fitted to what was known on
1 September 2020 for onset dates from 1 July, and the nowcasts compared with
the counts for the same onset dates as known on 15 October.

## Layout

- `_targets.R`: the pipeline.
- `R/`: functions used by the pipeline.
- `scripts/`: one-off setup scripts.
- `data/raw/`: downloaded files (not tracked).
- `data/processed/`: snapshot tables derived from the raw files (tracked).
- `outputs/`: figures, tables and `results.md`, written by the pipeline.

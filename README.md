# incidenceinflation 2.0: paper pipeline

The write-up of the model (`docs/downward_revisions.tex`) and a
[targets](https://books.ropensci.org/targets/) pipeline applying it to
simulated and real data. The write-up includes the figures which the pipeline
writes to `outputs/`, and its results tables are copied from
`outputs/results.md`, so both need updating by hand if the pipeline is rerun.

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

- `docs/`: the write-up.
- `_targets.R`: the pipeline.
- `R/`: functions used by the pipeline.
- `scripts/`: one-off setup scripts.
- `data/raw/`: downloaded files (not tracked).
- `data/processed/`: snapshot tables derived from the raw files (tracked).
- `outputs/`: figures, tables and `results.md`, written by the pipeline.

Further snapshot data in `data/processed/`, not yet analysed: Hong Kong COVID-19
cases by onset date with every change to an individual case's onset date
(`scripts/download_hk.R`), and Swedish COVID-19 deaths by date of death.

## Cases and deaths (docs/bvd_deaths.tex)

The joint model of cases and deaths is tested on simulated data by targets
whose names start with `deaths_sim` (`R/deaths_simulation.R`). They need the
package on its `deaths` branch installed into `.lib/`
(`Rscript scripts/install_package.R`). To run only these:

```
Rscript -e 'targets::tar_make(names = tidyselect::matches("deaths_sim"))'
```

The size of the run is set by `PIPELINE_REPLICATES_DEATHS` (simulated
outbreaks, default 1), `PIPELINE_CHAINS_DEATHS` (2) and
`PIPELINE_ITERATIONS_DEATHS` (300). While chains run, their progress is
written to `outputs/deaths_simulation/progress/<scenario>_<replicate>_<chain>.txt`.
The simulated data and fits are kept in the targets store; the summary, the
coverage of true cases by onset day and the figures are written to `outputs/`.

## Experiments on GitHub Actions

Fits of the outbreak model which take too long for one machine run on GitHub
Actions, one chain per job (`.github/workflows/experiments.yml`).

- `experiments/experiments.yml` lists the experiments: the reports used, the
  part of the model fitted, the settings of the delay, and the number and
  length of the chains. Add an entry to add an experiment.
- Each file of `experiments/batches/` is a batch: a list of names of
  experiments. Pushing a change to a batch's file starts one run of that
  batch, shown on the Actions tab under the message of the commit. Push the
  batches one at a time to have a run for each. The workflow can also be
  started by hand from the Actions tab (once it is on the default branch).
- Results go to the branch `experiment-results`, in a folder for each run:
  `README.md` (the tables), csv files, a plot of the delays, and each chain.
  The same summary is shown on the page of the run.
- The chains are targets of `_targets_experiments.R`, so the same experiments
  run on one machine with
  `BVD_EXPERIMENTS=name1,name2 PIPELINE_WORKERS=8 Rscript -e 'targets::tar_make(script = "_targets_experiments.R", store = "_targets_experiments")'`.
- The version of the model used is the `PACKAGE` line of the workflow.
- A chain which has not finished after 320 minutes stops and saves what is
  needed to carry it on (GitHub ends a job at six hours). To carry the chains
  of a run on, push a batch with the same experiments and a line
  `continue: <id>`, where the id is the number in the address of that run.
  Each chain then makes the draws it would have made had it not stopped. If
  `iterations` in `experiments/experiments.yml` has been raised since, chains
  which had finished are lengthened in the same way. What is saved for this
  is kept by GitHub for 30 days. A line `time_limit: <minutes>` in a batch
  changes the 320 minutes.

The situation report tables are not tracked. `data/bvd_data.tar.gz.enc` holds
them encrypted (with the cases from the model of cases alone which the
experiments with the cases fixed need); the passphrase is the repository
secret `BVD_DATA_KEY` and, on a machine which has the data, the file
`~/.bvd_data_key`. After adding reports run
`Rscript scripts/export_bvd_cases_median.R` (if the fits of cases alone have
changed) and `scripts/encrypt_bvd_data.sh`, and commit the file. To restore
the tables on another machine run `scripts/decrypt_bvd_data.sh`.

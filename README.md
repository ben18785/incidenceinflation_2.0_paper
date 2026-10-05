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
Rscript scripts/download_data.R     # fetches raw data into data/raw/
Rscript -e 'targets::tar_make()'
```

## Layout

- `_targets.R`: the pipeline.
- `R/`: functions used by the pipeline.
- `scripts/`: one-off setup scripts.
- `data/raw/`: downloaded files (not tracked).
- `data/processed/`: snapshot tables derived from the raw files (tracked).
- `outputs/`: figures and tables written by the pipeline.


You can use this DOI to cite this repository:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16878932.svg)](https://doi.org/10.5281/zenodo.16878932)

This repository contains the raw data and replication code to create the charts used in the manuscript I authored titled:

"How collaboration with China can revitalize American automotive innovation"

The key figures are:

- `figs/fig1-range-price-edit`
- `figs/fig2-annual-sales`

Each are saved as a vector graphic (pdf version) and static image (png version).

Figure 1 is reproduced by running the script `fig1-range-price.R`. Since the labeled data points have poor placement in the `figs/fig1-range-price` file, a hand-edited final version is created as `figs/fig1-range-price-edit` where I manually positioned some of the labels. I made the edits in the pdf (vector graphic) version, then saved it as the png version.

Figure 2 is reproduced by running the script `fig2-china-sales.R`.

The raw data used to create these figures is in the "data" folder, and the processed data needed only to re-create these figures is in the "data_processed" folder.

Detailed descriptions of the data sources can be found in the [README file](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/data/README.md) in the "data" folder.
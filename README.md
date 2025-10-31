
You can use this DOI to cite this repository:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16878932.svg)](https://doi.org/10.5281/zenodo.16878932)

This repository contains the raw data and replication code to create the charts used in the following paper:

> Helveston, John P. (2025) “How collaboration with China can revitalize US automotive innovation” _Science_. 390(6772). DOI: [10.1126/science.adz0541](https://doi.org/10.1126/science.adz0541)

The key figures are:

- `figs/fig1-range-price-edit`
- `figs/fig2-annual-sales`

Each are saved as a vector graphic (pdf version) and static image (png version).

Figure 1 is reproduced by running the script `fig1-range-price.R`. Since the labeled data points have poor placement in the `figs/fig1-range-price` file, a hand-edited final version is created as `figs/fig1-range-price-edit` where I manually positioned some of the labels. I made the edits in the pdf (vector graphic) version, then saved it as the png version.

Figure 1 also has an [adjusted version](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/figs/fig1-range-price-adjusted.png) to account for the fact that the driving ranges for the U.S. and Chinese BEVs are determined using different driving cycles. Specifically, the 5-cycle EPA is used in the U.S., and the CLTC is used in China, and the CLTC cycle likely over-estimates the EPA cycle range. I use a 30% over-estimate as a gross approximation.

Figure 2 is reproduced by running the script `fig2-china-sales.R`.

The raw data used to create these figures is in the "data" folder, and the processed data needed only to re-create these figures is in the "data_processed" folder.

Detailed descriptions of the data sources can be found in the [README file](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/data/README.md) in the "data" folder.
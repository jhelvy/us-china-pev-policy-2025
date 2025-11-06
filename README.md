
You can use this DOI to cite this repository:

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16878932.svg)](https://doi.org/10.5281/zenodo.16878932)

This repository contains the raw data and replication code to create the charts used in the following article:

> Helveston, John P. (2025) “How collaboration with China can revitalize US automotive innovation” _Science_. 390(6772). DOI: [10.1126/science.adz0541](https://doi.org/10.1126/science.adz0541)

The key figures are:

- `figs/fig1-range-price.png`
- `figs/figs1-annual-sales.png`

Each are saved as a vector graphic (pdf version) and static image (png version).

Figure descriptions:

- [Figure 1](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/figs/fig1-range-price-edit-labels.png) is reproduced by running the script `fig1-range-price.R`. Since the labeled data points have poor placement in the `figs/fig1-range-price.png` file, a hand-edited final version is created as `figs/fig1-range-price-edit-labels.png` where I manually positioned some of the labels for improved readability. To do so, I edited the pdf (vector graphic) version to reposition the labels, then saved it as a png.
- [Figure S1](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/figs/figs1-annual-sales.png) is only available in the article Supplementary Information and si reproduced by running the script `figs1-china-sales.R`.

The raw data used to create these figures is in the "data" folder, and the processed data needed only to re-create these figures is in the "data_processed" folder.

## Range-adjusted versions of Figure 1 

Figure 1 also has two adjusted versions:

- [EPA adjusted](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/figs/fig1-range-price-adjusted-epa.png)
- [CLTC adjusted](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/figs/fig1-range-price-adjusted-cltc.png)

In these versions, the ranges are adjusted to account for the fact that the driving ranges for the U.S. and Chinese BEVs are determined using different driving cycles. Specifically, the 5-cycle EPA is used in the U.S., and the CLTC is used in China. The CLTC cycle likely over-estimates the EPA cycle range by approximately 30% according to industry experts. To account for this, the "EPA adjusted" version shows the results with the Chinese BEV ranges _reduced_ by 30% as an approximation of the over-estimated range. Likewise, the "CLTC adjusted" version shows the results with the U.S. BEV ranges _increased_ by 30%.

An interactive version of this chart can also be seen here:
[https://jhelvy.github.io/science-2025/](https://jhelvy.github.io/science-2025/)

The app allows you to:

- Interactively adjust the range conversion factor (slider from 0% to 50%)
- Choose whether to adjust China ranges (EPA) or USA ranges (CLTC)
- View real-time updates to the scatter plot as you adjust parameters

Detailed descriptions of the data sources can be found in the [README file](https://github.com/jhelvy/us-china-pev-policy-2025/blob/main/data/README.md) in the "data" folder.

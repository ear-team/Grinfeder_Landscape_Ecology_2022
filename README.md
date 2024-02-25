# Soundscape dynamics of a cold protected forest: dominance of aircraft noise

[![Downloads](https://static.pepy.tech/badge/Grinfeder_Landscape_Ecology_2022)](https://pepy.tech/project/Grinfeder_Landscape_Ecology_2022)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Citation Badge](https://api.juleskreuer.eu/citation-badge.php?doi=110.1007/s10980-021-01360-1)](https://juleskreuer.eu/projekte/citation-badge/)

This repository contains the code adapted from the original code used by the article https://link.springer.com/article/10.1007/s10980-021-01360-1

The audio dataset used to train the ANN model is archived on Zenodo: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10701274.svg)](https://doi.org/10.5281/zenodo.10701274)

If the code, even partially, is used for other purpose please cite the article 
`Grinfeder, E., Haupert, S., Ducrettet, M., Barlet, J., Reynet, M. P., Sèbe, F., & Sueur, J. (2022). Soundscape dynamics of a cold protected forest: dominance of aircraft noise. Landscape Ecology, 1-16.`

## Setup and usage

Download the `.zip` from Github (click on `code` then `Download Zip`) and extract all folders without changing the name of the folders neither rearrange the folder and sub-folders.

Then, download the audio dataset and the annotation file from Zenodo https://doi.org/10.5281/zenodo.10701274. Extract the `.zip` files in the directory `audio_recordings`

Finaly, use your favorite R environment (e.g. RStudio). The script `training_ann.R `or the notebook `training_ann.ipynb` are ready to be used. Please install the required libraries if they are not already installed in your environment. Here is the list of library that are requested :
* seewave and tuneR
* neuralnet
* pROC

By default, the MFCCs will be loaded directly from the file mfcc.rds. If you want to recalculate them, set `COMPUTE_MFFC` to `TRUE`.

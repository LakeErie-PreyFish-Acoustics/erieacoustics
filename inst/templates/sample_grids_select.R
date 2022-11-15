# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# November 15, 2022
# M. DuFour

# What it does ----
# This script provides code to select survey sample grids
# using two custom functions from erieacoustics

# How to use ----
# This script uses functions for generating random grid samples, visualizing
# with maps, and exporting .png/.csv files for 2_Project_Proposal_Summary.
# 1. Run 'sample_grids_proposed(basin,year)' to generate proposed sample locations
# 2. Evaluate locations with vessel crew and partner agencies.
# 3. Update 'sample_grids_final.csv' document as needed.
# 4. Run 'sample_grids_final()
# a single transect export can be done like:
# export_transect_evdata(getwd(), "S1_R1", 500)
# the `getwd()` call is required as Echoview doesn't recogize relative paths from R

# ----
library(erieacoustics)
library(eriespatial)
library(magrittr)
## Set basin (e.g., WB, CB, or EB) and survey year (e.g., 2022)
basin <- "WB"
year <- 2022

## generate proposed sample grids
sample_grids_proposed(basin,year)

## finalize sample grids
sample_grids_final(basin,year)
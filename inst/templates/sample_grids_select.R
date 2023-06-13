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

# ----
## load packages
library(erieacoustics)
library(eriespatial)
library(dplyr)
library(sf)
library(readr)
library(ggplot2)
library(gridExtra)
library(here)

## Set basin (e.g., WB, CB, or EB) and survey year (e.g., 2022)
load(file.path(here(), "metadata.RData"))
basin <- metadata$Basin
year <- metadata$Year

## generate proposed sample grids
sample_grids_proposed(basin,year)

## generate extra sample grids if necessary
library(purrr)
allgrids <- read.csv("1_Annual_Protocol/sample_grids_all.csv")
random_grids <- read.csv("1_Annual_Protocol/sample_grids_proposed.csv")
notselected <- anti_join(allgrids, random_grids, by=c("Basin", "Stratum", "Grid"))

select_extra <- function(df, n_extra) {
  n_row <- nrow(df)
  n_select <- ifelse(n_extra > n_row, n_row, n_extra)
  df_return <- df[sample(1:n_row, n_select), ]
  df_return
}

notselected %>%
  split(.$Stratum) %>%
  map(select_extra, n_extra = 5) %>%
  bind_rows() %>%
  mutate(Priority = "Extra") %>%
  select(Basin, Stratum, Grid, Priority, Latitude, Longitude) %>%
  write.csv(., file = "1_Annual_Protocol/test_extra.csv", row.names = F)

## Edit sample_grids_final.csv as required

## finalize sample grids
sample_grids_final(basin,year)

# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# November 17, 2022
# M. DuFour
# Updated by J. Holden on Feb 21, 2022

# What it does ----
# This script will import, combine, and format summarized EpiLayer and Bottom line
# data from hydroacoustic survey transects. Aggregated files are then summarized by
# GRID and combine with water column profile data. The combine data 'wcpdat.csv' is
# to '7_Annual_Summary' folder.


# How to use ----
# 1. Ensure that data has imported to Echoview template using '1_import_data_to_template.R'.
# 2. Ensure that Echoview files have been processed and scrutinized
# 3. Ensure that transect level data has been exported using '2_export_data_from_EV'
# 4. Ensure that hydroacoustic data have been processed using '3_aggregate_format_hydro_data.R'
# 5. Ensure water column profile data has been entered into template '5_Enviro_Data/Water_Column_Profiles.csv'
# 6. Run script below

# ----

## suggested packages
library(erieacoustics)
library(readr)
library(dplyr)

## Gather a list of all files from /3_Ping_Data directory
alltransects <- dir('3_Ping_Data')

# import and merge all transects
epi_bot_lines <- bind_rows(lapply(alltransects, import_epi_bottom_lines))

## write to file
write_csv(epi_bot_lines, "5_Enviro_Data/EpiBotLineSummaries.csv")

## read in water column profile data
wcp <- read_csv("5_Enviro_Data/Water_Column_Profiles.csv")

## join files together
wcpdat <- left_join(wcp, epi_bot_lines, by = "GRID")

## write to file
write_csv(wcpdat, "7_Annual_Summary/wcpdat.csv")

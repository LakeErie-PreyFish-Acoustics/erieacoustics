# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# November 17, 2022
# M. DuFour

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

## double check that all required packages are installed
pck_list <- c('dplyr','readr','magrittr','base','magrittr','utils','stats')

is_installed <- pck_list %in% installed.packages()
if(!all(is_installed)){
  missing <- pck_list[!is_installed]
  stop(paste0("\nuse install.packages(", missing,") to install ", missing," package"))
  }


## load packages
library(readr)
library(dplyr)
library(base)
library(magrittr)
library(utils)
library(stats)


## Gather a list of all files from /3_Ping_Data directory
allfiles<-base::dir('3_Ping_Data', recursive = T, full.names = T)

## Import and bind together EpiLayeLine_Final.csv files
## Import and bind together BottomLine_Final.csv files
epi <- base::grep(allfiles, pattern = "EpiLayerLine_Final\\.csv$", value = T)
bot <- base::grep(allfiles, pattern = "BottomLine_Final\\.csv$", value = T)

## extract GRID numbers from file path names
GRID <- NULL
for(i in 1:base::length(epi)) GRID[i] <- (base::substring(epi[i], 20, 23))

## Import EpiLayerLine_Final data and append GRID numbers
epi <- (base::lapply(epi, readr::read_csv))
for(i in 1:base::length(GRID)) epi[[i]]$GRID <- GRID[i]
epi <- dplyr::bind_rows(epi)

## Import BottomLine_Final data and append GRID numbers
bot<-(base::lapply(bot, readr::read_csv))
for(i in 1:base::length(GRID)) bot[[i]]$GRID <- GRID[i]
bot <- dplyr::bind_rows(bot)

## write combine EpiLayerLines.csv and BottomLines.csv to file
#utils::write.csv(epi,"7_Annual_Summary/EpiLayerLines.csv")
#utils::write.csv(bot,"7_Annual_Summary/BottomLines.csv")

## average, min, max EpiLayer depths
epi_avg  <- stats::aggregate(Depth ~ GRID, data=epi, FUN="mean")
epi_min  <- stats::aggregate(Depth ~ GRID, data=epi, FUN="min")
epi_max  <- stats::aggregate(Depth ~ GRID, data=epi, FUN="max")
epi_line <- base::cbind(epi_avg, epi_min[,2], epi_max[,2])
base::colnames(epi_line)[2:4] <- c("epi_avg","epi_min","epi_max")

## average, min, max BottomLayer depths
bot_avg  <- stats::aggregate(Depth ~ GRID, data=bot, FUN="mean")
bot_min  <- stats::aggregate(Depth ~ GRID, data=bot, FUN="min")
bot_max  <- stats::aggregate(Depth ~ GRID, data=bot, FUN="max")
bot_line <- base::cbind(bot_avg, bot_min[,2], bot_max[,2])
base::colnames(bot_line)[2:4] <- c("bot_avg","bot_min","bot_max")

## join EpiLayerLine and BottomLine summaries together
epi_bot_lines <- dplyr::left_join(epi_line,bot_line, by="GRID")

## write to file
#utils::write.csv(epi_bot_lines, "5_Enviro_Data/EpiBotLineSummaries.csv")

## read in water column profile data
wcp <- readr::read_csv("5_Enviro_Data/Water_Column_Profiles.csv")

## join files together
wcpdat <- dplyr::left_join(wcp,epi_bot_lines, by="GRID")

## write to file
utils::write.csv(wcpdat, "7_Annual_Summary/wcpdat.csv")




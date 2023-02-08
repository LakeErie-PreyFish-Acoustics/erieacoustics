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

## suggested packages
library(readr)
library(dplyr)
library(base)
library(magrittr)


## Gather a list of all files from /3_Ping_Data directory
allfiles <- dir('3_Ping_Data', recursive = T, full.names = T)

## Import and bind together EpiLayeLine_Final.csv files
## Import and bind together BottomLine_Final.csv files
epi <- grep(allfiles, pattern = "EpiLayerLine_Final\\.csv$", value = T)
bot <- grep(allfiles, pattern = "BottomLine_Final\\.csv$", value = T)

## extract GRID numbers from file path names
GRID <- NULL
for(i in 1:length(epi)) GRID[i] <- (substring(epi[i], 20, 23))

## Import EpiLayerLine_Final data and append GRID numbers
read_csv_col_format <- function(x) read_csv(x, col_types = cols(.default = col_double(), Ping_date = col_date(), Ping_milliseconds = col_double(), Ping_time = col_time(), GPS_UTC_time = col_time()))
epi <- (lapply(epi, read_csv_col_format))
for(i in 1:length(GRID)) epi[[i]]$GRID <- GRID[i]
epi <- bind_rows(epi)

## Import BottomLine_Final data and append GRID numbers
bot<-(lapply(bot, read_csv_col_format))
for(i in 1:length(GRID)) bot[[i]]$GRID <- GRID[i]
bot <- bind_rows(bot)

## write combine EpiLayerLines.csv and BottomLines.csv to file
#readr::write_csv(epi,"7_Annual_Summary/EpiLayerLines.csv")
#readr::write_csv(bot,"7_Annual_Summary/BottomLines.csv")

## average, min, max EpiLayer depths
epi_line <- epi %>% group_by(GRID) %>%
  summarise(epi_avg = mean(Depth), epi_min = min(Depth), epi_max = max(Depth))

## average, min, max BottomLayer depths
bot_line <- bot %>% group_by(GRID) %>%
  summarise(bot_avg = mean(Depth), bot_min = min(Depth), bot_max = max(Depth))

## join EpiLayerLine and BottomLine summaries together
epi_bot_lines <- left_join(epi_line, bot_line, by = "GRID")

## write to file
write_csv(epi_bot_lines, "5_Enviro_Data/EpiBotLineSummaries.csv")

## read in water column profile data
wcp <- read_csv("5_Enviro_Data/Water_Column_Profiles.csv")

## join files together
wcpdat <- left_join(wcp, epi_bot_lines, by = "GRID")

## write to file
write_csv(wcpdat, "7_Annual_Summary/wcpdat.csv")

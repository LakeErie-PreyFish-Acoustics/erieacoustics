# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# September 27, 2022
# M. DuFour

# What it does ----
# This script will import, combine, and format summarized integration and target strength
# data from hydroacoustic survey transects. Three .csv files with data associated by
# BASIN, STRATUM, GRID, LAYER (epilimnion vs. hypolimnion region), and interval are exported.
#
# 'hacdat.csv' includes  integration, mean target strength, and fish density estimates.
#
# 'histo.csv' includes single target counts for 0.5 dB target strength bins ranging
# from -64.5 to -20.5 dB.
#
# histohac.csv' merges 'hacdat' and 'histo' together.

# How to use ----
# 1. Ensure that data has imported to Echoview template using '1_import_data_to_template.R'.
# 2. Ensure that Echoview files have been processed and scrutinized
# 3. Ensure that transect level data has been exported using '2_export_data_from_EV'
# 4. Run script below

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

## Import and bind together integration data
intg<-base::grep(allfiles, pattern = "intg\\.csv$", value = T)
intg<-dplyr::bind_rows(base::lapply(intg, readr::read_csv))
intg<-intg %>% dplyr::filter(!(base::is.na(Region_name)))

## Import and bind together target strength data
ts<-base::grep(allfiles, pattern = "ts\\.csv$", value = T)
ts<-dplyr::bind_rows(base::lapply(ts, readr::read_csv))

## Merge/join integration and target strength data
hacdat <- dplyr::left_join(intg, ts, by=c('Region_name', 'Interval', 'Date_M', 'Time_M'))

## remove intervals less than 375 m - typically shorts segment collected beyond specified 5 km transect
hacdat$IntDist <- hacdat$Dist_E.x-hacdat$Dist_S.x
hacdat <- dplyr::filter(hacdat, IntDist >= 375)

## Split Region_name into distinct basin, STRATUM, GRID, and LAYER for hacdat
hacdat$BASIN <- base::sapply(base::strsplit(hacdat$Region_name, "_"), '[', 1)
hacdat$STRATUM <- base::sapply(base::strsplit(hacdat$Region_name, "_"), '[',2)
hacdat$GRID <- base::sapply(base::strsplit(hacdat$Region_name, "_"), '[',3)
hacdat$LAYER <- base::sapply(base::strsplit(hacdat$Region_name, "_"), '[',4)

## replace missing TS values with average TS from INTERVALS within same TRANSECT and LAYER
hacdat$sigma_bs <- 10^(hacdat$TS_mean/10) # create sigma_bs
hacdat$sigma_bs <- base::ifelse(hacdat$TS_mean == 9999, NA,  hacdat$sigma_bs) # assign NAs
## impute missing sigma_bs_adj data - replace missing and Nv flagged sigma_bs values with mean of interval
hacdat <- hacdat %>%
  dplyr::group_by(BASIN, STRATUM, GRID, LAYER) %>%
  dplyr::mutate_at(vars(sigma_bs), ~replace_na(., mean(., na.rm = TRUE)))
hacdat$TS_mean <- 10*base::log10(hacdat$sigma_bs) # convert sigma_bs back to TS_mean using imputed values

## Calculate fish density:
## volume back scattering coefficient divided by backscattering cross-section = fish/cubic meter
## multiply by thickness (m) and 10,000 turns this into areal density (fish/hectare)
#hacdat$NperHa <- with(hacdat, (10^(Sv_mean/10))/(10^(TS_mean/10))*Thickness_mean.x*10000)
## Exporting and using ABC
hacdat$NperHa <- base::with(hacdat, (PRC_ABC/sigma_bs*10000)) # PRC_ is a region-based classification of ABC


## Reduce hacdat to essential columns
hacdat <-hacdat %>% dplyr::select(BASIN, STRATUM, GRID, LAYER, Interval, Date_M, Time_M, Lat_M.x, Lon_M.x,
                           Sv_mean, PRC_ABC, sigma_bs, TS_mean,Num_targets, NperHa, Exclude_below_line_depth_mean.x) %>%
                    dplyr::rename(Lat_M = Lat_M.x) %>%
                    dplyr::rename(Lon_M = Lon_M.x) %>%
                    dplyr::rename(BottomLine = Exclude_below_line_depth_mean.x)

## write hacdat data to file
utils::write.csv(hacdat, "7_Annual_Summary/hacdat.csv")





## Import and bind together target strength histogram data
histo<-base::grep(allfiles, pattern = "histo\\.csv$", value = T)
histo<-dplyr::bind_rows(base::lapply(histo, readr::read_csv)) ## column 114 is NA

## Split Region_name into distinct STRATUM, TRANSECT, and LAYER for histo
histo$BASIN <- base::sapply(base::strsplit(histo$Region_name, "_"), '[',1)
histo$STRATUM <- base::sapply(base::strsplit(histo$Region_name, "_"), '[',2)
histo$GRID <- base::sapply(base::strsplit(histo$Region_name, "_"), '[',3)
histo$LAYER <- base::sapply(base::strsplit(histo$Region_name, "_"), '[',4)

## Reduce histo to essential columns and transform to long form
## TS columns to rows with replicated data
histo <- histo %>% dplyr::select(BASIN, STRATUM, GRID, LAYER, Date_M, Time_M, Lat_M, Lon_M, Interval,
                          Targets_Binned, Attribute, `-64.500000`:`-20.500000`) %>%
                   dplyr::pivot_longer(`-64.500000`:`-20.500000`, names_to = "TS_bin") %>%
                   dplyr::pivot_wider(names_from = "Attribute")

## write histo data to file
utils::write.csv(histo, "7_Annual_Summary/histo.csv")



## Merge hacdat and histo data together
histohac<-dplyr::left_join(hacdat, histo, by = c("BASIN","STRATUM", "GRID", "LAYER", "Interval", "Date_M", "Time_M"))

## write histohac data to file
utils::write.csv(histohac, "7_Annual_Summary/histohac.csv")



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
utils::write.csv(epi,"7_Annual_Summary/EpiLayerLines.csv")
utils::write.csv(bot,"7_Annual_Summary/BottomLines.csv")

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
utils::write.csv(epi_bot_lines, "5_Enviro_Data/EpiBotLineSummaries.csv")

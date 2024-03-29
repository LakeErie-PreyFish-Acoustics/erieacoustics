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


## suggested packages
library(readr)
library(dplyr)
library(base)
library(magrittr)
library(stats)
library(tidyr)


## Gather a list of all files from /3_Ping_Data directory
allfiles <- dir('3_Ping_Data', recursive = T, full.names = T)

## Import and bind together integration data
intg <- grep(allfiles, pattern = "intg\\.csv$", value = T)
intg <- bind_rows(lapply(intg, read_csv))
intg <- intg %>% filter(!(is.na(Region_name)))

## Import and bind together target strength data
ts <- grep(allfiles, pattern = "ts\\.csv$", value = T)
ts <- bind_rows(lapply(ts, read_csv))

## Merge/join integration and target strength data
hacdat <- left_join(intg, ts, by=c('Region_name', 'Interval', 'Date_M', 'Time_M', 'Dist_E', 'Dist_S', 'Lat_M', 'Lon_M', 'Exclude_below_line_depth_mean'))

## remove intervals less than 375 m - typically shorts segment collected beyond specified 5 km transect
hacdat$IntDist <- hacdat$Dist_E - hacdat$Dist_S
hacdat <- filter(hacdat, IntDist >= 375)

## Split Region_name into distinct basin, STRATUM, GRID, and LAYER for hacdat
hacdat$BASIN <- sapply(strsplit(hacdat$Region_name, "_"), '[', 1)
hacdat$STRATUM <- sapply(strsplit(hacdat$Region_name, "_"), '[',2)
hacdat$GRID <- sapply(strsplit(hacdat$Region_name, "_"), '[',3)
hacdat$LAYER <- sapply(strsplit(hacdat$Region_name, "_"), '[',4)

## replace missing TS values with average TS from INTERVALS within same TRANSECT and LAYER
hacdat$sigma_bs <- 10^(hacdat$TS_mean/10) # create sigma_bs
hacdat$sigma_bs <- ifelse(hacdat$TS_mean == 9999, NA, hacdat$sigma_bs) # assign NAs
## impute missing sigma_bs_adj data - replace missing and Nv flagged sigma_bs values with mean of interval
hacdat <- hacdat %>%
  group_by(BASIN, STRATUM, GRID, LAYER) %>%
  mutate_at(vars(sigma_bs), ~replace_na(., mean(., na.rm = TRUE)))
hacdat$TS_mean <- 10*log10(hacdat$sigma_bs) # convert sigma_bs back to TS_mean using imputed values

## Calculate fish density:
## volume back scattering coefficient divided by backscattering cross-section = fish/cubic meter
## multiply by thickness (m) and 10,000 turns this into areal density (fish/hectare)
#hacdat$NperHa <- with(hacdat, (10^(Sv_mean/10))/(10^(TS_mean/10))*Thickness_mean.x*10000)
## Exporting and using ABC
hacdat$NperHa <- with(hacdat, (PRC_ABC/sigma_bs*10000)) # PRC_ is a region-based classification of ABC


## Reduce hacdat to essential columns
hacdat <-hacdat %>% select(BASIN, STRATUM, GRID, LAYER, Interval, Date_M, Time_M, Lat_M, Lon_M,
                                  Sv_mean, PRC_ABC, sigma_bs, TS_mean,Num_targets, NperHa,
                                  Exclude_below_line_depth_mean) %>%
                    rename(BottomLine = Exclude_below_line_depth_mean)

## write hacdat data to file
write_csv(hacdat, "7_Annual_Summary/hacdat.csv")





## Import and bind together target strength histogram data
histo <- grep(allfiles, pattern = "histo\\.csv$", value = T)
histo <- bind_rows(lapply(histo, read_csv)) ## column 114 is NA

## Split Region_name into distinct STRATUM, TRANSECT, and LAYER for histo
histo$BASIN <- sapply(strsplit(histo$Region_name, "_"), '[',1)
histo$STRATUM <- sapply(strsplit(histo$Region_name, "_"), '[',2)
histo$GRID <- sapply(strsplit(histo$Region_name, "_"), '[',3)
histo$LAYER <- sapply(strsplit(histo$Region_name, "_"), '[',4)

## Reduce histo to essential columns and transform to long form
## TS columns to rows with replicated data
histo <- histo %>% select(BASIN, STRATUM, GRID, LAYER, Date_M, Time_M, Lat_M, Lon_M, Interval,
                                 Targets_Binned, Attribute, `-64.500000`:`-20.500000`) %>%
                   pivot_longer(`-64.500000`:`-20.500000`, names_to = "TS_bin") %>%
                   pivot_wider(names_from = "Attribute")

## write histo data to file
write_csv(histo, "7_Annual_Summary/histo.csv")



## Merge hacdat and histo data together
histohac <- left_join(hacdat, histo, by = c("BASIN","STRATUM", "GRID", "LAYER", "Interval", "Date_M", "Time_M"))

## write histohac data to file
write_csv(histohac, "7_Annual_Summary/histohac.csv")


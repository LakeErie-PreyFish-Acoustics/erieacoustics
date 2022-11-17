# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# November 17, 2022
# M. DuFour

# What it does ----
# This script will import, combine, and format species composition data from
# midwater trawling. Two .csv files are generated with date, location, catch, species
# group, and size information.
#
# 'trwldat.csv' includes date, location, and catch/proportion by species group.
#
# 'trwllen.csv' includes date, location, and size by species and species group.
#
# How to use ----
# 1. Ensure that data has imported to Echoview template using '1_import_data_to_template.R'.
# 2. Ensure that Echoview files have been processed and scrutinized
# 3. Ensure that transect level data has been exported using '2_export_data_from_EV'
# 4. Ensure that hydroacoustic data have been processed using '3_aggregate_format_hydro_data.R'
# 5. Ensure water column profile data have been processed 'using '4_aggregate_format_wcp_data.R'
# 6. Ensure that trawl data has been entered into '4_Trawl_Data/Trawl_Effort.csv,
#    Trawl_Catch.csv, and Trawl_Length.csv templates
# 7. Run script below

# ----

## double check that all required packages are installed
pck_list <- c('dplyr','readr','magrittr','base','reshape2')

is_installed <- pck_list %in% installed.packages()
if(!all(is_installed)){
  missing <- pck_list[!is_installed]
  stop(paste0("\nuse install.packages(", missing,") to install ", missing," package"))
  }


## load packages
library(readr)
library(dplyr)
library(reshape2)
library(base)
library(magrittr)

## bring in effort, catch, and length data
eff <- readr::read_csv("4_Trawl_Data/Trawl_Effort.csv") %>%
  dplyr::filter(EFFST == 1) %>%
  dplyr::filter(complete.cases(GRID_10M)) %>%
  dplyr::rename(time = EFFTM0)
eff$GRID <- paste0("G",eff$GRID_10M)

cat <- readr::read_csv("4_Trawl_Data/Trawl_Catch.csv")
len <- readr::read_csv("4_Trawl_Data/Trawl_Length.csv")
epi <- readr::read_csv("5_Enviro_Data/EpiBotLineSummaries.csv")

## group species for analysis
cat$an_grp <- base::ifelse(cat$SPC == 121 & cat$GRP == 1, "RSYOY",
                           base::ifelse(cat$SPC == 121 & cat$GRP != 1, "RSYAO",
                                        base::ifelse(cat$SPC == 196, "ES",
                                                     base::ifelse(cat$SPC == 331 & cat$GRP == 1, "YPYOY", "OTHER"))))

## generate catch proportions by species group for each trawl
cat_an <- cat %>%
  dplyr::group_by(SAM,an_grp) %>%
  dplyr::summarize(CATCNT = sum(CATCNT)) %>%
  reshape2::dcast(SAM ~ an_grp)

## set NA values to 0
cat_an[base::is.na(cat_an)] = 0

## sum across species groups
for(i in 1:base::dim(cat_an)[1]) cat_an$TOTAL[i] <- base::sum(cat_an[i,2:6])
for(i in 1:base::dim(cat_an)[1]) cat_an$ES_p <- cat_an$ES/cat_an$TOTAL
for(i in 1:base::dim(cat_an)[1]) cat_an$OTHER_p <- cat_an$OTHER/cat_an$TOTAL
for(i in 1:base::dim(cat_an)[1]) cat_an$RSYAO_p <- cat_an$RSYAO/cat_an$TOTAL
for(i in 1:base::dim(cat_an)[1]) cat_an$RSYOY_p <- cat_an$RSYOY/cat_an$TOTAL
for(i in 1:base::dim(cat_an)[1]) cat_an$YPYOY_p <- cat_an$YPYOY/cat_an$TOTAL

## merge eff and cat_an
eff_cat_an <- dplyr::left_join(eff,cat_an,by="SAM")
eff_cat_an <- dplyr::left_join(eff_cat_an, epi, by="GRID")
eff_cat_an$LAYER <- base::ifelse(eff_cat_an$GRDEP <= eff_cat_an$epi_avg, "EPI","HYP")

## subset data to pertinent columns and switch to long form
trwldat_c <- eff_cat_an %>% dplyr::select(month, day, year, time, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, ES, OTHER, RSYAO, RSYOY, YPYOY, TOTAL) %>%
  reshape2::melt(id.vars = c("month","day","year","time","STRATUM","GRID", "LatDec", "LonDec", "SIDEP", "GRDEP", "LAYER")) %>%
  dplyr::rename(SpcGrp = variable) %>%
  dplyr::rename(catch=value)

trwldat_p <- eff_cat_an %>% dplyr::select(month, day, year, time, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, ES_p, OTHER_p, RSYAO_p, RSYOY_p, YPYOY_p) %>%
  reshape2::melt(id.vars = c("month","day","year","time","STRATUM","GRID", "LatDec", "LonDec", "SIDEP", "GRDEP", "LAYER")) %>%
  dplyr::rename(SpcGrp = variable) %>%
  dplyr::rename(prop=value)

trwldat_p$SpcGrp <- base::ifelse(trwldat_p$SpcGrp == "ES_p", "ES",
                                 base::ifelse(trwldat_p$SpcGrp == "OTHER_p", "OTHER",
                                              base::ifelse(trwldat_p$SpcGrp == "RSYAO_p", "RSYAO",
                                                           base::ifelse(trwldat_p$SpcGrp == "RSYOY_p", "RSYOY", "YPYOY"))))

trwldat <- dplyr::left_join(trwldat_c,trwldat_p, by=c("month","day","year","STRATUM","GRID","LatDec","LonDec","SIDEP","GRDEP","LAYER","SpcGrp"))

## write to file
readr::write_csv(trwldat,"7_Annual_Summary/trwldat.csv") # export

## regroup for analysis
len$SpcGrp <- base::ifelse(len$SPC == 121 & len$GRP == 1, "RSYOY",
                           base::ifelse(len$SPC == 121 & len$GRP != 1, "RSYAO",
                                        base::ifelse(len$SPC == 196, "ES",
                                                     base::ifelse(len$SPC == 331 & len$GRP == 1, "YPYOY", "OTHER"))))


## merge eff and len
eff_len <- dplyr::left_join(eff,len,by="SAM")
eff_len <- dplyr::left_join(eff_len, epi, by="GRID")
eff_len$LAYER <- base::ifelse(eff_len$GRDEP <= eff_len$epi_avg, "EPI","HYP")

## subset data to pertinent columns and switch to long form
trwllen <- eff_len %>% dplyr::select(month.x, day.x, year.x, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, SPC, GRP, SpcGrp, TLEN) %>%
  dplyr::rename(month = month.x) %>%
  dplyr::rename(day = day.x) %>%
  dplyr::rename(year = year.x)

## write to file
readr::write_csv(trwllen,"7_Annual_Summary/trwllen.csv") # export

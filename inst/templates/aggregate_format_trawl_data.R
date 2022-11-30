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

## suggested packages
library(readr)
library(dplyr)
library(reshape2)
library(base)
library(magrittr)

## bring in effort, catch, and length data
eff <- read_csv("4_Trawl_Data/Trawl_Effort.csv") %>%
  filter(EFFST == 1) %>%
  filter(complete.cases(GRID_10M)) %>%
  rename(time = EFFTM0)
eff$GRID <- paste0("G", eff$GRID_10M)

cat <- read_csv("4_Trawl_Data/Trawl_Catch.csv")
len <- read_csv("4_Trawl_Data/Trawl_Length.csv")
epi <- read_csv("5_Enviro_Data/EpiBotLineSummaries.csv")

## group species for analysis
cat <- cat %>% mutate(SpcGrp = case_when( SPC == 121 & GRP == 1 ~ "RSYOY",
                                          SPC == 121 & GRP != 1 ~ "RSYAO",
                                          SPC == 196 ~ "ES",
                                          SPC == 331 & GRP == 1~ "YPYOY",
                                          TRUE ~ "OTHER"
)
)

## generate catch proportions by species group for each trawl
cat_an <- cat %>%
  group_by(SAM, SpcGrp) %>%
  summarize(CATCNT = sum(CATCNT))


## sum totals across species groups
cat_an_tot <- cat_an %>% group_by(SAM) %>% summarise(TOTAL = sum(CATCNT))
cat_an <- left_join(cat_an, cat_an_tot, by="SAM")
cat_an$PROP <- cat_an$CATCNT/cat_an$TOTAL

## pivot wider and join totals
cat_an <- cat_an %>% pivot_wider(names_from = "SpcGrp", values_from = c("CATCNT","PROP"))

## set NA values to 0
cat_an[is.na(cat_an)] = 0

## merge eff and cat_an
eff_cat_an <- left_join(eff, cat_an, by = "SAM")
eff_cat_an <- left_join(eff_cat_an, epi, by = "GRID")
eff_cat_an$LAYER <- ifelse(eff_cat_an$GRDEP <= eff_cat_an$epi_avg, "EPI", "HYP")

## subset data to pertinent columns, switch to long form, and align SpcGrp names
trwldat_c <- eff_cat_an %>% select(month, day, year, time, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, CATCNT_RSYAO, CATCNT_RSYOY, CATCNT_ES, CATCNT_YPYOY, CATCNT_OTHER, TOTAL) %>%
  pivot_longer(cols = c("CATCNT_RSYAO", "CATCNT_RSYOY", "CATCNT_ES", "CATCNT_YPYOY", "CATCNT_OTHER", "TOTAL"), names_to = "SpcGrp", values_to = "catch") %>%
  mutate(SpcGrp = case_when( SpcGrp == "CATCNT_ES" ~ "ES",
                             SpcGrp == "CATCNT_OTHER" ~ "OTHER",
                             SpcGrp == "CATCNT_RSYAO" ~ "RSYAO",
                             SpcGrp == "CATCNT_RSYOY" ~ "RSYOY",
                             SpcGrp == "CATCNT_YPYOY" ~ "YPYOY",
                             TRUE ~ "TOTAL"))


trwldat_p <- eff_cat_an %>% select(month, day, year, time, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, PROP_RSYAO, PROP_RSYOY,  PROP_ES, PROP_YPYOY,  PROP_OTHER) %>%
  pivot_longer(cols = c("PROP_RSYAO", "PROP_RSYOY",  "PROP_ES", "PROP_YPYOY", "PROP_OTHER"), names_to = "SpcGrp", values_to = "prop") %>%
  mutate(SpcGrp = case_when( SpcGrp == "PROP_ES" ~ "ES",
                             SpcGrp == "PROP_OTHER" ~ "OTHER",
                             SpcGrp == "PROP_RSYAO" ~ "RSYAO",
                             SpcGrp == "PROP_RSYOY" ~ "RSYOY",
                             TRUE ~ "YPYOY"))

trwldat <- left_join(trwldat_c, trwldat_p, by = c("month", "day", "year", 'time',"STRATUM", "GRID", "LatDec", "LonDec", "SIDEP", "GRDEP", "LAYER", "SpcGrp"))

## set NA values to 1
trwldat[is.na(trwldat)] = 1

## write to file
write_csv(trwldat, "7_Annual_Summary/trwldat.csv") # export

## regroup for analysis
len <- len %>% mutate(SpcGrp = case_when( SPC == 121 & GRP == 1 ~ "RSYOY",
                                          SPC == 121 & GRP != 1 ~ "RSYAO",
                                          SPC == 196 ~ "ES",
                                          SPC == 331 & GRP == 1 ~ "YPYOY",
                                          TRUE ~ "OTHER"))

## merge eff and len
eff_len <- left_join(eff,len, by = c("month", "day", "year", "SAM"))
eff_len <- left_join(eff_len, epi, by = "GRID")
eff_len$LAYER <- ifelse(eff_len$GRDEP <= eff_len$epi_avg, "EPI", "HYP")

## subset data to pertinent columns and switch to long form
trwllen <- eff_len %>% select(month, day, year, STRATUM, GRID, LatDec, LonDec, SIDEP, GRDEP, LAYER, SPC, GRP, SpcGrp, TLEN)

## write to file
write_csv(trwllen, "7_Annual_Summary/trwllen.csv") # export

## code to prepare `Vessel_Log` dataset goes here
library(readr)
Vessel_Log <- read_csv("data-raw/Vessel_Log.csv")
usethis::use_data(Vessel_Log, overwrite = TRUE)

## code to prepare `Trawl_Depths` dataset goes here
library(readr)
Trawl_Depths <- read_csv("data-raw/Trawl_Depths.csv")
usethis::use_data(Trawl_Depths, overwrite = TRUE)

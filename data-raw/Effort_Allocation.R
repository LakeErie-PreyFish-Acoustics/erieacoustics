## code to prepare `Effort_Allocation` dataset goes here
library(readr)
Effort_Allocation <- read_csv("data-raw/effort_allocation.csv")
usethis::use_data(Effort_Allocation, overwrite = TRUE)

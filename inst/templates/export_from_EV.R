# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# May 12, 2022
# J. Holden

# What it does ----
# This script provides example code to run a batch export of the EV data
# using a custom export function from erieacoustics

# How to use ----
# This script provides a template for batch exporting transect data
# from Echoview.
# 1. Ensure that data has been processed with a supported template
# 2. Ensure that data has been inspected and region definitions have been drawn in EV
# 3. Ensure that your EV dongle is in and you have a license for scripting
# a single transect export can be done like:
# export_transect_evdata(getwd(), "EB_S15_G760", 500)
# the `getwd()` call is required as Echoview doesn't recognize relative paths from R

# ----
library(erieacoustics)
transects <- dir("3_Ping_Data")
export_all <- function(x) {export_transect_evdata(getwd(), x, 500)}

lapply(transects, export_all)

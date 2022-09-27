# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# September 27, 2022
# M. DuFour

# What it does ----
# This script runs the aggregate_format_data() function

# How to use ----
# 1. Ensure that data has been processed and scrutinized
# 2. Ensure that transect level data has been exported using '2_export_data_from_EV'
# the `getwd()` call is required as Echoview doesn't recognize relative paths from R

# ----
library(erieacoustics)
aggregate_format_data(getwd())


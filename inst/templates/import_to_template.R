# Meta data ----
# A template analysis file from erieacoustics
# Version 0.0.1
# May 12, 2022
# J. Holden

# How to use ----
# 1. Make sure you have followed previous steps included in the instructions,
# specifically - created an ecs calibration file and updated the EV template
# to include the new ecs file
# 2. ensure that you've edited the TRANSDUCER to match the file types
# TRANSDUCER is passed to erieacoustics::set_up_transect() so that the function
# can determine whether to import .raw or .dt4 files
# Note: the following work flow assumes all transects were collected using the same
# acoustics system. If the survey transects contain a mix of Biosonics and Simrad
# transducers you will have to split run them in different batches to account
# for a) they require different EV templates; and
# b) the file types differ (i.e. set_up_transect expects *.dt4
# files when TRANSDUCER == BIOSONIC)
# 3. Edit templatefile to reflect the template you intend to use

# Edit these variables ----
sonartype <- 'SIMRAD' # 'SIMRAD' or 'BIOSONIC'
templatefile <- '2_EVTemplate/ErieHacTemplate_2021_v2_simrad.EV' # path to template
calfile <- file.path(getwd(), '2_EVTemplate/calibrationfile.ecs')

# Start the import process ----
# the following code assumes you want to run all transects together as a batch
# see ?set_up_transect for documentation if you want to only run 1 at time

library(erieacoustics)

evtemplate <- file.path(getwd(), templatefile)
dir.exists('3_Ping_Data')
file.exists(evtemplate)
transects <- dir('3_Ping_Data')

# run all ----
# WARNING - this could take a while
run_all <- function(x) {set_up_transect(evtemplate, calfile, getwd(), sonartype, x)}
lapply(transects, run_all)

# end of R process
# go edit data in EV

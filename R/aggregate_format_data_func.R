#' Aggregate and format transect summary data
#'
#' @description Provides code to import, aggregate, and format integration
#' and target strength data from hydroacoustic survey.
#' @param projecthome A file path to the project directory. Generally, when working in an
#' @return The function will export three .csv files with data summarized by
#' BASIN, STRATUM, GRID, LAYER (epilimnion vs. hypolimnion region), and interval format.
#' 'hacdat.csv' includes  integration, mean target strength, and fish density estimates.
#' 'histo.csv' includes single target counts for 0.5 dB target strength bins ranging
#' from -64.5 to -20.5 dB. 'histohac.csv' merges 'hacdat' and 'histo' together.
#' @export
#' @examples
#' \dontrun{
#'}

aggregate_format_data <- function(projecthome) {

require(readr)
require(dplyr)
require(tidyr)

  ## Gather a list of all files from /3_Ping_Data directory
  allfiles<-dir('3_Ping_Data', recursive = T, full.names = T)

  ## Import and bind together integration data
  intg<-grep(allfiles, pattern = "intg\\.csv$", value = T)
  intg<-bind_rows(lapply(intg, read_csv))
  intg<-intg %>% filter(!(is.na(Region_name)))

  ## Import and bind together target strength data
  ts<-grep(allfiles, pattern = "ts\\.csv$", value = T)
  ts<-bind_rows(lapply(ts, read_csv))

  ## Merge/join integration and target strength data
  hacdat <- left_join(intg, ts, by=c('Region_name', 'Interval', 'Date_M', 'Time_M'))

  ## remove intervals less than 375 m - typically shorts segment collected beyond specified 5 km transect
  hacdat$IntDist <- hacdat$Dist_E.x-hacdat$Dist_S.x
  hacdat <- filter(hacdat, IntDist >= 375)

  ## Split Region_name into distinct basin, STRATUM, GRID, and LAYER for hacdat
  hacdat$BASIN <- sapply(strsplit(hacdat$Region_name, "_"), '[', 1)
  hacdat$STRATUM <- sapply(strsplit(hacdat$Region_name, "_"), '[',2)
  hacdat$GRID <- sapply(strsplit(hacdat$Region_name, "_"), '[',3)
  hacdat$LAYER <- sapply(strsplit(hacdat$Region_name, "_"), '[',4)

  ## replace missing TS values with average TS from INTERVALS within same TRANSECT and LAYER
  hacdat$sigma_bs <- 10^(hacdat$TS_mean/10) # create sigma_bs
  hacdat$sigma_bs <- ifelse(hacdat$TS_mean == 9999, NA,  hacdat$sigma_bs) # assign NAs
  ## impute missing sigma_bs_adj data - replace missing and Nv flagged sigma_bs values with mean of interval
  impute.mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))
  hacdat <- plyr::ddply(hacdat, ~ STRATUM + GRID + LAYER, transform, sigma_bs = impute.mean(sigma_bs))
  hacdat$TS_mean <- 10*log10(hacdat$sigma_bs) # convert sigma_bs back to TS_mean using imputed values

  ## Calculate fish density:
  ## volume back scattering coefficient divided by backscattering cross-section = fish/cubic meter
  ## multiply by thickness (m) and 10,000 turns this into areal density (fish/hectare)
  #hacdat$NperHa <- with(hacdat, (10^(Sv_mean/10))/(10^(TS_mean/10))*Thickness_mean.x*10000)
  ## Exporting and using ABC
  hacdat$NperHa <- with(hacdat, (PRC_ABC/sigma_bs*10000)) # PRC_ is a region-based classification of ABC

  ## Reduce hacdat to essential columns
  hacdat <-hacdat %>% select(BASIN, STRATUM, GRID, LAYER, Interval, Date_M, Time_M, Lat_M.x, Lon_M.x,
                             Sv_mean, PRC_ABC, sigma_bs, TS_mean,Num_targets, NperHa, Exclude_below_line_depth_mean.x) %>%
    rename(Lat_M = Lat_M.x) %>% rename(Lon_M = Lon_M.x) %>%
    rename(BottomLine = Exclude_below_line_depth_mean.x)

  ## write hacdat data to file
  write.csv(hacdat, "7_Annual_Summary/hacdat.csv")





  ## Import and bind together target strength histogram data
  histo<-grep(allfiles, pattern = "histo\\.csv$", value = T)
  histo<-bind_rows(lapply(histo, read_csv)) ## column 114 is NA

  ## Split Region_name into distinct STRATUM, TRANSECT, and LAYER for histo
  histo$BASIN <- sapply(strsplit(histo$Region_name, "_"), '[',1)
  histo$STRATUM <- sapply(strsplit(histo$Region_name, "_"), '[',2)
  histo$GRID <- sapply(strsplit(histo$Region_name, "_"), '[',3)
  histo$LAYER <- sapply(strsplit(histo$Region_name, "_"), '[',4)

  ## Reduce histo to essential columns and transform to long form
  ## TS columns to rows with replicated data
  histo <- histo %>% select(BASIN, STRATUM, GRID, LAYER, Date_M, Time_M, Lat_M, Lon_M, Interval,
                            Targets_Binned, `-64.500000`:`-20.500000`) %>%
    gather(TS, N_Targets, `-64.500000`:`-20.500000`) %>%
    mutate(TS = as.numeric(TS))

  ## write histo data to file
  write.csv(histo, "7_Annual_Summary/histo.csv")





  ## Merge hacdat and histo data together
  histohac<-left_join(hacdat, histo, by = c("BASIN","STRATUM", "GRID", "LAYER", "Interval", "Date_M", "Time_M"))

  ## write histohac data to file
  write.csv(histohac, "7_Annual_Summary/histohac.csv")

}



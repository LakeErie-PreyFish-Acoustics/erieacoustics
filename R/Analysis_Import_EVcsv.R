#' Import Echoview Analysis Exports
#'
#' @return a list with intg, ts and histo data
#' @export
#'
#' @examples
#' \dontrun{
#' library(erieacoustics)
#' hacdat <- Analysis_Import_EVcsv()
#'  }
Analysis_Import_EVcsv <- function(){
  # check "3_Ping_Data" directory exists
  if(!dir.exists("3_Ping_Data")){
    usethis::ui_oops("Can't find '/3_Ping_Data' directory.")
    stop("Directory format not valid.")
  }

  # read all files
  allfiles<-dir("3_Ping_Data", recursive = T, full.names = T)
  # get only the intg.csv
  intg<-grep(allfiles, pattern = "intg\\.csv$", value = T)
  # ts.csv
  ts<-grep(allfiles, pattern = "ts\\.csv$", value = T)
  # histo.csv
  histo<-grep(allfiles, pattern = "histo\\.csv$", value = T)

  # check that intg, ts and histo has length >0
  if(length(intg)==0){
    usethis::ui_oops("Expecting to find intg.csv files and found none.")
  }
  if(length(ts)==0){
    usethis::ui_oops("Expecting to find ts.csv files and found none.")
  }
  if(length(histo)==0){
    usethis::ui_oops("Expecting to find histo.csv files and found none.")
  }

  # read in all csv files and combine as single df
  intg<-dplyr::bind_rows(lapply(intg, readr::read_csv))
  ts<-dplyr::bind_rows(lapply(ts, readr::read_csv))
  histo<-dplyr::bind_rows(lapply(histo, readr::read_csv))

  # store and return as a list
  hacdat <- list(intg = intg, ts = ts, histo = histo)
  hacdat
}

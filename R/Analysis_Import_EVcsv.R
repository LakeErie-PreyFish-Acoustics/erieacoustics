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
  # read all files
  allfiles<-dir("3_Ping_Data", recursive = T, full.names = T)
  # get only the intg.csv
  intg<-grep(allfiles, pattern = "intg\\.csv$", value = T)
  # ts.csv
  ts<-grep(allfiles, pattern = "ts\\.csv$", value = T)
  # histo.csv
  histo<-grep(allfiles, pattern = "histo\\.csv$", value = T)

  # read in all csv files and combine as single df
  intg<-bind_rows(lapply(intg, readr::read_csv))
  ts<-bind_rows(lapply(ts, readr::read_csv))
  histo<-bind_rows(lapply(histo, readr::read_csv))

  # store and return as a list
  hacdat <- list(intg, ts, histo)
  hacdat
}

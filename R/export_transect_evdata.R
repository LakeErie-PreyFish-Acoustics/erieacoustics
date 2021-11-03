#' Export Echoview transect data
#'
#' @description Provides a series of COM commands to set export parameters and then export
#' the required analysis files.
#' @param prjdir
#' @param transectname
#' @param horizbin
#'
#' @return The function will attempt to return a cruise track (`gps.csv`), a copy of the
#' edited epi line in the Echoview format (`EpiLayerLine_Edited.evl`) and as a csv
#' (`EpiLayerLine_Final.csv`)
#' @export
#'
#' @examples
#' \dontrun{
#' library(erieacoustics)
#' # export_transect(getwd(), "R21_S22", 800)
#'}

export_transect <- function(prjdir, transectname, horizbin) {
  require(RDCOMClient)

  transect_dir<-file.path(prjdir, "Pings", transectname)
  EVFile2Open<-file.path(transect_dir, paste(transectname, ".EV", sep=""))
  if(!file.exists(EVFile2Open)) {
    usethis::ui_oops(paste(EVFile2Open, " does not exist",sep=""))
    stop("Check file name or arguments")
  }

  # Open the COM connection
  EVAppObj <- RDCOMClient::COMCreate('EchoviewCom.EvApplication')
  EVFile<-EVAppObj$OpenFile(EVFile2Open)

  # Export Cruise Track
  GPS<-EVFile[["Variables"]]$FindByName("Fileset1: position GPS fixes")
  if(GPS$ExportData(file.path(transect_dir, 'gps.csv'))) {
    usethis::ui_done("GPS track exported")
  } else {
    usethis::ui_oops("GPS fileset not found. gps.csv not created")
  }

  # Export Edited Epi Line
  epiline<-EVFile[['Lines']]$FindByName('Epi Layer Max Smoothed MEAN span gaps_Editable')

  ## exit function if epi line can't be found, else, export it.
  if(is.null(epiline)) {
    EVAppObj$Quit()
    usethis::ui_stop("Epi line could not be found. This is probably bad. COM has been terminated.")
    } else {
    epiline$Export(file.path(transect_dir, 'EpiLayerLine_Edited.evl'))
    EchoviewR::EVExportLineAsCSV(EVFile, "ExportSv",
                                 "Epi Layer Max Smoothed MEAN span gaps_Editable",
                                 file.path(transect_dir, 'EpiLayerLine_Final.csv'))
    usethis::ui_done("Epi line exported.")
    }

  # Ensure certain variable are activated
  EVExport<-EVFile[["Properties"]][['Export']]
  EVExport[['EmptyCells']]<-TRUE
  EVExport[['EmptySingleTargetPings']]<-TRUE

  # Set Sv grid based on horizbin input
  FinalSv<-EVFile[["Variables"]]$FindByName("ExportSv")
  FinalSv_propGrid<-FinalSv[['Properties']][['Grid']]
  FinalSv_propGrid$SetDepthRangeGrid(1, 200) # 200 is used to ensure cell is entire depth
  # of the water column is in a single cell, this does not necessarily have to be the case
  FinalSv_propGrid$SetTimeDistanceGrid(5, horizbin) # horizbin defined by user input

  # Set/confirm common export settings
  # should Sv properties be set here in case the template values were changed?

  # Export Sv in Regions by Cell
  if(FinalSv$ExportIntegrationByRegionsByCellsAll(file.path(transect_dir, 'intg.csv'))){
    usethis::ui_done("Sv by Regions by Cell Exported as intg.csv")
  } else {ui_oops("Something went wrong, Sv not exported.")}

  # Repeat above for TS
  FinalTS <- EVFile[["Variables"]]$FindByName('ExportSingleTargets')
  SinTar_propGrid<-FinalTS[['Properties']][['Grid']]
  SinTar_propGrid$SetDepthRangeGrid(1, 200)
  SinTar_propGrid$SetTimeDistanceGrid(5, horizbin)


  if(FinalTS$ExportSingleTargetsByRegionsByCellsAll(file.path(transect_dir, 'ts.csv'))){
    usethis::ui_done("TS by Regions by Cell Exported as ts.csv")
  } else {ui_oops("Something went wrong, TS not exported.")}

  # And for histo
  if(FinalTS$ExportFrequencyDistributionByRegionsByCellsAll(file.path(
    transect_dir, 'histo.csv'))) {
    usethis::ui_done("TS distribution by Regions by Cell Exported as histo.csv")
  } else {ui_oops("Something went wrong, histo not exported.")}

  # Save and Close
  EVFile$Save()
  EVFile$Close()
  on.exit(EVAppObj$Quit())
}




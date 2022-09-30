#' Export Echoview transect data
#'
#' @description Provides a series of COM commands to set export parameters and then export
#' the required analysis files.
#' @param projecthome A file path to the project directory. Generally, when working in an
#' RStudio project environment you can populate this field using `getwd()`
#' @param transectname Transect name to be exported. Function expects the transect
#' name to correspond with a transect folder located in the *Pings* directory
#' @param horizbin Size of the horizontal grid (in meters) to be applied for the analysis cells
#'
#' @return The function will attempt to return a cruise track (`gps.csv`), a copy of the
#' edited epi line in the Echoview format (`EpiLayerLine_Edited.evl`) and as a csv
#' (`EpiLayerLine_Final.csv`)
#' @export
#'
#' @examples
#' \dontrun{
#' library(erieacoustics)
#' export_transect_evdata(getwd(), "R21_S22", 800)
#'}

export_transect_evdata <- function(projecthome, transectname, horizbin) {
  require(RDCOMClient)

  transect_dir<-file.path(projecthome, "3_Ping_data", transectname)
  EVFile2Open<-file.path(transect_dir, paste(transectname, ".EV", sep=""))
  if(!file.exists(EVFile2Open)) {
    usethis::ui_oops(paste(EVFile2Open, " does not exist",sep=""))
    stop("Check file name or arguments")
  }

  # Open the COM connection
  EVAppObj <- RDCOMClient::COMCreate('EchoviewCom.EvApplication')
  EVFile<-EVAppObj$OpenFile(EVFile2Open)

  # Export Cruise Track
  gps_success <- FALSE
  GPS<-EVFile[["Variables"]]$FindByName("Fileset1: position GPS fixes")
  if(!is.null(GPS)) {
    gps_success <- GPS$ExportData(file.path(transect_dir, 'gps.csv'))
    }

  if(!gps_success) {
    GPS<-EVFile[["Variables"]]$FindByName("Fileset1: position GPS fixes (1)")
    if(!is.null(GPS)) {
      gps_success <- GPS$ExportData(file.path(transect_dir, 'gps.csv'))
      }
    }

  if(is.null(GPS)) {usethis::ui_oops("GPS file could not be found. gps.csv not created.")}
  if(gps_success){
    usethis::ui_done("GPS fixes exported as gps.csv")
  } else {
    usethis::ui_oops("GPS fixes could not be exported.")
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


  # Export Detected Bottom Line
  botline<-EVFile[['Lines']]$FindByName('DetectedBottom')

  ## exit function if bottom line can't be found, else, export it.
  if(is.null(botline)) {
    EVAppObj$Quit()
    usethis::ui_stop("Bottom line could not be found. This is probably bad. COM has been terminated.")
  } else {
    botline$Export(file.path(transect_dir, 'BottomLine_Detected.evl'))
    EchoviewR::EVExportLineAsCSV(EVFile, "ExportSv",
                                 "DetectedBottom",
                                 file.path(transect_dir, 'BottomLine_Final.csv'))
    usethis::ui_done("Bottom line exported.")
  }

  # Ensure certain variable are activated
  EVExport<-EVFile[["Properties"]][['Export']]
  EVExport[['EmptyCells']]<-TRUE
  EVExport[['EmptySingleTargetPings']]<-TRUE
  #EVExport[["IntegrationResults"]][["ABC"]]<-TRUE



  ## Set Var for line relative regions
  Var = EVFile[['Variables']]$FindByName('ExportSv')

  ## delete analysis regions from previous export
  test.number.of.regions = EVFile[['Regions']]$Count()
  if(test.number.of.regions == 0) {usethis::ui_done("There were no previously created analysis regions") } else {
     number.of.regions = EVFile[['Regions']]$Count()
    for (i in 1:number.of.regions){
      RegionObject = EVFile[['Regions']]$Item(number.of.regions-i)
      if(RegionObject$RegionType() == 1){ # All region types = -1; bad = 0; analysis = 1; marker = 2; bad data empty water = 4
        EVFile[['Regions']]$Delete(RegionObject)
      }
      rm(RegionObject)
    }
    usethis::ui_done("Previously created analysis regions have been deleted.")
  }


  ## Create line relative region - Epilimnion
  TopLine = EVFile[['Lines']]$FindByName('SurfaceExclusion') # set top line
  BottomLine = EVFile[['Lines']]$FindByName('Epi Layer Max Smoothed MEAN span gaps_Editable') # set bottom line
  NewRegion = Var$CreateLineRelativeRegion(paste0(basename(transectname),'_EPI'),TopLine,BottomLine,-1,-1) # create line relative region
  EpiClassObj = EVFile[['RegionClasses']]$FindByName('Epilimnion') # object for the class you want the region to have
  NewRegion[['RegionClass']] = EpiClassObj # change the region’s class to the desired one
  NewRegion[['RegionClass']]$Name() # check what class is now assigned to the region
  NewRegion[['RegionType']] = 1 # assign region type = 'Analysis' (1)

  ## Create line relative region - Hypolimnion
  TopLine = EVFile[['Lines']]$FindByName('Epi Layer Max Smoothed MEAN span gaps_Editable') # set top line
  BottomLine = EVFile[['Lines']]$FindByName('EchogramFloor') # set bottom line
  NewRegion = Var$CreateLineRelativeRegion(paste0(basename(transectname),'_HYP'),TopLine,BottomLine,-1,-1) # create line relative region
  HypoClassObj = EVFile[['RegionClasses']]$FindByName('Hypolimnion') # object for the class you want the region to have
  NewRegion[['RegionClass']] = HypoClassObj # change the region’s class to the desired one
  NewRegion[['RegionClass']]$Name() # check what class is now assigned to the region
  NewRegion[['RegionType']] = 1 # assign region type = 'Analysis' (1)


  # Check for analysis regions
  region_count <- EVFile[["Regions"]]$Count()
  if(region_count == 0) {
    EVAppObj$Quit()
    usethis::ui_oops("Are you sure you are ready to export this transect?")
    usethis::ui_stop("There are no regions defined")
  }

  region_index <- c(0:(region_count-1))

  check_region_type <- function(index_value) {
    region <- EVFile[["Regions"]]$Item(index_value)
    region$RegionType() == 1 # 1 is EV's enum value for Analysis Regions
  }

  has_analysis_region <- any(sapply(region_index, check_region_type))
  if(!(has_analysis_region)) {
    EVAppObj$Quit()
    usethis::ui_oops("Are you sure you are ready to export this transect?")
    usethis::ui_stop("No analysis regions found")
  }

  # Export region definitions
  EVRegions <- EVFile[["Regions"]]
  region_success <- EVRegions$ExportDefinitionsAll(
    file.path(transect_dir, 'Region_Definitions.evr')
    )

  if(region_success) {usethis::ui_done("Region definitions exported.")}


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
  } else {usethis::ui_oops("Something went wrong, TS not exported.")}

  # And for histo
  if(FinalTS$ExportFrequencyDistributionByRegionsByCellsAll(file.path(
    transect_dir, 'histo.csv'))) {
    usethis::ui_done("TS distribution by Regions by Cell Exported as histo.csv")
  } else {usethis::ui_oops("Something went wrong, histo not exported.")}


  # Export processed Sv ('ExportSv') as .png image
  ExportSvVar <- EVFile[['Variables']]$FindByName('ExportSv')                                         ## find and define variable to be exported
  ExportSvVar_propGrid<-ExportSvVar[['Properties']][['Grid']]
  ExportSvVar_propGrid$SetDepthRangeGrid(1, 200)
  ExportSvVar_propGrid$SetTimeDistanceGrid(5, horizbin)
  image.file.name <- paste0(basename(transectname),'_final','.png') ## define image file name

  if(ExportSvVar$ExportEchogramToImage(file.path(transect_dir,image.file.name,fsep='\\'),2000,-1,-1)) {
    usethis::ui_done("Transect image as .png")
  } else {usethis::ui_oops("Something went wrong, image not exported.")} ## export to transect_dir folder





  # Save and Close
  done_message1 <- paste0("Export script for ", transectname, " has completed.")
  done_message2 <- paste0("Files are saved in ", transect_dir)
  EVFile$Save()
  EVFile$Close()
  if(EVAppObj$Quit()){
    usethis::ui_done(done_message1)
    usethis::ui_done(done_message2)
  }
}




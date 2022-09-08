

#' Automate the setup of a template
#'
#' @param template A file path to an Echoview template
#' @param projecthome A file path to the project directory. Generally, when working in an
#' RStudio project environment you can populate this field using `getwd()`
#' @param sonartype The function uses a text pattern matching to find acoustic data files.
#' Function expects an input of *BIOSONIC* or *SIMRAD* to detect \*.dt4 or \*.raw
#' file types.
#' @param tranname Transect name that matches a valid directory in *3_Ping_Data/* directory
#'
#' @description This function calls RDCOMClient to establish a COM application for Echoview.
#' This function is primarily a wrapper for functions found in EchoviewR
#' (https://github.com/AustralianAntarcticDivision/EchoviewR) applied to files stored
#' in an expected file path.
#'
#' @importFrom RDCOMClient COMCreate
#' @importFrom RDCOMClient createCOMReference
#' @import RDCOMClient
#' @return
#' @export
#'
#'
#' @examples
#' \dontrun{
#'library(erieacoustics)
#'evtemplate <- file.path(getwd(), '2_EVTemplate/EVTemplate.EV')
#'dir.exists("3_Ping_Data")
#'file.exists(evtemplate)
#'
#'set_up_transect(evtemplate, projecthome = getwd(),
#'                sonartype = "SIMRAD", tranname = "ERIE")
#'set_up_transect(evtemplate, projecthome = getwd(),
#'              sonartype = "BIOSONIC", tranname = "COB")
#'}
#'

set_up_transect<-function (template, projecthome, sonartype, tranname) {
  if(!file.exists(template)) {
    usethis::ui_oops("It appears as though your template doesn't exist")
  }

  sonartype <- toupper(sonartype)
  if(!(sonartype %in% c("BIOSONIC", "SIMRAD"))){
    usethis::ui_oops("Not a valid sounder type. Please specify BIOSONIC or SIMRAD")

  }

  stopifnot(exprs = {
    file.exists(template)
    sonartype %in% c("BIOSONIC", "SIMRAD")
    })

  sonarfilepattern <- ifelse(sonartype == "BIOSONIC", "dt4$", "raw$")

  requireNamespace("RDCOMClient")
  library(RDCOMClient)
  # launch EV
  EvApp <-  RDCOMClient::COMCreate('EchoviewCom.EvApplication')
  # New file using template
  EvFile <- EvApp$NewFile(template)

  # get then load dt4 files
  dt4_dir<-file.path(projecthome, "3_Ping_Data", tranname)
  files_all<-dir(dt4_dir, full.names = T)
  dt4<-grep(files_all, pattern = sonarfilepattern, value = T)

  if(length(dt4) == 0) {
    EvFile$Close()
    EvApp$Quit()
    usethis::ui_oops("No valid acoustic formats found")
    stop(paste('no dt4 files found in', tranname, sep = ' '))
  }

  EchoviewR::EVAddRawData(EvFile, 'Fileset1', dt4)

  # Save
  evfilename<- paste(tranname, ".EV", sep = '')
  #message(evfilename)
  evfilefull<-file.path(dt4_dir, evfilename)
  #message(evfilefull)
  EvFile$SaveAs(evfilefull)

  # Copy virtual lines to editable lines
  EchoviewR::EVCreateEditableLine(EVFile = EvFile,
                       lineNameToCopy='CombineSurfaceLines',
                       editableLineName='SurfaceExclusion_Editable')

  EchoviewR::EVCreateEditableLine(EVFile = EvFile,
                       lineNameToCopy='Bottom_Backstep Smoothed',
                       editableLineName='BottomExclusion_Editable')

  EchoviewR::EVCreateEditableLine(EVFile = EvFile,
                       lineNameToCopy='Epi Layer',
                       editableLineName='Epi Layer_Editable')

  EchoviewR::EVCreateEditableLine(EVFile = EvFile,
                       lineNameToCopy='Epi Layer Max Smoothed MEAN span gaps',
                       editableLineName='Epi Layer Max Smoothed MEAN span gaps_Editable')



  # Export processed Sv ('ExportSv') as .png image
  ExportSvVar = EvFile[['Variables']]$FindByName('ExportSv')                                ## find and define variable to be exported
  image.file.name = paste0(basename(tranname),'_initial','.png')                                       ## define image file name
  ExportSvVar$ExportEchogramToImage(file.path(dt4_dir,image.file.name,fsep='\\'),2000,-1,-1) ## export to dt4_dir folder


   # save again
  EvFile$Save()

  # Close and quit
  EvFile$Close()
  EvApp$Quit()
  usethis::ui_done(paste(tranname, 'has been completed'))
  # end
}

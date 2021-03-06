#' Finish erieacoustic project setup
#' @description Several of the analysis procedures rely on custom functions. Rather than a
#' vignette approach, this function copies template analysis scripts that establish a workflow
#' based on the existing package functions. The template files are "auto-magically" created
#' following the project naming procedures and directories.
#' @return
#' @export
#'
#' @examples
#' finish_setup()
finish_setup <- function(){

  has_folder <-dir.exists("7_Annual_Summary")
  does_exist <- file.exists("7_Annual_Summary/1_import_data_to_template.R")

  if(!has_folder){
    usethis::ui_oops("7_Annual_Summary should exist in an Erie Acoustic project")
  }

  if(does_exist){
    usethis::ui_oops("Continuing would have replaced an existing file")
  }

  all_tests <- c(all(has_folder, !does_exist))
  if(!all_tests){
    usethis::ui_oops("Set up was not completed.")
  }

  if(all_tests){
  usethis::use_template(
    template = "import_to_template.R",
    save_as = "7_Annual_Summary/1_import_data_to_template.R",
    package = "erieacoustics"
  )
    usethis::use_template(
      template = "export_from_EV.R",
      save_as = "7_Annual_Summary/2_export_data_from_EV.R",
      package = "erieacoustics"
    )
  }

  usethis::use_template(
    template = "calibration_reference.Rmd",
    save_as = "6_Misc/Calibration_Instructions_Notes.Rmd",
    package = "erieacoustics"
  )

  rmarkdown::render("6_Misc/Calibration_Instructions_Notes.Rmd")
  rmarkdown::render("ReadMe.md")

  usethis::ui_done("ReadMe file rendered to html")
  usethis::ui_done("`1_import_data_to_template.R` file created in `7_Annual_Summary`")
  usethis::ui_done("Calibration help file created.")
}

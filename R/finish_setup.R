#' Finish erieacoustic project setup
#' @description Several of the analysis procedures rely on custom functions. Rather than a
#' vignette approach, this function copies template analysis scripts that establish a workflow
#' based on the existing package functions. The template files are "auto-magically" created
#' following the project naming procedures and directories.
#' @return NULL
#' @export
#'
#' @examples
#' finish_setup()
finish_setup <- function() {
  has_folder <- dir.exists("7_Annual_Summary")
  does_exist <- file.exists("7_Annual_Summary/1_import_data_to_template.R")

  if (!has_folder) {
    usethis::ui_oops("7_Annual_Summary should exist in an Erie Acoustic project")
  }

  if (does_exist) {
    usethis::ui_oops("Continuing would have replaced an existing file")
  }

  all_tests <- c(all(has_folder, !does_exist))
  if (!all_tests) {
    usethis::ui_oops("Set up was not completed.")
  }

  if (all_tests) {
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

  usethis::use_template(
    template = "sample_grids_select.R",
    save_as = "1_Annual_Protocol/1_Select_Sample_Grids.R",
    package = "erieacoustics"
  )

  usethis::use_template(
    template = "annual_survey_template.Rmd",
    save_as = "1_Annual_Protocol/2_Project_Proposal_Summary.Rmd",
    package = "erieacoustics"
  )

  usethis::use_template(
    template = "annual_summary_template.Rmd",
    save_as = "7_Annual_Summary/6_Annual_Summary.Rmd",
    package = "erieacoustics"
  )

  rmarkdown::render("6_Misc/Calibration_Instructions_Notes.Rmd")
  rmarkdown::render("ReadMe.md")

  usethis::ui_done("ReadMe file rendered to html")
  usethis::ui_done("`1_import_data_to_template.R` file created in `7_Annual_Summary`")
  usethis::ui_done("Calibration help file created.")

  usethis::use_template(
    template = "aggregate_format_hydro_data.R",
    save_as = "7_Annual_Summary/3_aggregate_format_hydro_data.R",
    package = "erieacoustics"
  )

  usethis::use_template(
    template = "aggregate_format_wcp_data.R",
    save_as = "7_Annual_Summary/4_aggregate_format_wcp_data.R",
    package = "erieacoustics"
  )

  usethis::use_template(
    template = "aggregate_format_trawl_data.R",
    save_as = "7_Annual_Summary/5_aggregate_format_trawl_data.R",
    package = "erieacoustics"
  )

  if (!file.exists("Water_Column_Profiles.csv has been created")) {
    WC <- c(
      "month", "day", "year", "time", "GRID", "depth_m",
      "do_mgl", "temp_c", "lattitude", "longitude"
    )

    write.table(t(WC),
      file = "5_Enviro_Data/Water_Column_Profiles.csv",
      row.names = F, col.names = F, sep = ","
    )
    usethis::ui_line("Water_Column_Profiles.csv has been created")
  }

  if (!file.exists("4_Trawl_Data/Trawl_Effort.csv")) {
    TE <- c(
      "STRATUM", "PRJ_CD", "DATE", "month", "day", "year", "SAM",
      "GRID_10M", "TD", "GR", "LatDec", "LonDec", "LatDec2", "LonDec2",
      "SITEM", "GRTEM", "XO2", "XO2%", "SIDEP", "GRDEP", "EFFTM0B",
      "EFFTM0", "EFFTM1B", "EFFTM1", "EFFDUR", "EFFDST", "XTOTDST",
      "SPEED", "EFFST", "COMMENT1"
    )
    write.table(t(TE),
      file = "4_Trawl_Data/Trawl_Effort.csv",
      row.names = F, col.names = F, sep = ","
    )
    usethis::ui_line("Trawl_Effort.csv has been created")
  }

  if (!file.exists("4_Trawl_Data/Trawl_Catch.csv")) {
    TC <- c("DATE", "month", "day", "year", "SAM", "SPC", "GRP", "CATCNT")

    write.table(t(TC),
      file = "4_Trawl_Data/Trawl_Catch.csv",
      row.names = F, col.names = F, sep = ","
    )

    usethis::ui_line("Trawl_Catch.csv has been created")
  }

  if (!file.exists("4_Trawl_Data/Trawl_Length.csv")) {
    TL <- c("DATE", "month", "day", "year", "SAM", "SPC", "GRP", "TLEN")
    write.table(t(TL),
      file = "4_Trawl_Data/Trawl_Length.csv",
      row.names = F, col.names = F, sep = ","
    )
    usethis::ui_line("Trawl_Length.csv has been created")
  }
}

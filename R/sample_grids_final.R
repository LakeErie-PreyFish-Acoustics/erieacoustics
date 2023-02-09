#' Finalize sample grids
#'
#' @param basin specify the basin (ex. EB, CB or WB)
#' @param year intended survey year
#'
#' @description This function creates final survey may pulling
#' from sample_grids_final.csv.
#' @return sample_grids_final.png
#' @export
#'
#' @examples
#' \dontrun{
#' sample_grids_final("WB",2022)
#'  }
sample_grids_final <- function(basin, year) {
  ## ensure required packages are installed
  ## if not - print error message
  pck_list <-
    c('eriespatial',
      'magrittr',
      'dplyr',
      'sf',
      'base',
      'readr',
      'ggplot2')

  is_installed <- pck_list %in% installed.packages()
  if (!all(is_installed)) {
    missing <- pck_list[!is_installed]
    stop(paste0(
      "\nuse install.packages(",
      missing,
      ") to install ",
      missing,
      " package"
    ))
  }

  ## load packages
  library(eriespatial)
  library(magrittr)
  library(dplyr)
  library(sf)
  library(base)
  library(readr)
  library(ggplot2)

  ## subset survey grid shape file
  shape_5mingrid_surv_sub <-
    eriespatial::shape_5mingrid_surv %>% dplyr::filter(BASIN == basin)

  ## if sample_grids_final.csv does not exist - print error message
  ## otherwise read in sample_grids_final.csv
  file <- "1_Annual_Protocol/sample_grids_final.csv"

  if (file.exists(file)) {
    sample_grids_final <- readr::read_csv(file) %>%
      sf::st_as_sf(coords = c("Longitude", "Latitude"),
                   crs = 4326)
    base::print("sample_grids_final.csv loaded successfully")
  } else {
    base::print("sample_grids_final.csv does not exist")
  }

  ## create X Y coordinate columns from geometry
  sample_grids_final$X <- sf::st_coordinates(sample_grids_final)[, 1]
  sample_grids_final$Y <- sf::st_coordinates(sample_grids_final)[, 2]

  ## basin specific shape and bounding box
  if (basin == "WB") {
    bound_box <-
      c(
        xmin = -83.550,
        ymin = 41.3494,
        xmax = -82.450,
        ymax = 42.1053
      )
    bounds <-
      bound_box %>% sf::st_bbox() %>% sf::st_as_sfc() %>% sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_wbstrata
  } else if (basin == "CB") {
    bound_box <-
      c(
        xmin = -82.4,
        ymin = 41.363,
        xmax = -80.4,
        ymax = 42.7205
      )
    bounds <-
      bound_box %>% sf::st_bbox() %>% sf::st_as_sfc() %>% sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_cbstrata
  } else if (basin == "EB") {
    bound_box <-
      c(
        xmin = -80.5,
        ymin = 42.1,
        xmax = -78.85,
        ymax = 42.9
      )
    bounds <-
      bound_box %>% sf::st_bbox() %>% sf::st_as_sfc() %>% sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_ebstrata
  } else {
    base::print("Check basin name")
  }


  ## create final survey map
  group.colors <- c(Extra = "red", Survey = "black")

  p1 <- eriespatial::base_erieshore +
    ggplot2::scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"])) +
    ggplot2::scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"])) +
    ggplot2::geom_sf(
      data = shape_5mingrid_surv_sub,
      col = "lightgray",
      fill = NA,
      lwd = 0.5,
      alpha = 0.5
    ) +
    ggplot2::geom_sf(data = basin_shape, aes(fill = STRATUM, alpha = 0.5)) +
    ggplot2::scale_fill_viridis_d(alpha = 0.5) +
    ggplot2::guides(alpha = "none") +
    ggplot2::geom_sf(data = sample_grids_final, aes(color = Priority), pch = 16) +
    ggplot2::geom_text(
      data = sample_grids_final,
      aes(label = Grid, x = X, y = Y),
      nudge_x = 0,
      nudge_y = 0.025,
      size = 2.5
    ) +
    ggplot2::ylab("Latitude (dd)") + xlab("Longitude (dd)") +
    ggplot2::labs(title = paste("Final sample grids", year)) +
    ggplot2::scale_color_manual(values = group.colors) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = c("right"))

  base::print(p1)


  ## write sample_grids_final.png to file
  ## note success and if previous file was overwritten
  file <- "1_Annual_Protocol/sample_grids_final.png"

  if (file.exists(file)) {
    ggplot2::ggsave(file,
                    plot = p1,
                    width = 6.5,
                    height = 4.25)
    base::print("previous sample_grids_final.png was overwritten")
  } else {
    ggplot2::ggsave(file,
                    plot = p1,
                    width = 6.5,
                    height = 4.25)
    base::print("sample_grids_final.png was written to file")
  }

}

#' Randomly generate proposed sample grids
#'
#' @param basin specify the basin (ex. EB, CB or WB)
#' @param year intended survey year
#'
#' @description This function randomly selects sample grids for each strata
#' based on effort allocation table.
#' @return sample_grids_proposed.png, sample_grids_proposed.csv,
#' and sample_grids_final.csv
#' @export
#'
#' @examples
#' \dontrun{
#' sample_grids_proposed("WB", 2022)
#' }
sample_grids_proposed <- function(basin, year) {
  ## ensure required packages are installed
  ## if not - print error message
  pck_list <- c("eriespatial", "magrittr", "dplyr", "sf", "base", "utils", "ggplot2", "gridExtra")

  is_installed <- pck_list %in% installed.packages()
  if (!all(is_installed)) {
    missing <- pck_list[!is_installed]
    stop(paste0("\nuse install.packages(", missing, ") to install ", missing, " package"))
  }

  ## load packages
  library(eriespatial)
  library(magrittr)
  library(dplyr)
  library(sf)
  library(base)
  library(utils)
  library(ggplot2)
  library(gridExtra)

  ## set seed as year
  set.seed(year)

  ## subset Effort_Allocation and shape_5mincent_surv to basin
  Effort_Allocation_sub <- erieacoustics::Effort_Allocation %>% dplyr::filter(BASIN == basin)
  shape_5mincent_surv_sub <- eriespatial::shape_5mincent_surv %>% dplyr::filter(BASIN == basin)
  shape_5mingrid_surv_sub <- eriespatial::shape_5mingrid_surv %>% dplyr::filter(BASIN == basin)

  ## create X Y coordinate columns from geometry
  shape_5mincent_surv_sub$X <- sf::st_coordinates(shape_5mincent_surv_sub)[, 1]
  shape_5mincent_surv_sub$Y <- sf::st_coordinates(shape_5mincent_surv_sub)[, 2]

  ## write all available sampled grids to file as .csv
  ## flag if previous file was overwritten
  file <- "1_Annual_Protocol/sample_grids_all.csv"

  if (file.exists(file)) {
    utils::write.csv(shape_5mincent_surv_sub, file)
    print("previous sample_grids_all.csv was overwritten")
  } else {
    utils::write.csv(shape_5mincent_surv_sub, file)
    print("sample_grids_all.csv was written to file")
  }

  ## randomly select centroids within strata based on Effort_Allocation
  strat <- base::unique(Effort_Allocation_sub$STRATUM)
  surv_cent <- NULL
  for (i in 1:length(strat)) {
    draws <- Effort_Allocation_sub[Effort_Allocation_sub$STRATUM == strat[i], ]$n_trans_eq
    cent <- shape_5mincent_surv_sub[shape_5mincent_surv_sub$STRATUM == strat[i], ]
    samp <- cent[base::sample(1:nrow(cent), draws), ]
    surv_cent <- base::rbind(surv_cent, samp)
  }

  ## create 'Priority' field
  surv_cent$Priority <- "'Survey or Extra'"

  ## create X Y coordinate columns from geometry
  surv_cent$X <- sf::st_coordinates(surv_cent)[, 1]
  surv_cent$Y <- sf::st_coordinates(surv_cent)[, 2]


  ## basin specific shape files and bounding box
  if (basin == "WB") {
    bound_box <- c(xmin = -83.550, ymin = 41.3494, xmax = -82.450, ymax = 42.1053)
    bounds <- bound_box %>%
      sf::st_bbox() %>%
      sf::st_as_sfc() %>%
      sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_wbstrata
  } else if (basin == "CB") {
    bound_box <- c(xmin = -82.4, ymin = 41.363, xmax = -80.4, ymax = 42.7205)
    bounds <- bound_box %>%
      sf::st_bbox() %>%
      sf::st_as_sfc() %>%
      sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_cbstrata
  } else if (basin == "EB") {
    bound_box <- c(xmin = -80.5, ymin = 42.1, xmax = -78.85, ymax = 42.9)
    bounds <- bound_box %>%
      sf::st_bbox() %>%
      sf::st_as_sfc() %>%
      sf::st_set_crs(4326)
    basin_shape <- eriespatial::shape_ebstrata
  } else {
    base::print("Check basin name")
  }

  ##  plot all available centroids
  p1 <- eriespatial::base_erieshore +
    ggplot2::scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"])) +
    ggplot2::scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"])) +
    ggplot2::geom_sf(data = shape_5mingrid_surv_sub, col = "lightgray", fill = NA, lwd = 0.5, alpha = 0.5) +
    ggplot2::geom_sf(data = basin_shape, aes(fill = STRATUM, alpha = 0.5)) +
    ggplot2::scale_fill_viridis_d(alpha = 0.5) +
    ggplot2::guides(alpha = "none") +
    ggplot2::geom_sf(data = shape_5mincent_surv_sub, color = "black", pch = 16) +
    ggplot2::geom_text(
      data = shape_5mincent_surv_sub, aes(label = GRID, x = X, y = Y),
      nudge_x = 0, nudge_y = 0.025, size = 2.0
    ) +
    ggplot2::ylab("Latitude (dd)") + xlab("Longitude (dd)") +
    ggplot2::labs(title = "Available sample grids") +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom")

  ## plot randomly selected centroids
  p2 <- eriespatial::base_erieshore +
    ggplot2::scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"])) +
    ggplot2::scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"])) +
    ggplot2::geom_sf(data = shape_5mingrid_surv_sub, col = "lightgray", fill = NA, lwd = 0.5, alpha = 0.5) +
    ggplot2::geom_sf(data = basin_shape, aes(fill = STRATUM, alpha = 0.5)) +
    ggplot2::scale_fill_viridis_d(alpha = 0.5) +
    ggplot2::guides(alpha = "none") +
    ggplot2::geom_sf(data = surv_cent, color = "black", pch = 16) +
    ggplot2::geom_text(
      data = surv_cent, aes(label = GRID, x = X, y = Y),
      nudge_x = 0, nudge_y = 0.025, size = 2.5
    ) +
    ggplot2::ylab("Latitude (dd)") + xlab("Longitude (dd)") +
    ggplot2::labs(title = "Randomly selected sample grids") +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom")

  ## combine two plots into one
  p12 <- gridExtra::grid.arrange(p1, p2, ncol = 2)

  ## save plot to file as .png
  ## flag if previous plot was overwritten
  file <- "1_Annual_Protocol/sample_grids_proposed.png"

  if (file.exists(file)) {
    ggplot2::ggsave(file, plot = p12)
    base::print("previous sample_grids_proposed.png was overwritten")
  } else {
    ggplot2::ggsave(file, plot = p12)
    base::print("sample_grids_proposed.png was written to file")
  }

  ## create and clean sample_grids table
  sample_grids <- surv_cent %>%
    dplyr::select(BASIN, STRATUM, GRID, Priority, Y, X) %>%
    dplyr::left_join(Effort_Allocation_sub[, c(2, 10)], by = "STRATUM") %>%
    sf::st_drop_geometry() %>%
    dplyr::rename(Basin = BASIN) %>%
    dplyr::rename(Stratum = STRATUM) %>%
    dplyr::rename(Grid = GRID) %>%
    dplyr::rename(Latitude = Y) %>%
    dplyr::rename(Longitude = X) %>%
    dplyr::rename("Trawl description" = trawl_tows_per_grid)


  ## write proposed sample_grids to file as .csv
  ## flag if the previous file was overwritten
  file <- "1_Annual_Protocol/sample_grids_proposed.csv"

  if (file.exists(file)) {
    utils::write.csv(sample_grids, file)
    base::print("previous sample_grids_proposed.csv was overwritten")
  } else {
    utils::write.csv(sample_grids, file)
    base::print("sample_grids_proposed.csv written to file")
  }


  ## write a second proposed sample_grids to file as .csv. for editing
  ## and refinement. Do not overwrite.
  file <- "1_Annual_Protocol/sample_grids_final.csv"

  if (file.exists(file)) {
    base::print("sample_grids_final.csv already exists")
  } else {
    utils::write.csv(sample_grids, file)
    base::print("sample_grids_final.csv written to file")
  }
}

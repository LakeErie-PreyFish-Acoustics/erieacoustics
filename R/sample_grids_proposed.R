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
#' sample_grid_rand_select("WB",2022)
#'  }
sample_grid_rand_select <- function(basin,year) {

  ## set seed as year
  set.seed(year)

  ## subset Effort_Allocation and shape_5mincent_surv to basin
  Effort_Allocation_sub <- Effort_Allocation %>% filter(BASIN == basin)
  shape_5mincent_surv_sub <- shape_5mincent_surv %>% filter(BASIN == basin)
  shape_5mingrid_surv_sub <- shape_5mingrid_surv %>% filter(BASIN == basin)

  ## write all avaialble sampled grids to file as .csv
  write.csv(shape_5mincent_surv_sub, "1_Annual_Protocol/sample_grids_all.csv")

  ## randomly select centroids within strata based on Effort_Allocation
  strat <- unique(Effort_Allocation_sub$STRATUM)
  surv_cent <- NULL
  for (i in 1:length(strat)){
    draws <- Effort_Allocation_sub[Effort_Allocation_sub$STRATUM == strat[i],]$n_trans_eq
    cent <- shape_5mincent_surv_sub[shape_5mincent_surv_sub$STRATUM == strat[i],]
    samp <- cent[sample(1:nrow(cent),draws),]
    surv_cent <- rbind(surv_cent,samp)
  }

  ## create 'Priority' field
  surv_cent$Priority <- "'Survey or Extra'"


  ## basin specific shape files and bounding box
  if(basin == "WB"){
  bound_box <- c(xmin = -83.550, ymin = 41.3494, xmax = -82.450, ymax = 42.1053)
  bounds <- bound_box %>% st_bbox() %>% st_as_sfc() %>% st_set_crs(4326)
  basin_shape <- shape_wbstrata
  } else if(basin == "CB"){
  bound_box <- c(xmin = -82.4, ymin = 41.363, xmax = -80.4, ymax = 42.7205)
  bounds <- bound_box %>% st_bbox() %>% st_as_sfc() %>% st_set_crs(4326)
  basin_shape <- shape_cbstrata
  } else if(basin == "EB"){
  bound_box <- c(xmin = -80.5, ymin = 42.1, xmax = -78.85, ymax = 42.9)
  bounds <- bound_box %>% st_bbox() %>% st_as_sfc() %>% st_set_crs(4326)
  basin_shape <- shape_ebstrata
  } else {print("Check basin name")}

  ##  plot all available centroids
  p1 <- base_erieshore +
    scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"]))+
    scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"]))+
    geom_sf(data = shape_5mingrid_surv_sub, col="lightgray", fill=NA, lwd = 0.5, alpha = 0.5) +
    geom_sf(data = basin_shape, aes(fill=STRATUM, alpha=0.5)) +
    scale_fill_viridis_d(alpha = 0.5) +
    guides(alpha="none") +
    geom_sf(data = shape_5mincent_surv_sub, color = "black", pch = 16) +
    geom_text(data = shape_5mincent_surv_sub, aes(label = GRID, x = X, y = Y),
              nudge_x = 0, nudge_y = 0.025, size = 2.0) +
    ylab("Latitude (dd)") + xlab("Longitude (dd)") +
    labs(title = "Available sample grids") +
    theme_bw() + theme (legend.position = "bottom")

  ## plot randomly selected centroids
  p2 <- base_erieshore +
    scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"]))+
    scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"]))+
    geom_sf(data = shape_5mingrid_surv_sub, col="lightgray", fill=NA, lwd = 0.5, alpha = 0.5) +
    geom_sf(data = basin_shape, aes(fill=STRATUM, alpha=0.5)) +
    scale_fill_viridis_d(alpha = 0.5) +
    guides(alpha="none") +
    geom_sf(data = surv_cent, color = "black", pch = 16) +
    geom_text(data = surv_cent, aes(label = GRID, x = X, y = Y),
              nudge_x = 0, nudge_y = 0.025, size = 2.5) +
    ylab("Latitude (dd)") + xlab("Longitude (dd)") +
    labs(title = "Randomly selected sample grids") +
    theme_bw() + theme (legend.position = "bottom")

  ## combine two plots into one
  p12 <<- grid.arrange(p1, p2, ncol = 2)

  ## save plot to file as .png
  ggsave("1_Annual_Protocol/sample_grids_proposed.png", plot = p12)

  ## ccreate and clean sample_grids table
  sample_grids <- surv_cent %>% select(BASIN,STRATUM,GRID,Priority,Y,X) %>%
              left_join(Effort_Allocation_sub[,c(2,10)], by="STRATUM") %>%
              st_drop_geometry() %>% rename(Basin = BASIN) %>%
              rename(Stratum = STRATUM) %>% rename(Grid = GRID) %>%
              rename(Latitude = Y) %>% rename(Longitude = X) %>%
              rename('Trawl description' = trawl_tows_per_grid)

 ## write proposed sample_grids to file as .csv
 write.csv(sample_grids, "1_Annual_Protocol/sample_grids_proposed.csv")

 ## write a second proposed sample_grids to file as .csv. for editing
 ## and refinement. Do not overwrite.
 file <- "1_Annual_Protocol/sample_grids_final.csv"

 if(file.exists(file)) {
   print("sample_grids_final.csv already exists")
 } else {
 write.csv(sample_grids, file)
 }

}


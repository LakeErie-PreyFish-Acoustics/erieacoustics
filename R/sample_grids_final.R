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
#' sample_grid_final_select("WB",2022)
#'  }
sample_grid_final_select <- function(basin, year){

## subset survey grid shape file
shape_5mingrid_surv_sub <- shape_5mingrid_surv %>% filter(BASIN == basin)


## read in final sample grid file
sample_grids_final <- read.csv("1_Annual_Protocol/sample_grids_final.csv") %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)

## create X Y coordinate columns from geometry
sample_grids_final$X <- st_coordinates(sample_grids_final)[,1]
sample_grids_final$Y <- st_coordinates(sample_grids_final)[,2]

## basin specific shape and bounding box
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


## create final survey map
group.colors <- c(Extra = "red", Survey = "black")

p1 <- base_erieshore +
  scale_x_continuous(limits = c(bound_box["xmin"], bound_box["xmax"]))+
  scale_y_continuous(limits = c(bound_box["ymin"], bound_box["ymax"]))+
  geom_sf(data = shape_5mingrid_surv_sub, col="lightgray", fill=NA, lwd = 0.5, alpha = 0.5) +
  geom_sf(data = basin_shape, aes(fill=STRATUM, alpha=0.5)) +
  scale_fill_viridis_d(alpha = 0.5) +
  guides(alpha="none") +
  geom_sf(data = sample_grids_final, aes(color = Priority), pch = 16) +
  geom_text(data = sample_grids_final, aes(label = Grid, x = X, y = Y),
            nudge_x = 0, nudge_y = 0.025, size = 2.5) +
  ylab("Latitude (dd)") + xlab("Longitude (dd)") +
  labs(title = paste("Final sample grids",year)) +
  scale_color_manual(values=group.colors) +
  theme_bw() +
  theme(legend.position = c("right"))

print(p1)

ggsave("1_Annual_Protocol/sample_grids_final.png", plot = p1)


}


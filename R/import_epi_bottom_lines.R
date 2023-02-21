#' import_epi_bottom_lines
#' @description A helper function to import, format and summarize the epi and bottom lines
#' that are exported from Echoview
#'
#' @param transect A transect in the expected `erieacoustics` format ("EB_S16_G1004")
#'
#' @return summary of epi and bottom line data from Echoview
#' @export
#'
#' @examples
#' \dontrun{
#' library(erieacoustics)
#' library(dplyr)
#' import_epi_bottom_lines("EB_S16_G1004")
#'
#' alltransects <- dir("3_Ping_Data")
#' epi_bot_lines <- bind_rows(lapply(alltransects, import_epi_bottom_lines))
#'}

import_epi_bottom_lines <- function(transect) {
  epi <- file.path("3_Ping_Data", transect, "EpiLayerLine_Final.csv")
  bot <- file.path("3_Ping_Data", transect, "BottomLine_Final.csv")

  if(!file.exists(epi)){
    usethis::ui_stop(paste0("EpiLayerLine_Final.csv doesn't exist for ", transect))}
  if(!file.exists(bot)){
    usethis::ui_stop(paste0("BottomLine_Final.csv doesn't exist for ", transect))}

  epi <- readr::read_csv(epi)
  bot <- readr::read_csv(bot)
  grid <- sapply(strsplit(transect, "_"), "[", 3)
  grid <- gsub("a", "", grid) # required for EB 2022
  grid <- gsub("b", "", grid) # required for EB 2022
  grid <- gsub("c", "", grid) # required for EB 2022
  grid <- as.numeric(gsub("G", "", grid))
  epi$GRID <- grid
  bot$GRID <- grid

  epi <- dplyr::group_by(epi, GRID)
  epi <- dplyr::summarize(epi, epi_avg = mean(Depth), epi_min = min(Depth), epi_max = max(Depth))

  bot <- dplyr::group_by(bot, GRID)
  bot <- dplyr::summarize(bot, bot_avg = mean(Depth), bot_min = min(Depth), bot_max = max(Depth))

  epi_bot_lines <- dplyr::left_join(bot, epi, by = "GRID")

  # if epi line is greater than bottom the value is arbitrary
  # no thermocline present, values should be NA
  epi_bot_lines$epi_avg <- ifelse(epi_bot_lines$epi_avg > epi_bot_lines$bot_avg, NA, epi_bot_lines$epi_avg)
  epi_bot_lines$epi_min <- ifelse(epi_bot_lines$epi_min > epi_bot_lines$bot_min, NA, epi_bot_lines$epi_min)
  epi_bot_lines$epi_max <- ifelse(epi_bot_lines$epi_max > epi_bot_lines$bot_max, NA, epi_bot_lines$epi_max)

  epi_bot_lines
}

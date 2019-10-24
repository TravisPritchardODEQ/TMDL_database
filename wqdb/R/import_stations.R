#' Import monitoring station location information from a template xlsx file.
#'
#' Retrieve station information from Oregon DEQ's template xlsx file. The script will read the "Monitoring_Locations" worksheet and
#' extract HUC codes and names from a WBD huc shpapefile. Returns a dataframe
#' formatted for use in a wqdb SQLite database.
#'
#' @param file The path and file name to template xlsx file.
#' @param huc_shp_dir The directory where the WBD huc shapefile is saved
#' @param huc_shp The name of the WBD huc shapefile. Do not include the .shp extension in the name.
#' @export
#' @return Dataframe of monitoring station location information

import_stations <- function(file, huc_shp_dir, huc_shp_name) {

  library(dplyr)
  library(readxl)
  library(rgdal)
  library(sp)

  # Setup -------------------------------------------------------------------

  # clean out exisiting environment
  # helps to avoid overwriting

  huc_shp <- rgdal::readOGR(dsn=huc_shp_dir, layer=huc_shp_name, stringsAsFactors=FALSE, integer64="warn.loss")

  huc_shp <- sp::spTransform(huc_shp, sp::CRS("+proj=longlat +datum=NAD83"))

  options(scipen=999)

  # Import Locations Info -------------------------------------------------------------------

  locations_col_types <- c('text', 'text', 'text', 'numeric', 'numeric', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'numeric', 'date', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'text', 'numeric', 'numeric', 'numeric', 'numeric')

  locations_import <- readxl::read_excel(file, sheet = "Monitoring_Locations", col_types = locations_col_types)

  colnames(locations_import) <- make.names(names(locations_import), unique=TRUE)

  df.mloc1 <- locations_import %>%
    dplyr::select(MLocID=Monitoring.Location.ID,
                  StationDes=Monitoring.Location.Name,
                  MonLocType=Monitoring.Location.Type,
                  HUC8=HUC.8.Code,
                  Lat_DD=Latitude,
                  Long_DD=Longitude,
                  Reachcode,
                  Measure,
                  AU_ID=Assessment.Unit.ID) %>%
    dplyr::mutate(EcoRegion3=as.character(NA),
                  EcoRegion4=as.character(NA))

  sp::coordinates(df.mloc1) <- ~Long_DD+Lat_DD
  df.mloc1@proj4string <- huc_shp@proj4string

  mlocs_in_hucs <- sp::over(df.mloc1, huc_shp)

  # Extract HUC info
  df.mloc2 <- mlocs_in_hucs %>%
    dplyr::select(HUC8_Name=HU_8_NAME, HUC10=HUC_10, HUC10_Name=HU_10_NAME, HUC12=HUC_12, HUC12_Name=HU_12_NAME) %>%
    cbind(as.data.frame(df.mloc1)) %>%
    dplyr::select(MLocID, StationDes, MonLocType, EcoRegion3, EcoRegion4,
                  HUC8, HUC8_Name, HUC10, HUC10_Name, HUC12, HUC12_Name,
                  Lat_DD, Long_DD, Reachcode, Measure, AU_ID)

  return(df.mloc2)

}

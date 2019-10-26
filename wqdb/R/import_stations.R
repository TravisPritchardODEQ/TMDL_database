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

  huc_shp <- rgdal::readOGR(dsn=huc_shp_dir, layer=huc_shp_name, stringsAsFactors=FALSE, integer64="warn.loss")

  huc_shp <- sp::spTransform(huc_shp, sp::CRS("+proj=longlat +datum=NAD83"))

  options(scipen=999)

  # Import Locations Info -------------------------------------------------------------------

  locations_col_types <- c('text', 'text', 'text', 'numeric', 'numeric', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'text', 'date', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'text', 'text', 'numeric', 'text', 'numeric')

  locations_import <- readxl::read_excel(file, sheet = "Monitoring_Locations", col_types = locations_col_types)

  colnames(locations_import) <- make.names(names(locations_import), unique=TRUE)

  df.mloc1 <- locations_import %>%
    dplyr::select(MLocID=Monitoring.Location.ID,
                  StationDes=Monitoring.Location.Name,
                  Lat_DD=Latitude,
                  Long_DD=Longitude,
                  CollMethod=Coordinate.Collection.Method,
                  Datum=Horizontal.Datum,
                  MapScale=Source.Map.Scale,
                  AU_ID=Assessment.Unit.ID,
                  MonLocType=Monitoring.Location.Type,
                  TribalLand=Tribal.Land.,
                  TribalName=Tribal.Land.Name,
                  AltLocID=Alternate.ID.1,
                  AltLocName=Alternate.Context.1,
                  Comments=Monitoring.Location.Comments,
                  STATE=State.Code,
                  COUNTY=County.Name,
                  HUC8=HUC.8.Code,
                  GNIS_Name,
                  Reachcode,
                  Measure,
                  LLID,
                  RiverMile) %>%
    dplyr::mutate(TribalLand=ifelse(grepl("[Yy]es",TribalLand),1,0))

  # make spatial
  sp::coordinates(df.mloc1) <- ~Long_DD+Lat_DD
  df.mloc1@proj4string <- huc_shp@proj4string

  # Extract HUC info
  mlocs_in_hucs <- sp::over(df.mloc1, huc_shp)

  # add to dataframe
  df.mloc2 <- mlocs_in_hucs %>%
    dplyr::select(HUC8_Name=HU_8_NAME, HUC10=HUC_10, HUC10_Name=HU_10_NAME, HUC12=HUC_12, HUC12_Name=HU_12_NAME) %>%
    cbind(as.data.frame(df.mloc1)) %>%
    dplyr::mutate(HUC10=as.character(HUC10),
                  HUC12=as.character(HUC12))

  # Add other cols that are not in xlsx template
  df.mloc2[ , setdiff(wqdb::station_cols(), colnames(df.mloc2))] <- NA

  # reorder
  df.mloc3 <- df.mloc2 %>%
    dplyr::select(wqdb::station_cols())

  return(df.mloc3)

}

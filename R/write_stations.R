#' Write Station Info into a wqdb formatted SQLite Database.
#'
#' Take a dataframe of monitoring location station information and write it to the stations table in a water quality SQLite database. Note - trying to load in duplicate values will cause an error.
#'
#' @param stations Dataframe of monitoring location station information to
#'     import into the SQLite database. The dataframe format should be the same as Oregon DEQ Stations database.
#'     Required dataframe columns include:
#'
#'     MlocID: string - Monitoring Location ID. A unique identifier for the monitoring location (i.e., 10996-ORDEQ).
#'     Organization ID is not required as part of the monitoring location ID, but we suggest including it to
#'     help differentiate locations quickly and easily.
#'
#'     StationDes: string - Monitoring location name. A geographically descriptive name.
#'
#'     Lat_DD: numeric - Latitude in decimal degrees (i.e., 45.123456).
#'
#'     Long_DD: numeric - Longitude in decimal degrees (i.e.,-123.123456).
#'
#'     Datum: string - Horizontal Datum. Valid values include: "NAD27" for North American Datum 1927,
#'     "NAD83" for North American Datum 1983, and "WGS84" for World Geodetic System 1984
#'
#' @param db The path and file name to the SQLite database where the stations data will be imported into.
#' @keywords stations
#' @export

write_stations <- function(stations, db){

  library(RSQLite)
  library(DBI)
  library(glue)

con <- DBI::dbConnect(RSQLite::SQLite(), db)
DBI::dbWriteTable(con, 'Stations', value=stations, append = TRUE)
DBI::dbDisconnect(con)

}

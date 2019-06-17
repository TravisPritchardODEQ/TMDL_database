#' Take a vector of monitoring location station IDs (MLocIDs) and query station data from DEQ's Stations database. This station data is then loaded in the Stations table in the specified SQLite database. Note - trying to load in duplicate values will cause an error.
#'
#' @param stations Dataframe of monitoring location station information to import into the SQLite database. The table format should be the same as Oregon DEQ Stations database.
#' @param sqlite_db The path and file name to the SQLite database where the stations data will be imported into.
#' @keywords stations
#' @export

import_stations <- function(stations, sqlite_db){

  library(RSQLite)
  library(DBI)
  library(glue)

con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_db)
DBI::dbWriteTable(con, 'Stations', value= stations, append = TRUE)
DBI::dbDisconnect(con)

}

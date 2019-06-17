#'Import station info into a SQLite database.
#'
#' Take a vector of monitoring location station IDs (MLocIDs) and query station data from DEQ's Stations database. This station data is then loaded in the Stations table in the specified SQLite database. Note - trying to load in duplicate values will cause an error.
#'
#' @param mlocs Vector of unique monitoring location station IDs (MLocIDs) to retrieve from DEQ's Stations database.
#' @param sqlite_db The path and file name to the SQLite database where the stations data will be imported into.
#' @param stations_db Stations database ODBC system data source name (DSN) identifed the ODBC data sources administrator. Default is "STATIONS".
#' @keywords stations
#' @export
#' @return None
#' @examples
#' library(AWQMSdata)
#'
#' # Retreive AWQMS data
#' df.awqms <- AWQMS_Data(startdate = "1995-01-01",
#'                       enddate = "2019-12-31",
#'                       char = "Temperature, water",
#'                       HUC10 = "1801020604",
#'                       crit_codes = TRUE,
#'                       filterQC = TRUE)
#'
#'create_wq_db("Jenny_Creek.db")
#'
#'import_AWQMS_data(AWQMS_df=df.awqms,
#'                  sqlite_db="Jenny_Creek.db")
#'import_stations_db(mlocs=unique(df.awqms$MLocID),
#'                   sqlite_db="Jenny_Creek.db",
#'                   stations_db = "STATIONS")

import_stations_db <- function(mlocs, sqlite_db, stations_db = "STATIONS"){

  library(RSQLite)
  library(DBI)
  library(glue)

con <- DBI::dbConnect(odbc::odbc(), stations_db)
query <- "Select * from VWStationsFinal where MLocID in ({mlocs*})"
query <- glue::glue_sql(query,.con = con)
stations <- DBI::dbGetQuery(con, query)
DBI::dbDisconnect(con)


con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_db)
DBI::dbWriteTable(con, 'Stations', value= stations, append = TRUE)
DBI::dbDisconnect(con)

}

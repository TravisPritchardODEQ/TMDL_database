

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
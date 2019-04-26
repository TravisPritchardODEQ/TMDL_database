

insert_stations_db <- function(mlocs, sqlite_database, stations_database = "STATIONS"){

con <- DBI::dbConnect(odbc::odbc(), stations_database)
query <- "Select * from VWStationsFinal where MLocID in ({mlocs*})"
query <- glue::glue_sql(query,.con = con)
stations <- DBI::dbGetQuery(con, query)
DBI::dbDisconnect(con)


con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_database)
DBI::dbWriteTable(con, 'Stations', value= stations, append = TRUE)
DBI::dbDisconnect(con)

}
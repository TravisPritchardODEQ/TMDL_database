
library(devtools)

devtools::install_github("rmichie/wqdb", host = "https://api.github.com")
devtools::install_github("TravisPritchardODEQ/AWQMSdata", host = "https://api.github.com")

library(wqdb)
library(AWQMSdata)

# tations database ODBC system data source name (DSN) identifed the ODBC data sources administrator. Default is usually "STATIONS".
stations_odbc <- "STATIONS"

setwd("E:/GitHub/wqdb/example")

df.stations <- query_stations(stations_odbc=stations_odbc)

# retreive AWQMS data
df.awqms <- AWQMS_Data(startdate = "1995-01-01", enddate = "2000-12-31",
           char = "Temperature, water",
           HUC10 = "1801020604",
           crit_codes = TRUE,
           filterQC = TRUE)

# Get station IDs
mlocs <- unique(df.awqms$MLocID)

# retreive staiton info from stations database
con <- DBI::dbConnect(odbc::odbc(), stations_odbc)
query <- "Select * from VWStationsFinal where MLocID in ({mlocs*})"
query <- glue::glue_sql(query,.con = con)
df.stations <- DBI::dbGetQuery(con, query)
DBI::dbDisconnect(con)

# create and write data into the db
write_wqdb(db="Jenny_Creek.db",awqms=df.awqms, stations=df.stations)

# get all the data back
df <- read_wqdb("Jenny_Creek.db")

unlink("Jenny_Creek.db")





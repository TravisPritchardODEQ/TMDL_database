
library(devtools)

devtools::install_github("rmichie/wqdb", host = "https://api.github.com")
devtools::install_github("TravisPritchardODEQ/AWQMSdata", host = "https://api.github.com")

library(wqdb)
library(AWQMSdata)

# stations database ODBC system data source name (DSN) identifed the ODBC data sources administrator. Default is usually "STATIONS".
stations_odbc <- "STATIONS"

setwd("E:/GitHub/wqdb/example")

df.stations <- query_stations(stations_odbc=stations_odbc, huc10 = "1801020604")

# Get station IDs
mlocs <- unique(df.stations$MLocID)

# retreive AWQMS data
df.awqms <- AWQMS_Data(startdate = "1995-01-01", enddate = "2002-12-31",
           char = "Temperature, water",
           station = mlocs,
           crit_codes = TRUE,
           filterQC = TRUE)

# create and write data into the db
write_wqdb(db="Jenny_Creek.db",awqms=df.awqms, stations=df.stations)

# get all the data back
df <- read_wqdb("Jenny_Creek.db")

unlink("Jenny_Creek.db")





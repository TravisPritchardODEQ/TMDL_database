
library(devtools)

devtools::install_github("rmichie/wqdb", subdir="wqdb", host = "https://api.github.com", upgrade = FALSE)
devtools::install_github("TravisPritchardODEQ/AWQMSdata", host = "https://api.github.com")

library(wqdb)
library(AWQMSdata)
library(dplyr)

# This code only works for employees of ODEQ.
# Requires read access permissions for internal odbc connections to the AWQMS and Stations databases.

# stations database ODBC system data source name (DSN) identifed in the ODBC data sources administrator. Default is usually "STATIONS".
stations_odbc <- "STATIONS"

setwd("E:/GitHub/wqdb/example")

df.stations <- query_stations(stations_odbc=stations_odbc, huc8="17100309")

applegate_stations <- df.stations[grepl("^Applegate River", df.stations$StationDes, ignore.case=TRUE) & df.stations$OrgID=="OregonDEQ",]

# Get station IDs
mlocs <- unique(applegate_stations$MLocID)

# retreive AWQMS data
applegate <- AWQMS_Data(startdate = "1995-01-01", enddate = "2018-12-31",
                        station = mlocs,
                        crit_codes = TRUE,
                        filterQC = TRUE)


# create and write data into the db
write_wqdb(db="applegate.db", awqms=applegate, stations=applegate_stations)

# get all the data back
df <- read_wqdb("applegate.db")

# Save data into wqdb data directory
setwd("E:/GitHub/wqdb/wqdb/data")
save(applegate, file="applegate.RData")
save(applegate_stations, file="applegate_stations.RData")

# Summarize the data
app.summary <- applegate %>%
  dplyr::filter(Statistical_Base=="7DADM") %>%
  dplyr::mutate(datetime=lubridate::ymd(SampleStartDate),
                year=lubridate::year(datetime)) %>%
  dplyr::group_by(MLocID, StationDes, Statistical_Base, year) %>%
  dplyr::summarize(min_date=min(datetime),
                   max_date=max(datetime),
                                      n=n())

# delete db
unlink("applegate.db")




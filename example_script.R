
library(devtools)

devtools::install_github("TravisPritchardODEQ/AWQMSdata", host = "https://api.github.com")

library(AWQMSdata)

fun_dir <- "E:/GitHub/wq_sqlite/R"

setwd("E:/GitHub/wq_sqlite")

source(paste0(fun_dir,"/","create_wq_db.R"))
source(paste0(fun_dir,"/","import_AWQMS_data.R"))
source(paste0(fun_dir,"/","import_stations_db.R"))


# retreive AWQMS data
df.awqms <- AWQMS_Data(startdate = "1995-01-01", enddate = "2019-12-31",
           char = "Temperature, water",
           HUC10 = "1801020604",
           crit_codes = TRUE,
           filterQC = TRUE)

df.stations <- AWQMS_Stations(char = "Temperature, water",
                              HUC8 = "18010206",
                              crit_codes = TRUE)


create_wq_db("Jenny_Creek.db")

import_AWQMS_data(AWQMS_df=df.awqms, sqlite_db="Jenny_Creek.db")
import_stations_db(mlocs=unique(df.awqms$MLocID), sqlite_db="Jenny_Creek.db", stations_db = "STATIONS")




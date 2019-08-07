#' Applegate River Water Quality Data
#'
#' Water quality data from the Applegate River, Oregon, USA. Data was retreived from
#' the Oregon Department of Environmetnal Quality's AWQMS database.
#'
#' @docType data
#' @usage data(applegate)
#' @keywords applegate, water quality
#' @keywords datasets
#' @examples
#' data(applegate_temps)
#'
#' # Code below was used to compile station info on the Applegate River. This code only works for employees of ODEQ.
#' # Requires read access permissions for internal odbc connections to the AWQMS and Stations databases.
#'
#' library(wqdb)
#' library(AWQMSdata)
#'
#' df.stations <- wqdb::query_stations(stations_odbc="STATIONS", huc8="17100309")
#'
#' applegate_stations <- df.stations[grepl("^Applegate River", df.stations$StationDes, ignore.case=TRUE) & df.stations$OrgID=="OregonDEQ",]
#'
#' # Get station IDs
#' mlocs <- unique(applegate_stations$MLocID)
#'
#' # Retreive AWQMS data
#' applegate <- AWQMSdata::AWQMS_Data(startdate = "1995-01-01", enddate = "2018-12-31",
#'                                    station = mlocs,
#'                                    crit_codes = TRUE,
#'                                    filterQC = TRUE)

"applegate"

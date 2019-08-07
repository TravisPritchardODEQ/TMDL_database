#' Applegate River Monitoring Stations
#'
#' Monitoring stations on the Applegate River, Oregon, USA. Data was retreived from
#' the Oregon Department of Environmetnal Quality's Stations database.
#'
#' @docType data
#' @usage data(applegate_stations)
#' @keywords applegate, stations
#' @keywords datasets
#' @examples
#' data(applegate_stations)
#'
#' # Code below was used to compile applegate stations. This code only works for employees of ODEQ.
#' # Requires read access permissions for internal odbc connections to the Stations database.
#'
#' library(wqdb)
#'
#' df.stations <- wqdb::query_stations(stations_odbc="STATIONS", huc8="17100309")
#'
#' applegate_stations <- df.stations[grepl("^Applegate River", df.stations$StationDes, ignore.case=TRUE) & df.stations$OrgID=="OregonDEQ",]

"applegate_stations"

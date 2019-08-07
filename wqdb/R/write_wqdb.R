#' Write data into a wqdb formatted SQLite Database.
#'
#' Create and/or write to a wqdb formatted SQLite database. If the wqdb database already exists
#' this function will check if the tables exist and create them if not.
#' If a dataframe is passed the data will be written into the tables. Duplicate records are checked and not overwritten.
#'
#' @param db The path and file name to the new SQLite database to be created.
#' @param awqms The dataframe to be written into the 'awqms' table. The dataframe
#'    columns and datatypes are the same as a dataframe returned from AWQMSdata::AWQMS_data(). Defualt is NULL.
#' @param other The dataframe to be written into the 'other' table. Defualt is NULL.
#' @param continuous The dataframe to be written into the 'continuous' table. Defualt is NULL.
#' @param stations The dataframe to be written into the 'stations' table. Defualt is NULL.
#' @param characteristics The dataframe to be written into the 'characteristics' table. Defualt is NULL.
#'
#' @keywords database, sqlite
#' @export
#' @return None
#' @examples
#' # get sample data
#' applegate.awqms <- data(applegate_temps)
#' applegate.stations <- data(applegate_stations)
#'
#' write_wqdb(db="applegate.db", awqms=applegate.awqms, stations=applegate.stations)
#'
write_wqdb <- function(db, awqms=NULL, other=NULL, continuous=NULL, stations=NULL, characteristics=NULL){

  library(RSQLite)
  library(DBI)
  library(glue)

  wqdb::create_wqdb(db)

  if(!is.null(awqms)) {

    awqms.cols <- wqdb::awqms_cols()
    import_data <- awqms[,names(awqms) %in% awqms.cols]

    con <- DBI::dbConnect(RSQLite::SQLite(), db)
    DBI::dbWriteTable(conn=con, name="awqms", value=import_data, append = TRUE)
    DBI::dbDisconnect(conn=con)

  }


  if(!is.null(other)) {

    other.cols <- wqdb::awqms_cols()
    import_data <- other[,names(other) %in% other.cols]

    con <- DBI::dbConnect(RSQLite::SQLite(), db)
    DBI::dbWriteTable(conn=con, name="other", value=import_data, append = TRUE)
    DBI::dbDisconnect(conn=con)

  }

  if(!is.null(continuous)) {

    cont.cols <- wqdb::cont_cols()
    import_data <- continuous[,names(continuous) %in% cont.cols]

    con <- DBI::dbConnect(RSQLite::SQLite(), db)
    DBI::dbWriteTable(conn=con, name="continuous", value=import_data, append = TRUE)
    DBI::dbDisconnect(conn=con)

  }

  if(!is.null(stations)) {

    station.cols <- wqdb::station_cols()
    import_data <- stations[,names(stations) %in% station.cols]

    con <- DBI::dbConnect(RSQLite::SQLite(), db)
    DBI::dbWriteTable(conn=con, name="stations", value=import_data, append = TRUE)
    DBI::dbDisconnect(conn=con)

  }

  if(!is.null(characteristics)) {

    char.cols <- wqdb::char_cols()
    import_data <- characteristics[,names(characteristics) %in% char.cols]

    con <- DBI::dbConnect(RSQLite::SQLite(), db)
    DBI::dbWriteTable(conn=con, name="characteristics", value=import_data, append = TRUE)
    DBI::dbDisconnect(conn=con)

  }

}

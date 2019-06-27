
#' Retrive data from a wqdb formatted SQLite Database.
#'
#' Retrive data from a water quality formatted SQLite database. Function is a SQLite version of the AWQMS_Data() function from the AWQMS_Data package.
#'
#' @param db The path and file name to the SQLite database.
#' @param table The db table to query. By default this is set to "vw_discrete". The continuous data table is "vw_continuous".
#' @param startdate Required parameter setting the startdate of the data being fetched. Format 'yyyy-mm-dd'
#' @param enddate Optional parameter setting the enddate of the data being fetched. Format 'yyyy-mm-dd'
#' @param station Optional vector of stations to be fetched
#' @param project Optional vector of projects to be fetched
#' @param char Optional vector of characteristics to be fetched
#' @param stat_base Optional vector of Result Stattistical Bases to be fetched ex. Maximum
#' @param media Optional vector of sample media to be fetched
#' @param org optional vector of Organizations to be fetched
#' @param HUC8 Optional vector of HUC8 codes to be fetched
#' @param HUC8_Name Optional vector of HUC8 names to be fetched
#' @param HUC10 Optional vector of HUC10s to be fetched
#' @param HUC12 Optional vector of HUC12s to be fetched
#' @param HUC12_Name Optional vector of HUC12 names to be fetched
#' @param crit_codes If true, include standard codes used in determining criteria
#' @return Dataframe from a wqdb formatted database
#' @example
#' read_wqdb(db="test.db", startdate = "2017-01-01", enddate = "2000-12-31", station = c("10591-ORDEQ", "29542-ORDEQ"))
#' @export
#'
#'

read_wqdb <- function(db, table="vw_discrete", startdate="1949-09-15", enddate = NULL, station = NULL,
                      project = NULL, char = NULL, stat_base = NULL,
                      media = NULL, org = NULL, HUC8 = NULL, HUC8_Name = NULL,
                      HUC10 = NULL, HUC12 = NULL,  HUC12_Name = NULL) {

  library(RSQLite)
  library(DBI)
  library(glue)

  # Build base query language
  query <- paste0("SELECT a.* FROM ", table," a WHERE date(a.SampleStartDate) >= date({startdate})")

  # Conditially add addional parameters

  # add end date
  if (length(enddate) > 0) {
    query = paste0(query, "\n AND date(a.SampleStartDate) <= date({enddate})" )
  }


  # station
  if (length(station) > 0) {

    query = paste0(query, "\n AND a.MLocID IN ({station*})")
  }

  #Project

  if (length(project) > 0) {
    query = paste0(query, "\n AND (a.Project1 in ({project*}) OR a.Project2 in ({project*})) ")

  }

  # characteristic
  if (length(char) > 0) {
    query = paste0(query, "\n AND a.Char_Name in ({char*}) ")

  }

  #statistical base
  if(length(stat_base) > 0){
    query = paste0(query, "\n AND a.Statistical_Base in ({stat_base*}) ")

  }

  # sample media
  if (length(media) > 0) {
    query = paste0(query, "\n AND a.SampleMedia in ({media*}) ")

  }

  # organization
  if (length(org) > 0){
    query = paste0(query,"\n AND a.OrganizationID in ({org*}) " )

  }

  #HUC8

  if(length(HUC8) > 0){
    query = paste0(query,"\n AND a.HUC8 in ({HUC8*}) " )

  }


  #HUC8_Name

  if(length(HUC8_Name) > 0){
    query = paste0(query,"\n AND a.HUC8_Name in ({HUC8_Name*}) " )

  }

  if(length(HUC10) > 0){
    query = paste0(query,"\n AND a.HUC10 in ({HUC10*}) " )

  }

  if(length(HUC12) > 0){
    query = paste0(query,"\n AND a.HUC12 in ({HUC12*}) " )

  }


  if(length(HUC12_Name) > 0){
    query = paste0(query,"\n AND a.HUC12_Name in ({HUC12_Name*}) " )

  }


  con <- DBI::dbConnect(RSQLite::SQLite(), db)

  # Create query language
  query.sql <- glue::glue_sql(query,.con = con)
  data_fetch <- DBI::dbGetQuery(con, query.sql)

  DBI::dbDisconnect(con)

  return(data_fetch)

}




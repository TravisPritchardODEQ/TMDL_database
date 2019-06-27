#' Write data into a wqdb formatted SQLite Database.
#'
#' Create and/or write to a SQLite database with table fields identical to Oregon DEQ's AWQMS and Stations database.
#' If the database already exists this function will check if the tables exist and create them if not.
#' If a dataframe is passed the data will be written into the tables. Duplicate records are checked and not overwritten.
#'
#' @param db The path and file name to the new SQLite database to be created.
#' @param df The dataframe to be written into the SQLite database. Default value is NULL.
#'     The dataframe columns and datatypes are the same as a dataframe returned from AWQMSdata::AWQMS_data().
#' @param table The db table where df will be written. By default this is set to "awqms". Other options inlcude "stations",
#'     "other", "continuous", or "characteristics".
#'     "characteristics"
#'     `chr_uid`: integer
#'     `Char_Name`: character
#'     `CASNumber`: character
#'
#'
#' @keywords database, sqlite
#' @export
#' @return None
#'
write_wqdb <- function(db, df=NULL, table="awqms"){

  library(RSQLite)
  library(DBI)
  library(glue)

wqdblite::create_wqdb(db)

if(table %in% c("awqms", "other")) {

  AWQMS.cols <- c('OrganizationID'
                ,'Org_Name'
                ,'Project1'
                ,'Project2'
                ,'Project3'
                ,'MLocID'
                ,'act_id'
                ,'Activity_Type'
                ,'SampleStartDate'
                ,'SampleStartTime'
                ,'SampleStartTZ'
                ,'SampleMedia'
                ,'SampleSubmedia'
                ,'SamplingMethod'
                ,'chr_uid'
                ,'Char_Name'
                ,'Char_Speciation'
                ,'Sample_Fraction'
                ,'CASNumber'
                ,'Result_UID'
                ,'Result_status'
                ,'Result_Type'
                ,'Result'
                ,'Result_Numeric'
                ,'Result_Operator'
                ,'Result_Unit'
                ,'Unit_UID'
                ,'ResultCondName'
                ,'RelativeDepth'
                ,'Result_Depth'
                ,'Result_Depth_Unit'
                ,'Result_Depth_Reference'
                ,'act_depth_height'
                ,'ActDepthUnit'
                ,'Act_depth_Reference'
                ,'Act_Depth_Top'
                ,'Act_Depth_Top_Unit'
                ,'Act_Depth_Bottom'
                ,'Act_Depth_Bottom_Unit'
                ,'Time_Basis'
                ,'Statistical_Base'
                ,'Statistic_N_Value'
                ,'act_sam_compnt_name'
                ,'stant_name'
                ,'Bio_Intent'
                ,'Taxonomic_Name'
                ,'Analytical_method'
                ,'Method_Code'
                ,'Method_Context'
                ,'Analytical_Lab'
                ,'Activity_Comment'
                ,'Result_Comment'
                ,'lab_Comments'
                ,'QualifierAbbr'
                ,'QualifierTxt'
                ,'IDLType'
                ,'IDLValue'
                ,'IDLUnit'
                ,'MDLType'
                ,'MDLValue'
                ,'MDLUnit'
                ,'MRLType'
                ,'MRLValue'
                ,'MRLUnit'
                ,'URLType'
                ,'URLValue'
                ,'URLUnit'
                ,'WQX_submit_date'
)


import_data <- df[,names(df) %in% AWQMS.cols]

}

if(table == "continuous") {

  cont.cols <- c('OrganizationID'
                  ,'Org_Name'
                  ,'Project1'
                  ,'Project2'
                  ,'Project3'
                  ,'MLocID'
                  ,'SampleStartDate'
                  ,'SampleStartTime'
                  ,'SampleStartTZ'
                  ,'SampleMedia'
                  ,'SampleSubmedia'
                  ,'SamplingMethod'
                  ,'Char_Name'
                  ,'Char_Speciation'
                  ,'Sample_Fraction'
                  ,'CASNumber'
                  ,'Result_UID'
                  ,'Result'
                  ,'Result_Unit'
                 , 'EquipmentID')


  import_data <- df[,names(df) %in% cont.cols]

}

if(table == "stations") {

  station.cols <- c('OrgID',
                    'station_key',
                    'MLocID',
                    'StationDes',
                    'Lat_DD',
                    'Long_DD',
                    'Datum',
                    'CollMethod',
                    'MapScale',
                    'AU_ID',
                    'MonLocType',
                    'TribalLand',
                    'TribalName',
                    'AltLocID',
                    'AltLocName',
                    'WellType',
                    'WellFormType',
                    'WellDepth',
                    'WellDepthUnit',
                    'Comments',
                    'IsFinal',
                    'WellAquiferName',
                    'STATE',
                    'COUNTY',
                    'T_R_S',
                    'EcoRegion3',
                    'EcoRegion4',
                    'HUC4_Name',
                    'HUC6_Name',
                    'HUC8_Name',
                    'HUC10_Name',
                    'HUC12_Name',
                    'HUC8',
                    'HUC10',
                    'HUC12',
                    'ELEV_Ft',
                    'GNIS_Name',
                    'Reachcode',
                    'Measure',
                    'LLID',
                    'RiverMile',
                    'SnapDate',
                    'ReachRes',
                    'Perm_ID_PT',
                    'SnapDist_ft',
                    'Conf_Score',
                    'QC_Comm',
                    'UseNHD_LL',
                    'Permanent_Identifier',
                    'COMID',
                    'precip_mm',
                    'temp_Cx10',
                    'Predator_WorE',
                    'Wade_Boat',
                    'ReferenceSite',
                    'FishCode',
                    'SpawnCode',
                    'WaterTypeCode',
                    'WaterBodyCode',
                    'BacteriaCode',
                    'DO_code',
                    'ben_use_code',
                    'pH_code',
                    'DO_SpawnCode',
                    'OWRD_Basin',
                    'TimeZone',
                    'EcoRegion2',
                    'UserName',
                    'Created_Date')



  import_data <- df[,names(df) %in% station.cols]

}

if(table == "characteristics") {

  char.cols <- c('chr_uid',
                 'Char_Name',
                 'CASNumber')

  import_data <- df[,names(df) %in% char.cols]

}

con <- DBI::dbConnect(RSQLite::SQLite(), db)
DBI::dbWriteTable(conn=con, name=table, value=import_data, append = TRUE)
DBI::dbDisconnect(conn=con)


}

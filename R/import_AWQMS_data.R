#'Import AWQMS data into a SQLite database
#'
#'Imports a dataframe returned by AWQMSdata::AWQMS_data() and inserts it into an existing SQLite database created using the create_wq_db() function. Data is inserted in the 'AWQMS_data' table. Note, trying to load in duplicate records will cause an error.
#'
#' @param df  The AWQMS dataframe to be imported into the SQLite database. This data frame is often returned by AWQMSdata::AWQMS_data().
#' @param db The path and file name to the SQLite database where df will be imported into.
#' @keywords AWQMS
#' @export
#' @return None
#' @examples
#' library(AWQMSdata)
#'
#' # Retreive AWQMS data
#' df.awqms <- AWQMS_Data(startdate = "1995-01-01",
#'                        enddate = "2019-12-31",
#'                        char = "Temperature, water",
#'                        HUC10 = "1801020604",
#'                        crit_codes = TRUE,
#'                        filterQC = TRUE)
#'
#'create_wq_db("Jenny_Creek.db")
#'
#'import_AWQMS_data(df=df.awqms,
#'                  db="Jenny_Creek.db")
#'import_stations_db(mlocs=unique(df.awqms$MLocID),
#'                   db="Jenny_Creek.db",
#'                   stations_db = "STATIONS")

import_AWQMS_data <- function(df, db){


  library(RSQLite)
  library(DBI)

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


  import_data <- df[,AWQMS.cols]

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  DBI::dbWriteTable(con, 'AWQMS_data', value= import_data, append = TRUE)
  DBI::dbDisconnect(con)

}

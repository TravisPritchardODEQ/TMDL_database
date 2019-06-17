
import_AWQMS_data <- function(AWQMS_df, sqlite_db){
  
  
  library(RSQLite)
  library(DBI)
  library(dplyr)

import_data <- AWQMS_df %>%
  dplyr::select(
    'OrganizationID'
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

con <- DBI::dbConnect(RSQLite::SQLite(), sqlite_db)
DBI::dbWriteTable(con, 'AWQMS_data', value= import_data, append = TRUE)
DBI::dbDisconnect(con)

}

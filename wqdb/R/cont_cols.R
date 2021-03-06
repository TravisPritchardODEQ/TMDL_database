#' Continous table column names.
#'
#' Returns a vector of column names used in the continous table in a wqdb.

#' @keywords Continous
#' @export
#' @return Vector of column names

cont_cols <- function(){

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
                 ,'EquipmentID')

  return(cont.cols)
}

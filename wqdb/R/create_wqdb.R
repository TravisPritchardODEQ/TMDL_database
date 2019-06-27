#' Create a wqdb formatted SQLite database.
#'
#' Create a SQLite database with table fields identical to Oregon DEQ's AWQMS and Stations database.
#' If the database already exists this function will check if the tables exist and create them if not.
#' Tables created include:
#' 'stations':  Table of station information
#' 'characteristics' Table of AWQMS charateristics. Same as the table returned from wqdblite::AWQMS_chars()
#' 'awqms' Table of AWQMS data
#' 'other' Table of non AWQMS data
#' 'continuous' Table of continous data
#' 'vw_discrete' view of awqms and other outer joined with Stations
#' 'vw_continuous' view of continuous outer joined with Stations
#'
#' @param db The path and file name to the new SQLite database to be created.
#' @keywords database, sqlite
#' @export
#' @return None
#'
create_wqdb <- function(db){

  library(RSQLite)
  library(DBI)
  library(glue)

  con <- DBI::dbConnect(RSQLite::SQLite(), db)

  # Create lookup tables ----------------------------------------------------

  print("Creating Characteristics Table")

  char_create <- "CREATE TABLE IF NOT EXISTS `characteristics` (
  `chr_uid` INTEGER,
  `Char_Name` TEXT PRIMARY KEY NOT NULL,
  `CASNumber` TEXT
)"

  query <- glue::glue_sql(char_create,.con = con)
  DBI::dbExecute(con, query)

  DBI::dbWriteTable(con, 'characteristics', value= wqdblite::AWQMS_chars, overwrite = TRUE)

  # Stations ----------------------------------------------------------------

  # Create stations table in database

  print("Creating Stations Table")

  create_stations <- "CREATE TABLE IF NOT EXISTS `stations` (
`OrgID` TEXT NOT NULL,
`station_key` TEXT,
`MLocID` TEXT NOT NULL,
`StationDes` TEXT NOT NULL,
`Lat_DD` REAL NOT NULL,
`Long_DD` REAL NOT NULL,
`Datum` TEXT,
`CollMethod` TEXT,
`MapScale` REAL,
`AU_ID` TEXT,
`MonLocType` TEXT,
`TribalLand` REAL,
`TribalName` TEXT,
`AltLocID` TEXT,
`AltLocName` TEXT,
`WellType` TEXT,
`WellFormType` TEXT,
`WellDepth` REAL,
`WellDepthUnit` TEXT,
`Comments` TEXT,
`IsFinal` INTEGER,
`WellAquiferName` TEXT,
`STATE` TEXT,
`COUNTY` TEXT,
`T_R_S` TEXT,
`EcoRegion3` TEXT,
`EcoRegion4` TEXT,
`HUC4_Name` TEXT,
`HUC6_Name` TEXT,
`HUC8_Name` TEXT,
`HUC10_Name` TEXT,
`HUC12_Name` TEXT,
`HUC8` TEXT,
`HUC10` TEXT,
`HUC12` TEXT,
`ELEV_Ft` INTEGER,
`GNIS_Name` TEXT,
`Reachcode` TEXT,
`Measure` REAL,
`LLID` TEXT,
`RiverMile` REAL,
`SnapDate` TEXT,
`ReachRes` INTEGER,
`Perm_ID_PT` TEXT,
`SnapDist_ft` REAL,
`Conf_Score` INTEGER,
`QC_Comm` TEXT,
`UseNHD_LL` TEXT,
`Permanent_Identifier` TEXT,
`COMID` INTEGER,
`precip_mm` REAL,
`temp_Cx10` REAL,
`Predator_WorE` TEXT,
`Wade_Boat` TEXT,
`ReferenceSite` TEXT,
`FishCode` INTEGER,
`SpawnCode` INTEGER,
`WaterTypeCode` INTEGER,
`WaterBodyCode` INTEGER,
`BacteriaCode` INTEGER,
`DO_code` INTEGER,
`ben_use_code` INTEGER,
`pH_code` INTEGER,
`DO_SpawnCode` INTEGER,
`OWRD_Basin` TEXT,
`TimeZone` TEXT,
`EcoRegion2` TEXT,
`UserName` TEXT,
`Created_Date` TEXT,
`UID` INTEGER PRIMARY KEY AUTOINCREMENT
)"

  query <- glue::glue_sql(create_stations,.con = con)
  DBI::dbExecute(con, query)

  # Create unique index to ensure we only have unique OrgID, MLocID combinations

  create_stations_index <- 'CREATE UNIQUE INDEX IF NOT EXISTS "index_stations" ON "stations" (
  "OrgID",
  "MLocID")'

  query <- glue::glue_sql(create_stations_index,.con = con)
  DBI::dbExecute(con, query)

  # Create datatables --------------------------------------------------

  print("Creating awqms Table")
  # Create AWQMS data table

  awqms_tbl_create_query <- "CREATE TABLE IF NOT EXISTS `awqms` (
`OrganizationID` TEXT NOT NULL,
`Org_Name` TEXT  NOT NULL,
`Project1` TEXT  NOT NULL,
`Project2` TEXT,
`Project3` TEXT,
`MLocID` TEXT  NOT NULL,
`act_id` TEXT,
`Activity_Type` TEXT,
`SampleStartDate` TEXT  NOT NULL,
`SampleStartTime` TEXT  NOT NULL,
`SampleStartTZ` TEXT  NOT NULL,
`SampleMedia` TEXT  NOT NULL,
`SampleSubmedia` TEXT,
`SamplingMethod` TEXT,
`chr_uid` INTEGER,
`Char_Name` TEXT  NOT NULL,
`Char_Speciation` TEXT,
`Sample_Fraction` TEXT,
`CASNumber` TEXT,
`Result_UID` INTEGER,
`Result_status` TEXT,
`Result_Type` TEXT,
`Result` TEXT,
`Result_Numeric` REAL,
`Result_Operator` TEXT,
`Result_Unit` TEXT,
`Unit_UID` INTEGER,
`ResultCondName` TEXT,
`RelativeDepth` TEXT,
`Result_Depth` TEXT,
`Result_Depth_Unit` TEXT,
`Result_Depth_Reference` TEXT,
`act_depth_height` TEXT,
`ActDepthUnit` TEXT,
`Act_depth_Reference` TEXT,
`Act_Depth_Top` TEXT,
`Act_Depth_Top_Unit` TEXT,
`Act_Depth_Bottom` TEXT,
`Act_Depth_Bottom_Unit` TEXT,
`Time_Basis` TEXT,
`Statistical_Base` TEXT,
`Statistic_N_Value` REAL,
`act_sam_compnt_name` TEXT,
`stant_name` TEXT,
`Bio_Intent` TEXT,
`Taxonomic_Name` TEXT,
`Analytical_method` TEXT,
`Method_Code` TEXT,
`Method_Context` TEXT,
`Analytical_Lab` TEXT,
`Activity_Comment` TEXT,
`Result_Comment` TEXT,
`lab_Comments` TEXT,
`QualifierAbbr` TEXT,
`QualifierTxt` TEXT,
`IDLType` TEXT,
`IDLValue` REAL,
`IDLUnit` TEXT,
`MDLType` TEXT,
`MDLValue` REAL,
`MDLUnit` TEXT,
`MRLType` TEXT,
`MRLValue` REAL,
`MRLUnit` TEXT,
`URLType` TEXT,
`URLValue` REAL,
`URLUnit` TEXT,
`WQX_submit_date` REAL,
PRIMARY KEY(Result_UID),
FOREIGN KEY(OrganizationID, MLocID) REFERENCES stations(OrgID,MLocID),
FOREIGN KEY(Char_Name) REFERENCES characteristics(Char_Name)
)"

  query <- glue::glue_sql(awqms_tbl_create_query,.con = con)
  DBI::dbExecute(con, query)

  create_awqms_index <- 'CREATE INDEX IF NOT EXISTS "index_awqms" ON "awqms" (
  "OrgID",
  "MLocID",
  "Char_Name",
  "Char_Speciation",
  "Sample_Fraction",
  "SampleStartDate",
  "SampleStartTime",
  "Statistical_Base")'

  query <- glue::glue_sql(create_awqms_index,.con = con)
  DBI::dbExecute(con, query)

  # Other data table --------------------------------------------------------
  print("Creating other Table")

  other_tbl_create_query <- "CREATE TABLE IF NOT EXISTS `other` (
`OrganizationID` TEXT NOT NULL,
`Org_Name` TEXT  NOT NULL,
`Project1` TEXT  ,
`Project2` TEXT,
`Project3` TEXT,
`MLocID` TEXT  NOT NULL,
`act_id` TEXT,
`Activity_Type` TEXT,
`SampleStartDate` TEXT  NOT NULL,
`SampleStartTime` TEXT  NOT NULL,
`SampleStartTZ` TEXT  NOT NULL,
`SampleMedia` TEXT  NOT NULL,
`SampleSubmedia` TEXT,
`SamplingMethod` TEXT,
`chr_uid` INTEGER,
`Char_Name` TEXT  NOT NULL,
`Char_Speciation` TEXT,
`Sample_Fraction` TEXT,
`CASNumber` TEXT,
`Result_UID` INTEGER,
`Result_status` TEXT,
`Result_Type` TEXT,
`Result` TEXT,
`Result_Numeric` REAL,
`Result_Operator` TEXT,
`Result_Unit` TEXT,
`Unit_UID` INTEGER,
`ResultCondName` TEXT,
`RelativeDepth` TEXT,
`Result_Depth` TEXT,
`Result_Depth_Unit` TEXT,
`Result_Depth_Reference` TEXT,
`act_depth_height` TEXT,
`ActDepthUnit` TEXT,
`Act_depth_Reference` TEXT,
`Act_Depth_Top` TEXT,
`Act_Depth_Top_Unit` TEXT,
`Act_Depth_Bottom` TEXT,
`Act_Depth_Bottom_Unit` TEXT,
`Time_Basis` TEXT,
`Statistical_Base` TEXT,
`Statistic_N_Value` REAL,
`act_sam_compnt_name` TEXT,
`stant_name` TEXT,
`Bio_Intent` TEXT,
`Taxonomic_Name` TEXT,
`Analytical_method` TEXT,
`Method_Code` TEXT,
`Method_Context` TEXT,
`Analytical_Lab` TEXT,
`Activity_Comment` TEXT,
`Result_Comment` TEXT,
`lab_Comments` TEXT,
`QualifierAbbr` TEXT,
`QualifierTxt` TEXT,
`IDLType` TEXT,
`IDLValue` REAL,
`IDLUnit` TEXT,
`MDLType` TEXT,
`MDLValue` REAL,
`MDLUnit` TEXT,
`MRLType` TEXT,
`MRLValue` REAL,
`MRLUnit` TEXT,
`URLType` TEXT,
`URLValue` REAL,
`URLUnit` TEXT,
`WQX_submit_date` REAL,
FOREIGN KEY(OrganizationID, MLocID) REFERENCES stations(OrgID,MLocID ),
FOREIGN KEY(Char_Name) REFERENCES characteristics(Char_Name)
)"

  query <- glue::glue_sql(other_tbl_create_query,.con = con)
  DBI::dbExecute(con, query)

  create_other_tbl_index <- 'CREATE INDEX IF NOT EXISTS "index_other" ON "other" (
  "OrgID",
  "MLocID",
  "Char_Name",
  "Char_Speciation",
  "Sample_Fraction",
  "SampleStartDate",
  "SampleStartTime",
  "Statistical_Base")'

  query <- glue::glue_sql(create_other_tbl_index,.con = con)
  DBI::dbExecute(con, query)

  # Create continuous data table --------------------------------------------

  print("Creating continuous Table")

  cont_tbl_create <- 'CREATE TABLE IF NOT EXISTS "continuous" (
  "OrganizationID"	TEXT NOT NULL,
  "MLocID"	TEXT NOT NULL,
  "SampleStartDate"	TEXT NOT NULL,
  "SampleStartTime"	TEXT NOT NULL,
  "SampleStartTZ" TEXT NOT NULL,
  "SampleMedia"	TEXT,
  "MediaSubdivisionName"	TEXT,
  "Result_Depth"	REAL,
  "Char_Name"	TEXT,
  "Result"	REAL,
  "Result_Unit"	TEXT,
  "Result_status"	TEXT,
  "EquipmentID"	TEXT,
  "Project1"	TEXT,
  "Project2"	TEXT,
  "Project3"	TEXT,
FOREIGN KEY(OrganizationID, MLocID) REFERENCES stations(OrgID, MLocID ),
FOREIGN KEY(Char_Name) REFERENCES characteristics(Char_Name)
)'

  DBI::dbExecute(con, cont_tbl_create)

  create_continuous_index <- 'CREATE UNIQUE INDEX IF NOT EXISTS "index_continuous" ON "continuous" (
  "OrganizationID",
  "MLocID",
  "SampleStartDate",
  "SampleStartTime",
  "SampleMedia",
  "MediaSubdivisionName",
  "Result_Depth",
  "Char_Name",
  "EquipmentID")'

  DBI::dbExecute(con, create_continuous_index)

  # Create data views --------------------------------------------------------


  # discrete data view ------------------------------------------------------


  print("Create data view")

  create_data_view <- "CREATE VIEW IF NOT EXISTS vw_discrete
AS
SELECT
a.OrganizationID,
a.Org_Name,
a.Project1,
a.Project2,
a.Project3,
a.MLocID,
b.StationDes,
b.MonLocType,
b.EcoRegion3,
b.EcoRegion4,
b.HUC8,
b.HUC8_Name,
b.HUC10,
b.HUC12,
b.HUC12_Name,
b.Lat_DD,
b.Long_DD,
b.Reachcode,
b.Measure,
b.AU_ID,
a.act_id,
a.Activity_Type,
a.SampleStartDate,
a.SampleStartTime,
a.SampleStartTZ,
a.SampleMedia,
a.SampleSubmedia,
a.SamplingMethod,
a.chr_uid,
a.Char_Name,
a.Char_Speciation,
a.Sample_Fraction,
a.CASNumber,
a.Result_UID,
a.Result_status,
a.Result_Type,
a.Result,
a.Result_Numeric,
a.Result_Operator,
a.Result_Unit,
a.Unit_UID,
a.ResultCondName,
a.RelativeDepth,
a.Result_Depth,
a.Result_Depth_Unit,
a.Result_Depth_Reference,
a.act_depth_height,
a.ActDepthUnit,
a.Act_depth_Reference,
a.Act_Depth_Top,
a.Act_Depth_Top_Unit,
a.Act_Depth_Bottom,
a.Act_Depth_Bottom_Unit,
a.Time_Basis,
a.Statistical_Base,
a.Statistic_N_Value,
a.act_sam_compnt_name,
a.stant_name,
a.Bio_Intent,
a.Taxonomic_Name,
a.Analytical_method,
a.Method_Code,
a.Method_Context,
a.Analytical_Lab,
a.Activity_Comment,
a.Result_Comment,
a.lab_Comments,
a.QualifierAbbr,
a.QualifierTxt,
a.IDLType,
a.IDLValue,
a.IDLUnit,
a.MDLType,
a.MDLValue,
a.MDLUnit,
a.MRLType,
a.MRLValue,
a.MRLUnit,
a.URLType,
a.URLValue,
a.URLUnit,
b.WaterTypeCode,
b.WaterBodyCode,
b.FishCode,
b.SpawnCode,
b.BacteriaCode,
b.DO_code,
b.DO_SpawnCode,
b.ben_use_code,
b.OWRD_Basin,
b.pH_code
FROM awqms a
LEFT OUTER JOIN
stations b ON a.OrganizationID = b.OrgID AND a.MLocID = b.MLocID
UNION
SELECT
a.OrganizationID,
a.Org_Name,
a.Project1,
a.Project2,
a.Project3,
a.MLocID,
b.StationDes,
b.MonLocType,
b.EcoRegion3,
b.EcoRegion4,
b.HUC8,
b.HUC8_Name,
b.HUC10,
b.HUC12,
b.HUC12_Name,
b.Lat_DD,
b.Long_DD,
b.Reachcode,
b.Measure,
b.AU_ID,
a.act_id,
a.Activity_Type,
a.SampleStartDate,
a.SampleStartTime,
a.SampleStartTZ,
a.SampleMedia,
a.SampleSubmedia,
a.SamplingMethod,
a.chr_uid,
a.Char_Name,
a.Char_Speciation,
a.Sample_Fraction,
a.CASNumber,
a.Result_UID,
a.Result_status,
a.Result_Type,
a.Result,
a.Result_Numeric,
a.Result_Operator,
a.Result_Unit,
a.Unit_UID,
a.ResultCondName,
a.RelativeDepth,
a.Result_Depth,
a.Result_Depth_Unit,
a.Result_Depth_Reference,
a.act_depth_height,
a.ActDepthUnit,
a.Act_depth_Reference,
a.Act_Depth_Top,
a.Act_Depth_Top_Unit,
a.Act_Depth_Bottom,
a.Act_Depth_Bottom_Unit,
a.Time_Basis,
a.Statistical_Base,
a.Statistic_N_Value,
a.act_sam_compnt_name,
a.stant_name,
a.Bio_Intent,
a.Taxonomic_Name,
a.Analytical_method,
a.Method_Code,
a.Method_Context,
a.Analytical_Lab,
a.Activity_Comment,
a.Result_Comment,
a.lab_Comments,
a.QualifierAbbr,
a.QualifierTxt,
a.IDLType,
a.IDLValue,
a.IDLUnit,
a.MDLType,
a.MDLValue,
a.MDLUnit,
a.MRLType,
a.MRLValue,
a.MRLUnit,
a.URLType,
a.URLValue,
a.URLUnit,
b.WaterTypeCode,
b.WaterBodyCode,
b.FishCode,
b.SpawnCode,
b.BacteriaCode,
b.DO_code,
b.DO_SpawnCode,
b.ben_use_code,
b.OWRD_Basin,
b.pH_code
FROM other a
LEFT OUTER JOIN
stations b ON a.OrganizationID = b.OrgID AND a.MLocID = b.MLocID"

  DBI::dbExecute(con, create_data_view)


  # Continuous data view ----------------------------------------------------

  create_cont_data_view <- "CREATE VIEW IF NOT EXISTS vw_continuous AS
SELECT
a.OrganizationID
,a.MLocID
,b.StationDes
,b.MonLocType
,b.EcoRegion3
,b.EcoRegion4
,b.HUC8
,b.HUC8_Name
,b.HUC10
,b.HUC12
,b.HUC12_Name
,b.Lat_DD
,b.Long_DD
,b.Reachcode
,b.Measure
,b.AU_ID
,a.SampleStartDate
,a.SampleStartTime
,a.SampleMedia
,a.MediaSubdivisionName
,a.Result_Depth
,a.Char_Name
,a.Result
,a.Result_Unit
,a.Result_status
,a.EquipmentID
,a.Project1
,a.Project2
,a.Project3
,b.WaterTypeCode
,b.WaterBodyCode
,b.FishCode
,b.SpawnCode
,b.BacteriaCode
,b.DO_code
,b.DO_SpawnCode
,b.ben_use_code
,b.OWRD_Basin
,b.pH_code

From continuous a
LEFT OUTER JOIN
stations b ON a.OrganizationID = b.OrgID AND a.MLocID = b.MLocID
order by a.MLocID, a.SampleStartDate, a.SampleStartTime"

  DBI::dbExecute(con, create_cont_data_view)

  DBI::dbDisconnect(con)




}

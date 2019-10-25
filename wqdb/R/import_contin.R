#' Import continuous result information from a template xlsx file.
#'
#' Retrieve monitoring results from Oregon DEQ's continuous data submission template xlsx file. The script will read the template and return a dataframe
#' formatted for use in a wqdb SQLite database. Only Result Status IDs that are "Final" are included.
#'
#' @param file The path and file name to template xlsx file.
#' @param orgID The ID of the organization who is responsible for the data.
#' @param orgname The name of the organization who is responsible for the data.
#' @export
#' @return Dataframe of continuous result data formatted for use in a wqdb SQLite database

import_contin <- function(file, orgID, orgname) {

  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(readxl)
  library(zoo)

  options(scipen=999)

  # Import Project Info -------------------------------------------------------------------

  projects_col_types <- c('text', 'text', 'text', 'text', 'text', 'text', 'text')

  projects_import <- readxl::read_excel(file, sheet = "Projects", col_types = projects_col_types)

  colnames(projects_import) <- make.names(names(projects_import), unique=TRUE)

  # Import Locations Info -------------------------------------------------------------------

  locations_col_types <- c('text', 'text', 'text', 'numeric', 'numeric', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'text', 'date', 'text', 'text', 'text', 'text', 'text',
                           'text', 'text', 'text', 'text', 'text', 'numeric', 'text', 'numeric')

  locations_import <- readxl::read_excel(file, sheet = "Monitoring_Locations", col_types = locations_col_types)

  colnames(locations_import) <- make.names(names(locations_import), unique=TRUE)

  # Import Results -------------------------------------------------------------------

  results_col_types <- c('text', 'date', 'date', 'text', 'text', 'text', 'numeric', 'text', 'text')

  # read results tab of submitted file
  Results_import <- readxl::read_excel(file, sheet = "Results", col_types = results_col_types)
  colnames(Results_import) <- make.names(names(Results_import), unique=TRUE)

  # convert F to C, filter out rejected data, and create datetime column
  results_data <- Results_import %>%
    dplyr::mutate(r = ifelse(Result.Unit == "deg F", round((Result.Value - 32)*(5/9),2), Result.Value),
                  r_units = ifelse(Result.Unit == "deg F", "deg C", Result.Unit )) %>%
    dplyr::filter(!Result.Status.ID %in% c("Rejected")) %>%
    dplyr::mutate(time_char = strftime(Activity.Start.Time, format = "%H:%M:%S", tz = 'UTC'),
                  datetime = lubridate::ymd_hms(paste(as.Date(Activity.Start.Date), time_char))) %>%
    dplyr::arrange(Monitoring.Location.ID, datetime) %>%
    dplyr::rename(Equipment = Equipment.ID..)

  # Read Audit Data ---------------------------------------------------------
  #
  # audit_col_types <- c('text', 'text', 'text', 'text', 'date', 'date', 'date', 'date', 'text', 'text',
  #                      'text', 'text', 'text', 'text', 'numeric', 'text', 'text', 'text', 'text', 'text',
  #                      'text', 'text')
  #
  # Audit_import <- readxl::read_excel(file, sheet = "Audit_Data", col_types = audit_col_types)
  #
  # colnames(Audit_import) <- make.names(names(Audit_import), unique=TRUE)
  #
  # # get rid of extra blankfields
  # Audits <- Audit_import %>%
  #   filter(!is.na(Project.ID))
  #
  # # table of methods unique to project, location, equipment, char, and method
  # Audits_unique <- unique(Audits[c("Project.ID", "Monitoring.Location.ID", "Equipment.ID..", "Characteristic.Name", "Result.Analytical.Method.ID")])
  #
  #
  #
  # # Reformat Audit info
  # matches Dan Brown's import configuration
  # If template has Result.Qualifier as column, use that value, if not use blank.
  # Audit_info <- Audits %>%
  #   mutate(Result.Qualifier = ifelse("Result.Qualifier" %in% colnames(Audits), Result.Qualifier, "" ),
  #          Activity.Start.Time = as.character(strftime(Activity.Start.Time, format = "%H:%M:%S", tz = "UTC")),
  #          Activity.End.Time = as.character(strftime(Activity.End.Time, format = "%H:%M:%S", tz = "UTC")) ) %>%
  #   select(Project.ID, Monitoring.Location.ID, Activity.Start.Date,
  #          Activity.Start.Time, Activity.End.Date, Activity.End.Time,
  #          Activity.Start.End.Time.Zone, Activity.Type,
  #          Activity.ID..Column.Locked., Equipment.ID.., Sample.Collection.Method,
  #          Characteristic.Name, Result.Value, Result.Unit, Result.Analytical.Method.ID,
  #          Result.Analytical.Method.Context, Result.Value.Type, Result.Status.ID,
  #          Result.Qualifier, Result.Comment)

  # AWQMS summary stats -----------------------------------------------------

  #   dplyr::left_join(Audits_unique, by = c("Monitoring.Location.ID", "Characteristic.Name" = "Characteristic.Name") )

    results_data2 <- results_data %>%
    dplyr::filter(Result.Status.ID == 'Final') %>%
    dplyr::mutate(Result.Analytical.Method.ID = dplyr::case_when(Characteristic.Name == "Conductivity" ~ "120.1",
                                                          Characteristic.Name %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "NFM 6.2.1-LUM",
                                                          Characteristic.Name == "pH" ~ "150.1",
                                                          Characteristic.Name == "Temperature, water" ~ "170.1",
                                                          Characteristic.Name == "Turbidity" ~ "180.1",
                                                          TRUE ~ "error"),
                  Method_Context = dplyr::case_when(Characteristic.Name == "Conductivity" ~ "U.S. Environmental Protection Agency",
                                                    Characteristic.Name %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "USDOI/USGS",
                                                    Characteristic.Name == "pH" ~ "U.S. Environmental Protection Agency",
                                                    Characteristic.Name == "Temperature, water" ~ "U.S. Environmental Protection Agency",
                                                    Characteristic.Name == "Turbidity" ~ "U.S. Environmental Protection Agency",
                                                    TRUE ~ as.character(NA)),
                  Analytical_method = dplyr::case_when(Characteristic.Name == "Conductivity" ~ "Conductance",
                                                       Characteristic.Name %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "Dissolved-oxygen concentration, field measurement by luminescent sensor",
                                                       Characteristic.Name == "pH" ~ "pH",
                                                       Characteristic.Name == "Temperature, water" ~ "Temperature",
                                                       Characteristic.Name == "Turbidity" ~ "Turbidity by Nephelometry",
                                                       TRUE ~ as.character(NA)),
                  SamplingMethod = "ContinuousPrb",
                  SmplColEquip = "Probe/Sensor",
                  SmplColEquipComment = as.character(NA),
                  Samplers = as.character(NA),
                  Project = projects_import$Project.Name,
                  AnaStartDate = as.character(NA),
                  AnaStartTime = as.character(NA),
                  AnaEndDate = as.character(NA),
                  AnaEndTime = as.character(NA),
                  ActStartDate = format(datetime, "%Y-%m-%d"),
                  ActStartTime = format(datetime, "%H:%M"),
                  ActEndDate = format(datetime, "%Y-%m-%d"),
                  ActEndTime = format(datetime, "%H:%M"),
                  RsltType = "Actual",
                  ActStartTimeZone = Activity.Start.End.Time.Zone,
                  ActEndTimeZone = Activity.Start.End.Time.Zone,
                  AnaStartTimeZone = as.character(NA),
                  AnaEndTimeZone = as.character(NA),
                  Result_Numeric = round(Result.Value, digits = 2),
                  Result = as.character(Result_Numeric))

  df.final <- results_data2 %>%
    dplyr::select(Char_Name=Characteristic.Name,
                  Result,
                  Result_Numeric,
                  Result_Unit=r_units,
                  Result_status=Result.Status.ID,
                  Method_Code=Result.Analytical.Method.ID,
                  Result_Type=RsltType,
                  MLocID=Monitoring.Location.ID,
                  Project1=Project,
                  SamplingMethod,
                  Analytical_method,
                  Method_Context,
                  SampleStartDate=ActStartDate,
                  SampleStartTime=ActStartTime,
                  SampleStartTZ=ActStartTimeZone) %>%
    dplyr::left_join(wqdb::AWQMS_chars, by="Char_Name") %>%
    dplyr::mutate(Activity_Type = "FMC",
                  OrganizationID=orgID,
                  Org_Name=orgname,
                  Project2=as.character(NA),
                  Project3=as.character(NA),
                  act_id=as.character(NA),
                  SampleMedia="Water",
                  Result_Depth=as.character(NA),
                  Result_Depth_Unit=as.character(NA),
                  SampleSubmedia=as.character(NA),
                  Char_Speciation=as.character(NA),
                  Sample_Fraction=as.character(NA),
                  Result_UID=as.character(NA),
                  Result_Operator = "=",
                  Unit_UID=as.character(NA),
                  ResultCondName=as.character(NA),
                  RelativeDepth=as.character(NA),
                  Result_Depth=as.character(NA),
                  Result_Depth_Unit=as.character(NA),
                  Result_Depth_Reference=as.character(NA),
                  act_depth_height=as.character(NA),
                  ActDepthUnit=as.character(NA),
                  Act_depth_Reference=as.character(NA),
                  Act_Depth_Top=as.character(NA),
                  Act_Depth_Top_Unit=as.character(NA),
                  Act_Depth_Bottom=as.character(NA),
                  Act_Depth_Bottom_Unit=as.character(NA),
                  Statistical_Base=as.character(NA),
                  Statistic_N_Value=as.character(NA),
                  Time_Basis=as.character(NA),
                  act_sam_compnt_name=as.character(NA),
                  stant_name=as.character(NA),
                  Bio_Intent=as.character(NA),
                  Taxonomic_Name=as.character(NA),
                  Analytical_Lab=as.character(NA),
                  Activity_Comment=as.character(NA),
                  Result_Comment=as.character(NA),
                  lab_Comments=as.character(NA),
                  QualifierAbbr=as.character(NA),
                  QualifierTxt=as.character(NA),
                  IDLType=as.character(NA),
                  IDLValue=as.character(NA),
                  IDLUnit=as.character(NA),
                  MDLType=as.character(NA),
                  MDLValue=as.character(NA),
                  MDLUnit=as.character(NA),
                  MRLType=as.character(NA),
                  MRLValue=as.character(NA),
                  MRLUnit=as.character(NA),
                  URLType=as.character(NA),
                  URLValue=as.character(NA),
                  URLUnit=as.character(NA),
                  WQX_submit_date=as.character(NA)) %>%
    dplyr::select(wqdb::awqms_cols(),)

  return(df.final)

}

#' Import continuous result information from a template xlsx file and summarize into summary statistics.
#'
#' Retrieve monitoring results from Oregon DEQ's continuous data submission template xlsx file. The script will read the "Results" worksheet and
#' calculate summary stats including the daily minimum, daily mean, daily maximum, and 7-day average of the daily maximums. For dissolved oxygen results with sufficient
#' number of observations the 30 day average daily mean is calculated. Returns a dataframe formatted for use in a wqdb SQLite database.
#'
#' @param file The path and file name to template xlsx file.
#' @param orgID The ID of the organization who is responsible for the data.
#' @param orgname The name of the organization who is responsible for the data.
#' @export
#' @return Dataframe of calculated summary stats formatted for use in a wqdb SQLite database

import_contin_summary <- function(file, orgID, orgname) {

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
                  datetime = lubridate::ymd_hms(paste(as.Date(Activity.Start.Date), time_char)),
                  Activity.Start.Date = as.Date(Activity.Start.Date))

  # get unique list of characteristics to run for loop through
  unique_characteritics <- unique(Results_import$Characteristic.Name)

  #create list for getting data out of loop
  monloc_do_list <- list()
  sumstatlist <- list()

  # For loop for summary statistics -----------------------------------------

  # Loop goes through each characteristc and generates summary stats
  # After loop, data gets pushed into single table
  for (i in 1:length(unique_characteritics)){

    print(paste("Begin",  unique_characteritics[i], "- characteristic", i, "of", length(unique_characteritics)))

    # Characteristic for this loop iteration
    char <- unique_characteritics[i]

    # Filter so table only contains single characteristic
    results_data_char <- results_data %>%
      dplyr::filter(Characteristic.Name == char) %>%
      # generare unique hour field for hourly values and stats
      dplyr::mutate(hr =  format(datetime, "%Y-%j-%H"))

    # Simplify to hourly values and Stats
    hrsum <- results_data_char %>%
      dplyr::group_by(Monitoring.Location.ID, Equipment.ID.., hr, r_units, Activity.Start.End.Time.Zone) %>%
      dplyr::summarise(date = mean(Activity.Start.Date),
                       hrDTmin = min(datetime),
                       hrDTmax = max(datetime),
                       hrN = sum(!is.na(r)),
                       hrMean = mean(r, na.rm=TRUE),
                       hrMin = min(r, na.rm=TRUE),
                       hrMax = max(r, na.rm=TRUE))

    # For each date, how many hours have hrN > 0
    # remove rows with zero records in an hour.
    hrdat<- hrsum[which(hrsum$hrN >0),]

    # Summarise to daily statistics
    daydat <- hrdat %>%
      dplyr::group_by(Monitoring.Location.ID, Equipment.ID.., date, r_units, Activity.Start.End.Time.Zone) %>%
      dplyr::summarise(dDTmin = min(hrDTmin),
                       dDTmax = max(hrDTmax),
                       hrNday = length(hrN),
                       dyN = sum(hrN),
                       dyMean = mean(hrMean, na.rm=TRUE),
                       dyMin = min(hrMin, na.rm=TRUE),
                       dyMax = max(hrMax, na.rm=TRUE))

    daydat <- daydat %>%
      dplyr::rowwise() %>%
      dplyr::mutate(ResultStatusID = ifelse(hrNday >= 22, 'Final', "Rejected")) %>%
      dplyr::mutate(cmnt =ifelse(hrNday >= 22, "Generated by ORDEQ",
                                 ifelse(hrNday <= 22 & hrNday >= 20,
                                        paste0("Generated by ORDEQ; Estimated - ", as.character(hrNday), ' hrs with valid data in day' ),
                                        paste0("Generated by ORDEQ; Rejected - ", as.character(hrNday), ' hrs with valid data in day' )) )) %>%
      dplyr::mutate(ma.mean7 = as.numeric(""),
                    ma.min7 = as.numeric(""),
                    ma.mean30 = as.numeric(""),
                    ma.max7 = as.numeric(""))

    #Deal with DO Results
    if (results_data_char$Characteristic.Name[1] == "Dissolved oxygen (DO)") {

      #monitoring location loop
      for(j in 1:length(unique(daydat$Monitoring.Location.ID))){
        print(paste("Station", j, "of", length(unique(daydat$Monitoring.Location.ID))))

        station <- unique(daydat$Monitoring.Location.ID)[j]

        #Filter dataset to only look at 1 monitoring location at a time
        daydat_station <- daydat %>%
          dplyr::filter(Monitoring.Location.ID == station) %>%
          dplyr::mutate(startdate7 = as.Date(date) - 6,
                        startdate30 = as.Date(date) -30)

        # 7 day loop
        # Loops throough each row in the monitoring location dataset
        # And pulls out records that are within the preceding 7 day window
        # If there are at least 6 values, then calculate 7 day min and mean
        # Assigns data back to daydat_station

        print("Begin 7 day moving averages")

        for(k in 1:nrow(daydat_station)){

          start7 <- daydat_station$startdate7[k]
          end7 <- daydat_station$date[k]

          station_7day <- daydat_station %>%
            dplyr::filter(date <= end7 & date >= start7) %>%
            dplyr::filter(hrNday >= 22)

          ma.mean7 <- ifelse(length(unique(station_7day$date)) >= 6, mean(station_7day$dyMean), NA )
          ma.min7 <- ifelse(length(unique(station_7day$date)) >= 6, mean(station_7day$dyMin), NA )

          daydat_station[k,"ma.mean7"] <- ifelse(k >=7, ma.mean7, NA)
          daydat_station[k, "ma.min7"] <- ifelse(k >=7, ma.min7, NA)

        } #end of 7day loop

        # 30 day loop
        # Loops throough each row in the monitoring location dataset
        # And pulls out records that are within the preceding 30 day window
        # If there are at least 29 values, then calculate 30 day mean
        # Assigns data back to daydat_station

        print("Begin 30 day moving averages" )

        for(l in 1:nrow(daydat_station)){


          start30 <- daydat_station$startdate30[l]
          end30 <- daydat_station$date[l]

          station_30day <- daydat_station %>%
            dplyr::filter(date <= end30 & date >= start30) %>%
            dplyr::filter(hrNday >= 22)

          ma.mean30 <- ifelse(length(unique(station_30day$date)) >= 29, mean(station_30day$dyMean), NA )

          daydat_station[l,"ma.mean30"] <- ifelse(l >= 30, ma.mean30, NA)

        } #end of 30day loop

        # Assign dataset filtered to 1 monitoring location to a list for combining outside of for loop
        monloc_do_list[[j]] <- daydat_station

      } # end of monitoring location for loop

      # Combine list to single dataframe
      sum_stats <- dplyr::bind_rows(monloc_do_list)

    } # end of DO if statement

    ##  TEMPERATURE

    if (results_data_char$Characteristic.Name[1] == 'Temperature, water' ) {

      # Temperature is much easier to calculate, since it needs a complete 7 day record to calculate the 7day moving average
      # This can happen with a simple grouping
      sum_stats <- daydat %>%
        dplyr::arrange(Monitoring.Location.ID, date) %>%
        dplyr::group_by(Monitoring.Location.ID) %>%
        dplyr::mutate(startdate7 = lag(date, 6, order_by = date),
                      macmt = paste(lag(ResultStatusID, 6),
                                    lag(ResultStatusID, 5),
                                    lag(ResultStatusID, 4),
                                    lag(ResultStatusID, 3),
                                    lag(ResultStatusID, 2),
                                    lag(ResultStatusID, 1)),
                      # flag out which result gets a moving average calculated
                      calc7ma = ifelse(startdate7 == (as.Date(date) - 6) & (!grepl("Rejected",macmt )), 1, 0 ))%>%
        dplyr::mutate(ma.max7 = ifelse(calc7ma == 1 ,round(zoo::rollmean(x = dyMax, 7, align = "right", fill = NA),2) , NA )) %>%
        dplyr::select(-startdate7, -calc7ma, -macmt )

    } #end of temp if statement

    ## Other - just set sum_stats to daydat, since no moving averages need to be generated.
    if (results_data_char$Characteristic.Name[1] != 'Temperature, water' & results_data_char$Characteristic.Name[1] != "Dissolved oxygen (DO)"  ) {

      sum_stats <- daydat

    } #end of not DO or temp statement

    #Assign the char ID to the dataset
    sum_stats <- sum_stats %>%
      dplyr::mutate(charID = char)

    #Set to list for getting out of for loop
    sumstatlist[[i]] <-  sum_stats

  } # end of characteristics for loop

  # Bind list to dataframe
  sumstat <- bind_rows(sumstatlist)

  #Gather summary statistics from wide format into long format
  #rename summary statistcs to match AWQMS Import COnfiguration
  sumstat_long <- sumstat %>%
    dplyr::rename("Maximum" = dyMax,
                  "Minimum" = dyMin,
                  "Mean"    = dyMean,
                  "7DADMin" = ma.min7,
                  "7DADMean"= ma.mean7,
                  "7DADM"   = ma.max7,
                  "30DADMean" = ma.mean30) %>%
    tidyr::gather(
      "Maximum",
      "Minimum",
      "Mean",
      "7DADMin",
      "7DADMean",
      "7DADM",
      "30DADMean",
      key = "StatisticalBasis",
      value = "Result",
      na.rm = TRUE
    ) %>%
    dplyr::arrange(Monitoring.Location.ID, date) %>%
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

  # Join method to sumstat table
  # sumstat_long <- sumstat_long %>%
  #   mutate(Equipment = as.character(Equipment)) %>%
  #   left_join(Audits_unique, by = c("Monitoring.Location.ID", "charID" = "Characteristic.Name") )

  AWQMS_sum_stat <- sumstat_long %>%
    dplyr::mutate(RsltTimeBasis = dplyr::case_when(StatisticalBasis %in% c("7DADMin","7DADMean","7DADM") ~ "7 Day",
                                            StatisticalBasis == "30DADMean" ~ "30 Day",
                                            TRUE ~ "1 Day"),
                  ActivityType = "FMC",
                  Result.Analytical.Method.ID = dplyr::case_when(charID == "Conductivity" ~ "120.1",
                                                          charID %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "NFM 6.2.1-LUM",
                                                          charID == "pH" ~ "150.1",
                                                          charID == "Temperature, water" ~ "170.1",
                                                          charID == "Turbidity" ~ "180.1",
                                                          TRUE ~ "error"),
                  SmplColMthd = "ContinuousPrb",
                  SmplColEquip = "Probe/Sensor",
                  SmplDepth = "",
                  SmplDepthUnit = "",
                  SmplColEquipComment = "",
                  Samplers = "",
                  Project = projects_import$Project.Name,
                  AnaStartDate = "",
                  AnaStartTime = "",
                  AnaEndDate = "",
                  AnaEndTime = "",
                  ActStartDate = format(dDTmax, "%Y-%m-%d"),
                  ActStartTime = format(dDTmax, "%H:%M"),
                  ActEndDate = format(dDTmax, "%Y-%m-%d"),
                  ActEndTime = format(dDTmax, "%H:%M"),
                  RsltType = "Calculated",
                  ActStartTimeZone = Activity.Start.End.Time.Zone,
                  ActEndTimeZone = Activity.Start.End.Time.Zone,
                  AnaStartTimeZone = "",
                  AnaEndTimeZone = "",
                  Result = round(Result, digits = 2))

  df.final <- AWQMS_sum_stat %>%
    dplyr::select(Char_Name=charID,
                  Result,
                  Result_Unit=r_units,
                  Method_Code=Result.Analytical.Method.ID,
                  Result_Type=RsltType,
                  Result_status=ResultStatusID,
                  Statistical_Base=StatisticalBasis,
                  Time_Basis=RsltTimeBasis,
                  Result_Comment=cmnt,
                  Activity_Type=ActivityType,
                  MLocID=Monitoring.Location.ID,
                  SamplingMethod=SmplColMthd,
                  Result_Depth=SmplDepth,
                  Result_Depth_Unit=SmplDepthUnit,
                  Project1=Project,
                  SampleStartDate=ActStartDate,
                  SampleStartTime=ActStartTime,
                  SampleStartTZ=ActStartTimeZone) %>%
    dplyr::left_join(wqdb::AWQMS_chars, by="Char_Name") %>%
    dplyr::mutate(Method_Context = dplyr::case_when(Char_Name == "Conductivity" ~ "U.S. Environmental Protection Agency",
                                             Char_Name %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "USDOI/USGS",
                                             Char_Name == "pH" ~ "U.S. Environmental Protection Agency",
                                             Char_Name == "Temperature, water" ~ "U.S. Environmental Protection Agency",
                                             Char_Name == "Turbidity" ~ "U.S. Environmental Protection Agency",
                                             TRUE ~ as.character(NA)),
                  Analytical_method = dplyr::case_when(Char_Name == "Conductivity" ~ "Conductance",
                                                Char_Name %in% c("Dissolved oxygen (DO)", "Dissolved oxygen saturation") ~ "Dissolved-oxygen concentration, field measurement by luminescent sensor",
                                                Char_Name == "pH" ~ "pH",
                                                Char_Name == "Temperature, water" ~ "Temperature",
                                                Char_Name == "Turbidity" ~ "Turbidity by Nephelometry",
                                                TRUE ~ as.character(NA)),
                  OrganizationID=orgID,
                  Org_Name=orgname,
                  Project2=as.character(NA),
                  Project3=as.character(NA),
                  act_id=as.character(NA),
                  SampleMedia="Water",
                  SampleSubmedia=as.character(NA),
                  Char_Speciation=as.character(NA),
                  Sample_Fraction=as.character(NA),
                  Result = as.character(Result),
                  Result_Numeric = as.numeric(Result),
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
                  Statistic_N_Value=as.character(NA),
                  act_sam_compnt_name=as.character(NA),
                  stant_name=as.character(NA),
                  Bio_Intent=as.character(NA),
                  Taxonomic_Name=as.character(NA),
                  Analytical_Lab=as.character(NA),
                  Activity_Comment=as.character(NA),
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

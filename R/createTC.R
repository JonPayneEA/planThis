#' @title Create Time card
#'
#' @description Function that links daily hours to outlook calendars to produce an OTL form
#'
#' @param categories Link to your categories file (csv)
#' @param daily Link to your daily hours (xlsx)
#' @param outCal Link to your Outlook export file (csv)
#' @param week_start The week of interest
#' @param split A selection of projects to split time between
#' @param weight Weighting factor for each project
#' @param pathOTL Link to folder where you wish the OTL data to be exported to
#' @param export Set as True - saves the OTL form in your pathOTL folder
#'
#' @return
#' @export
#' @import dplyr
#' @import lubridate
#' @import magrittr
#' @import readr
#' @import readxl
#' @import tidyr
#' @import tibble
#'
#' @examples
#' catags <- 'C:/Users/jpayne05/Desktop/Time/Categories_TCs.csv'
#' dailHours <- 'C:/Users/jpayne05/Desktop/Time/Daily_hours.xlsx'
#' outlC <- 'C:/Users/jpayne05/Desktop/Time/calendar_appoints3.csv'
#' weekS <- '2023-05-22'
#' pathOTL <- 'C:/Users/jpayne05/Desktop/Time'
#' tasks <- c('Cap Skills', 'FFIDP', 'Reactive Forecasting')
#' weightings <- c(1, 2, 1)
#' tc <- createTC(categories = categories,
#'                daily = daily,
#'                outCal = outCal,
#'                week_start = week,
#'                split = tasks,
#'                weight = weightings,
#'                file_path = folder,
#'                export = FALSE)
#' tc
createTC <- function(categories = NULL,
                     daily = NULL,
                     outCal = NULL,
                     week_start = NULL,
                     split = NULL,
                     weight = NULL,
                     pathOTL = NULL,
                     export = TRUE) {
  if (is.null(week_start)) {
    recMons <- rev(getRecentMondays())
    if (Sys.Date() - recMons[1] < 7) {
      # Find first date smaller more than 7 days ago
      # This should always be last week
      posit <- which(Sys.Date() - recMons  > 7, recMons)[1]
      week_start <- recMons[posit]
      cat('Week commencing', as.character(week_start), 'used\n')
    } else {
      week_start <- recMons[1]
      cat('Week commencing', as.character(week_start), 'used\n')
    }
  }
  # Load category data  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  suppressMessages(
    catags <- readr::read_csv(paste0(categories))
  )

  # Check tasks do they math the categories file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (all(tasks %in% catags$Categories)) {
    cat('\nAll tasks match the Categories file\n')
  } else {
    stop('The submitted tasks do not match Categories file, please check both inputs')
  }
  # Load daily data  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  suppressMessages(
    suppressWarnings(
      daily_hours <- readxl::read_excel(paste0(daily)) %>%
        mutate(Date = as.Date(Date)) %>%
        mutate_at(vars(Start, End), toTime) %>%
        mutate(Start = ifelse(is.na(Start), NA, paste(Date, Start))) %>%
        mutate(Start = as.POSIXct(Start, origin="1970-01-01")) %>%
        mutate(End = ifelse(is.na(End), NA, paste(Date, End))) %>%
        mutate(End = as.POSIXct(End, origin="1970-01-01")) %>%
        mutate_at(c('Lunch','Total', 'Flexi'), toHMS) %>%
        mutate_at(c('Lunch','Total', 'Flexi'), toHours) %>%
        select(-Expected, -Flexi)
    )
  )

  # Filter by working week ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  row <- which(daily_hours$Date == week_start & daily_hours$Day == 'Mon')
  if (is.integer0(row))
    warning('Please check the date, it does not match with any Monday')

  # Calculate the working week ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Has to start on a Monday
  workWeek <- daily_hours %>%
    filter(Date >= week_start & Date <= as.Date(week_start) + 6)

  # Calculate sick and leave hours ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  sleave <- workWeek %>%
    mutate(Length = Total)

  if (any(c('Leave Half', 'Sick Half') %in% workWeek$Type)){
    sleavehalfR <- which(workWeek$Type == 'Leave Half' |
                           workWeek$Type == 'Sick Half')
    for (i in sleavehalfR) {
      slhalfhours <- as.numeric(difftime(workWeek$End[sleavehalfR],
                                         workWeek$Start[sleavehalfR],
                                         units = 'secs' )/3600)
      if (slhalfhours > 3.7 & slhalfhours < 7.4) {
        sleave[sleavehalfR, 8] <-  workWeek[sleavehalfR, 7] - slhalfhours
      } else if (slhalfhours < 3.7) {
        sleave[sleavehalfR, 8] <-  workWeek[sleavehalfR, 7] - 3.7
        } else {
          warning('Please check the timings in your daily hours spreadsheet')
        }
    }
  }
# Create a seperate sick and leave time card - add to main one later ~~~~~~~~~~~
  suppressMessages(
    sleaveTC <- sleave %>%
      filter(Type %in% c('Leave', 'Sick', 'Leave Half', 'Sick Half',
                         'Bank Holiday')) %>%
      mutate(allDay = ifelse(Length == 7.4 | Length == 0, TRUE, FALSE)) %>%
      rename(dayType = Type) %>%
      left_join(catags, by = c('dayType' = 'Categories')) %>%
      mutate(Subject = dayType, Categories = dayType) %>%
      relocate(Subject, Categories, .after = dayType) %>%
      select(-Start, -End, -Lunch, -Description)
  )

  # Import calendar ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If .xlsx likely exported via Power Automate ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # If .csv likely exported from outlook ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (grep('.xlsx', basename(calexcel))) {
    calendar <- readxl::read_excel(calexcel)
    calTidy <- calendar %>%
      filter(Categories != 'Ignore & Leave' &
               Categories != 'Duty' &
               !is.na(Categories)) %>%
      mutate(Date = as.Date(`Start Time`)) %>%
      mutate(StartDT = as.POSIXct(`Start Time`, tz = "UTC", "%Y-%m-%dT%H:%M:%OS")) %>%
      mutate(EndDT = as.POSIXct(`End Time`, tz = "UTC", "%Y-%m-%dT%H:%M:%OS")) %>%
      mutate(Length = as.numeric(
        difftime(EndDT, StartDT, units ='secs')
        /3600)) %>%
      select(Date, Subject = Event, Categories, StartDT, EndDT, Length, allDay)

  } else {

    suppressMessages(
      calendar <- readr::read_csv(paste0(outCal),
                                  col_types = cols(`Start Date` =
                                                     col_date(format = "%d/%m/%Y"),
                                                   `End Date` =
                                                     col_date(format = "%d/%m/%Y"),
                                                   `Reminder Date` = col_skip(),
                                                   `Reminder Time` = col_skip(),
                                                   `Optional Attendees` = col_skip(),
                                                   `Meeting Resources` = col_skip(),
                                                   `Billing Information` = col_skip(),
                                                   Location = col_skip(),
                                                   Mileage = col_skip()))
    )

    # Tidy dates and times about calendar ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Ignore & Leave, Duty and NA categories are filtered out
    calTidy <- calendar %>%
      filter(Categories != 'Ignore & Leave' &
               Categories != 'Duty' &
               !is.na(Categories)) %>%
      filter(`Start Date` >= week_start & `Start Date` <= as.Date(week_start) +6) %>%
      mutate(StartDT = as.POSIXct(paste(`Start Date`, `Start Time`))) %>%
      mutate(EndDT = as.POSIXct(paste(`End Date`, `End Time`))) %>%
      mutate(Length = as.numeric(
        difftime(EndDT, StartDT, units ='secs')
        /3600)) %>%
      mutate(Date = as.Date(StartDT)) %>%
      select(Date, Subject, Categories, StartDT, EndDT, Length,
             allDay = `All day event`)
  }

  # Fix dates of all day events ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  calTidy$Date <- as.Date(ifelse(calTidy$allDay == TRUE,
                                 calTidy$Date + 1,
                                 calTidy$Date),
                          origin="1970-01-01")

  # Coerce multiple time codes to a list ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  calTidy$Categories <- as.list(strsplit(calTidy$Categories, ';'))
  calTidy$codes <- lengths(calTidy$Categories)

  # Divide time by length of list (no of time codes) ~~~~~~~~~~~~~~~~~~~~~~~~~~~
  calTidy$Length <- calTidy$Length / calTidy$codes

  # Unnest the tibble ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  calTidy <- tidyr::unnest(calTidy, cols = c(Categories))

  # Join calendar and time codes ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  suppressMessages(
    calCodes <- calTidy %>%
      left_join(catags, by = 'Categories')
  )

  # Join the above to the daily hours  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  suppressMessages(
    all <- workWeek %>%
      rename(dayType = Type) %>%
      full_join(calCodes, by = 'Date') %>%
      # colnames()
      select(Day, Date, dayType, Subject, Categories, Total, Length, allDay,
             Code, Task, Type)
  )

  # Combine calendar events with leave and sick ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  allTib <- if (!is.null(sleaveTC)) {
    allTib <- rbind(all, sleaveTC)
  } else {
    allTib <- all
  }

  # Identify all day sick or leave
  slRow <- which(allTib$allDay == TRUE &
                   ((allTib$dayType == 'Sick' & allTib$Subject == 'Sick') |
                      (allTib$dayType == 'Leave' & allTib$Subject == 'Leave') |
                      (allTib$dayType == 'Bank Holiday' &
                         allTib$Subject == 'Bank Holiday')))

  if (!is.integer0(slRow)){
    sl <- allTib[slRow,]
    slDates <- sl$Date
    allTibSL <- allTib %>%
      # Remove all appointments on the dates of leave / sick ~~~~~~~~~~~~~~~~~~~~~
      filter(Date != slDates) %>%
      # Add the sick/ leave back in
      rbind(sl)
  } else {
    allTibSL <- allTib
  }

  # Identify all day standard tasks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  adRow <- which(allTibSL$allDay == TRUE & allTibSL$dayType == 'Standard')
  if (!is.integer0(adRow)){
    ad <- allTibSL[adRow,]
    # Find the number of all day tasks per day
    multi <- ad %>%
      group_by(Day, Date) %>%
      count()

    # Find excess hours to assign ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    suppressMessages(
      summary <- allTibSL %>%
        slice(-adRow) %>%
        group_by(Day, Date) %>%
        summarise(Hours = mean(Total), calTotal = sum(Length)) %>%
        mutate(Excess = Hours - calTotal)
    )

    # Join 3 tables data and calculate split times ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    suppressMessages(
      adCor <- ad %>%
        left_join(multi) %>%
        left_join(summary) %>%
        mutate(Length = n * Excess) %>%
        select(-n, -Hours, - calTotal, - Excess)
    )
  # Merge split times and cleaned sick leave table ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  allTibad <- rbind(allTibSL[-adRow,], adCor)
  } else {
    allTibad <- allTibSL
}

  # Convert no calendar event days to Length 0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Stops the days being removed in next steps

  naRow <- which(allTibad$dayType== 'Standard' &
                 is.na(allTibad$Categories) &
                   is.na(allTibad$Length))
  if (!is.integer0(naRow)) {
    allTibad$Length[naRow] <- 0
  }

  # Find the remaining excess hours ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Hours multiplied by 10 to improve distribution ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  suppressMessages(
    finalSum <- allTibad %>%
      group_by(Day, Date, dayType) %>%
      summarise(Hours = mean(Total), calTotal = sum(Length)) %>%
      mutate(Excess = ceiling((Hours - calTotal)*10)) %>%
      filter(Excess > 0)
  )

  # What categories divide across and how to weight them ~~~~~~~~~~~~~~~~~~~~~~~
  cats <- rep(split, times = weight)
  catL <- length(cats)

  # Pad hours using multinormal distribution ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  multinom <- list()
  for (i in seq_along(finalSum$Day)){
    multinom[[i]] <- rmultinom(n = 1,
                               size = finalSum$Excess[i],
                               prob = rep(1/catL, catL))/10
  }

  padding <- tibble(Day = rep(finalSum$Day, each = catL),
                    Date = rep(finalSum$Date, each = catL),
                    dayType = rep(finalSum$dayType, each = catL),
                    Subject = rep(cats, times = dim(finalSum)[1]),
                    Categories = rep(cats, times = dim(finalSum)[1]),
                    Total = rep(finalSum$Hours, each = catL),
                    Length = unlist(multinom),
                    allDay = rep(FALSE, length(Day)))

  catPad <- padding %>%
    left_join(catags, by = 'Categories') %>%
    select(-Description)


  fin <- rbind(allTibad, catPad)
  fin <- fin %>%
    mutate(hoursType = rep('', length(Day)))

  ts <- fin %>%
    arrange(., Date) %>%
    select(Day, Code, Task, Type, Length, hoursType) %>%
    pivot_wider(names_from = Day,
                values_from = Length,
                values_fill = 0,
                values_fn = sum) %>%
    na.omit()

  if (export == TRUE) {
    neo <- matrix(data = '', nrow = 100, ncol = 12)
    neo[1,1] <- 'ORACLE TIME & LABOR'
    neo[3,2] <- 'Template Name : ABC'
    neo[5:7, 2] <- c('In the START_HEADER - STOP_HEADER section you can:',
                     '1. Select an overriding approver from the POSSIBLE VALUES list.',
                     '2. Enter comments being careful not to use a comma - enclose all details containing comma within double quotes.')
    neo[9, 1] <- 'In the START_TEMPLATE - STOP_TEMPLATE section you can:'
    neo[10:15, 2] <- c('1. Delete an entire timecard line entry. Use the delete line function in the spreadsheet.',
                       '2. Modify/Edit an hours entered.  Make your entry in the appropriate cell.',
                       '3. Insert a new entry - above the STOP_TEMPLATE (reserved line).',
                       'Use the insert line function in the spreadsheet.',
                       '4. Select POSSIBLE VALUES corresponding to the appropriate column headings.',
                       '5. Enter comments being careful not to use a comma - enclose all details containing comma within double quotes.')

    neo[17:19, 2] <- c(' DO NOT Make entries outside of the START_HEADER - STOP_HEADER or ',
                       ' START_TEMPLATE - STOP_TEMPLATE section.',
                       ' DO NOT delete/edit the ORACLE RESERVED section.')
    neo[22,1] <- 'START_HEADER'
    neo[25, 1] <- 'STOP_HEADER'

    neo[28, 1] <- 'START_TEMPLATE'
    neo[29, 1:12] <- c('Project/ABC Code',	'Task',	'Type',	'Hours Type',
                       'Mon',	'Tue',	'Wed',	'Thu',	'Fri',	'Sat',	'Sun',
                       'END_COLUMN')
    tsMat <- as.matrix(ts)
    matrows <- length(tsMat[,1])
    neo[30:(29 + matrows), 1:11] <- tsMat
    # Adding an ' infront of taks, when exporting to csv leading zeros get dropped
    # neo[30:(29 + matrows), 2] <- paste0("'",  neo[30:(29 + matrows), 2])
    neo[29, 12] <- 'END_COLUMN'

    newRow <- 30 + matrows + 2
    neo[newRow, 1] <- 'STOP_TEMPLATE'
    neo[(newRow+2):(newRow + 10), 1] <- c('###############################',
                                          'ORACLE RESERVED SECTION',
                                          '###############################',
                                          '',
                                          'START_ORACLE',
                                          'A|PROJECTS|Attribute1|A|PROJECTS|Attribute2|A|PROJECTS|Attribute3|A|OTL_ALIAS_1|Attribute1|D|D|D|D|D|D|D|',
                                          '321070',
                                          'NO_HEADER',
                                          'STOP_ORACLE')
    neo[(newRow + 10), 2] <- 'END'
    # For clarity replace - with _ for file export
    weekUC <- gsub('-', '_', week_start)
    # Export OTL form
    write.table(neo,
                file = paste0(pathOTL, '/', 'OTL_wc_', weekUC, '.csv'),
                row.names = FALSE,
                col.names = FALSE,
                sep = ",")
    print(paste0(pathOTL, '/', 'OTL_wc_', weekUC, '.csv'))
    cat('Source OTL form written to', pathOTL, '\n')
  }
  return(ts)
}

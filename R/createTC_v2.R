# categories = catags
# daily = dailHours
# outCal = outlC
# week_start = weekS
# week_start = '2023-05-08'
# week_start = '2023-04-03'
#
# split = tasks
# weight = weightings
# pathOTL = path
# export = FALSE
#
# createTC <- function(categories = NULL,
#                      daily = NULL,
#                      outCal = NULL,
#                      week_start = NULL,
#                      split = NULL,
#                      weight = NULL,
#                      pathOTL = NULL,
#                      export = TRUE) {
#
#   ##################### Import data #####################
#   ## Load category data
#   catags <- data.table::fread(categories)
#   ## Load daily data
#   if (tools::file_ext(outCal) == 'xlsx') {
#     daily_hours <- readxl::read_excel(daily)
#   } else {
#     daily_hours <- data.table::fread(daily)
#   }
#   ## Load Calendar data
#   if (tools::file_ext(outCal) == 'xlsx') {
#     calendar <- readxl::read_excel(outCal)
#   } else {
#     calendar <- data.table::fread(calendar)
#   }
#
#   ##################### Set work week #####################
#   ## If no date supplied use previous week
#   if (is.null(week_start)) {
#     recMons <- rev(getRecentMondays())
#     if (Sys.Date() - recMons[1] < 7) {
#       # Find first date smaller more than 7 days ago
#       # This should always be last week
#       posit <- which(Sys.Date() - recMons  > 7, recMons)[1]
#       week_start <- recMons[posit]
#       cat('Week commencing', as.character(week_start), 'used\n')
#     } else {
#       week_start <- recMons[1]
#       cat('Week commencing', as.character(week_start), 'used\n')
#     }
#   }
#
#   ##################### Tidy data #####################
#   ## Check tasks (split) match the categories file
#   if (all(split %in% catags$Categories)) {
#     cat('\nAll tasks in the split field match the Categories file\n')
#   } else {
#     stop('The submitted tasks in the split field do not match Categories file, please check both inputs')
#   }
#
#   ## Convert daily hours into correct format
#   daily_hours <- data.table::as.data.table(daily_hours)
#   daily_hours <- daily_hours[, `:=`(Date = as.Date(Date),
#                                     Start = fixTimes(date = Date,
#                                                      endStart = Start),
#                                     End = fixTimes(date = Date,
#                                                    endStart = End),
#                                     Lunch = toHours(toHMS(Lunch)),
#                                     Total = toHours(toHMS(Total)),
#                                     Flexi = toHours(toHMS(Flexi)))]
#   daily_hours[,`:=`(Expected = NULL, Flexi = NULL)]
#
#   ##################### Filter to work week #####################
#   workWeek <- daily_hours[Date >= week_start & Date <= as.Date(week_start) + 6,]
#   colnames(workWeek)[3] <- 'dayType'
#
#   ## Convert calendar into correct format
#   calendar <- data.table::as.data.table(calendar) # Convert to data.table
#   calendar[, `:=`(Date = as.Date(`Start Time`),
#                   StartDT = as.POSIXct(`Start Time`,
#                                        tz = "UTC",
#                                        "%Y-%m-%dT%H:%M:%OS"),
#                   EndDT = as.POSIXct(`End Time`,
#                                      tz = "UTC",
#                                      "%Y-%m-%dT%H:%M:%OS")),] # Set date classes
#
#   ##################### Correct calendar #####################
#   ## Filter calendar to working week
#   ## Calculate length of meetings
#   calTidy <- calendar[StartDT >= week_start &
#                         StartDT <= as.Date(week_start) + 6,,]
#   calTidy[, Length := as.numeric(difftime(EndDT, StartDT, units = 'secs')
#                                  / 3600),]
#
#   ## Coerce multiple category appointments to lists
#   ## Calendar export comma delimits string of categories
#   calTidy$Categories <- as.list(strsplit(calTidy$Categories, ','))
#   ## Find lengths of list elements
#   calTidy$codes <- lengths(calTidy$Categories)
#   ## Divide time by length of list (no of time codes)
#   ## Converting to list duplicates the tasks and hours
#   ## Dividing by element lengths resolves this
#   calTidy$Length <- calTidy$Length / calTidy$codes
#   ## Unnest the table and conert to data.table
#   calTidy <- data.table::as.data.table(tidyr::unnest(calTidy,
#                                                      cols = c(Categories)))
#
#   ##################### Omit blank category appointments #####################
#   ## Remove no time code categories
#   ## Ignore & Leave, Duty, and Holiday
#   calTidy <- calTidy[Categories != 'Ignore & Leave' & Categories != 'Duty' &
#                        Categories != 'Holiday' & !is.na(Categories),,]
#
#
#   ##################### Clean appointments #####################
#   ## On half days remove appointments that start after the day end time
#   ## Left join workWeek to all
#
#   calTidy <- calTidy[workWeek, on = 'Date']
#   calTidy <- calTidy[StartDT < End,]
#
#   if (dim(calTidy)[1] > 0){
#     calTidy <- calTidy[, .(Date, Subject = Event, Categories, StartDT, EndDT,
#                          Length, allDay),]
#   } ####else
#
#   ##################### Link calendar to categories #####################
#   ## A left join gives each item a timecode
#   calCodes <- catags[calTidy, on = 'Categories']
#
#   ##################### Link calendar to workWeek #####################
#   ## A full join is used so that every item has the dayType parameter
#   all <- merge(workWeek, calCodes, by = 'Date', all = TRUE)
#   all <- all[, .(Day, Date, dayType, Subject, Categories, Length, allDay,
#                  Code, Task, Type),]
#
#   ##################### Tidy all data #####################
#   ## Remove all day sick and leave days from dayType field
#   ## Half days are retained
#   slRow <- which(all$allDay == TRUE &
#                    ((all$dayType == 'Sick' & all$Subject == 'Sick') |
#                       (all$dayType == 'Leave' & all$Subject == 'Leave') |
#                       (all$dayType == 'Flexi' & all$Subject == 'Flexi') |
#                       (all$dayType == 'Bank Holiday' &
#                          all$Subject == 'Bank Holiday')))
#
#   ## Remove rows from 'all'
#   if (!is.integer0(slRow)){
#     all <- all[-slRow, ]
#   }
#
#   ##################### Find allDay tasks #####################
#   ## Identify all day standard tasks
#   # adRow <- which(all$allDay == TRUE & all$dayType == 'Standard')
#   adRow <- which(all$allDay == TRUE)
#
#   ## Find the hours accounted for in the calendar
#   ## All day events removed
#   if (!is.integer0(adRow)){
#     calHours <- all[-adRow, .(calHours = sum(Length)),
#                          by = c('Day', 'Date')]
#   } else {
#     calHours <- all[, .(calHours = sum(Length)),
#                          by = c('Day', 'Date')]
#   }
#
#   ## Pull out the all day tasks
#   if (!is.integer0(adRow)){
#     ad <- all[adRow,]
#     # Find the number of all day tasks per day
#     multi <- ad[,.(n = .N), by = c('Day', 'Date')]
#
#     ## Find excess hours to assign
#     ## suppressMessages(
#     summary <- workWeek[, .(Day, Date, dayType, Total)]
#     ## Left join with calendar hours
#     summary <- calHours[summary, on = c('Day', 'Date')]
#     ## Convert NAs to 0
#     summary$calHours <- data.table::nafill(summary$calHours, fill = 0)
#     ## Calculate excess
#     summary[, Excess := Total - calHours]
#     ## Remove total to simplify next join
#     summary[, Total := NULL]
#     ## Two left joins to collate the correct details
#     ## Divide all dayby n to designate splits
#     adCor <- ad[multi, on = c('Day', 'Date')]
#     adCor <- summary[adCor, on = c('Day', 'Date', 'dayType')]
#     adCor[, Length := Excess / n]
#
#     ## Merge split times and cleaned sick leave table
#     allTibad <- rbind(all[-adRow,], adCor[, .(Day, Date, dayType, Subject,
#                                               Categories, Length, allDay, Code,
#                                               Task, Type)])
#   } else {
#     allTibad <- all
#   }
#
#   ##################### Create sick and leave OTL #####################
#   ## Duplicate workWeek
#   sleave <- data.table::copy(workWeek)
#   colnames(sleave)[7] <- 'Length'
#
#   ##################### Part days #####################
#   ## Half days first
#   if (any(c('Leave Half', 'Sick Half') %in% workWeek$dayType)){
#     # Find the rows with Half sick/leave
#     sleavehalfR <- which(workWeek$dayType == 'Leave Half' |
#                            workWeek$dayType == 'Sick Half')
#     for (i in sleavehalfR) {
#       # Subtract start and end times and convert seconds to hours
#       slhalfhours <- as.numeric(difftime(workWeek$End[sleavehalfR],
#                                          workWeek$Start[sleavehalfR],
#                                          units = 'secs' )/3600)
#       if (slhalfhours > 3.7 & slhalfhours < 7.4) {
#         sleave[sleavehalfR, 8] <-  workWeek[sleavehalfR, 7] - slhalfhours
#       } else if (slhalfhours < 3.7) {
#         sleave[sleavehalfR, 8] <-  workWeek[sleavehalfR, 7] - 3.7
#       } else {
#         warning('Please check the timings in your daily hours spreadsheet')
#       }
#     }
#   }
#
#   sleave
#
#
#
#
#
#
#   # Sort all day appointments
#   # Create sick/leave etc. timecard
#

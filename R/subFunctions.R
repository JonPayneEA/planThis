#' @title Find whether data are integer(0)
#'
#' @param x Data of interest
#'
#' @return A TRUE/FALSE is returned detailing whetherr the crriteria have been met
#' @export
#'
#' @examples
#' data <- 1
#' is.integer0(data)
is.integer0 <- function(x){
  is.integer(x) && length(x) == 0L
}


#' @title Convert excel "time" into R compatible time
#'
#' @param x Data of interest
#' @param na.rm Set as TRUE
#'
#' @return Converted excel time to R time
#' @export
#'
#' @examples
#' # Leave blank
toTime <- function(x, na.rm = FALSE){
  (as.character(gsub(".* ","",x)))

}


#' @title Convert times to hms (hours minutes seconds)
#'
#' @param x Data of interest
#' @param na.rm Set as TRUE
#'
#' @importFrom lubridate hms
#'
#' @return HMS times
#' @export
#'
#' @examples
#' # Leave blank
toHMS <- function(x, na.rm = FALSE){
  (hms(toTime(x)))
}


#' @title Convert hms to seconds
#'
#' @param x Data of interest
#' @param na.rm Set as TRUE
#'
#' @importFrom lubridate period_to_seconds
#'
#' @return Seconds in a numeric form
#' @export
#'
#' @examples
#' # Leave blank
toHours <- function(x, na.rm = FALSE){
  (as.numeric(period_to_seconds(x) / 3600))
}


#' @title Get recent Mondays
#'
#' @description This function looks back over the past 70 days and draws out dates that fall on Monday.
#'
#' @return A vector of Monday dates from the previous 70 days
#' @export
#'
#' @examples
#' getRecentMondays()
getRecentMondays <- function(){
  daysR <- seq(as.Date(Sys.Date()-70), by = "day", length.out = 70)
  days <- as.POSIXlt(daysR, format = '%Y-%j')
  mons <- days[days$wday==1]
  as.Date(mons[!is.na(mons)])
}

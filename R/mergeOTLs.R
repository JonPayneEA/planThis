#' @title Compile OTL data
#'
#' @param folderOTL The folder you have saved the OTL export files
#' @param category Filepath to the categories file
#' @param quarterYear Set to 'all', this compiles all OTLs. If you set to 'current' it will compile all the OTLs that are in the same quarter as sys.Date(). To specify a quarter set to the format of 'Qx yyyy' e.g. 'Q1 2023'.
#' @param aggregate Set to FALSE. If TRUE it will sum all the ours spent on each category.
#'
#' @return All OTL files merged into one table
#' @export
#'
#' @importFrom magrittr %>%
#' @importFrom data.table data.table
#' @importFrom data.table merge.data.table
#' @importFrom data.table rbindlist
#' @importFrom lubridate quarter
#' @importFrom lubridate year
#' @importFrom tools file_path_sans_ext
#'
#'
#' @examples
#'
#' folder <- 'C:/Users/jpayne05/OneDrive - Defra/Time_Recording/OTLs'
#' cats <- 'C:/Users/jpayne05/OneDrive - Defra/Time_Recording/Categories/Categories_TCs.csv'
#' dt <- mergeOTL(folderOTL = folder, category = cats, quarterYear = 'all')
#' dt
#' dt1 <- mergeOTL(folderOTL = folder, category = cats, quarterYear = 'all',
#'                 aggregate = TRUE)
#' dt1
mergeOTL <- function(folderOTL, category, quarterYear = 'all', aggregate = FALSE){

  if (quarterYear == 'current') {
    date <- Sys.Date()
    quarterYear <- paste0('Q',
                          lubridate::quarter(OTL$Date, fiscal_start = 4),
                          ' ',
                          lubridate::year(OTL$Date))
  }

  # List OTL files
  files <- list.files(folder, full.names = TRUE, pattern = 'OTL_wc_')
  # Load categories file
  categories <- data.table::fread(cats, select = c(3, 4, 1))

  # Import OTL files
  otls <- list()
  for (i in seq_along(files)){
    # Find end point for each table
    # Table starts on row 29, skip 28 rows
    dt <- data.table::fread(files[i],
                            skip = 28)
    end <- which(dt[,1] == 'STOP_TEMPLATE') - 3

    # Import specific table
    dt <- data.table::fread(files[i],
                            skip = 28,
                            nrows = end,
                            select = c(1, 2, 5:11))
    colnames(dt)[1] <- 'Code'

    # Get task rather than OTL codes
    catags <- data.table::merge.data.table(dt, categories, by = c('Code', 'Task'))

    # Change Mon-Sun to dates using the file name dates
    # Have to be coerced to character strings
    week_start <- basename(files[i]) %>%
      tools::file_path_sans_ext() %>%
      gsub(pattern = 'OTL_wc_', replacement = '') %>%
      as.Date(format = "%Y_%m_%d")
    days <- as.character((0:6) + week_start)
    colnames(catags)[3:9] <- days

    # Reorder data table
    dt <- data.table::data.table(catags[, 10], catags[,3:9])
    # Melt data.table
    dt <- data.table::melt(dt, id.vars = 'Categories')
    otls[[i]] <- dt
  }

  # Unlist the data
  OTL <- data.table::rbindlist(otls)
  # Change the column names to
  colnames(OTL)[2:3] <- c('Date', 'Hours')
  # Convert previous columns from character to date
  OTL$Date <- as.Date(OTL$Date)
  # Remove 0 hour tasks
  OTL <- OTL[Hours > 0,,]
  # Calculate quarter and year
  OTL$Quarter <- paste0('Q',lubridate::quarter(OTL$Date, fiscal_start = 4),' ',
                        lubridate::year(OTL$Date))

  if (!quarterYear %in% c('all', 'auto')){
    # Check quarterYear is present
    if (quarterYear %in% OTL$Quarter == FALSE){
      stop('The quarterYear input does not exist in the data')
    }
    # Filter by quarter
    OTL <- OTL[Quarter == quarterYear,,]
  }

  if (aggregate == TRUE){
    # Aggregate to task
    totals <- OTL[, .(Sum = sum(Hours)), by = Categories]
    class(totals) <- c('totalOTLs', class(OTL))
    return(totals)
  }
  class(OTL) <- c('mergedOTLs', class(OTL))
  return(OTL)
}


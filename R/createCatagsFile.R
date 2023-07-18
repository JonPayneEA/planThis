#' @title Create categories file
#'
#' @description Set up a category file that then can be used with the creatTC function.
#'
#' @param path File path of where you wish the categories file to be saved
#'
#' @importFrom  tibble tibble
#'
#' @return A csv of common category files is produced
#' @export
#'
#' @examples
#' # link <- getwd()
#' # createCatagsFile(path = link)
createCatagsFile <- function(path = NULL){
  if (is.null(path)){
    stop('Please include a file path of where you wish the category file to be saved')
  }
  Categories <- c('Ignore & Leave', 'Admin', 'Business', 'Cap Admin',
                  'Cap Skills', 'Team Meeting', 'Objective Setting', 'Sick',
                  'Leave', 'Sick Half', 'Leave Half', 'Duty', 'Duty Training',
                  'Get Training', 'Give Training')
  Description <- c(NA, 'Team Admin', 'Business Team Meeting',
                   'Administration support and development of the M&F Modelling programme',
                   'Capital Training', 'Attend General Team Meetings',
                   'Performance Appraisal and Development', 'Sick', 'Leave',
                   'Sick Half', 'Leave Half', NA, 'Flood Forecasting Duty',
                   'Prep Training', 'Prep Training')
  Code <- c(NA, 'ENVEGM5.16', 'ENVHOABCPC120', 'ENVHOABCPC120', 'ENVHOABCPC120',
            'ENVEGM5.1.1', 'ENVEGM4.6', 'ENVABE', 'ENVABE', 'ENVABE', 'ENVABE',
            NA, 'ENVHOABCPC076', 'ENVEGM4.3', 'ENVEGM4.3')
  Task <- c(NA, '010', '990', '01',	'03',	'990', '990', '01',	'02',	'01',	'02',
            NA,	'03',	'902',	'901')
  Type <- rep('STAFF Plain Time-Straight Time', times = length(Categories))
  tib <- tibble::tibble(Categories, Description, Code, Task, Type)

  # Stop overwriting of categories.csv file
  files <- list.files(path)
  if ('Categories.csv' %in% files){
    stop('Categories.csv already exists in this location')
  }
  write.table(tib,
              file = paste0(path, '/Categories.csv'),
              row.names = FALSE,
              col.names = TRUE,
              sep = ",")
  print(paste0(path, '/Categories.csv'))
  cat('\nSource Categories file written to', path, '\n')
}


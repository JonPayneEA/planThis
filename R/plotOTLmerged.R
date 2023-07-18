#' @title Plotting OTL data
#'
#' @details Produces a bar plot for OTL data of class 'mergedOTLs'
#'
#' @param x Dataset derived from mergeOTL() function
#' @param ... Other options passed to ggplot(., aes())
#' @method plot mergedOTLs
#' @return ggplot bar chart to detail where OTL is falling
#' @export
#'
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 geom_bar
#'
#' @examples
#' \dontrun{
#' plot(dt1)
#' }
plot.mergedOTLs <- function(x, ...){
  p <- ggplot2::ggplot(x, ggplot2::aes(y = Sum, x = Categories, fill = Categories, ...)) +
    ggplot2::geom_bar(stat = "identity")
  return(p)
}

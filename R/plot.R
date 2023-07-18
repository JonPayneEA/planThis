#' @title Plotting OTL data
#'
#' @param x Dataset derived from mergeOTL function
#' @param ... Additional parameters as required
#'
#' @return
#' @export
#'
#' @examples
#' plot(dt1)
plot <- function(x, ...) {
  UseMethod('plot', x)
}

#' @rdname plot
#' @export
plot.totalOTLs <- function(x){
  p <- ggplot(x, aes(y = Sum, x = Categories, fill = Categories)) +
    geom_bar(stat = "identity")
  return(p)
}

#' @rdname plot
#' @export
plot.mergedOTLs <- function(x){
  p <- ggplot(x, aes(y = Sum, x = Categories, fill = Categories)) +
    geom_bar(stat = "identity")
  return(p)
}

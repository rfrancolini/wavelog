
#' Plot waveheight data
#'
#' @export
#' @param x tibble of wavelogger data
#' @param main character, title
#' @param xlabel character, title of xaxis
#' @param ylabel character, title of yaxis
#' @param ... further arguments passed to \code{\link[ggplot2]{theme}}
#' @return ggplot2 object

draw_plot <- function(x = mbar_to_elevation(),
                      main = "Wave Height",
                      xlabel = "Date",
                      ylabel = "Surface Elevation (m)",
                      ...){

  #filter data and take one measurement every second
  x.sec <- x %>% dplyr::slice(which(dplyr::row_number() %% 4 == 1))
  #x.sec2 <- x %>% dplyr::slice(which(dplyr::row_number() %% 8 == 1))

  ggplot2::ggplot(data = x.sec, ggplot2::aes(x = .data$DateTime, y = .data$swdepth)) +
  ggplot2::geom_line(na.rm = TRUE) +
  ggplot2::labs(title = main, x = xlabel, y = ylabel)

}


#' Plot waveheight data
#'
#' @export
#' @param x tibble of wave stats data
#' @param main character, title
#' @param xlabel character, title of xaxis
#' @param ylabel character, title of yaxis
#' @param ... further arguments passed to \code{\link[ggplot2]{theme}}
#' @return ggplot2 object

wavespec_plot <- function(x = wave_stats(),
                      main = "Significant Wave Height",
                      xlabel = "Date",
                      ylabel = "Significant Wave Height (m)",
                      ...){


    ggplot2::ggplot(data = x, ggplot2::aes(x = .data$DateTime, y = .data$Hm0)) +
    ggplot2::geom_line(na.rm = TRUE) +
    ggplot2::labs(title = main, x = xlabel, y = ylabel)

}

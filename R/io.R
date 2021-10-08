
#' retrieve example type wavelogger directory path
#'
#' @export
#' @return character
example_filepath <- function(){
  system.file("exampledata/2021_OWHL_LittleDris_Small.zip",
                   package = "wavelogger")
}


#' read wavelogger data file
#'
#' @export
#' @param filepath character, the name of the directory - full path needed
#' @return tibble

# adapted from postprocessing workflow: http://owhl.org/post-processing-information/
read_wavelogger <- function(filepath = example_filepath())
  {

  stopifnot(inherits(filepath, "character"))
  #stopifnot(file.exists(filepath[1]))  Removed this - possible zipped file, check diff way?

  myTimeZone = "UTC" #default setting on owhl

  if (grepl(".zip", filepath) == FALSE) {

    filenames <- list.files(path=filepath, pattern = '*.csv', full.names=TRUE)
    x = owhlR::joinOWHLfiles(filenames, timezone = myTimeZone, verbose = FALSE)

  } else {

    filelist <- unzip(zipfile = filepath, list = TRUE)
    filenames <- as.vector(filelist$Name)

    tempd <- tempdir()
    unzip(filepath, exdir = tempd)
    filenames <- file.path(tempd, filenames)
    x = owhlR::joinOWHLfiles(filenames, timezone = myTimeZone, verbose = FALSE)
    unlink(tempd)

  }

  return(dplyr::as_tibble(x) %>% dplyr::select(-POSIXt, -frac.seconds))

}


#' retrieve example type air pressure data
#'
#' @export
#' @return character
example_airpressure <- function(){
  system.file("exampledata/KRKD_MesoWest_LittleDris_Small.csv",
              package = "wavelogger")
}


#########################################################
### Need to figure out how to grab air pressure data
### that matches the timeframe of the owhl data
### until then using example data i am feeding it
#########################################################

#' read sea level pressure data file
#'
#' @export
#' @param filename character, the name of the air pressure file
#' @return tibble

read_airpressure <- function(filename = example_airpressure())
  {
    stopifnot(inherits(filename, "character"))
    stopifnot(file.exists(filename[1]))

    #This is particular to current example dataset.
    x <- suppressMessages(readr::read_csv(filename[1], skip = 6))

    #cleaning up the header
    h <- colnames(x)
    lut <- c("Station_ID" = "Station_ID",
             "Date_Time" = "DateTime",
             "sea_level_pressure_set_1d.INHG" = "sea_pressure.INHG",
             "sea_level_pressure_set_1d.mbar" = "sea_pressure.mbar")
    colnames(x) <- lut[h]

    #convert date/time to POSIXct format
    x$DateTime = as.POSIXct(x$DateTime, format = "%m/%d/%Y %H:%M", tz = 'UTC')

    return(x)
}

#' interpolate sea level pressure to match owhl data
#'
#' @export
#' @param wavelogger tibble, wavelogger data
#' @param airpressure tibble, airpressure data
#' @return tibble

interp_wave_air <- function(wavelogger = read_wavelogger(),
                            airpressure = read_airpressure())
  {
    ix <- findInterval(wavelogger$DateTime, airpressure$DateTime)

    wavelogger <- wavelogger %>%
      dplyr::mutate(airpressure = airpressure$sea_pressure.mbar[ix],
                    swpressure = Pressure.mbar - airpressure)

    # Convert data to tsibbles
    #air <- tsibble::as_tsibble(airpressure, index = date)
    #wave <- tsibble::as_tsibble(wavelogger, index = DateTime)

    return(wavelogger)
}




#' retrieve example type wavelogger directory path
#'
#' @export
#' @return character
example_filepath <- function(){
  x <- ("inst/exampledata/2021_OWHL_LittleDris_Small.zip")
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
    filenames <- paste(tempd, filenames, sep ="\\")
    x = owhlR::joinOWHLfiles(filenames, timezone = myTimeZone, verbose = FALSE)
    unlink(tempd)

  }

  return(x)

}


#' retrieve example type air pressure data
#'
#' @export
#' @return character
example_airpressure <- function(){
  x <- ("inst/exampledata/KRKD_MesoWest_LittleDris_Small.csv")
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
             "Date_Time" = "date",
             "sea_level_pressure_set_1.INHG" = "sea_pressure.INHG.1",
             "pressure_set_1d.INHG" = "pressure.INHG.2",
             "sea_level_pressure_set_1d.INHG" = "sea_pressure.INHG.3",
             "sea_level_pressure_set_1d.mbar" = "sea_pressure.mbar")
    colnames(x) <- lut[h]

    #convert date/time to POSIXct format
    x$date = as.POSIXct(x$date, format = "%m/%d/%Y %H:%M", tz = 'UTC')

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
  # Convert data sets to zoo objects
  wave <- zoo::zoo(wavelogger[,'Pressure.mbar'],
                   order.by = wavelogger[,'DateTime'])

  air <- zoo::zoo(airpressure[,'sea_pressure.mbar'],
            order.by = airpressure$date)

  # Linearly interpolate 'air' to match the time index in 'wave'
  airout <- window(zoo::na.approx(merge(wave,air)), zoo::index(wave))

  # Copy the resulting sea level pressure data into 'wavelogger' data frame
  ###NOT WORKING OCT 7###
  wavelogger$SeaLevelPress.mbar <- round(as.numeric(airout$air), digits=2)

  # Call the new column swPressure.mbar for "seawater pressure"
  wavelogger$swPressure.mbar <- wavelogger$Pressure.mbar - wavelogger$SeaLevelPress.mbar

  return(wavelogger)

}



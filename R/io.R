
#' retrieve example type wavelogger directory path
#'
#' @export
#' @return character
example_filepath <- function(){
  system.file("exampledata/2021_OWHL_LittleDris_Small.zip",
                   package = "wavelogger")
}

#' clip wavelogger table by date
#'
#' @export
#' @param x tibble, waveloger
#' @param startstop POSIXt vector of two values or NA, only used if clip = "user"
#' @return tibble
clip_wavelogger <- function(x,
                           startstop = NA) {

  if (is.na(startstop)[1]) {
    x <- x %>% dplyr::mutate (Date = as.Date(.data$DateTime, tz = "EST"),
                              DateNum = as.numeric(.data$DateTime))

    ix <- which(diff(x$Date) != 0)[1]  + 1
    firstday <- as.numeric(difftime(x$DateTime[ix], x$DateTime[1]))

    if (firstday < 23) {
      x <- x[-(1:(ix-1)),]
    }

    iix <- dplyr::last(which(diff(x$Date) != 0))  + 1
    lastday <- as.numeric(difftime(dplyr::last(x$DateTime),x$DateTime[iix]))

    if (lastday < 23) {
      x <- x[-((iix+1):nrow(x)),]
    }

    x <- x %>% dplyr::select(-.data$Date, -.data$DateNum)
  }


  if (!is.na(startstop)[1]) {
    x <- x %>%
      dplyr::filter(.data$DateTime >= startstop[1]) %>%
      dplyr::filter(.data$DateTime <= startstop[2])
  }

  x
}


#' read wavelogger data file
#'
#' @export
#' @param filepath character, the name of the directory - full path needed
#' @param clipped character, if auto, removed partial start/end days. if user, uses supplied startstop days. if none, does no date trimming
#' @param startstop POSIXt vector of two values or NA, only used if clip = "user"
#' @return tibble

# adapted from postprocessing workflow: http://owhl.org/post-processing-information/
read_wavelogger <- function(filepath = example_filepath(),
                            clipped = c("auto", "user", "none")[1],
                            startstop = NA){

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

  x <- switch(tolower(clipped[1]),
              "auto" = clip_wavelogger(x, startstop = NA),
              "user" = clip_wavelogger(x, startstop = startstop),
              "none" = x,
              stop("options for clipped are auto, user, or none. what is ", clipped, "?")
  )

  return(dplyr::as_tibble(x) %>% dplyr::select(-.data$POSIXt, -.data$frac.seconds))

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

    #omit any rows that have an NA value
    x <- na.omit(x)

    return(x)
}

#' interpolate air pressure to match owhl, calculate seawater pressure
#'
#' @export
#' @param wavelogger tibble, wavelogger data
#' @param airpressure tibble, airpressure data
#' @return tibble

interp_swpressure <- function(wavelogger = read_wavelogger(),
                            airpressure = read_airpressure())
  {
    ix <- findInterval(wavelogger$DateTime, airpressure$DateTime)

    wavelogger <- wavelogger %>%
      dplyr::mutate(airpressure = airpressure$sea_pressure.mbar[ix],
                    swpressure = .data$Pressure.mbar - .data$airpressure)

    # Convert data to tsibbles
    #air <- tsibble::as_tsibble(airpressure, index = date)
    #wave <- tsibble::as_tsibble(wavelogger, index = DateTime)

    return(wavelogger)
}




#' convert pressure to sea surface elevation, correct for signal attenuation
#'
#' @export
#' @param wavelogger tibble, wavelogger data
#' @param latitude numeric, approx latitude of deployment - degrees north
#' @return tibble

mbar_to_elevation <- function(wavelogger = interp_swpressure(),
                              latitude = 44.5)
{

  wavelogger <- wavelogger %>%
    dplyr::mutate(swdepth = owhlR::millibarToSeawater(wavelogger$swpressure,
                                                      latitude = latitude),
                  swdepth = oceanwaves::prCorr(.data$swdepth,
                                               Fs = 4,
                                               zpt = 0.2))

  return(wavelogger)
}



#' convert pressure to sea surface elevation, correct for signal attenuation
#'
#' @export
#' @param wavelogger tibble, wavelogger data
#' @param burst numeric, time in minutes to calculate wave stats
#' @param ... other
#' @return tibble

wave_stats <- function(wavelogger = mbar_to_elevation(),
                      burst = 30,
                      ...)
{

  waves_spec <- owhlR::processBursts(Ht = wavelogger$swdepth,
                                     times = wavelogger$DateTime,
                                     burstLength = burst,
                                     Fs = 4)

  return(waves_spec)
}














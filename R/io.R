
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
#' @param startstop POSIXt vector of two values in UTC or NA, only used if clip = "user"
#' @return tibble
clip_wavelogger <- function(x,
                           startstop = NA) {

  if (is.na(startstop)[1]) {
    x <- x %>% dplyr::mutate (Date = as.Date(.data$DateTime, tz = "UTC"),
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
  x <- read.csv(system.file("exampledata/KRKD_MesoWest_LittleDris.csv",
              package = "wavelogger"))
  x <- na.omit(x)
  x$DateTime = as.POSIXct(x$DateTime, format = "%Y-%m-%dT%H:%M:%S", tz = 'UTC')
  return(x)
}

#' retrieve air pressure data from mesowest database
#'
#' @export
#' @param api_key character, your api key for mesowest
#' @param wavelogger tibble, wavelogger data
#' @return tibble

read_airpressure <- function(api_key = NA,
                              wavelogger = read_wavelogger())
{
   stopifnot(inherits(api_key, "character"))
   suppressMessages(mesowest::requestToken(api_key))

  #use mesowest function to grab air pressure data
  #uses dates of interest based on wavelogger data

  starttime <- format(wavelogger$DateTime[1], "%Y%m%d%H%M")
  stoptime <- format(dplyr::last(wavelogger$DateTime), "%Y%m%d%H%M")

  meso <- mesowest::mw(service = "timeseries",
          stid = "KRKD",
          vars = "sea_level_pressure",
          start = starttime,
          end = stoptime,
          units = "english",
          jsonsimplify = TRUE)

  x <- data.frame(lapply(meso$STATION$OBSERVATIONS, unlist))

  x <- x %>%
        dplyr::select(-2) %>%
        dplyr::rename(DateTime = .data$date_time) %>%
        dplyr::rename(sea_pressure.mbar = .data$sea_level_pressure_set_1d)

  x$DateTime = as.POSIXct(x$DateTime, format = "%Y-%m-%dT%H:%M:%S", tz = 'UTC')
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
#' @param latitude numeric, approx latitude of deployment - degrees north, default 44.5
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














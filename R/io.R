
#' retreive example type wavelogger directory path
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
#' @param deploy POSIXt or NA, if not NA, clip data before this time
#' @param recover POSIXt or NA, if not NA, clip data before this time
#' @return tibble

# adapted from postprocessing workflow: http://owhl.org/post-processing-information/
read_wavelogger <- function(filepath = example_filepath(),
                         deploy = NA,
                         recover = NA){

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



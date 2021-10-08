Waves
================

## Wavelogger

This is for managing and understanding your open wave height logger data

## Requirements

-   [R v4+](https://www.r-project.org/)
-   [dplyr](https://CRAN.R-project.org/package=dplyr)
-   [readr](https://CRAN.R-project.org/package=readr)
-   [stringr](https://CRAN.R-project.org/package=stringr)
-   [ggplot2](https://CRAN.R-project.org/package=ggplot2)
-   [oceanwaves](https://CRAN.R-project.org/package=oceanwaves)
-   [oce](https://CRAN.R-project.org/package=oce)
-   [owhlR](https://github.com/millerlp/owhlR) *from github*

## Installation

    remotes::install_github("rfrancolini/wavelogger")

## Read Example Data

``` r
library(wavelogger)
x <- read_wavelogger()
head(x)
```

    ## # A tibble: 6 x 3
    ##   DateTime            Pressure.mbar TempC
    ##   <dttm>                      <dbl> <dbl>
    ## 1 2021-05-15 00:00:00         1558.  7.93
    ## 2 2021-05-15 00:00:00         1557.  7.93
    ## 3 2021-05-15 00:00:00         1558   7.94
    ## 4 2021-05-15 00:00:00         1558.  7.94
    ## 5 2021-05-15 00:00:01         1557.  7.93
    ## 6 2021-05-15 00:00:01         1556.  7.94

## Read Air Pressure Data

``` r
a <- read_airpressure()
head(a)
```

    ## # A tibble: 6 x 4
    ##   Station_ID DateTime            sea_pressure.INHG sea_pressure.mbar
    ##   <chr>      <dttm>                          <dbl>             <dbl>
    ## 1 KRKD       2021-05-14 01:00:00              30.0             1016.
    ## 2 KRKD       2021-05-14 01:05:00              30.0             1017.
    ## 3 KRKD       2021-05-14 01:10:00              30.0             1017.
    ## 4 KRKD       2021-05-14 01:15:00              30.0             1017.
    ## 5 KRKD       2021-05-14 01:20:00              30.0             1017.
    ## 6 KRKD       2021-05-14 01:25:00              30.0             1017.

## Interpolate Data, Calculate Sea Water Pressure

``` r
i <- interp_swpressure(wavelogger = x, airpressure = a) 
head(i)
```

    ## # A tibble: 6 x 5
    ##   DateTime            Pressure.mbar TempC airpressure swpressure
    ##   <dttm>                      <dbl> <dbl>       <dbl>      <dbl>
    ## 1 2021-05-15 00:00:00         1558.  7.93       1017.       542.
    ## 2 2021-05-15 00:00:00         1557.  7.93       1017.       541.
    ## 3 2021-05-15 00:00:00         1558   7.94       1017.       541.
    ## 4 2021-05-15 00:00:00         1558.  7.94       1017.       542.
    ## 5 2021-05-15 00:00:01         1557.  7.93       1017.       541.
    ## 6 2021-05-15 00:00:01         1556.  7.94       1017.       540.

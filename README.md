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
-   [owhlR](https://github.com/millerlp/owhlR)

## Installation

    remotes::install_github("rfrancolini/wavelogger")

## Read Example Data

``` r
library(wavelogger)
x <- read_wavelogger()
head(x)
```

    ##       POSIXt            DateTime frac.seconds Pressure.mbar TempC
    ## 1 1621036800 2021-05-15 00:00:00            0        1558.5  7.93
    ## 2 1621036800 2021-05-15 00:00:00           25        1557.4  7.93
    ## 3 1621036800 2021-05-15 00:00:00           50        1558.0  7.94
    ## 4 1621036800 2021-05-15 00:00:00           75        1558.5  7.94
    ## 5 1621036801 2021-05-15 00:00:01            0        1557.1  7.93
    ## 6 1621036801 2021-05-15 00:00:01           25        1556.3  7.94

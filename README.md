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
-   [mesowest](https://github.com/fickse/mesowest) *from github*

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
    ## 1 2021-05-16 00:00:00         1556.  7.91
    ## 2 2021-05-16 00:00:00         1556.  7.9 
    ## 3 2021-05-16 00:00:00         1556.  7.89
    ## 4 2021-05-16 00:00:00         1556   7.89
    ## 5 2021-05-16 00:00:01         1556   7.89
    ## 6 2021-05-16 00:00:01         1556.  7.89

## Read Air Pressure Data Example

``` r
a <- example_airpressure()
head(a)
```

    ##              DateTime sea_pressure.mbar
    ## 1 2021-05-16 00:00:00           1022.05
    ## 2 2021-05-16 00:05:00           1022.05
    ## 3 2021-05-16 00:10:00           1022.05
    ## 4 2021-05-16 00:15:00           1022.05
    ## 5 2021-05-16 00:20:00           1022.06
    ## 6 2021-05-16 00:25:00           1022.06

## Calculate Wave Statistcs

``` r
i <- interp_swpressure(wavelogger = x, airpressure = a)
```

    ## Warning in findInterval(wavelogger$DateTime, airpressure$DateTime): NAs
    ## introduced by coercion

``` r
w <- wave_stats(wavelogger = mbar_to_elevation(wavelogger = i)) 

head(w)
```

    ##          h       Hm0        Tp          m0    T_0_1    T_0_2      EPS2
    ## 1 5.453213 0.1402373 11.428571 0.001229156 7.402025 6.566161 0.5203867
    ## 2 5.542616 0.1396065 11.612903 0.001218124 7.495820 6.640505 0.5236368
    ## 3 5.721951 0.1426491 10.434783 0.001271799 7.252966 6.422508 0.5247174
    ## 4 5.975653 0.1542862 12.413793 0.001487764 7.073558 6.291575 0.5138374
    ## 5 6.313440 0.1479298 12.000000 0.001367701 6.561599 5.858567 0.5043821
    ## 6 6.674818 0.1508412  8.674699 0.001422066 6.250685 5.621321 0.4862671
    ##        EPS4            DateTime
    ## 1 0.7457289 2021-05-15 20:30:00
    ## 2 0.7517771 2021-05-15 21:00:00
    ## 3 0.7431470 2021-05-15 21:30:00
    ## 4 0.7337762 2021-05-15 22:00:00
    ## 5 0.7088957 2021-05-15 22:30:00
    ## 6 0.6863810 2021-05-15 23:00:00

## Graph Significant Wave Height

``` r
wave_plot <- wavespec_plot(w)
wave_plot
```

![](README_files/figure-gfm/GraphWaves-1.png)<!-- -->

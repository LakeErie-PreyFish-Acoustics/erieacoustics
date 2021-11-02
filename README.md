
# erieacoustics

<!-- badges: start -->
[![Generic badge](https://img.shields.io/badge/Dev-InProgress-<COLOR>.svg)](https://shields.io/)

<!-- badges: end -->

The goal of `erieacoustics` is to provide a common set of functions for analysis of acoustic survey data in Lake Erie.

## Required Packages
#### RDCOMClient

`RDCOMClient` is the package that allows R to control [Echoview](https://echoview.com/). For R versions >= 4.1 you will be required to install a forked version of the package:

``` r
devtools::install_github("dkyleward/RDCOMClient")
```

#### EchoviewR
`EchoviewR` provides many useful functions to simplify many of the common tasks using COM to interact with Echoview. Documentation can be found at: [EchoviewR](https://github.com/AustralianAntarcticDivision/EchoviewR)

``` r
devtools::install_github('AustralianAntarcticDivision/EchoviewR')
```


## Installation

You can install the development version of erieacoustics from github.

``` r
devtools::install_github("https://github.com/HoldenJe/erieacoustics") 
```

## Example

``` r
library(erieacoustics)
evtemplate <- file.path(getwd(), 'EVTemplate/EVTemplateFile.EV')
dir.exists("Pings")
file.exists(evtemplate)

set_up_transect(evtemplate, projecthome = getwd(), 
                sonartype = "SIMRAD", tranname = "ERIE")


set_up_transect(evtemplate, projecthome = getwd(), 
                sonartype = "BIOSONIC", tranname = "COB")

```


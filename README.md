
# erieacoustics

<!-- badges: start -->
[![Generic badge](https://img.shields.io/badge/Dev-InProgress-<COLOR>.svg)](https://shields.io/)

<!-- badges: end -->

The goal of `erieacoustics` is to provide a common set of functions for analysis of acoustic survey data in Lake Erie. The project also provides an RStudio project template to create the necessary directory structure for a Lake Erie acoustic survey to work with the package functions. The template can be accessed from RStudio by: File > New Project > New Directory > New Erie Acoustic Project and then by filling in the required meta data at project set up. Additional templates and starter code is also added by running `erieacoustics::finish_setup()`.

Check out the [NEWS](NEWS.md) file for version and contributor information.

## Required Packages
#### RDCOMClient

`RDCOMClient` is the package that allows R to control [Echoview](https://echoview.com/). It can be installed via the github repo:

``` r
devtools::install_github("omegahat/RDCOMClient")
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
finish_setup()
evtemplate <- file.path(getwd(), 'EVTemplate/EVTemplateFile.EV')
dir.exists("3_Ping_Data")
file.exists(evtemplate)

set_up_transect(evtemplate, projecthome = getwd(), 
                sonartype = "SIMRAD", tranname = "ERIE")


set_up_transect(evtemplate, projecthome = getwd(), 
                sonartype = "BIOSONIC", tranname = "COB")

```

## Templates
Template scripts are created when `erieacoustics::finish_setup()` is ran. Clean templates can be generated using:
```
usethis::use_template(
      template = "export_from_EV.R",
      save_as = "7_Annual_Summary/2_export_data_from_EV.R",
      package = "erieacoustics"
    )
```

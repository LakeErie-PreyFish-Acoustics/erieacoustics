% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/export_transect_evdata.R
\name{export_transect_evdata}
\alias{export_transect_evdata}
\title{Export Echoview transect data}
\usage{
export_transect_evdata(prjdir, transectname, horizbin)
}
\arguments{
\item{prjdir}{Project directory normally obtained using `getwd()`}

\item{transectname}{Transect name to be exported. Function expects the transect
name to correspond with a transect folder located in the *Pings* directory}

\item{horizbin}{Size of the horizontal grid (in meters) to be applied for the analysis cells}
}
\value{
The function will attempt to return a cruise track (`gps.csv`), a copy of the
edited epi line in the Echoview format (`EpiLayerLine_Edited.evl`) and as a csv
(`EpiLayerLine_Final.csv`)
}
\description{
Provides a series of COM commands to set export parameters and then export
the required analysis files.
}
\examples{
\dontrun{
library(erieacoustics)
export_transect_evdata(getwd(), "R21_S22", 800)
}
}

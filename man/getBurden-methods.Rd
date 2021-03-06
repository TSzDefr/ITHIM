% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-ITHIM.R
\docType{methods}
\name{getBurden}
\alias{getBurden}
\alias{getBurden,ITHIM,character,character-method}
\alias{getBurden,ITHIM,character,missing-method}
\alias{getBurden,ITHIM,missing,character-method}
\alias{getBurden,ITHIM,missing,missing-method}
\title{Gets Burden}
\usage{
getBurden(x, bur, dis)

\S4method{getBurden}{ITHIM,character,character}(x, bur, dis)

\S4method{getBurden}{ITHIM,character,missing}(x, bur)

\S4method{getBurden}{ITHIM,missing,character}(x, dis)

\S4method{getBurden}{ITHIM,missing,missing}(x)
}
\arguments{
\item{x}{ITHIM object}

\item{bur}{A character string indicating the type of disease burden
measure.  Available values are "deaths", "yll", "yld" and
"daly".  The default value is "daly".}

\item{dis}{A character string indicating which disease to consider.
Possible values are "BreastCancer", "ColonCancer", "HHD",
"IHD", "Stroke", "Dementia", "Diabetes", "Depression",
"LungCancer", "InflammatoryHD", "RespiratoryDisease" and
"RTIs".  See \code{readGBD} for more information.  The default
value is "all" which returns the sum of disease burden across
these diseases.}
}
\value{
A numerical value for the disease burden
}
\description{
Gets burden
}
\note{
If bur is set wrong 0 will be returned, not an error message.
    This is a bug.  It should not return zero in this case.  That
    is misleading.
}


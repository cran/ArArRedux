% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/timezero.R
\name{fitlogratios}
\alias{fitlogratios}
\alias{fitlogratios.default}
\alias{fitlogratios.timeresolved}
\alias{fitlogratios.PHdata}
\title{Extrapolation to 'time zero'}
\usage{
fitlogratios(x, ...)

\method{fitlogratios}{default}(x, ...)

\method{fitlogratios}{timeresolved}(x, denmass, ...)

\method{fitlogratios}{PHdata}(x, denmass = NULL, ...)
}
\arguments{
\item{x}{an object of class \code{timeresolved} or \code{PHdata}}

\item{...}{further arguments (see below)}

\item{denmass}{a string denoting the denominator isotope}
}
\value{
an object of class \code{logratios}
}
\description{
This function extrapolates time resolved mass spectrometer data to
t=0. When fed with multicollector data, it forms the ratios of the
raw signals, forms their logs and performs linear regression to t=0
When fed with single collector data, the function first takes their
logs and extrapolates them to t=0 before taking ratios, unless
\code{denmass}=NULL, in which case the logs of the raw signals are
extrapolated.
}
\examples{
samplefile <- system.file("Samples.csv",package="ArArRedux")
masses <- c("Ar37","Ar38","Ar39","Ar40","Ar36")
m <- loaddata(samplefile,masses) # samples and J-standards
blanklabel <- "EXB#"
l <- fitlogratios(blankcorr(m,blanklabel),"Ar40")
plotcorr(l)
}

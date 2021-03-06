% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/J.R
\name{getJfactors}
\alias{getJfactors}
\title{Calculate the irradiation parameter ('J factor')}
\usage{
getJfactors(R)
}
\arguments{
\item{R}{a vector of 40Ar*/39ArK ratios}
}
\value{
an object of class \code{redux} containing, as
\code{intercepts}, the 40Ar*/39ArK ratios of the samples, the
interpolated J-factors, and the 40K decay constant; and as
\code{covmat}: the covariance matrix. All other class properties
are inherited from \code{R}.
}
\description{
Interpolate the irradiation parameters for the samples
given the 40Ar*/39ArK ratios of the samples and fluence monitors
}
\examples{
data(Melbourne)
R <- get4039(Melbourne$X,Melbourne$irr)
J <- getJfactors(R)
plotcorr(J)
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/decay.R
\name{decaycorrection}
\alias{decaycorrection}
\title{Correct for radioactive decay occurred since irradiation}
\usage{
decaycorrection(X, irr, isotope)
}
\arguments{
\item{X}{an objects of class \code{redux}}

\item{irr}{the irradiation schedule}

\item{isotope}{a string denoting the isotope that needs correcting}
}
\value{
an object of class \code{redux}
}
\description{
Correct for radioactive decay of neutron-induced 37Ar and 39Ar
occurred since irradiation
}
\examples{
data(Melbourne)
C <- calibration(Melbourne$X,"DCAL")
A <- massfractionation(C,Melbourne$fract)
D9 <- decaycorrection(A,Melbourne$irr,"Ar39")
plotcorr(D9)
}

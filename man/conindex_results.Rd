\name{conindex_results}
\alias{conindex_results}
\alias{print.conindex}
\alias{confint.conindex}
\title{Inspect Concentration Index Results}
\description{Print an index, extract a one-row data frame, or obtain an approximate confidence interval if a replicate-weight standard error is available.}
\usage{
conindex_results(x)
\method{print}{conindex}(x, ...)
\method{confint}{conindex}(object, parm = NULL, level = 0.95, ...)
}
\arguments{
\item{x}{Object of class \code{conindex}.}
\item{object}{Object of class \code{conindex}.}
\item{parm}{Must be \code{NULL}.}
\item{level}{Confidence level between zero and one.}
\item{...}{Unused extra arguments for generic-method compatibility.}
}
\value{\code{conindex_results} gives a one-row data frame;
\code{print} returns the input invisibly; \code{confint} returns
an interval matrix.}
\examples{
d <- data.frame(y = 1:4)
z <- conindex(d, "y")
conindex_results(z)
}

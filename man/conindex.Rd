\name{conindex}
\alias{conindex}
\title{Weighted Concentration and Inequality Indices}
\description{Compute relative, generalized, modified, Wagstaff and Erreygers
concentration indices with weighted mid-ranks. When \code{rankvar} is omitted,
the outcome is also the ranking variable and the result is a Gini-type index.}
\usage{
conindex(data, varname, rankvar = NULL, weight = NULL,
         truezero = TRUE, limits = NULL, generalized = FALSE,
         bounded = FALSE, wagstaff = FALSE, erreygers = FALSE,
         svy = NULL, na_action = c("omit", "fail"))
}
\arguments{
\item{data}{Data frame containing numeric variables. If \code{svy} is supplied, it must correspond row-for-row to the survey design.}
\item{varname}{Name of the numeric outcome variable.}
\item{rankvar}{Optional name of numeric ranking variable, omitted for Gini.}
\item{weight}{Optional weight column name or numeric vector. Omit with \code{svy}.}
\item{truezero}{If \code{FALSE} with a single lower limit, compute a modified index. Defaults to \code{TRUE}.}
\item{limits}{Theoretical limits of the outcome: length two when \code{bounded=TRUE}, or one lower limit for a modified index.}
\item{generalized}{Compute generalized index \eqn{2 Cov_w(h,R)}.}
\item{bounded}{Transform outcome to \eqn{(h-a)/(b-a)}; requires finite \code{limits=c(a,b)}.}
\item{wagstaff}{Compute Wagstaff normalization of a bounded outcome.}
\item{erreygers}{Compute Erreygers normalization of a bounded outcome.}
\item{svy}{Optional \code{svyrep.design} from package \pkg{survey}; recomputes ranks and moments in every replicate.}
\item{na_action}{Drop invalid observations (default) or fail; with \code{svy}, invalid observations always fail.}
}
\details{
The weighted mid-rank for all observations tied at ranking value \eqn{y}
is the sum of the weights strictly below \eqn{y}, plus half the total weight
of the tie group, divided by the sum of all weights. With \eqn{R} denoting
that rank and \eqn{\mu} the weighted outcome mean, the standard index is
\eqn{C=2 Cov_w(h,R)/\mu}. Generalized is \eqn{G=2 Cov_w(h,R)}.
For the normalized bounded outcome \eqn{z=(h-a)/(b-a)}, Erreygers is
\eqn{E=8 Cov_w(z,R)} and Wagstaff is
\eqn{W=2 Cov_w(z,R)/(\mu_z(1-\mu_z))}.
For a modified index with lower limit \eqn{a}, use
\eqn{M=2 Cov_w(h,R)/(\mu-a)}.

With survey replicate weights, the point estimate is recomputed for each
replicate; reported standard errors are design-dependent and use the
replicate construction supplied by the analyst. Confidence intervals and
p-values use a normal approximation. Without a replicate-weight survey
design, this function does not estimate standard errors. Theoretical bounds
must be meaningful for normalized indices; sample-based scaling alone
does not imply substantive absolute outcome limits.
}
\value{A \code{conindex} object containing \code{CI}, \code{CIse},
\code{p.value}, \code{N}, \code{Nunique}, \code{rank},
\code{type}, and concentration-curve coordinates in \code{curve}.}
\references{
O'Donnell, O., O'Neill, S., Van Ourti, T. and Walsh, B. (2016).
Conindex: Estimation of concentration indices. \emph{The Stata Journal},
16(1), 112--138. \doi{10.1177/1536867X1601600112}.
}
\examples{
d <- data.frame(income = 1:4, outcome = c(1, 2, 3, 4), w = c(1, 1, 1, 1))
conindex(d, "outcome", "income", weight = "w")
conindex(d, "outcome", weight = "w")
b <- data.frame(income = 1:4, health = c(0, 0, 1, 1))
conindex(b, "health", "income", bounded = TRUE,
         limits = c(0, 1), erreygers = TRUE)
}

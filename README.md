# polecon (research candidate; not CRAN-submission-ready)

This package provides weighted fractional-rank concentration indices (relative,
generalized, modified, Wagstaff and Erreygers) and supports replicate-weight
variance estimation through the `survey` package. It deliberately does **not**
claim numerical parity with every feature of Stata's `conindex` command.

## Install locally

```r
install.packages("testthat")
install.packages("survey")
install.packages("devtools")
devtools::install("path/to/polecon")
```

## Basic usage

```r
library(polecon)
d <- data.frame(income = 1:4, fvi = c(0, 0, 1, 1), w = 1)
conindex(d, "fvi", "income", weight = "w", bounded = TRUE,
         limits = c(0, 1), erreygers = TRUE)
```

## Survey-design inference

The user must select a valid replicate construction for their sample design.
For example, for a stratified clustered design with valid multi-PSU strata:

```r
library(survey)
set.seed(42)
d <- data.frame(
  strata = rep(1:3, each = 8),
  psu = rep(1:12, each = 2),
  income = seq_len(24),
  fvi = seq(0.15, 0.85, length.out = 24),
  wt = rep(c(1, 2), 12)
)
s <- svydesign(id = ~psu, strata = ~strata, weights = ~wt,
               data = d, nest = TRUE)
sr <- as.svrepdesign(s, type = "bootstrap", replicates = 100, mse = TRUE)
out <- conindex(d, "fvi", "income", bounded = TRUE,
                limits = c(0, 1), erreygers = TRUE, svy = sr)
print(out)
confint(out)
```

## Intended scope

This is an initial, restricted, auditable foundation. Complex index families,
Stata's extended/symmetric indices, regression-based robust/clustered standard
errors and group comparisons from the originally supplied prototype have **not**
been carried into this candidate, pending separate parity and reference tests.
The code does not recalculate a separately estimated FVI or its category
elasticities in each survey replicate: that must be implemented in the
researcher's own resampling pipeline if such uncertainty is of interest.

## Before CRAN submission

Confirm the **maintainer email** in `DESCRIPTION`, verify the name
against CRAN at submission time, complete independent Stata parity tests,
run the `testthat` suite, and run `R CMD build`, then `R CMD check --as-cran`
on the resulting source tarball using a current version of R. This environment
did not have an R executable, so the package has **not** passed R checks here.

## Attribution

Concept and initial implementation follow O'Donnell, O'Neill, Van Ourti and
Walsh (2016), *The Stata Journal*, https://doi.org/10.1177/1536867X1601600112.
Their Stata code is distributed under GPL-3; see `inst/COPYRIGHTS`.

The project-specific example for food vulnerability indices is available in
`inst/FVI_USAGE.md`.

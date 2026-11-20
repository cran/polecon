# polecon

`polecon` provides quantitative methods for empirical research in political
economy, with applications to food security, household economic vulnerability,
and inequality. The package currently provides weighted concentration and
inequality indices, with explicit treatment of tied ranks. It supports variance
estimation with survey replicate weights and recalculates fractional ranks for
each replicate.

## Installation

```r
install.packages("polecon")
```

## Basic usage

```r
library(polecon)

d <- data.frame(income = 1:4, fvi = c(0, 0, 1, 1), w = 1)
conindex(d, "fvi", "income", weight = "w", bounded = TRUE,
         limits = c(0, 1), erreygers = TRUE)
```

## Survey-design inference

The method used to construct replicate weights should suit the sample design.
The example below uses bootstrap replicate weights for a stratified cluster
sample with multiple primary sampling units per stratum. It requires the
`survey` package, which can be installed with `install.packages("survey")`.

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

## Scope

`conindex()` computes relative, generalized, modified, Wagstaff-normalized,
and Erreygers-normalized concentration indices. See `?conindex` for the
estimators, their assumptions, and the available arguments.

If the outcome is a food vulnerability index (FVI) estimated in a separate
model, the variance calculation treats the supplied FVI values as fixed.
To account for uncertainty in the estimated FVI or its category elasticities,
re-estimate the FVI within each replicate in your own analysis. A worked example
is available in `inst/FVI_USAGE.md` in the package source.

## Attribution

The concentration index methods and the original Stata `conindex` command are
described in O'Donnell, O., O'Neill, S., Van Ourti, T., and Walsh, B. (2016).
*Conindex: Estimation of concentration indices*. The Stata Journal, 16(1),
112–138. <https://doi.org/10.1177/1536867X1601600112>.

The Stata code is distributed under GPL-3. See `inst/COPYRIGHTS` in the
package source for attribution and license details.

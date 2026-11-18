# Example: FVI concentration analysis for HBS 2024

After installing `polecon`, use the two FVI variables on the same sample.

```r
library(polecon)
library(survey)

ci_data <- comparison |>
  dplyr::ungroup() |>
  dplyr::filter(is.finite(FVI1), is.finite(FVI2),
                is.finite(HH099), HA10 > 0,
                !is.na(HA06), !is.na(HA07))

s <- svydesign(ids = ~HA07, strata = ~HA06,
               weights = ~HA10, data = ci_data, nest = TRUE)

# The method must be appropriate to the actual sampling design.
set.seed(42)
sr <- as.svrepdesign(s, type = "bootstrap", replicates = 500,
                     mse = TRUE)

# Estimates and replicate-weight SE; note: weight is omitted with svy.
a <- conindex(ci_data, "FVI1", "HH099", bounded = TRUE,
              limits = c(0, 1), svy = sr)
b <- conindex(ci_data, "FVI1", "HH099", bounded = TRUE,
              limits = c(0, 1), erreygers = TRUE, svy = sr)
c <- conindex(ci_data, "FVI2", "HH099", bounded = TRUE,
              limits = c(0, 1), svy = sr)
d <- conindex(ci_data, "FVI2", "HH099", bounded = TRUE,
              limits = c(0, 1), erreygers = TRUE, svy = sr)

rbind(conindex_results(a), conindex_results(b),
      conindex_results(c), conindex_results(d))
```

Important: the above procedure treats FVI1 and FVI2 as already observed.
It does not re-estimate category elasticities, standardized components or min-max
normalization limits in each replicate. When the research design requires
full propagation of generated-regressor uncertainty, the external FVI
construction itself must be recomputed for each replicate. Input `HH099`
provides ranking by total household income, **not necessarily equivalized**
disposable household income.

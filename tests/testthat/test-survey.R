test_that("replicate designs recompute weighted ranks and return uncertainty", {
  skip_if_not_installed("survey")
  set.seed(18)
  d <- data.frame(
    stratum = rep(1:3, each = 8),
    psu = rep(1:12, each = 2),
    income = seq_len(24),
    outcome = (seq_len(24) + 2) / 30,
    wt = rep(c(1, 2), 12)
  )
  s <- survey::svydesign(ids = ~psu, strata = ~stratum,
                         weights = ~wt, data = d, nest = TRUE)
  sr <- survey::as.svrepdesign(s, type = "bootstrap",
                              replicates = 60, mse = TRUE)
  z <- conindex(d, "outcome", "income", bounded = TRUE,
                limits = c(0, 1), erreygers = TRUE, svy = sr)
  point <- conindex(d, "outcome", "income", weight = "wt",
                    bounded = TRUE, limits = c(0, 1), erreygers = TRUE)
  expect_equal(z$CI, point$CI, tolerance = 1e-10)
  expect_true(is.finite(z$CIse))
  expect_true(z$CIse >= 0)
  expect_equal(dim(confint(z)), c(1L, 2L))
})

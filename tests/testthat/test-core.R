test_that("unweighted four-observation Gini is exact", {
  d <- data.frame(y = 1:4, x = 1:4)
  expect_equal(conindex(d, "y")$CI, 0.25, tolerance = 1e-12)
  expect_equal(conindex(d, "y", "x")$CI, 0.25, tolerance = 1e-12)
})

test_that("midranks handle ties and unequal weights", {
  d <- data.frame(rank = c(1, 1, 2), h = c(1, 2, 3),
                  w = c(1, 3, 2))
  x <- conindex(d, "h", "rank", weight = "w")
  expect_equal(x$rank, c(1/3, 1/3, 5/6), tolerance = 1e-12)
  expect_equal(x$CI, 5 / 39, tolerance = 1e-12)
  expect_equal(sum(x$rank * d$w) / sum(d$w), 0.5, tolerance = 1e-12)
})

test_that("weighted ranks are invariant to rescaling weights", {
  d <- data.frame(h = c(1, 4, 2, 8), r = c(2, 1, 1, 3), w = c(3, 1, 5, 2))
  a <- conindex(d, "h", "r", weight = "w")
  d$w <- 17 * d$w
  b <- conindex(d, "h", "r", weight = "w")
  expect_equal(a$CI, b$CI, tolerance = 1e-12)
  expect_equal(a$rank, b$rank, tolerance = 1e-12)
})

test_that("known bounded normalizations agree with algebra", {
  d <- data.frame(r = 1:4, h = c(0, 0, 1, 1))
  a <- conindex(d, "h", "r", bounded = TRUE, limits = c(0, 1))
  b <- conindex(d, "h", "r", bounded = TRUE,
                limits = c(0, 1), erreygers = TRUE)
  c <- conindex(d, "h", "r", bounded = TRUE,
                limits = c(0, 1), wagstaff = TRUE)
  expect_equal(a$CI, 0.5, tolerance = 1e-12)
  expect_equal(b$CI, 1.0, tolerance = 1e-12)
  expect_equal(c$CI, 1.0, tolerance = 1e-12)
})

test_that("generalized and modified formulas are consistent", {
  d <- data.frame(h = 1:4, r = 1:4)
  expect_equal(conindex(d, "h", "r", generalized = TRUE)$CI,
               0.625, tolerance = 1e-12)
  expect_equal(conindex(d, "h", "r", truezero = FALSE,
                        limits = 0)$CI, 0.25, tolerance = 1e-12)
})

test_that("constant ranking produces zero concentration", {
  d <- data.frame(h = c(1, 2, 4, 8), r = 1)
  expect_equal(conindex(d, "h", "r")$CI, 0, tolerance = 1e-12)
})

test_that("invalid data and options fail predictably", {
  d <- data.frame(h = c(1, 2, NA), r = 1:3, w = c(1, 1, 1))
  expect_equal(conindex(d, "h", "r")$N, 2L)
  expect_error(conindex(d, "h", "r", na_action = "fail"), "Missing")
  expect_error(conindex(d, "h", "r", erreygers = TRUE), "bounded")
  expect_error(conindex(d, "h", "r", bounded = TRUE, limits = c(0, 1)),
               "outside")
  expect_error(conindex(d, "h", "r", weight = c(0, 0, 0)), "two valid")
})

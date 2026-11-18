#' Concentration indices with weighted fractional ranks
#'
#' Estimate standard, generalized, modified, Wagstaff-normalized and
#' Erreygers-normalized concentration indices. When `svy` is a
#' replicate-weight survey design, all weighted ranks and moments are
#' recomputed under each set of replicate weights.
#'
#' @param data A data frame containing the variables. Must agree row-for-row
#'   with `svy$variables` when `svy` is supplied.
#' @param varname Name of the numeric outcome variable.
#' @param rankvar Name of the numeric ranking variable; omit for a Gini index.
#' @param weight A column name or numeric vector of nonnegative weights.
#'   Omit when providing `svy`, since the design supplies the weights.
#' @param truezero Logical. If TRUE, the standard relative index is interpreted
#'   on a scale with a meaningful zero. Retained for compatibility.
#' @param limits Numeric theoretical limits: a pair for `bounded=TRUE`, or a
#'   single lower limit for a modified index with `truezero=FALSE`.
#' @param generalized Return the generalized index, in units of the outcome.
#' @param bounded Use the specified fixed bounds to map the outcome to [0,1].
#' @param wagstaff Use Wagstaff's normalization for a bounded outcome.
#' @param erreygers Use Erreygers's normalization for a bounded outcome.
#' @param svy Optional object of class `svyrep.design` from package 'survey'.
#'   A conventional survey design must first be converted using
#'   `survey::as.svrepdesign()`; the replication method must fit the design.
#' @param na_action Either `omit` or `fail` for standalone data. Missing
#'   observations with `svy` are rejected: subset the design in advance.
#' @return An object of class `conindex`, with `CI`, `CIse`, `p.value`,
#'   weighted ranks and concentration-curve coordinates.
#' @references O'Donnell, O., O'Neill, S., Van Ourti, T. and Walsh, B.
#'   (2016). Conindex: Estimation of concentration indices.
#'   The Stata Journal 16(1):112-138.
#'   doi:10.1177/1536867X1601600112
#' @export
conindex <- function(data, varname, rankvar = NULL, weight = NULL,
                     truezero = TRUE, limits = NULL,
                     generalized = FALSE, bounded = FALSE,
                     wagstaff = FALSE, erreygers = FALSE,
                     svy = NULL, na_action = c("omit", "fail")) {
  na_action <- match.arg(na_action)
  if (!is.data.frame(data)) stop("'data' must be a data frame.", call. = FALSE)
  .ci_name(varname, data, "varname")
  if (is.null(rankvar)) rankvar <- varname
  .ci_name(rankvar, data, "rankvar")
  if (!all(vapply(list(truezero, generalized, bounded, wagstaff, erreygers),
                  function(z) is.logical(z) && length(z) == 1L && !is.na(z),
                  logical(1)))) stop("Index flags must be scalar TRUE/FALSE.", call. = FALSE)
  if (sum(c(generalized, wagstaff, erreygers)) > 1L)
    stop("Generalized, Wagstaff and Erreygers are mutually exclusive.", call. = FALSE)
  if (generalized && bounded)
    stop("Generalized indices use outcome units; do not combine with bounded=TRUE.", call. = FALSE)
  if ((wagstaff || erreygers) && !bounded)
    stop("Wagstaff/Erreygers require 'bounded=TRUE'.", call. = FALSE)
  if (bounded) {
    if (!is.numeric(limits) || length(limits) != 2L ||
        any(!is.finite(limits)) || limits[1] >= limits[2])
      stop("'bounded=TRUE' needs finite limits=c(lower, upper).", call. = FALSE)
  } else if (!is.null(limits)) {
    if (truezero || generalized || length(limits) != 1L ||
        !is.numeric(limits) || !is.finite(limits))
      stop("Without bounds, a single minimum requires 'truezero=FALSE'.", call. = FALSE)
  }
  modified <- !truezero && !bounded
  if (modified && (is.null(limits) || generalized))
    stop("A modified index needs one lower limit and cannot be generalized.", call. = FALSE)

  if (!is.null(svy)) {
    if (!requireNamespace("survey", quietly = TRUE))
      stop("Install 'survey' to use 'svy'.", call. = FALSE)
    if (!inherits(svy, "svyrep.design"))
      stop("'svy' must be a replicate-weight design; convert with survey::as.svrepdesign().", call. = FALSE)
    if (!is.null(weight)) stop("Omit 'weight' when 'svy' is supplied.", call. = FALSE)
    vars <- svy$variables
    if (!is.data.frame(vars) || nrow(vars) != nrow(data) ||
        !identical(vars[[varname]], data[[varname]]) ||
        !identical(vars[[rankvar]], data[[rankvar]]))
      stop("'data' and 'svy$variables' must agree row-for-row on outcome and rank.", call. = FALSE)
    w <- as.numeric(stats::weights(svy, type = "sampling"))
  } else if (is.null(weight)) {
    w <- rep(1, nrow(data))
  } else if (is.character(weight) && length(weight) == 1L) {
    .ci_name(weight, data, "weight")
    w <- data[[weight]]
  } else if (is.numeric(weight) && length(weight) == nrow(data)) {
    w <- weight
  } else {
    stop("'weight' must be a column name or numeric vector matching the data.", call. = FALSE)
  }
  h <- data[[varname]]
  r <- data[[rankvar]]
  if (!is.numeric(h) || !is.numeric(r) || !is.numeric(w))
    stop("Outcome, ranking variable and weights must be numeric.", call. = FALSE)
  ok <- is.finite(h) & is.finite(r) & is.finite(w) & w > 0
  if (any(!ok)) {
    if (!is.null(svy) || na_action == "fail")
      stop("Missing/non-finite observations or nonpositive weights: subset or clean the design/data first.", call. = FALSE)
    h <- h[ok]; r <- r[ok]; w <- w[ok]
  }
  if (length(h) < 2L) stop("At least two valid observations are required.", call. = FALSE)
  if (bounded && (any(h < limits[1]) || any(h > limits[2])))
    stop("The outcome lies outside the supplied theoretical bounds.", call. = FALSE)
  if (modified && any(h < limits[1]))
    stop("The outcome lies below its specified theoretical minimum.", call. = FALSE)

  estimator <- function(ww, hh, rr) .ci_estimate(
    hh, rr, ww, bounds = if (bounded) limits else NULL,
    mode = if (erreygers) "erreygers" else if (wagstaff) "wagstaff"
           else if (generalized) "generalized" else if (modified) "modified"
           else "standard",
    lower = if (modified) limits[1] else NULL)

  value <- estimator(w, h, r)
  se <- pv <- NA_real_
  if (!is.null(svy)) {
    # withReplicates re-estimates the rank distribution AND the outcome mean.
    theta <- function(ww, dd) {
      estimator(as.numeric(ww), dd[[varname]], dd[[rankvar]])
    }
    stat <- survey::withReplicates(svy, theta)
    if (!isTRUE(all.equal(value, as.numeric(stat), tolerance = 1e-9)))
      stop("Replicate-design point estimate disagrees with the direct estimator.", call. = FALSE)
    se <- sqrt(as.numeric(attr(stat, "var")))
    pv <- if (is.finite(se) && se > 0) 2 * stats::pnorm(-abs(value / se))
          else if (is.finite(se) && se == 0) {
            if (value == 0) NA_real_ else 0
          } else NA_real_
  }
  ranks <- .ci_rank(r, w)
  curve <- .ci_curve(h, r, w)
  typ <- if (erreygers) "Erreygers" else if (wagstaff) "Wagstaff"
         else if (generalized) "Generalized" else if (modified) "Modified"
         else "Standard"
  obj <- list(CI = value, CIse = se, p.value = pv, N = length(h),
              Nunique = length(unique(r)), rank = ranks,
              type = paste(typ, if (identical(rankvar, varname)) "Gini" else "CI"),
              curve = curve,
              options = list(bounded = bounded, limits = limits,
                             generalized = generalized, wagstaff = wagstaff,
                             erreygers = erreygers, truezero = truezero,
                             variance = if (is.null(svy)) "not estimated" else "replication"))
  class(obj) <- "conindex"
  obj
}

.ci_name <- function(name, data, argument) {
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(name) || !(name %in% names(data)))
    stop(sprintf("'%s' must name one column in 'data'.", argument), call. = FALSE)
}

.ci_rank <- function(r, w) {
  ord <- order(r)
  rr <- r[ord]; ww <- w[ord]
  # Consecutive ranks share one weighted mid-point, including ties.
  g <- cumsum(c(TRUE, diff(rr) != 0))
  group_weights <- as.numeric(rowsum(ww, g, reorder = FALSE))
  before <- c(0, utils::head(cumsum(group_weights), -1L))
  result <- numeric(length(r))
  result[ord] <- ((before + group_weights / 2) /
                  sum(group_weights))[g]
  result
}

.ci_estimate <- function(h, r, w, bounds, mode, lower) {
  keep <- is.finite(h) & is.finite(r) & is.finite(w) & w > 0
  h <- h[keep]; r <- r[keep]; w <- w[keep]
  if (length(h) < 2L) stop("Insufficient positive-weight observations.", call. = FALSE)
  if (!is.null(bounds)) h <- (h - bounds[1]) / diff(bounds)
  mu <- sum(w * h) / sum(w)
  if (mode %in% c("standard", "wagstaff") && mu <= 0)
    stop("Relative and normalized indices need a positive outcome mean.", call. = FALSE)
  if (mode == "modified" && mu <= lower)
    stop("Modified index needs a mean above the theoretical minimum.", call. = FALSE)
  if (mode == "wagstaff" && mu >= 1)
    stop("Wagstaff index is undefined when the bounded outcome mean equals one.", call. = FALSE)
  if (mode == "standard" && any(h < 0))
    warning("Negative outcomes can make the standard index difficult to interpret.", call. = FALSE)
  rr <- .ci_rank(r, w)
  cov <- sum(w * h * (rr - 0.5)) / sum(w)
  if (mode == "erreygers") return(8 * cov)
  if (mode == "generalized") return(2 * cov)
  if (mode == "modified") return(2 * cov / (mu - lower))
  if (mode == "wagstaff") return(2 * cov / (mu * (1 - mu)))
  2 * cov / mu
}

.ci_curve <- function(h, r, w) {
  ord <- order(r); h <- h[ord]; r <- r[ord]; w <- w[ord]
  groups <- cumsum(c(TRUE, diff(r) != 0))
  ww <- as.numeric(rowsum(w, groups, reorder = FALSE))
  wh <- as.numeric(rowsum(w * h, groups, reorder = FALSE))
  d <- sum(wh)
  data.frame(p = c(0, cumsum(ww) / sum(ww)),
             share = if (d == 0) rep(NA_real_, length(ww) + 1L)
                     else c(0, cumsum(wh) / d))
}

#' @export
print.conindex <- function(x, ...) {
  cat(x$type, "\n", "Observations:", x$N,
      "\nEstimate:", format(x$CI, digits = 8),
      "\nSE:", format(x$CIse, digits = 8),
      "\np-value:", format(x$p.value, digits = 8), "\n")
  invisible(x)
}

#' @export
confint.conindex <- function(object, parm = NULL, level = 0.95, ...) {
  if (!is.null(parm)) stop("'parm' is not applicable.", call. = FALSE)
  if (!is.numeric(level) || length(level) != 1L ||
      !is.finite(level) || level <= 0 || level >= 1)
    stop("'level' must lie strictly between 0 and 1.", call. = FALSE)
  if (!is.finite(object$CIse)) stop("An SE requires a replicate-weight survey design.", call. = FALSE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  ans <- matrix(c(object$CI - z * object$CIse,
                  object$CI + z * object$CIse), nrow = 1L)
  colnames(ans) <- c("lower", "upper")
  rownames(ans) <- "index"
  ans
}

#' @export
conindex_results <- function(x) {
  if (!inherits(x, "conindex")) stop("'x' must be a conindex object.", call. = FALSE)
  data.frame(type = x$type, N = x$N, CI = x$CI,
             SE = x$CIse, p_value = x$p.value)
}

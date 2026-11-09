## Utility functions shared across scripts

##' List whose unnamed elements are named by their deparsed arguments,
##' e.g. namedList(a = 1, x, y) has names "a", "x", "y"
##' (copied from lme4, R/lmerControl.R)
namedList <- function(...) {
    L <- list(...)
    snm <- sapply(substitute(list(...)), deparse)[-1]
    if (is.null(nm <- names(L))) nm <- snm
    if (any(nonames <- nm == "")) nm[nonames] <- snm[nonames]
    setNames(L,nm)
}

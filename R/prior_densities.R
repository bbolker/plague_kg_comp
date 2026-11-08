## Prior density curves on the canonical scale of each parameter
## (see data/param_dict.csv), for plotting under the parameter values.
##
##  - louseplague priors: data/louseplague_priors.csv (Gamma/Beta)
##  - yersinia priors: prior_default() ("lab") and plague_fit_prior() ("fit"),
##    transformed by the dictionary's yersinia_transform

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(purrr)
})

source(here::here("R", "yersinia_params.R"))

## density functions for the families used by louseplague and yersinia
prior_dfun <- function(family, p) {
    switch(family,
           Uniform = \(x) dunif(x, p$min, p$max),
           Normal = \(x) dnorm(x, p$mean, p$sd),
           LogNormal = \(x) dlnorm(x, p$meanlog, p$sdlog),
           Gamma = if (!is.null(p$scale)) \(x) dgamma(x, shape = p$shape, scale = p$scale)
                   else \(x) dgamma(x, shape = p$shape, rate = p$rate),
           Exponential = \(x) dexp(x, p$rate),
           Beta = \(x) dbeta(x, p$shape1, p$shape2),
           stop("unknown prior family ", family))
}

## quantile function, extending prior_qfun() (R/yersinia_params.R) to
## Gamma priors given by scale
prior_qfun2 <- function(family, p) {
    if (family == "Gamma" && !is.null(p$scale)) {
        return(\(q) qgamma(q, shape = p$shape, scale = p$scale))
    }
    prior_qfun(family, p)
}

##' Density of Y = g(X) for the transforms used in the dictionary ("x", "1/x")
transformed_dfun <- function(dfun, transform) {
    switch(transform,
           x = dfun,
           "1/x" = \(y) dfun(1 / y) / y^2,
           stop("unsupported transform ", transform))
}

##' Quantiles of Y = g(X) (sorted, since 1/x reverses order)
transformed_qfun <- function(qfun, transform) {
    switch(transform,
           x = qfun,
           "1/x" = \(q) 1 / qfun(1 - q),
           stop("unsupported transform ", transform))
}

##' All priors as a tibble with one row per (param, prior_set) and list
##' columns holding the density and quantile functions on the canonical scale
prior_specs <- function(dict = read_csv(here::here("data", "param_dict.csv"),
                                        show_col_types = FALSE)) {
    lp <- read_csv(here::here("data", "louseplague_priors.csv"), show_col_types = FALSE)
    louse <- lp |>
        mutate(spec = pmap(list(family, shape, scale, shape1, shape2),
                           \(family, shape, scale, shape1, shape2) {
                               p <- if (family == "Gamma") list(shape = shape, scale = scale)
                                    else list(shape1 = shape1, shape2 = shape2)
                               list(d = prior_dfun(family, p), q = prior_qfun2(family, p))
                           }),
               prior_set = "louseplague") |>
        select(param, prior_set, spec)
    ydict <- yersinia_dict(dict)
    lab <- set_names(map(ydict$yersinia_name, yersinia::prior_default),
                     ydict$yersinia_name) |> compact()
    yplist <- list(`yersinia lab` = lab, `yersinia fit` = fit_prior_list())
    yers <- imap(yplist, \(plist, set) {
        imap(plist, \(pr, nm) tibble(prior_set = set, yersinia_name = nm, pr = list(pr))) |>
            list_rbind()
    }) |> list_rbind() |>
        inner_join(ydict, by = "yersinia_name") |>
        mutate(spec = map2(pr, yersinia_transform, \(pr, tt) {
            list(d = transformed_dfun(prior_dfun(pr$family, pr$params), tt),
                 q = transformed_qfun(prior_qfun(pr$family, pr$params), tt))
        })) |>
        select(param, prior_set, spec)
    bind_rows(louse, yers)
}

##' Evaluate prior densities on a grid over [lo, hi] for each param.
##' @param specs output of prior_specs()
##' @param ranges tibble with param, lo, hi (the panel range)
##' @param log_x compute the density of log10(Y), for plotting on a log axis
##' @param height maximum height of each curve (in row units)
prior_curves <- function(specs, ranges, log_x = FALSE, n = 401, height = 0.8) {
    specs |>
        inner_join(ranges, by = "param") |>
        mutate(curve = pmap(list(spec, lo, hi), \(spec, lo, hi) {
            x <- if (log_x) 10^seq(log10(lo), log10(hi), length.out = n)
                 else seq(lo, hi, length.out = n)
            d <- spec$d(x)
            if (log_x) d <- d * x * log(10)
            d[!is.finite(d)] <- NA
            tibble(x = x, density = d)
        })) |>
        select(param, prior_set, curve) |>
        tidyr::unnest(curve) |>
        group_by(param, prior_set) |>
        filter(any(density > 0, na.rm = TRUE)) |>
        mutate(rel_density = height * density / max(density, na.rm = TRUE)) |>
        ungroup()
}

##' Central quantile range of each prior (canonical scale)
prior_ranges <- function(specs, probs = c(0.005, 0.995)) {
    specs |>
        mutate(lo = map_dbl(spec, \(s) min(s$q(probs))),
               hi = map_dbl(spec, \(s) max(s$q(probs)))) |>
        select(param, prior_set, lo, hi)
}

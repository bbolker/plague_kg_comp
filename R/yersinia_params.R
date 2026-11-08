## Parameter values and priors from the yersinia package, in the common long
## format (see data/README.md):
##  - scenario values (inst/scenarios/*.yaml)
##  - default priors: prior_default() (Virtual Lab) and plague_fit_prior()
##    (canonical monty fitting prior), summarised as median and central 95%
##    interval on the canonical scale of each parameter
##
## Only parameters with a yersinia_transform in data/param_dict.csv are
## included, i.e. those comparable (at least partly) with other sources.

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(purrr)
    library(tidyr)
})

yersinia_dict <- function(dict = read_csv(here::here("data", "param_dict.csv"), show_col_types = FALSE)) {
    dict |>
        filter(!is.na(yersinia_name), !is.na(yersinia_transform)) |>
        select(param, label, units, yersinia_name, yersinia_transform)
}

yersinia_version <- function() {
    d <- utils::packageDescription("yersinia")
    paste0("yersinia ", d$Version,
           if (!is.null(d$RemoteSha)) paste0(" (", substr(d$RemoteSha, 1, 7), ")"))
}

##' Scenario values (one row per scenario x parameter)
yersinia_scenarios <- function(ydict = yersinia_dict()) {
    files <- dir(system.file("scenarios", package = "yersinia"),
                 pattern = "\\.yaml$", full.names = TRUE)
    vals <- map(files, \(f) {
        y <- yaml::read_yaml(f)
        nums <- keep(y, is.numeric)
        tibble(scenario = sub("\\.yaml$", "", basename(f)),
               yersinia_name = names(nums), value = unlist(nums))
    }) |> list_rbind()
    vals |>
        inner_join(ydict, by = "yersinia_name") |>
        mutate(source_set = "yersinia",
               id = paste("yersinia", scenario, yersinia_name, sep = "_"),
               study = paste0("yersinia scenario '", scenario, "'"),
               estimate = map2_dbl(value, yersinia_transform,
                                   \(x, tt) eval(str2lang(tt), list(x = x))),
               type = "scenario",
               basis = "scenario",
               orig_symbol = yersinia_name, orig_value = value,
               orig_units = ifelse(units == "1/day" | yersinia_transform == "1/x",
                                   "1/day", units),
               notes = yersinia_version()) |>
        select(param, label, source_set, id, study, estimate, type, units, basis,
               orig_symbol, orig_value, orig_units, notes)
}

## quantile functions for the prior families used by yersinia
prior_qfun <- function(family, p) {
    switch(family,
           Uniform = \(q) qunif(q, p$min, p$max),
           Normal = \(q) qnorm(q, p$mean, p$sd),
           LogNormal = \(q) qlnorm(q, p$meanlog, p$sdlog),
           Gamma = \(q) qgamma(q, shape = p$shape, rate = p$rate),
           Exponential = \(q) qexp(q, p$rate),
           Beta = \(q) qbeta(q, p$shape1, p$shape2),
           stop("unknown prior family ", family))
}

##' Parse the monty DSL of plague_fit_prior() into a list of priors
fit_prior_list <- function() {
    lines <- deparse(body(yersinia::plague_fit_prior))
    m <- regmatches(lines, regexec("^\\s*(\\w+) ~ (\\w+)\\((.*)\\)\\s*$", lines))
    m <- keep(m, \(x) length(x) == 4)
    set_names(map(m, \(x) {
        args <- eval(str2lang(paste0("list(", x[4], ")")))
        if (x[3] == "Uniform") names(args) <- c("min", "max")
        if (x[3] == "Gamma") names(args) <- c("shape", "rate")
        list(family = x[3], params = args)
    }), map_chr(m, 2))
}

##' Prior summaries (median and central 95% interval, canonical scale)
yersinia_priors <- function(ydict = yersinia_dict()) {
    lab <- set_names(map(ydict$yersinia_name, yersinia::prior_default),
                     ydict$yersinia_name) |> compact()
    pri <- list(lab = lab, fit = fit_prior_list())
    imap(pri, \(plist, set) {
        imap(plist, \(pr, nm) {
            qf <- prior_qfun(pr$family, pr$params)
            tibble(prior_set = set, yersinia_name = nm, family = pr$family,
                   desc = paste0(pr$family, "(",
                                 paste(names(pr$params), unlist(pr$params),
                                       sep = " = ", collapse = ", "), ")"),
                   q = list(qf(c(0.025, 0.5, 0.975))))
        }) |> list_rbind()
    }) |> list_rbind() |>
        inner_join(ydict, by = "yersinia_name") |>
        mutate(qt = map2(q, yersinia_transform,
                         \(x, tt) sort(eval(str2lang(tt), list(x = x)))),
               source_set = "yersinia",
               id = paste("yersinia_prior", prior_set, yersinia_name, sep = "_"),
               study = ifelse(prior_set == "lab",
                              "yersinia prior_default()", "yersinia plague_fit_prior()"),
               estimate = map_dbl(qt, 2),
               lwr = map_dbl(qt, 1), upr = map_dbl(qt, 3),
               type = "prior", interval = "prior 95% interval",
               basis = "prior",
               orig_symbol = yersinia_name,
               notes = paste0(desc, " on ", yersinia_name, "; estimate = prior median; ",
                              yersinia_version())) |>
        select(param, label, source_set, id, study, estimate, lwr, upr, interval,
               type, units, basis, orig_symbol, notes)
}

yersinia_long <- function() {
    bind_rows(yersinia_scenarios(), yersinia_priors())
}

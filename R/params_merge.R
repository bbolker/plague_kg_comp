## Merge Keeling & Gilligan (2000) parameters with Park's literature
## compendium in a common long format (one row per reported value).
## See data/README.md for the column definitions.
##
##  - data/kg_params.csv: KG values in their original notation and units,
##    converted here to canonical units via data/param_dict.csv
##  - data/park_params.csv: Park's compendium (canonical, edited by hand),
##    with quantities as reported (mean + SD/SE + n, ranges, point values).
##    Intervals for mean_sd/mean_se rows are derived here.
##  - data/didelot_params.csv: Didelot et al. (2017) fixed values and
##    posterior estimates (same format as park_params.csv)
##  - data/lit_params.csv: our own extractions from the literature (same
##    format)
##  - yersinia package scenarios and default priors (R/yersinia_params.R)
##
## Run as a script (from the project root) to write data/params_combined.csv.

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(purrr)
})

source(here::here("R", "yersinia_params.R"))

read_dict <- function(file = here::here("data", "param_dict.csv")) {
    read_csv(file, show_col_types = FALSE)
}

##' Evaluate a transformation string (in terms of x), e.g. "365/x"
apply_transform <- function(x, transform) {
    map2_dbl(x, transform, \(xx, tt) eval(str2lang(tt), list(x = xx)))
}

##' Fill in lwr/upr from reported SD or SE.
##' mean_sd: estimate +/- z * sd/sqrt(n)  (CI of the mean, as in Park's code)
##' mean_se: estimate +/- z * se
##' Rows of other types are unchanged; `interval` records how lwr/upr arose.
derive_intervals <- function(d, z = qnorm(0.975)) {
    d |>
        mutate(
            half = case_when(type == "mean_sd" ~ z * sd / sqrt(n),
                             type == "mean_se" ~ z * se,
                             .default = NA_real_),
            interval = case_when(!is.na(half) ~ "95% CI (derived)",
                                 type == "range" ~ "range",
                                 type == "CI" ~ "CI (reported)",
                                 type == "posterior" ~ "95% CrI (reported)",
                                 .default = NA_character_),
            lwr = coalesce(lwr, estimate - half),
            upr = coalesce(upr, estimate + half)) |>
        select(-half)
}

##' A hand-entered literature table (e.g. data/park_params.csv), with
##' labels/units from the dictionary
lit_long <- function(file, source_set, dict = read_dict()) {
    lit <- read_csv(file, show_col_types = FALSE)
    unmatched <- setdiff(lit$param, dict$param)
    if (length(unmatched) > 0) {
        stop("parameters missing from data/param_dict.csv: ",
             paste(unmatched, collapse = ", "))
    }
    lit |>
        left_join(select(dict, param, label, units), by = "param") |>
        mutate(source_set = source_set) |>
        derive_intervals()
}

##' KG parameters (data/kg_params.csv) in the common long format.
##' KG values are point values; the seasonal range of K_F is recorded in
##' notes, not as lwr/upr (which denote uncertainty).
kg_long <- function(kg = read_csv(here::here("data", "kg_params.csv"), show_col_types = FALSE),
                    dict = read_dict()) {
    kg |>
        filter(category != "setup") |>
        inner_join(select(dict, param, label, units_new = units,
                          kg_symbol, kg_transform),
                   by = c("symbol" = "kg_symbol")) |>
        mutate(source_set = "kg",
               id = paste0("kg_", symbol),
               study = "Keeling and Gilligan (2000)",
               bibkey = "keeling2000bubonic; keeling2000metapopulation",
               estimate = apply_transform(value, kg_transform),
               type = "point estimate",
               orig_symbol = symbol,
               orig_value = value,
               orig_units = units) |>
        select(param, label, source_set, id, study, bibkey,
               estimate, type, units = units_new, basis = kg_status,
               orig_symbol, orig_value, orig_units, notes)
}

##' Combine all sources
combine_params <- function(kg = kg_long(),
                           park = lit_long(here::here("data", "park_params.csv"), "park"),
                           didelot = lit_long(here::here("data", "didelot_params.csv"), "didelot"),
                           lit = lit_long(here::here("data", "lit_params.csv"), "lit"),
                           yersinia = yersinia_long()) {
    cols <- c("param", "label", "source_set", "id", "study", "bibkey",
              "host", "vector", "location",
              "estimate", "lwr", "upr", "interval", "sd", "se", "n", "type",
              "units", "basis", "orig_symbol", "orig_value", "orig_units",
              "page", "notes")
    bind_rows(kg, park, didelot, lit, yersinia) |>
        select(any_of(cols)) |>
        arrange(param, source_set, id)
}

if (sys.nframe() == 0) {
    out <- combine_params()
    write_csv(out, here::here("data", "params_combined.csv"), na = "")
    message("wrote ", nrow(out), " rows to data/params_combined.csv")
}

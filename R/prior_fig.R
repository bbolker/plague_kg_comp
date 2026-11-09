## Parameter values from all sources (literature, KG, Didelot et al.,
## yersinia scenarios) with prior densities (louseplague, yersinia), one
## panel per parameter. Extends louseplague's figure/prior_fig.R.
##
##  prior_fig("lit")   : parameters with literature values (linear axes)
##  prior_fig("model") : parameters that only models specify (log axes)
##  prior_fig(..., include_modes = , exclude_modes = , include_hosts = ,
##            exclude_hosts = ) : subset by transmission mode
##      (rat-flea, human-ecto, pneumonic) and/or host/vector (rat, human,
##      flea, louse), as given in data/param_dict.csv
##
## Run as a script to write outputs/figs/param_priors_{lit,model,lit_ratflea}.{pdf,png},
## or with --tikz to write the corresponding .tex files via
## tikzDevice.

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(ggplot2)
})

source(here::here("R", "utils.R"))
source(here::here("R", "prior_densities.R"))

theme_set(theme_bw())

## Okabe-Ito (minus black and yellow), one fixed colour per source
source_cols <- c(park = "#0072B2", lit = "#D55E00", kg = "#009E73",
                 didelot = "#E69F00", yersinia = "#56B4E9")
source_labs <- c(park = "literature (Park)", lit = "literature (this project)",
                 kg = "Keeling & Gilligan (2000)", didelot = "Didelot et al. (2017)",
                 yersinia = "yersinia scenarios")
type_shapes <- c(`point estimate` = 16, range = 1, CI = 15, posterior = 18,
                 fixed = 0, maximum = 17, scenario = 4)
prior_ltys <- c(louseplague = "solid", `yersinia lab` = "dashed",
                `yersinia fit` = "dotted")
prior_cols <- c(louseplague = "grey40", `yersinia lab` = source_cols[["yersinia"]],
                `yersinia fit` = source_cols[["yersinia"]])
prior_fills <- c(louseplague = "grey80")

tex_escape <- function(x) gsub("&", "\\\\&", x)

##' Panel labels: parameter description (wrapped at `width` characters),
##' then "(symbol, units)" on the last line (plotmath or LaTeX)
panel_labels <- function(label, units, description, tikz = FALSE, width = 40) {
    show_units <- !is.na(units) & !units %in% c("dimensionless", "probability")
    desc_lines <- lapply(description, strwrap, width = width)
    if (tikz) {
        desc <- vapply(desc_lines, \(l) paste(tex_escape(l), collapse = "\\\\"), "")
        paste0("\\shortstack{", desc, "\\\\($", label, "$",
               ifelse(show_units, paste0(", ", tex_escape(units)), ""), ")}")
    } else {
        pm <- vapply(label, \(l) latex2exp::TeX(paste0("$", l, "$"), output = "character"), "")
        ## plotmath displays the parentheses in (...); * juxtaposes without space
        sym <- paste0("(", pm, ifelse(show_units, paste0('*", ', units, '"'), ""), ")")
        ## stack lines with nested atop(): atop(atop(l1, l2), sym); atop()
        ## sets its arguments in a smaller style, so wrap each in displaystyle()
        ds <- \(x) paste0("displaystyle(", x, ")")
        vapply(seq_along(sym), \(i) {
            Reduce(\(a, b) paste0("atop(", ds(a), ", ", ds(b), ")"),
                   c(encodeString(desc_lines[[i]], quote = '"'), sym[i]))
        }, "")
    }
}

##' Log-axis labels: powers of ten where a break is an exact power, plain
##' numbers otherwise (panels with narrow ranges get non-power breaks)
log_labels <- function(x, tikz = FALSE) {
    k <- round(log10(x))
    pow <- !is.na(x) & abs(log10(x) - k) < 1e-8
    plain <- format_num(x)
    if (tikz) {
        ifelse(pow, sprintf("$10^{%d}$", as.integer(k)), plain)
    } else {
        parse(text = ifelse(is.na(x), "''",
                            ifelse(pow, paste0("10^", as.integer(k)), paste0("'", plain, "'"))))
    }
}

format_num <- function(x) {
    vapply(x, \(v) if (is.na(v)) NA_character_ else format(signif(v, 2), scientific = FALSE,
                                                         drop0trailing = TRUE), "")
}

##' Abbreviated references from bib keys: first 4 letters of the first
##' author's surname, plus the first 4 of the second author's if there are
##' exactly two, or "+" if three or more; then the year (Baco1915,
##' KeelGill2000, Toll+2010). Corporate authors get the initials of their
##' name (IPC1908). For multiple keys ("a; b") the first is used.
bib_abbrev <- function(bibkey, bib = here::here("plague_kg_comp.bib")) {
    entries <- suppressWarnings(bibtex::read.bib(bib))
    abbrev1 <- function(key) {
        e <- entries[[key]]
        fam <- vapply(e$author, \(a) paste(a$family, collapse = " "), "")
        fam <- iconv(fam, to = "ASCII//TRANSLIT")
        corporate <- length(e$author) == 1 && is.null(e$author[[1]]$given)
        nm <- if (corporate) {
            words <- strsplit(sub("\\s*\\(.*", "", fam), "\\s+")[[1]]
            paste(substr(words, 1, 1), collapse = "")
        } else {
            short <- substr(gsub("[^A-Za-z]", "", fam), 1, 4)
            paste0(short[1], switch(min(length(short), 3), "", short[2], "+"))
        }
        paste0(nm, e$year)
    }
    keys <- sub(";.*", "", bibkey)
    out <- rep(NA_character_, length(keys))
    ok <- !is.na(keys)
    out[ok] <- vapply(keys[ok], abbrev1, "")
    out
}

param_modes <- c("rat-flea", "human-ecto", "pneumonic")
param_hosts <- c("rat", "human", "flea", "louse")

##' Restrict a parameter dictionary by transmission mode and host/vector
##' (the `mode` and `host` columns hold ";"-separated values).
##' include_*: keep parameters with at least one of these values;
##' exclude_*: drop parameters with any of these values.
##' NULL means no restriction; exclusion is applied after inclusion.
subset_dict <- function(dict, include_modes = NULL, exclude_modes = NULL,
                        include_hosts = NULL, exclude_hosts = NULL) {
    has_any <- function(col, vals, choices) {
        vals <- match.arg(vals, choices, several.ok = TRUE)
        vapply(strsplit(col, ";", fixed = TRUE), \(v) any(v %in% vals), logical(1))
    }
    keep <- rep(TRUE, nrow(dict))
    if (!is.null(include_modes)) keep <- keep & has_any(dict$mode, include_modes, param_modes)
    if (!is.null(include_hosts)) keep <- keep & has_any(dict$host, include_hosts, param_hosts)
    if (!is.null(exclude_modes)) keep <- keep & !has_any(dict$mode, exclude_modes, param_modes)
    if (!is.null(exclude_hosts)) keep <- keep & !has_any(dict$host, exclude_hosts, param_hosts)
    dict[keep, ]
}

##' Beeswarm-style vertical positions within rows: values in a row that
##' would overlap horizontally (points, or intervals including their
##' estimates, padded by `pad` of the panel width) are moved to the
##' nearest free offset (0, +1, -1, +2, ...); offsets are scaled so the
##' outermost value stays within `max_off` of the row centre. Deterministic.
##' Adds `y`: numeric position, with panel-local row numbers (free facet
##' scales give each panel only its own rows, in factor order).
swarm_offsets <- function(vals, ranges, log_x = FALSE, pad = 0.015,
                          max_off = 0.4, step = 0.25) {
    tr <- if (log_x) log10 else identity
    place <- function(lo, hi) {
        k <- integer(length(lo))
        placed <- logical(length(lo))
        for (i in order((lo + hi) / 2)) {
            cands <- c(0L, rbind(seq_along(lo), -seq_along(lo)))
            for (cand in cands) {
                same <- placed & k == cand
                if (!any(same & lo <= hi[i] & hi >= lo[i])) break
            }
            k[i] <- cand
            placed[i] <- TRUE
        }
        k
    }
    vals |>
        left_join(ranges, by = "param") |>
        group_by(param) |>
        mutate(row_pos = match(row, intersect(levels(row), row)),
               width = tr(hi) - tr(lo)) |>
        group_by(param, row) |>
        mutate(x_lo = tr(pmin(estimate, lwr, na.rm = TRUE)) - pad * width,
               x_hi = tr(pmax(estimate, upr, na.rm = TRUE)) + pad * width,
               k = place(x_lo, x_hi),
               y = row_pos + k * min(step, max_off / max(1, abs(k)))) |>
        ungroup() |>
        select(-c(lo, hi, width, x_lo, x_hi, k, row_pos))
}

##' Data for one figure: point/interval rows, prior curves, panel order
##' (short_labels: abbreviated references as row labels, else study names;
##' scenarios: include the yersinia scenario values, which are model
##' choices or duplicates of KG/Didelot values rather than primary sources;
##' ...: include_modes, exclude_modes, include_hosts, exclude_hosts,
##' passed to subset_dict())
prior_fig_data <- function(group = c("lit", "model"), tikz = FALSE, short_labels = TRUE,
                           scenarios = FALSE, ...) {
    group <- match.arg(group)
    log_x <- group == "model"
    dict <- read_csv(here::here("data", "param_dict.csv"), show_col_types = FALSE) |>
        subset_dict(...)
    comb <- read_csv(here::here("data", "params_combined.csv"), show_col_types = FALSE)
    louse_priors <- read_csv(here::here("data", "louseplague_priors.csv"), show_col_types = FALSE)
    lit_params <- union(comb$param[comb$source_set %in% c("park", "lit")], louse_priors$param)
    not_comparable <- dict$param[dict$kg_comparable %in% "no"]
    vals <- comb |>
        filter(type != "prior",
               scenarios | type != "scenario",
               ## values a study took from an earlier model duplicate it
               is.na(borrowed_from),
               param %in% dict$param,
               if (group == "lit") param %in% lit_params else !param %in% lit_params,
               !(source_set == "kg" & param %in% not_comparable)) |>
        mutate(type = case_when(type %in% c("CI", "mean_sd", "mean_se") ~ "CI",
                                .default = type),
               row = case_when(source_set == "yersinia" ~ source_labs[["yersinia"]],
                               short_labels ~ bib_abbrev(bibkey),
                               source_set == "kg" ~ source_labs[["kg"]],
                               .default = study))
    if (log_x) {
        vals <- filter(vals, coalesce(estimate, lwr) > 0)
    }
    if (nrow(vals) == 0) stop("no '", group, "' parameters match the mode/host subset")
    ## rows bottom to top: literature, our extractions, KG, Didelot, yersinia
    row_order <- vals |>
        distinct(source_set, row) |>
        mutate(source_set = factor(source_set, levels = names(source_cols))) |>
        arrange(source_set, desc(row)) |>
        pull(row)
    if (tikz) row_order <- tex_escape(row_order)
    vals <- mutate(vals, row = factor(if (tikz) tex_escape(row) else row, levels = row_order))

    specs <- prior_specs(dict) |> filter(param %in% vals$param)
    ## panel range: the data, plus the central range of the priors that set
    ## the scale (louseplague priors for "lit", yersinia priors for "model")
    scale_sets <- if (group == "lit") "louseplague" else c("yersinia lab", "yersinia fit")
    data_rng <- vals |>
        group_by(param) |>
        summarise(lo = min(c(estimate, lwr), na.rm = TRUE),
                  hi = max(c(estimate, upr), na.rm = TRUE))
    prior_rng <- prior_ranges(specs) |> filter(prior_set %in% scale_sets)
    ranges <- bind_rows(data_rng, select(prior_rng, -prior_set)) |>
        group_by(param) |>
        summarise(lo = if (log_x) min(lo) / 1.5 else 0, hi = max(hi) * if (log_x) 1.5 else 1.05)
    curves <- prior_curves(specs, ranges, log_x = log_x)
    vals <- swarm_offsets(vals, ranges, log_x)

    param_order <- dict$param[dict$param %in% vals$param]
    labs <- dict |>
        filter(param %in% param_order) |>
        mutate(panel = panel_labels(label, units, description, tikz)) |>
        select(param, panel)
    panel_levels <- labs$panel[match(param_order, labs$param)]
    add_panel <- \(d) d |>
        left_join(labs, by = "param") |>
        mutate(panel = factor(panel, levels = panel_levels))
    namedList(vals = add_panel(vals), curves = add_panel(curves), log_x, tikz)
}

##' Build the figure
##' (...: subset parameters by transmission mode and host/vector, see
##' subset_dict(), e.g. prior_fig("lit", include_modes = "pneumonic") or
##' prior_fig("lit", include_hosts = "flea", exclude_hosts = "human");
##' scenarios: see prior_fig_data())
prior_fig <- function(group = c("lit", "model"), tikz = FALSE, ncol = 4, short_labels = TRUE,
                      scenarios = FALSE, ...) {
    d <- prior_fig_data(match.arg(group), tikz, short_labels, scenarios, ...)
    lab_fun <- if (tikz) function(x) tex_escape(x) else identity
    ## louseplague priors (derived from the literature values) are drawn as
    ## filled areas, model priors as lines
    filled <- "louseplague"
    curve_fill <- filter(d$curves, prior_set %in% filled)
    curve_line <- filter(d$curves, !prior_set %in% filled)
    sets <- intersect(names(prior_ltys), curve_line$prior_set)
    p <- ggplot(d$vals, aes(y = row)) +
        ## train each panel's discrete axis on all rows first, so rows keep
        ## the factor order; the other layers use numeric positions (d$vals$y
        ## = panel-local row number + swarm offset; curves below row 1)
        geom_blank(aes(x = coalesce(estimate, lwr))) +
        geom_ribbon(data = curve_fill,
                    aes(x = x, ymin = 0, ymax = rel_density, fill = prior_set),
                    inherit.aes = FALSE, na.rm = TRUE) +
        geom_path(data = curve_line,
                  aes(x = x, y = rel_density, linetype = prior_set, colour = prior_set),
                  inherit.aes = FALSE, linewidth = 0.5, na.rm = TRUE) +
        geom_errorbar(data = filter(d$vals, !is.na(lwr)),
                      aes(xmin = lwr, xmax = upr, y = y, colour = source_set),
                      width = 0.12, orientation = "y") +
        geom_point(data = filter(d$vals, !is.na(estimate)),
                   aes(x = estimate, y = y, colour = source_set, shape = type),
                   size = 2) +
        facet_wrap(~panel, scales = "free",
                   labeller = if (tikz) label_value else label_parsed, ncol = ncol) +
        scale_colour_manual(values = c(source_cols, prior_cols),
                            breaks = names(source_cols),
                            labels = lab_fun(source_labs[names(source_cols)]),
                            name = NULL, guide = guide_legend(order = 3)) +
        scale_shape_manual(values = type_shapes, name = NULL,
                           breaks = intersect(names(type_shapes), d$vals$type),
                           guide = guide_legend(order = 4)) +
        ## legend order: prior fill, prior lines, sources, value types
        (if (nrow(curve_fill) > 0) scale_fill_manual(values = prior_fills, name = "prior",
                                                     guide = guide_legend(order = 1))) +
        scale_linetype_manual(values = prior_ltys,
                              name = if (nrow(curve_fill) > 0) NULL else "prior", breaks = sets,
                              guide = guide_legend(order = 2,
                                                   override.aes = list(colour = unname(prior_cols[sets])))) +
        ## discrete rows; the prior curves use numeric positions below row 1
        scale_y_discrete() +
        labs(x = NULL, y = NULL) +
        theme(panel.spacing = grid::unit(0, "pt"),
              strip.background = element_blank(),
              legend.position = "top",
              legend.box = "vertical",
              panel.grid.minor = element_blank())
    if (d$log_x) {
        p <- p + scale_x_log10(breaks = scales::breaks_log(n = 4),
                               labels = \(x) log_labels(x, tikz))
    }
    p
}

if (sys.nframe() == 0) {
    tikz <- "--tikz" %in% commandArgs(trailingOnly = TRUE)
    dir.create(here::here("outputs", "figs"), showWarnings = FALSE, recursive = TRUE)
    ## figure name -> prior_fig() arguments and size (width, height in inches)
    figs <- list(lit = list(args = list("lit"), size = c(16, 15)),
                 model = list(args = list("model"), size = c(16, 8)),
                 lit_ratflea = list(args = list("lit", exclude_hosts = c("human", "louse")), size = c(16, 8)))
    for (g in names(figs)) {
        p <- do.call(prior_fig, c(figs[[g]]$args, list(tikz = tikz)))
        size <- figs[[g]]$size
        if (tikz) {
            options(tikzMetricPackages = c("\\usepackage[utf8]{inputenc}",
                                           "\\usepackage[T1]{fontenc}",
                                           "\\usetikzlibrary{calc}",
                                           "\\usepackage{amssymb}"))
            f <- here::here("outputs", "figs", paste0("param_priors_", g, ".tex"))
            tikzDevice::tikz(f, width = size[1], height = size[2])
            print(p)
            invisible(dev.off())
        } else {
            f <- here::here("outputs", "figs", paste0("param_priors_", g, c(".pdf", ".png")))
            for (ff in f) ggsave(ff, p, width = size[1], height = size[2], dpi = 150)
        }
        message("wrote ", paste(f, collapse = ", "))
    }
}

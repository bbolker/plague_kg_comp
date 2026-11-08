## Parameter values from all sources (literature, KG, Didelot et al.,
## yersinia scenarios) with prior densities (louseplague, yersinia), one
## panel per parameter. Extends louseplague's figure/prior_fig.R.
##
##  prior_fig("lit")   : parameters with literature values (linear axes)
##  prior_fig("model") : parameters that only models specify (log axes)
##
## Run as a script to write outputs/figs/param_priors_{lit,model}.{pdf,png},
## or with --tikz to write outputs/figs/param_priors_{lit,model}.tex via
## tikzDevice.

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(ggplot2)
})

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

tex_escape <- function(x) gsub("&", "\\\\&", x)

##' Panel labels: parameter symbol plus units (plotmath or LaTeX)
panel_labels <- function(label, units, tikz = FALSE) {
    show_units <- !is.na(units) & !units %in% c("dimensionless", "probability")
    if (tikz) {
        paste0("$", label, "$", ifelse(show_units, paste0(" (", units, ")"), ""))
    } else {
        pm <- vapply(label, \(l) latex2exp::TeX(paste0("$", l, "$"), output = "character"), "")
        paste0(pm, ifelse(show_units, paste0('~~"(', units, ')"'), ""))
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

##' Data for one figure: point/interval rows, prior curves, panel order
prior_fig_data <- function(group = c("lit", "model"), tikz = FALSE) {
    group <- match.arg(group)
    log_x <- group == "model"
    dict <- read_csv(here::here("data", "param_dict.csv"), show_col_types = FALSE)
    comb <- read_csv(here::here("data", "params_combined.csv"), show_col_types = FALSE)
    louse_priors <- read_csv(here::here("data", "louseplague_priors.csv"), show_col_types = FALSE)
    lit_params <- union(comb$param[comb$source_set %in% c("park", "lit")], louse_priors$param)
    not_comparable <- dict$param[dict$kg_comparable %in% "no"]
    vals <- comb |>
        filter(type != "prior",
               if (group == "lit") param %in% lit_params else !param %in% lit_params,
               !(source_set == "kg" & param %in% not_comparable)) |>
        mutate(type = case_when(type %in% c("CI", "mean_sd", "mean_se") ~ "CI",
                                .default = type),
               row = case_when(source_set == "kg" ~ source_labs[["kg"]],
                               source_set == "yersinia" ~ source_labs[["yersinia"]],
                               .default = study))
    if (log_x) {
        vals <- filter(vals, coalesce(estimate, lwr) > 0)
    }
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

    param_order <- dict$param[dict$param %in% vals$param]
    labs <- dict |>
        filter(param %in% param_order) |>
        mutate(panel = panel_labels(label, units, tikz)) |>
        select(param, panel)
    panel_levels <- labs$panel[match(param_order, labs$param)]
    add_panel <- \(d) d |>
        left_join(labs, by = "param") |>
        mutate(panel = factor(panel, levels = panel_levels))
    lst(vals = add_panel(vals), curves = add_panel(curves), log_x, tikz)
}

##' Build the figure
prior_fig <- function(group = c("lit", "model"), tikz = FALSE, ncol = 4) {
    d <- prior_fig_data(match.arg(group), tikz)
    lab_fun <- if (tikz) function(x) tex_escape(x) else identity
    dodge <- position_dodge(width = 0.6, orientation = "y")
    sets <- intersect(names(prior_ltys), d$curves$prior_set)
    p <- ggplot(d$vals, aes(y = row)) +
        ## train each panel's discrete axis on all rows first, so rows keep
        ## the factor order (layers with a subset of rows would reorder them)
        geom_blank(aes(x = coalesce(estimate, lwr))) +
        geom_path(data = d$curves,
                  aes(x = x, y = rel_density, linetype = prior_set, colour = prior_set),
                  inherit.aes = FALSE, linewidth = 0.5, na.rm = TRUE) +
        geom_errorbar(data = filter(d$vals, !is.na(lwr)),
                      aes(xmin = lwr, xmax = upr, group = id, colour = source_set),
                      width = 0.25, orientation = "y", position = dodge) +
        geom_point(data = filter(d$vals, !is.na(estimate)),
                   aes(x = estimate, group = id, colour = source_set, shape = type),
                   size = 2, position = dodge) +
        facet_wrap(~panel, scales = "free",
                   labeller = if (tikz) label_value else label_parsed, ncol = ncol) +
        scale_colour_manual(values = c(source_cols, prior_cols),
                            breaks = names(source_cols),
                            labels = lab_fun(source_labs[names(source_cols)]),
                            name = NULL) +
        scale_shape_manual(values = type_shapes, name = NULL,
                           breaks = intersect(names(type_shapes), d$vals$type)) +
        scale_linetype_manual(values = prior_ltys, name = "prior", breaks = sets,
                              guide = guide_legend(override.aes = list(colour = unname(prior_cols[sets])))) +
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
    sizes <- list(lit = c(16, 15), model = c(16, 8))
    for (g in names(sizes)) {
        p <- prior_fig(g, tikz = tikz)
        if (tikz) {
            options(tikzMetricPackages = c("\\usepackage[utf8]{inputenc}",
                                           "\\usepackage[T1]{fontenc}",
                                           "\\usetikzlibrary{calc}",
                                           "\\usepackage{amssymb}"))
            f <- here::here("outputs", "figs", paste0("param_priors_", g, ".tex"))
            tikzDevice::tikz(f, width = sizes[[g]][1], height = sizes[[g]][2])
            print(p)
            invisible(dev.off())
        } else {
            f <- here::here("outputs", "figs", paste0("param_priors_", g, c(".pdf", ".png")))
            for (ff in f) ggsave(ff, p, width = sizes[[g]][1], height = sizes[[g]][2], dpi = 150)
        }
        message("wrote ", paste(f, collapse = ", "))
    }
}

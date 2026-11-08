## Read the Keeling & Gilligan (2000) parameter table and compute derived
## quantities. Sources: data/kg_params.csv (Proc R Soc B Table 1 + Nature
## Table 1/Methods) and data/kg_a_lower_bounds.csv (Proc R Soc B Table 2).

data_dir <- here::here("data")

##' Read the KG parameter table, adding per-day values for rates
read_kg_params <- function(file = file.path(data_dir, "kg_params.csv")) {
    pars <- read.csv(file, stringsAsFactors = FALSE)
    is_rate <- pars$units == "1/yr"
    pars$value_per_day <- ifelse(is_rate, pars$value / 365, NA)
    pars
}

##' Named vector of KG parameter values (original units)
kg_values <- function(pars = read_kg_params()) {
    setNames(pars$value, pars$symbol)
}

##' Seasonal flea carrying capacity, Proc R Soc B §5:
##' K_F(season) = k_F (1 + kappa_F)^sin(2 pi season), 0 <= season < 1.
##' k_F and kappa_F are recovered from the stated range (min, max):
##' min = k_F/(1+kappa_F), max = k_F (1+kappa_F).
kg_seasonal_KF <- function(KF_min = 3.29, KF_max = 11.17) {
    k_F <- sqrt(KF_min * KF_max)
    kappa_F <- sqrt(KF_max / KF_min) - 1
    KF_fun <- function(season) k_F * (1 + kappa_F)^sin(2 * pi * season)
    list(k_F = k_F, kappa_F = kappa_F,
         ## annual mean (= k_F * besselI(log(1 + kappa_F), 0))
         mean = integrate(KF_fun, 0, 1)$value,
         KF = KF_fun)
}

##' R0 for rat epizootics, Proc R Soc B §6:
##' R0 = beta_R K_F [1 - exp(-a K_R)] / d_F
kg_R0 <- function(v = kg_values()) {
    with(as.list(v), beta_R * K_F * (1 - exp(-a * K_R)) / d_F)
}

##' Threshold value of a*K_R for R0 = 1
kg_aK_threshold <- function(v = kg_values()) {
    with(as.list(v), -log(1 - d_F / (beta_R * K_F)))
}

##' Lower bounds on a from sylvatic plague (Proc R Soc B Table 2).
##' Recomputes a_min = threshold / density for comparison with the
##' published values.
read_kg_a_bounds <- function(file = file.path(data_dir, "kg_a_lower_bounds.csv"),
                             threshold = kg_aK_threshold()) {
    b <- read.csv(file, stringsAsFactors = FALSE)
    b$a_min_lwr_calc <- threshold / b$density_max
    b$a_min_upr_calc <- threshold / b$density_min
    b
}

if (sys.nframe() == 0) {
    pars <- read_kg_params()
    print(pars[, c("symbol", "value", "units", "value_per_day", "kg_status",
                   "yersinia_name")], row.names = FALSE)
    v <- kg_values(pars)
    cat("\nR0 =", round(kg_R0(v), 3),
        "; threshold a*K_R =", round(kg_aK_threshold(v), 3),
        "; a*K_R =", v[["a"]] * v[["K_R"]], "\n")
    s <- kg_seasonal_KF()
    cat("seasonal K_F: k_F =", round(s$k_F, 3), ", kappa_F =", round(s$kappa_F, 3),
        ", annual mean =", round(s$mean, 3), "(KG state 6.57)\n\n")
    print(read_kg_a_bounds(), digits = 3, row.names = FALSE)
}

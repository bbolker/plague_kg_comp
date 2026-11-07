## Disease-free rat dynamics with inherited resistance: compare where
## density dependence acts.
##
##  "KG"      : Keeling & Gilligan (2000) as written; births at r, density-
##              dependent mortality r*T/K on S and R.
##              S' = r S (1 - T/K) + r R (1-p) - d S
##              R' = r R (p - T/K) - d R
##  "recruit" : density-dependent recruitment (as in the yersinia stochastic
##              model, with iota = 1); births at b = r (1 - T/K).
##              S' = b S + b R (1-p) - d S
##              R' = b R p - d R
##
## In both cases the resistant fraction f = R/(S+R) obeys
##   f' = -(1-p) b(t) f,
## with b = r (KG) or b = r (1 - T/K) (recruitment).

library(deSolve)

## default KG parameters (per year)
kg_pars <- c(r = 5, d = 0.2, K = 2500)

waning_rhs <- function(t, y, parms) {
    with(as.list(c(y, parms)), {
        T <- S + R
        if (version == "KG") {
            dS <- r * S * (1 - T/K) + r * R * (1 - p) - d * S
            dR <- r * R * (p - T/K) - d * R
        } else {
            b <- r * (1 - T/K)
            dS <- b * S + b * R * (1 - p) - d * S
            dR <- b * R * p - d * R
        }
        list(c(dS, dR))
    })
}

##' Resistant fraction over time after a crash, starting with all survivors
##' resistant (f0 = 1).
##' @param p probability of inherited resistance
##' @param crash surviving population as a fraction of T* = K (1 - d/r)
##' @param times output times (years)
##' @param version "KG" or "recruit"
##' @param pars named vector with r, d, K
resist_frac <- function(p, crash, times = c(0, 1, 5, 10, 20),
                        version = c("KG", "recruit"), pars = kg_pars) {
    version <- match.arg(version)
    Tstar <- pars[["K"]] * (1 - pars[["d"]]/pars[["r"]])
    y0 <- c(S = 0, R = crash * Tstar)
    parms <- c(as.list(pars), p = p, version = version)
    out <- ode(y0, times, waning_rhs, parms, method = "lsoda")
    data.frame(p = p, crash = crash, version = version,
               time = out[, "time"],
               ## clamp tiny negative values from ODE round-off
               f = pmax(0, out[, "R"] / (out[, "S"] + out[, "R"])))
}

##' Analytical dilution due to regrowth alone under the recruitment version:
##' f_end/f_0 = (T0/Tend)^(1-p) (ignoring the exp(-(1-p) d tau) factor)
regrowth_dilution <- function(p, crash) crash^(1 - p)

##' Run the full comparison grid
waning_grid <- function(p = c(0.975, 0.5), crash = c(0.5, 0.1, 0.01, 0.001),
                        times = c(0, 1, 5, 10, 20)) {
    g <- expand.grid(p = p, crash = crash, version = c("KG", "recruit"),
                     stringsAsFactors = FALSE)
    do.call(rbind, Map(resist_frac, g$p, g$crash,
                       MoreArgs = list(times = times),
                       version = g$version))
}

if (sys.nframe() == 0) {
    ## run as a script: print the comparison
    res <- waning_grid()
    wide <- reshape(res, idvar = c("p", "crash", "time"),
                    timevar = "version", direction = "wide")
    wide$regrowth_pred <- regrowth_dilution(wide$p, wide$crash)
    print(wide, digits = 3, row.names = FALSE)
}

## install packages needed for the plague_kg_comp project
## (no pak: CRAN via install.packages, others via r-universe/remotes)
options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c(
    "bbmle"        ## MLE, e.g. fitting distributions to reported quantiles
  , "cli"          ## yersinia import
  , "checkmate"    ## yersinia import
  , "colorspace"
  , "cowplot"
  , "deSolve"
  , "fitdistrplus"
  , "furrr"
  , "future"
  , "glue"         ## yersinia import
  , "here"
  , "latex2exp"    ## LaTeX labels -> plotmath
  , "Matrix"       ## yersinia import
  , "patchwork"
  , "progressr"
  , "remotes"
  , "tikzDevice"   ## LaTeX graphics output
  , "rlang"        ## yersinia import
  , "tidyverse"
  , "withr"        ## yersinia import
  , "yaml"
)

i1 <- installed.packages()
pkgs <- setdiff(pkgs, rownames(i1))
if (length(pkgs) > 0) {
    install.packages(pkgs)
}

## odin2/dust2/monty (mrc-ide) from r-universe
mrc_pkgs <- setdiff(c("odin2", "dust2", "monty"), rownames(i1))
if (length(mrc_pkgs) > 0) {
    install.packages(mrc_pkgs,
                     repos = c("https://mrc-ide.r-universe.dev",
                               getOption("repos")))
}

## yersinia: fork with the 'true' Keeling-Gilligan model variant (add_kg branch)
remotes::install_github("bbolker/yersinia@add_kg", upgrade = "never")

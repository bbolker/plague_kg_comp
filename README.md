# plague_kg_comp

Comparing the Keeling–Gilligan (KG) rat–flea plague model
[@keeling2000bubonic; @keeling2000metapopulation] with simpler and
alternative formulations, and building literature-based prior
distributions for the parameters of plague models.

## Goals

1. **Parameters and priors.** Reconcile the parameter values used by
   KG with the scenario parameter sets in the `yersinia` package and
   with Daniel Park's review of parameter values in the literature
   (from the `louseplague` project). Use these to build prior
   distributions with the methods worked out for `louseplague`.
2. **Model comparison.** Compare the original KG model with:
   a. the closest simple compartmental model, with the flea
      compartment collapsed out entirely;
   b. KG with perfectly efficient flea search (search efficiency
      $a \to \infty$, so that $1 - e^{-aT_r} \to 1$);
   c. SIR models whose incidence functions match KG's (or
      deliberately don't);
   d. the carcass-transmission model of @didelot2017model, which
      replaces flea transmission with transmission from infectious
      rat carcasses.

   The comparison covers single-patch dynamics (R0, epidemic shape,
   endemic equilibria and their stability, timescales) and, eventually,
   what each model implies for **metapopulation persistence**. That
   part concentrates on whichever parameter turns out to matter most,
   qualitatively, for persistence.

## Related sources

- **`~/projects/louseplague`**: the plague model of Park, Bolker et
  al. (human ectoparasites, Second Pandemic).
  - `data/parameter.R`: Park's literature values. Each entry is a
    data.frame with `study`, `parameter`, `estimate`/`lwr`/`upr`, and
    `type` (`CI`, `range` or `point estimate`).
  - `data/param_tab.R`: combines the entries and maps parameter names
    to model components.
  - `data/prior_dean.R`: the prior means used by @dean2018human.
  - `figure/prior_fig.R`: draws the figure comparing literature values
    with the priors.
  - `doc/plague.Rnw` (section "Uncertainty in parametric assumption",
    and Table `tab:param`): how heterogeneous reports (CIs, ranges,
    single point estimates) were turned into independent Gamma/Beta
    priors.
  - `doc/plague.bib`: bibliography.
- **`~/R/pkgs/yersinia`** (fork of `flmnh-ai/yersinia`, at
  `bbolker/yersinia`): odin2/dust2/monty implementation.
  - The core stochastic model (`inst/odin/`) uses Didelot's carcass
    formulation.
  - The original KG flea model appears only as a deterministic
    reference in `vignettes/reference-deterministic-models.Rmd`.
  - Parameter sets are in `inst/scenarios/*.yaml` (`keeling-gilligan`,
    `historical`, `didelot`, `modern-estimates`, `defaults`).
  - Default priors are in `R/app_priors.R` (`prior_default()`).

## Setup

```sh
Rscript get_pkgs.R
```

This installs the CRAN packages, the mrc-ide packages (`odin2`,
`dust2`, `monty`, from the mrc-ide r-universe) and `yersinia`. It
installs `yersinia` from GitHub, using the `add_kg` branch of
`bbolker/yersinia` (where a 'true' KG model variant is being
developed) and falling back to the default branch if that branch
doesn't exist.

## Layout (planned)

- `R/`: model definitions and helper functions
- `data/`: parameter tables (KG, yersinia scenarios, Park's
  literature values)
- `doc/`: write-ups (Quarto)
- `notes/`: shorter working notes (Quarto), e.g.
  `notes/density_dependence.qmd` on where rat density dependence acts
  and how fast inherited resistance wanes
- `figs/`: figures
- `papers/`: downloaded PDFs for full-text reading. This is
  **gitignored** because the repo is public; don't commit PDFs.

## Bibliography

`plague_kg_comp.bib` is the project bibliography. Copy entries from
`~/projects/louseplague/doc/plague.bib` as they're needed, keeping the
louseplague citation keys (e.g. `keeling2000bubonic`) so that keys stay
consistent between the two projects. New references (e.g. from extending
Park's literature search) get added here directly.

See `TODO.md` for the work plan.

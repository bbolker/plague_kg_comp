

<!-- README.md is generated from README.qmd by `make README.md`. Please edit README.qmd, not README.md. -->

# plague_kg_comp

Comparing the Keeling–Gilligan (KG) rat–flea plague model (Keeling and
Gilligan 2000a, 2000b) with simpler and alternative formulations, and
building literature-based prior distributions for the parameters of
plague models.

## Goals

1.  **Parameters and priors.** Reconcile the parameter values used by KG
    with the scenario parameter sets in the `yersinia` package and with
    Daniel Park’s review of parameter values in the literature (from the
    `louseplague` project). Use these to build prior distributions with
    the methods worked out for `louseplague`.
2.  **Model comparison.** Compare the original KG model with:
    - **(a)** the closest simple compartmental model, with the flea
      compartment collapsed out entirely;
    - **(b)** KG with perfectly efficient flea search (search efficiency
      $a \to \infty$, so that $1 - e^{-aT_r} \to 1$);
    - **(c)** SIR models whose incidence functions match KG’s (or
      deliberately don’t);
    - **(d)** the carcass-transmission model of Didelot, Whittles, and
      Hall (2017), which replaces flea transmission with transmission
      from infectious rat carcasses.

    The comparison covers single-patch dynamics (R0, epidemic shape,
    endemic equilibria and their stability, timescales) and, eventually,
    what each model implies for **metapopulation persistence**. That
    part concentrates on whichever parameter turns out to matter most,
    qualitatively, for persistence.

## Related sources

- **`~/projects/louseplague`**: the plague model of Park, Bolker et
  al. (human ectoparasites, Second Pandemic).
  - `data/parameter.R`: Park’s literature values. Each entry is a
    data.frame with `study`, `parameter`, `estimate`/`lwr`/`upr`, and
    `type` (`CI`, `range` or `point estimate`).
  - `data/param_tab.R`: combines the entries and maps parameter names to
    model components.
  - `data/prior_dean.R`: the prior means used by Dean et al. (2018).
  - `figure/prior_fig.R`: draws the figure comparing literature values
    with the priors.
  - `doc/plague.Rnw` (section “Uncertainty in parametric assumption”,
    and Table `tab:param`): how heterogeneous reports (CIs, ranges,
    single point estimates) were turned into independent Gamma/Beta
    priors.
  - `doc/plague.bib`: bibliography.
- **`~/R/pkgs/yersinia`** (fork of `flmnh-ai/yersinia`, at
  `bbolker/yersinia`): odin2/dust2/monty implementation.
  - The core stochastic model (`inst/odin/`) uses Didelot’s carcass
    formulation.
  - The original KG flea model appears only as a deterministic reference
    in `vignettes/reference-deterministic-models.Rmd`.
  - Parameter sets are in `inst/scenarios/*.yaml` (`keeling-gilligan`,
    `historical`, `didelot`, `modern-estimates`, `defaults`).
  - Default priors are in `R/app_priors.R` (`prior_default()`).

## Setup

``` sh
Rscript get_pkgs.R
```

This installs the CRAN packages, the mrc-ide packages (`odin2`, `dust2`,
`monty`, from the mrc-ide r-universe) and `yersinia`. It installs
`yersinia` from GitHub, using the `add_kg` branch of `bbolker/yersinia`
(where a ‘true’ KG model variant is being developed).

`README.md` is generated from `README.qmd` by `make README.md`, which
also formats the references. Edit `README.qmd`, never `README.md`.

## Layout (planned)

- `R/`: model definitions and helper functions
- `data/`: parameter tables (KG, yersinia scenarios, Park’s literature
  values)
- `doc/`: write-ups (Quarto)
- `notes/`: shorter working notes (Quarto):
  - `notes/density_dependence.qmd`: where rat density dependence acts
    and how fast inherited resistance wanes
  - `notes/param_comparison.qmd`: literature (Park) vs. KG, Didelot et
    al. and yersinia parameter values and priors
  - `notes/param_priors.qmd`: figures of all parameter values with the
    louseplague and yersinia prior densities (extends louseplague’s
    prior figure)
- `outputs/figs/`: rendered figures (`make`; `make tikz` for LaTeX
  versions). PDFs and `.tex` files are gitignored; PNGs are not.
- `papers/`: downloaded PDFs for full-text reading. This is
  **gitignored** because the repo is public; don’t commit PDFs.

## Bibliography

`plague_kg_comp.bib` is the project bibliography. Copy entries from
`~/projects/louseplague/doc/plague.bib` as they’re needed, keeping the
louseplague citation keys (e.g. `keeling2000bubonic`) so that keys stay
consistent between the two projects. New references (e.g. from extending
Park’s literature search) get added here directly.

See `TODO.md` for the work plan.

## References

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0">

<div id="ref-dean2018human" class="csl-entry">

Dean, Katharine R, Fabienne Krauer, Lars Walløe, Ole Christian
Lingjærde, Barbara Bramanti, Nils Chr Stenseth, and Boris V Schmid.
2018. “Human Ectoparasites and the Spread of Plague in Europe During the
Second Pandemic.” *Proceedings of the National Academy of Sciences* 115
(6): 1304–9. <https://doi.org/10.1073/pnas.1715640115>.

</div>

<div id="ref-didelot2017model" class="csl-entry">

Didelot, Xavier, Lilith K Whittles, and Ian Hall. 2017. “Model-Based
Analysis of an Outbreak of Bubonic Plague in Cairo in 1801.” *Journal of
The Royal Society Interface* 14 (131): 20170160.

</div>

<div id="ref-keeling2000bubonic" class="csl-entry">

Keeling, MJ, and CA Gilligan. 2000a. “Bubonic Plague: A Metapopulation
Model of a Zoonosis.” *Proceedings of the Royal Society of London B:
Biological Sciences* 267 (1458): 2219–30.

</div>

<div id="ref-keeling2000metapopulation" class="csl-entry">

———. 2000b. “Metapopulation Dynamics of Bubonic Plague.” *Nature* 407
(6806): 903–6. <https://doi.org/10.1038/35038073>.

</div>

</div>

# data/

Parameter values for plague models in one common long format, so that
values from different sources can be merged with tidyverse.

## Files

| File | Contents | Made by |
|---|---|---|
| `param_dict.csv` | parameter dictionary (see below) | by hand |
| `kg_params.csv` | Keeling & Gilligan (2000) parameters in their original notation and units: *Proc R Soc B* Table 1, plus the *Nature* Table 1 and Methods | by hand |
| `kg_a_lower_bounds.csv` | KG *Proc R Soc B* Table 2: lower bounds on flea searching efficiency $a$ from densities of wild rodents with plague outbreaks | by hand |
| `park_params.csv` | Daniel Park's literature compendium, with quantities as reported. This is the **canonical** version, edited by hand; it replaces `louseplague/data/parameter.R` | by hand |
| `didelot_params.csv` | Didelot et al. (2017), Cairo 1801: fixed values and posterior means with 95% CrIs. Same format as `park_params.csv` | by hand |
| `louseplague_priors.csv` | the priors used in louseplague (Park et al.; Gamma/Beta), by parameter | by hand, from louseplague `figure/prior_fig.R` |
| `lit_params.csv` | our own extractions from the literature (e.g. Bacot 1915). Same format as `park_params.csv` | by hand |
| `params_combined.csv` | KG, Park, Didelot and yersinia values (scenarios and default priors) in one table | `make data/params_combined.csv` (`R/params_merge.R`, `R/yersinia_params.R`) |

`R/kg_params.R` reads `kg_params.csv` and computes derived quantities:
$R_0$, the $aK_R$ threshold, the seasonal $K_F$ parameters, and a check
of the Table 2 bounds.

## Parameter dictionary (`param_dict.csv`)

There is one row per parameter, with these columns:

- `param`: ASCII id used to join tables (e.g. `inf_period_rat`)
- `label`: LaTeX label without `$` delimiters (e.g. `1/\gamma_r`). For
  plots, use `latex2exp::TeX(paste0("$", label, "$"))` or tikzDevice.
- `park_label`: Park's original plotmath label (e.g. `1/gamma[r]`),
  kept for reference
- `mode`, `description`, `units`: the canonical units. Durations are in
  days and rates are per day.
- `kg_symbol`, `kg_transform`: the KG symbol and an R expression in `x`
  that converts KG's value (rates per year) to the canonical units,
  e.g. `365/x`
- `yersinia_name`: the corresponding parameter in the yersinia package,
  if there is one
- `kg_comparable`: whether KG's parameter means the same thing as the
  literature values (`yes`, `partial` or `no`)
- `yersinia_transform`, `yersinia_comparable`: the same for yersinia
  parameters (e.g. `1/x` turns the rate `m_r` into an infectious
  period). Only parameters with a transform are included in the
  combined table.
- `notes`

## Literature values (`park_params.csv`)

There is one row per reported value. Each row stores the quantities *as
reported*, and derived intervals are computed in code
(`R/params_merge.R`). The columns are:

- `id`: unique row id (Park's object names, with `_1`, `_2`, …
  suffixes for multi-valued entries)
- `param`: parameter id (see `param_dict.csv`)
- `study`, `bibkey`: every key must be in `plague_kg_comp.bib`
- `host`, `vector`, `location`: context, where known
- `estimate`, `lwr`, `upr`, `sd`, `se`, `n`: in the canonical units of
  `param`. How to fill these depends on `type`:
  - `point estimate`: `estimate` (and `n` if known)
  - `range`: `lwr`, `upr` (and `estimate` if reported)
  - `CI`: `estimate`, `lwr`, `upr` as reported
  - `mean_sd`: `estimate`, `sd`, `n`. The 95% CI of the mean,
    estimate ± 1.96 sd/√n, is derived in code.
  - `mean_se`: `estimate`, `se`. The 95% CI, estimate ± 1.96 se, is
    derived in code.
  - `posterior`: posterior mean or median as `estimate`, with the
    reported credible interval as `lwr`, `upr`
  - `fixed`: a value assumed by a modelling study (not estimated)
  - `maximum`: the longest duration observed (e.g. the longest-surviving
    individuals in an experiment). This is a bound, not a mean.

    **To do: decide how to interpret `maximum` values when building
    priors.** Some options, taking Bacot (1915) as the example, with
    exponential survival with mean $m$:
    - **Treat the value as a fixed upper quantile**, e.g. the 0.95
      quantile: $m = x/\ln 20 \approx x/3$. For 47 days this gives
      $m \approx 16$ days.
    - **Treat it as the maximum of $n$ individuals.** The expected
      maximum is $m(\ln n + 0.577)$. With $n = 100$–$300$ fleas per
      cage, $x \approx 5.2$–$6.3\,m$, so 47 days gives
      $m \approx 7.5$–$9$ days. This depends on $n$ and on how many
      fleas actually carried infection (65–80% in Bacot's samples).
    - **Use a likelihood.** The maximum of $n$ exponentials has a known
      distribution (approximately Gumbel), so each cage can contribute
      a likelihood term instead of a point value. Cages that failed to
      infect after storage (8 of 11 in Bacot 1915) are
      censored/negative observations, and these carry information too.

    Uncertainty in these values is not reported. It comes from the
    small number of cages, the unknown number of infected survivors,
    and the fact that the outcome ("still infective") combines flea
    survival with retention of infection. Conditions also differ from
    the field: cool (about 8°C), humid, and a different flea species
    from *X. cheopis*. Any interpretation should carry this uncertainty
    into the prior, e.g. as a wide interval, rather than treating the
    converted value as exact.
- `orig_value`, `orig_units`: the reported value before conversion to
  the canonical units (e.g. survival in hours, or total counts before
  dividing by the number of hosts)
- `page`: page, table or figure in the source
- `notes`

## Combined table (`params_combined.csv`)

This is the union of the KG and literature values, generated by
`R/params_merge.R`. It has the columns above plus these:

- `label`: LaTeX label, from the dictionary
- `source_set`: `kg`, `park`, `didelot`, `lit` (our own extractions) or
  `yersinia`. yersinia rows
  have `type` `scenario` (scenario values) or `prior` (the prior median
  as `estimate`, with the central 95% interval as `lwr`/`upr`)
- `interval`: how `lwr`/`upr` arose: `range`, `CI (reported)`,
  `95% CI (derived)`, `95% CrI (reported)` or `prior 95% interval`
- `units`
- `basis`: KG's Table 1 status (`estimated` from lab/field data,
  `fundamental`, or `chosen` within realistic bounds)
- `orig_symbol`: KG's symbol (KG rows only)

`lwr`/`upr` always describe *uncertainty or variation among estimates*.
For example, the seasonal range of KG's $K_F$ (3.29–11.17) is recorded in
`notes`, not in `lwr`/`upr`.

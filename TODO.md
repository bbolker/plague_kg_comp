# TODO

## 1. Parameter comparisons and prior distributions

### 1a. Keeling–Gilligan parameters

- [ ] Remaining KG material to tabulate: the cellular automaton
      transition probabilities (Proc R Soc B Table 3) and the
      sensitivity results (Fig. 3).
- [ ] The annual mean of KG's seasonal K_F, computed from their stated
      range (3.29 to 11.17), is 6.64 rather than the stated 6.57.
      Probably a rounding issue in the range; check.
- [ ] Go back to the sources cited in the caption of Proc R Soc B
      Table 1 (the parameters marked * there) and recover uncertainty
      (ranges, CIs, sample sizes) for parameters that aren't yet in
      Park's compendium. Add the sources to the bib and the values to
      the tidy parameter table (1c).

  | Source (KG Table 1 ref.) | bibkey | Parameters | Access |
  |---|---|---|---|
  | 1. Buckle & Smith (eds) 1994 | `buckle1994rodent` | r_R, d_R | book (CAB International, not OUP as KG say) |
  | 2. Hirst 1938 | `hirst1938plague` | p, g_R, K_F | McMaster print only (below) |
  | 3. Wheeler & Douglas 1945 | `wheeler1945sylvatic` | β_R | doi:10.1093/infdis/77.1.1 |
  | 4. Macchiavello 1954 | `macchiavello1954reservoirs` | β_R | 12-part serial in *J. Trop. Med. Hyg.* 57: 3–298 (KG cite pp. 1–68) |
  | 5. Hinnebusch, Gage & Schwan 1998 | `hinnebusch1998estimation` | β_R | doi:10.4269/ajtmh.1998.58.562 |
  | 6. Bacot 1915 | `bacot1915observations` | d_F | free: <https://pmc.ncbi.nlm.nih.gov/articles/PMC2206740/> |

- [ ] **Digitize Chart 1 of Wheeler & Douglas (1945)** (`pix/wheeler1945_chart1.png`,
      full paper in `papers/`). The chart gives *per-individual* data for all
      46 infective fleas (32 *D. montanus*, 14 *X. cheopis*): the day of each
      transmission (filled square) and the day the flea died (X), on a
      1-day grid. That is the only individual-level source we have for the
      flea extrinsic incubation and infective periods, so it would give SDs
      and the shape of both distributions, not just the mean/min/max the
      text reports (see `notes/lit_summary.qmd`).
  - An automated attempt (deskew, axis calibration, per-cell fill fraction)
    failed to reproduce the paper's published summary statistics: it
    recovered a pre-infective max of 23 days against the stated 33. The
    sticking points are the row grid (the scan has ~0.6 degrees of skew and the
    printed flea-number labels sit a variable distance from their data
    rows) and adjacent square+X marks merging into one blob.
  - **Reading it by eye is probably faster than fixing the automation.**
    Record one row per flea as (species, flea number, transmission days,
    death day) in a new `data/wheeler1945_chart1.csv`.
  - Validate any extraction against the four published statistics per
    species: *X. cheopis* pre-infective mean 16 (6-33), infective period
    mean 4 (1-18); *D. montanus* pre-infective mean 10 (3-27), infective
    period mean 5 (1-51).

  Hirst (1938): no free online copy found as of 2026-11-07. The
  encyclopaedia (ed. Rolleston, Butterworth) is partly scanned on
  archive.org (Digital Library of India), but vol. IX, which
  covers "Plague", wasn't among the volumes identified.
  **McMaster has it in print:** *British Encyclopaedia of Medical
  Practice* (1936–39, 12 v.), Health Sciences Library, History of
  Health & Medicine Room (lower level), call no. **WB 13 .B862
  1936**. The Omni record notes "Gift: Ms. C. Reimann (v. 9)", so
  vol. 9 is held. It isn't digitised and the room may be for
  consultation only, so plan to scan pp. 675–698 on site and put
  the scan in `papers/`.
  Hirst's book *The Conquest of Plague* (Oxford: Clarendon, 1953)
  may give the same data on rat resistance and flea indices.
  McMaster doesn't hold it, but other libraries in the Omni
  network do (two records), so request it through Omni. Also, the KG value
  of p (inherited resistance) is cited to Hirst, contrary to the
  yersinia documentation, which says p has "no empirical basis".

### 1b. yersinia parameter sets

- [ ] Fix in yersinia (`add_kg` branch, then upstream):
  - `prior_default()` for r_r, d_r, r_h and d_h is Uniform(1e-4, 0.1)
    per day. That puts almost all its mass 1–2 orders of magnitude
    above every scenario value.
  - The `keeling-gilligan` scenario's carcass parameters (rho = 10,
    beta_r = 0.086, beta_h = 2.7e-5) are all outside
    `plague_fit_prior()`.
  - Rat infectious periods of 17–25 days in the `didelot`,
    `keeling-gilligan`, `historical` and `modern-estimates` scenarios
    all trace back to KG's *chosen* m_R = 20/yr, via Didelot. The
    literature gives 2–11 days. Only `defaults` (5 days) is consistent.
- [ ] Didelot et al. (2017) also has posterior correlations (their
      Fig. 4) and the p0 estimate. Add them if needed for priors.
- [ ] Find the provenance of the `historical` and `modern-estimates`
      values. Their YAML files give no specific sources.
- [ ] Check the KG → carcass mapping in `keeling-gilligan.yaml`
      (ρ = a·K_R, δ_R = d_F, β_r = β_R·K_F/(1−g_r)), which matches R0.
      Do the dynamics also match, e.g. timescales and equilibria? This
      ties in with model comparison (d).

### 1c. Park's review of parameter values

- [ ] Fill in `page` (and check `host`/`vector`/`location`) as the
      sources are read. Resolve Park's open questions:
  - whether Tollenaere et al. report SE or SD;
  - Guernier et al.'s flea index ("appear to be wrong??");
  - Davis & Fales: Park divided rat counts by 10^6 humans; check the
    actual human population;
  - the meaning of Park's 'i5, i6, 17' comment on Tollenaere's
    recovery probabilities.
- [ ] The overlap between KG and Park shows large disagreements (see
      `notes/param_comparison.qmd`):
  - free-flea survival: KG 36.5 days (citing Bacot 1915) vs. 1–6 days
    (Bacot & Martin 1924). Didelot et al. also call KG's value
    unrealistic and estimate 3.7 [1.2, 8.6] days for the carcass
    infectious period;
  - rat infectious period: KG 18.25 days (a *chosen* value, later
    adopted by Didelot et al. and yersinia) vs. 2–11 days;
  - rat recovery probability: KG 0.02 vs. 0.09–0.17.

  Bacot (1915), KG's source for d_F, reports only the *maximum*
  persistence of infectivity: 3 of 11 cages of *C. fasciatus* were still
  infective after 29–47 days without a host in cool, humid storage
  (`data/lit_params.csv`). KG's 36.5 days treats that maximum as a mean.
  Still open: the sources for KG's rat infectious period and rat
  recovery probability (m_R is "chosen"; g_R is cited to Hirst 1938).
- [ ] Consider tracking down the earlier work that Bacot (1915) cites in
      his first paragraph, and adding its values to
      `data/lit_params.csv` (and the references to the bib). All three
      are free in PubMed Central:
  - Verjbitzki (1904), "The part played by insects in the epidemiology
    of plague", MD thesis, St Petersburg. Bacot cites it as 1904; it was
    republished in *J. Hyg.* 8: 162–208 (1908; spelled "Verjbitski"
    there,
    [PMC2167148](https://pmc.ncbi.nlm.nih.gov/articles/PMC2167148/)).
    Fleas carried the bacilli and re-infected for up to 3 days;
  - Indian Plague Commission (1906), "Experiments upon the transmission
    of plague by fleas. Part II. Transference from rat to rat", *J.
    Hyg.* 6: 435–449
    ([PMC2236158](https://pmc.ncbi.nlm.nih.gov/articles/PMC2236158/)):
    infection by fleas up to 21 days after their last chance to feed
    on infected blood. The other papers in that issue (*J. Hyg.* 6(4))
    may also be useful. They include the immunity of Bombay rats
    (relevant to p and g_R) and chronic plague in rats. This volume
    may also be the source of KG's garbled "J. Hyg. 6" citation for
    Bacot;
  - Bacot & Martin (1914), "Observations on the mechanism of the
    transmission of plague by fleas", *J. Hyg.* 13 (Plague Suppl. III):
    423–439
    ([PMC2167459](https://pmc.ncbi.nlm.nih.gov/articles/PMC2167459/)):
    infected fleas that were fed regularly lived up to 50 days at
    10–15°C and 23 days at 27°C, and stayed infected.

  These are mostly persistence of infectivity, in fed and unfed fleas,
  rather than mean survival, so they need the same care as Bacot 1915
  (`maximum` type). They may also inform the flea incubation and
  infectious periods.
- [ ] Reproduce the louseplague priors (now in
      `data/louseplague_priors.csv` and plotted in
      `notes/param_priors.qmd`) with the method in `doc/plague.Rnw`:
  - fit independent Gamma/Beta priors whose high-density region covers
    most of the reported values;
  - convert SE/SD to approximate normal CIs;
  - for parameters with only one reported value, choose a prior
    spanning a biologically plausible range;
  - relax Dean et al.'s transmission-rate priors to Gamma with the
    same mean and shape = 2;
  - document every value that is excluded as implausible.
- [ ] Consider making this more formal: treat each report (point,
      range or CI) as interval-censored or measurement-error data and
      fit a distribution by ML or a hierarchical model, rather than
      matching quantiles by eye.
- [ ] (later) Check and extend Park's extraction with a fresh
      literature search, adding new sources to the bib.
- [ ] Find empirical sources for the parameters that are poorly
      supported. Their louseplague priors rest only on model
      assumptions or on a single study, so the prior width is Park's
      judgement. Start with these:
  - **No empirical value, only model choices:**
    - flea reproductive rate r_f: the only value is KG's r_F = 20/yr,
      which KG "chose within biologically realistic bounds" (no
      source in Table 1). Park's prior is centred on it. Look at
      *X. cheopis* life-table studies (development time, fecundity,
      temperature dependence);
    - flea-to-rat transmission β_r: Dean et al.'s assumed range (0–1)
      plus KG's β_R = 4.7/yr. KG mark β_R as estimated from Wheeler &
      Douglas (1945), Macchiavello (1954) and Hinnebusch et al.
      (1998); check what those actually measure;
    - flea searching efficiency s_f: Dean et al.'s assumed value 3,
      plus KG's a = 0.004/rat on a different scale (left out of the
      figure). See KG Proc R Soc B §6 for the bounds on a;
    - transmission rates set only by Dean et al.'s assumed ranges:
      flea-to-human β_b (KG's β_H isn't comparable), louse-to-human
      β_l and human-to-louse β_h; pneumonic β_p also has a Didelot et
      al. posterior.
  - **One empirical study:** louse growth rate r_l (Evans & Smith
    1952) and louse infectious period 1/γ_l (Houhamdi et al. 2006).
  - **Two old or indirect studies:** rat-to-human ratio (Boelter 1909;
    Davis & Fales 1949) and rat recovery probability g_r (Tollenaere
    et al. 2010, plus KG's g_R = 0.02, from Hirst 1938).

### 1d. Parameter/prior figures (`R/prior_fig.R`)

- [ ] (later) Graphics tweaks for `outputs/figs/param_priors_*`:
  - HTML version with **ggiraph**, with hover text giving the full
    reference for each point or interval (study, bibkey, notes), e.g.
    in `notes/param_priors.qmd`. Add ggiraph to `get_pkgs.R`.
  - For the other formats (PDF, PNG, tikz), shorten the row labels to
    abbreviated references: the first 4 letters of the first author's
    surname, plus the first 4 letters of the second author's surname
    if there are exactly two authors, or `+` if there are three or
    more; then the year. Examples: `Baco1915`, `KeelGill2000`,
    `Toll+2010`. Generate these from the bib entries (via `bibkey`),
    not by hand. Decide how to handle corporate authors (e.g. the
    Indian Plague Commission) and the "yersinia scenarios" row.
  - Consider alternatives to the current vertical dodging of several
    values within one row (`position_dodge`, which looks like
    jittering, e.g. Tollenaere et al.'s four CIs or the yersinia
    scenarios):
    - one sub-row per value, labelled (e.g. `Toll+2010a`, or by
      scenario name or experimental condition);
    - deterministic offsets ordered by value (no random component);
    - a beeswarm layout (ggbeeswarm) for many point values;
    - for yersinia, small labelled ticks or scenario-specific shapes
      instead of five identical crosses.

## 2. Comparing model types

### Models

- [ ] (0) Original KG model (rats S/I/R, flea index N, free infectious
      fleas F, humans), deterministic and stochastic versions.
- [ ] (a) The closest simple compartmental model, with the flea
      compartment collapsed out entirely (e.g. a quasi-steady-state or
      timescale-separation reduction).
- [ ] (b) KG with perfectly efficient flea search (a → ∞, so that
      1 − exp(−a T_r) → 1).
- [ ] (c) SIR models with incidence functions that match KG's (or
      don't): frequency- vs. density-dependent, saturating.
- [ ] (d) The carcass-transmission model of Didelot et al. (2017), as
      implemented in yersinia.
- [ ] Add a 'true' KG model variant (explicit flea index N and free
      infectious fleas F, rather than the carcass mapping in
      `keeling-gilligan.yaml`) to yersinia, as an odin2 model alongside
      `inst/odin/plague_stochastic_humans.R`, on the `add_kg` branch
      of `bbolker/yersinia` (which `get_pkgs.R` installs). Include
      single-patch and metapop versions, and a scenario file with the
      original KG flea parameters. Consider a PR upstream once it's stable.
- [ ] In the `add_kg` model, add a switch for where rat density
      dependence acts. The full analysis so far is in
      `notes/density_dependence.qmd`, with code in `R/waning.R`.
  - KG as written: births at r_R, and density-dependent mortality
    r_R T_R/K_R on S_R and R_R (but not I_R). Resistance wanes at the
    constant rate r_R(1−p).
  - Recruitment version (current yersinia stochastic model): births at
    r_R(1−T_R/K_R). Resistance wanes at r_R(1−p)(1−T_R/K_R): close to
    r_R(1−p) while the population regrows after a crash, but only
    d_R(1−p) near K_R.
  - Disease-free result: f = R/(S+R) satisfies f′ = −(1−p) b(t) f,
    where b is the per-capita birth rate. Under the recruitment
    version, regrowth from T_0 to T_end gives f_end/f_0 =
    (T_0/T_end)^(1−p) e^(−(1−p) d τ). That dilution is small for
    p = 0.975 but large for p = 0.5 (which the yersinia metapop
    vignette uses).
  - Compare the two versions over complete epidemic → crash → recovery
    → inter-epidemic cycles, with disease (selective removal of S,
    survivors g_R joining R), across a range of p. Look at the
    resistant fraction at the start of the next epidemic, the
    inter-epidemic interval, and the consequences for persistence.
  - Also handle iota (fitness cost of resistance) in yersinia, which KG
    don't have (KG equivalent: iota = 1).
- [ ] Fix the deterministic KG reference vignette in yersinia
      (`vignettes/reference-deterministic-models.Rmd`, lines ~160, 324,
      438): the flea-index equation omits d_F. KG have
      `d_F * F * (1 - exp(-a*T_r)) / T_r`; the vignette has
      `F * (1 - exp(-a*T_r)) / T_r`, which isn't even dimensionally a
      rate. Also document that the S/R equations put density
      dependence on mortality, and that this differs from the
      stochastic model.
- [ ] Correct the yersinia documentation of p (`inst/explainer/build.R`
      ~l. 371–382). It says values near 1 "prevent the resistance trait
      from washing out" and that p has no empirical basis. In KG, 1−p is
      what *sets* the rate at which resistance washes out, and p is
      cited to Hirst (1938).
- [ ] Implement all of these in one framework (deSolve or odin2
      deterministic first, then stochastic) with a shared parameter
      interface.

### Model comparison settings

- [ ] **Match models on fundamental quantities**, not on raw parameter
      values: $R_0$, the intrinsic rate of increase $r$, and the mean and
      coefficient of variation of the generation interval. These are what
      make different model structures comparable.
  - Derive them analytically where possible.
  - Where they aren't analytically derivable (or available in the
    literature), compute them numerically: start the model with one
    infected individual, switch off the effect of new infections on the
    rest of the system, and integrate the number of infections generated.
    That gives $R_0$ and the generation-interval distribution directly.
  - The [`macpan2`](https://canmod.github.io/macpan2/) repository may have
    machinery illustrating these computations; check it before writing our
    own.

### Single-patch dynamics

- [ ] Derive R0 for each model; check how parameters map between models
      when R0 is matched. So far we have KG's R0 (3.09, in
      `R/kg_params.R`) and Didelot et al.'s R0 (2.85 [1.82, 3.95], in
      `data/didelot_params.csv`).
- [ ] Compare epidemic curves: peak timing, peak size, final size, rat
      and human mortality.
- [ ] Compare endemic equilibria and their stability (damped
      oscillations, periods), and rat population crash and recovery.
- [ ] Compare stochastic fade-out (probability of extinction after the
      first epidemic, critical community size).

### Metapopulation persistence

- [ ] Reproduce the main persistence results of KG (*Nature* 2000)
      with the original model.
- [ ] **Identify the most qualitatively important parameter for
      metapopulation persistence** with a sensitivity analysis.
      Candidates include inherited resistance p and where density
      dependence acts (see the switch above), flea search efficiency
      a, rat and flea movement rates, carrying capacities K_r and K_f,
      and number of patches.
- [ ] Compare persistence (e.g. time to global extinction, fraction of
      runs that persist) across model types along that parameter axis.
- [ ] Look at how the yersinia metapop model (`plague_stochastic_metapop`)
      couples patches and whether that coupling is comparable to KG's.

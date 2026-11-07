# TODO

## Setup / bibliography

- [ ] Add references to `plague_kg_comp.bib` from
      `~/projects/louseplague/doc/plague.bib` as they're needed,
      especially the sources behind Park's parameter table (Table
      `tab:param` in `doc/plague.Rnw`).
- [ ] The `keeling-gilligan.yaml` scenario in yersinia cites KG
      *Nature* 2000 (`keeling2000metapopulation`), but its R0 equation
      ("p. 2226") comes from KG *Proc R Soc B* 2000
      (`keeling2000bubonic`). Work out which parameters come from which
      paper, and fix the citation upstream if appropriate.

## 1. Parameter comparisons and prior distributions

### 1a. Keeling–Gilligan parameters

- [ ] Tabulate the parameters of both KG 2000 papers, with units, and
      convert everything to per-day rates.
- [ ] Note which values are measured, which are assumed and which are
      tuned (e.g. Park et al. rejected KG's rat infectious period as
      implausible).
- [ ] Go back to the sources cited in the caption of Proc R Soc B
      Table 1 (the parameters marked * there) and recover uncertainty
      (ranges, CIs, sample sizes) for parameters that aren't yet in
      Park's compendium. Add the sources to the bib and the values to
      the tidy parameter table (1c).

      | Source (KG Table 1 ref.) | Parameters |
      |---|---|
      | 1. Buckle & Smith (eds) 1994, *Rodent Pests and Their Control* (Oxford UP) | r_R, d_R |
      | 2. Hirst 1938, "Plague", *Brit. Encyc. Med. Prac.* 9:675–698 | p, g_R, K_F |
      | 3. Wheeler & Douglas 1945, *J. Infect. Dis.* 77:1–12 | β_R |
      | 4. Macchiavello 1954, *J. Trop. Med. Hyg.* 57:1–68 | β_R |
      | 5. Hinnebusch, Gage & Schwan 1998, *Am. J. Trop. Med. Hyg.* | β_R |
      | 6. Bacot 1915, *J. Hyg.* (Plague Suppl.) | d_F |

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

- [ ] Tabulate the `historical`, `keeling-gilligan`, `didelot`,
      `modern-estimates` and `defaults` scenarios (`inst/scenarios/`)
      side by side, along with `prior_default()` from `R/app_priors.R`.
- [ ] Find the provenance of the `historical` and `modern-estimates`
      values. Their YAML files give no specific sources.
- [ ] Check the KG → carcass mapping in `keeling-gilligan.yaml`
      (ρ = a·K_R, δ_R = d_F, β_r = β_R·K_F/(1−g_r)), which matches R0.
      Do the dynamics also match, e.g. timescales and equilibria? This
      ties in with model comparison (d).

### 1c. Park's review of parameter values

- [ ] Import `data/parameter.R` and `data/param_tab.R` from louseplague
      into a tidy table (study, parameter, estimate, lwr, upr, type).
- [ ] Reproduce the louseplague priors with the method in
      `doc/plague.Rnw`:
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
- [ ] Map parameter names and definitions across KG, yersinia and
      louseplague (e.g. rate vs. mean duration, per-rat flea index vs.
      total, carcass vs. free-flea pools).
- [ ] (later) Check and extend Park's extraction with a fresh
      literature search, adding new sources to the bib.

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
      dependence acts.
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

### Single-patch dynamics

- [ ] Derive R0 for each model; check how parameters map between models
      when R0 is matched.
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

## Build targets for plague_kg_comp

.PHONY: all clean tikz

FIGS = $(foreach g,lit model,$(foreach e,pdf png,outputs/figs/param_priors_$(g).$(e)))
FIG_DEPS = R/prior_fig.R R/prior_densities.R R/yersinia_params.R data/params_combined.csv data/param_dict.csv data/louseplague_priors.csv

all: README.md data/params_combined.csv $(FIGS)

## README.md is generated: edit README.qmd, not README.md
README.md: README.qmd plague_kg_comp.bib
	quarto render README.qmd --to gfm

## KG, Park, Didelot, our own and yersinia values in one long table
data/params_combined.csv: R/params_merge.R R/yersinia_params.R data/kg_params.csv data/param_dict.csv data/park_params.csv data/didelot_params.csv data/lit_params.csv
	Rscript R/params_merge.R

## parameter values + prior densities (literature and model-only parameters)
$(FIGS) &: $(FIG_DEPS)
	Rscript R/prior_fig.R

## tikz versions of the same figures (outputs/figs/*.tex)
tikz: $(FIG_DEPS)
	Rscript R/prior_fig.R --tikz

clean:
	rm -f README.html

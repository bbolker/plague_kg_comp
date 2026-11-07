## Build targets for plague_kg_comp

.PHONY: all clean

all: README.md data/params_combined.csv

## README.md is generated: edit README.qmd, not README.md
README.md: README.qmd plague_kg_comp.bib
	quarto render README.qmd --to gfm

## KG + Park values in one long table
data/params_combined.csv: R/params_merge.R data/kg_params.csv data/param_dict.csv data/park_params.csv
	Rscript R/params_merge.R

clean:
	rm -f README.html

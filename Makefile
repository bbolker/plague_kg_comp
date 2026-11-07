## Build targets for plague_kg_comp

.PHONY: all clean

all: README.md

## README.md is generated: edit README.qmd, not README.md
README.md: README.qmd plague_kg_comp.bib
	quarto render README.qmd --to gfm

clean:
	rm -f README.html

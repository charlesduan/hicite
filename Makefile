export TEXINPUTS := ./support:./helpers:
main: hicite.pdf

hicite.pdf: hicite.tex
	xelatex "$<"
	xelatex "$<"

test.pdf: test.tex
	xelatex "$<"

hicite.tds.zip: hicite.sty
	mkdir -p tex/latex/hicite
	cp hicite.sty support/* tex/latex/hicite
	zip -r hicite.tds.zip tex
	rm -rf tex

hicite.tex: hicite.ins FORCE
	latex hicite.ins

hicite.sty: hicite.ins FORCE
	latex hicite.ins

test.tex: hicite.ins FORCE
	latex hicite.ins

doc/%.pdf: src/%.dtx helpers/driver.tex helpers/hidoc.sty helpers/docparams.tex
	xelatex -output-directory=doc "$<"

doc: doc/*.pdf

FORCE:


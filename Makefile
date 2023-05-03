export TEXINPUTS := ./gen:./support:./helpers:

main: manual/hicite.pdf

dist: hicite.tds.zip

test: test/test.pdf

package: gen/hicite.sty

manual/hicite.pdf: manual/hicite.tex
	xelatex --output-directory=manual manual/hicite
	makeindex -s gind.ist manual/hicite
	xelatex --output-directory=manual manual/hicite

test/test.pdf: test/test.tex
	xelatex --output-directory=test test/test

hicite.tds.zip: gen/hicite.sty
	mkdir -p tex/latex/hicite
	cp gen/* support/* tex/latex/hicite
	zip -r hicite.tds.zip tex
	rm -rf tex

manual/hicite.tex: hicite.ins FORCE
	latex hicite.ins

gen/hicite.sty: hicite.ins FORCE
	latex hicite.ins

test/test.tex: hicite.ins FORCE
	latex hicite.ins

doc/%.pdf: src/%.dtx helpers/driver.tex helpers/hidoc.sty helpers/docparams.tex
	xelatex -output-directory=doc "$<"

doc: doc/*.pdf

FORCE:

clean:
	rm -f {.,doc,gen,test,manual}/*.{aux,glo,hd,idx,log,out,toc,ilg,ind}

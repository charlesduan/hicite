export TEXINPUTS := ./tex//:./helpers:

ifeq (, $(shell which xelatex-dev))
    XELATEX := xelatex
else
    XELATEX := xelatex-dev
endif

#
# Generating documentation
#
manual: manual/hicite-manual.pdf

manual/hicite-manual.tex: hicite.sty hicite.ins dirs FORCE
	latex '\let\MakeManual\relax \input hicite.ins'

manual/hicite-manual.pdf: manual/hicite-manual.tex
	$(XELATEX) --output-directory=manual manual/hicite-manual
	makeindex -s gind.ist manual/hicite-manual
	$(XELATEX) --output-directory=manual manual/hicite-manual


#
# Documentation for individual modules
#

doc/%.pdf: src/%.dtx dirs $(doc_helpers)
	$(XELATEX) -output-directory=doc "$<"

doc: $(patsubst src/%.dtx,doc/%.pdf,$(wildcard src/*.dtx))

doc_helpers = helpers/driver.tex helpers/hidoc.sty helpers/docparams.tex



#
# Generating the package code
#

package: hicite.sty

hicite.sty: hicite.ins dirs FORCE
	latex hicite.ins


#
# Running tests
#

test: test/test.pdf

test/test.pdf: package test/test.tex
	$(XELATEX) --output-directory=test test/test

test/test.tex: hicite.ins dirs FORCE
	latex '\let\MakeTests\relax \input hicite.ins'


#
# Making distributions
#

ctan: hicite-ctan.tgz

hicite-ctan.tgz: clean package
	cd .. ; \
	tar czvf hicite/hicite-ctan.tgz \
		--exclude '*.log' \
		--exclude 'test' --exclude 'doc' \
		--exclude 'manual/*.tex' \
		--exclude tables \
		--exclude '*.tgz' \
		--exclude '*.zip' \
		--exclude 'hicite/hi*.sty' \
		--exclude 'TODO.md' \
		--exclude '.git*' --exclude '*.sw[op]' \
		hicite

dist: hicite.tds.zip

hicite.tds.zip: hicite.sty
	mkdir hicite.tds ; \
	mkdir -p hicite.tds/tex/latex/hicite ; \
	cp tex/* *.sty hicite.tds/tex/latex/hicite ; \
	cd hicite.tds ; \
	zip -r ../hicite.tds.zip * ; \
	cd .. ; \
	rm -rf hicite.tds


#
# Utilities and cleanup
#

all: manual test dist ctan

dirs:
	test -d doc || mkdir doc
	test -d test || mkdir test
	test -d manual || mkdir manual

FORCE:

clean:
	rm -f {.,doc,gen,test,manual}/*.{aux,glo,hd,idx,log,out,toc,ilg,ind}

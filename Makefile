export TEXINPUTS := ./gen:./support:./helpers:

ifeq (, $(shell which xelatex-dev))
    XELATEX := xelatex
else
    XELATEX := xelatex-dev
endif

ctan: dist
	( ls | grep -v 'gen|test|manual|doc' ; echo 'manual/hicite.pdf' ) \
		| xargs tar czvf ctan.tgz

main: manual/hicite.pdf

dist: hicite.tds.zip

test: test/test.pdf

package: gen/hicite.sty

manual/hicite.pdf: manual/hicite.tex
	$(XELATEX) --output-directory=manual manual/hicite
	makeindex -s gind.ist manual/hicite
	$(XELATEX) --output-directory=manual manual/hicite

test/test.pdf: test/test.tex
	$(XELATEX) --output-directory=test test/test

hicite.tds.zip: gen/hicite.sty
	mkdir -p tex/latex/hicite
	cp gen/* support/* tex/latex/hicite
	zip -r hicite.tds.zip tex
	rm -rf tex

manual/hicite.tex: hicite.ins dirs FORCE
	latex hicite.ins

gen/hicite.sty: hicite.ins dirs FORCE
	latex hicite.ins

test/test.tex: hicite.ins dirs FORCE
	latex hicite.ins

dirs:
	test -d doc || mkdir doc
	test -d test || mkdir test
	test -d gen || mkdir gen
	test -d manual || mkdir manual

doc_helpers = helpers/driver.tex helpers/hidoc.sty helpers/docparams.tex

doc/%.pdf: src/%.dtx dirs $(doc_helpers)
	$(XELATEX) -output-directory=doc "$<"

doc: $(patsubst src/%.dtx,doc/%.pdf,$(wildcard src/*.dtx))

FORCE:

clean:
	rm -f {.,doc,gen,test,manual}/*.{aux,glo,hd,idx,log,out,toc,ilg,ind}

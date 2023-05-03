# *Hereinafter*: A Legal Citation Program

This repository provides source code and literate programming documentation for
*Hereinafter*, a LaTeX package for legal citations. It is designed to produce
the following outputs:

1. A distribution of the package, contained in `hicite.tds.zip`, along with
   individual `.sty` package files
2. A single-file user manual, `hicite.pdf`
3. Individual documentation files for each of the source code modules, in the
   `doc` subdirectory
4. A test suite




## Repository Contents

The following is an outline of the contents of this repository:

- Source code:
  - `hicite.ins`: The installation file
  - `src`: Source code files for the modules of the program
  - `support`: Supporting files such as tables which should be included with an
    installation
  - `helpers`: A directory of LaTeX package files used for compiling the
    documentation and testing the package

- Generated files:
  - `gen`: Generated package files which should be included with an installation
  - `test`: The unit test output
  - `manual`: The compiled user manual




## Installation and Usage

The file `hicite.tds.zip` contains all of the files necessary for installation.
It can be generated with the command `make dist`. To install, unzip the contents
of that file into your local `texmf` directory.

Alternately, you can install the contents of the `gen` and `support` directories
into an appropriate place in your filesystem.




## Generating Files

This section explains how to generate package and other files within this
repository. (It should not be necessary to do so, since the files have already
been generated and are saved in the repository.) Package files are produced
using `latex`, and readable documentation with `xelatex`. These are run through
`make` commands as described below.

### Package Files

To make the `hicite.sty` package file and auxiliary package files, run `make
package`. This will compile the `hicite.ins` file to produce the package files
in to the `gen` directory.

Additional files required for the distribution are in the folder `support`. To
produce a complete distribution, run `make dist`, which will combine all the
necessary files for a distribution into a correctly formed TeX directory tree.


### User Manual

The user manual is generated by calling `make` with no arguments. This first
compiles `hicite.ins` which (besides making the package files) constructs the
`.tex` file for the manual. It then compiles that generated file into a PDF
document.

Compiling the manual and other documentation requires the fonts Libertinus
Serif, Source Sans 3, and Source Code Pro. These are all freely available.

### Module Documentation

In addition to the user manual, each source code module (in the `src` directory)
can be individually compiled into its own documentation. The module
documentation files contain more implementation details in a literate
programming style.

To compile the documentation for a particular module file `src/[module].dtx`,
run `make doc/[module].pdf`. Alternately, run `make doc` to regenerate all of
the module documentation.


### Tests

The tests are run by calling `make test`. This produces a file `test/test.tex`
which, when compiled, checks the operation of the package. Upon compilation, the
resulting document can be reviewed to ensure that all of the test outputs match
expectations. The compilation process attempts to perform as many checks as
possible automatically, but in some cases the best it can do is ensure that the
package's output is the same physical length as the expected result. The latter
types of tests are marked as ``Probably passed.''



## Implementing the Documentation

To keep track of all of the documentation for this package, a somewhat complex
scheme of literate programming is used in the source code. This section explains
that scheme.


### Background: Doc and Docstrip

This documentation uses the LaTeX *doc* and *docstrip* utilities for separating
the documentation from code. Relevant information on those programs may be found
here:

- [Doc](http://mirrors.ctan.org/macros/latex/base/doc.pdf)
- [Ltxdoc class](https://mirrors.ctan.org/macros/latex/base/ltxdoc.pdf)
- [Docstrip](https://mirrors.ctan.org/tex-archive/macros/latex/base/docstrip.pdf)
- [Tutorial](https://tug.org/TUGboat/tb29-2/tb92pakin.pdf) on writing package
  files

Briefly, the *doc* tool compiles `.dtx` files as LaTeX documents, ignoring
leading comment markers. The *docstrip* tool removes commented lines, and
furthermore permits conditional output: Code between flags like `%<*flag>` and
`%</flag>` will be ignored by *docstrip* unless the tool is told to keep
`flag` code. *Docstrip* calls these flags "guards," and this package uses guards
extensively.


### Source Code File Structure

Files use the `doc` and `docstrip` tools for compilation, and follow the
conventions laid out for those programs. They further follow several
conventions particular to this documentation.

First, two guards are used: `doc` and `package`. Any content meant for the user
documentation should be bracketed with `doc`, and any source code and
implementation comments are surrounded by `package`. Thus, instructions of
general use to package users should go into `doc` sections, while explanations
of internal implementation details should be comments in `package` sections.

Second, a common preamble is included in all module files:
```tex
%%
%% \iffalse filename: [module].dtx \fi
%%
%<*doc>
\input driver
\thisis{[module]}{[Section Heading for Module]}
```
The meta-comment is just helpful for identifying different files. More important
are the last three lines. The file `driver.tex` will define the `\thisis`
command to produce either a section heading when the file is compiled as part of
user manual, and a document title when compiled as a standalone
documentaiton file. Since these lines are within a `%<*doc>` guard, they will be
ignored for producing the package code file.


### Additional Files

In addition to the module `.dtx` files, there are a few other files to note:

- `intro.dtx`: Introductory text for the user manual and the package code
- `conclusion.dtx`: Conclusory text
- `parts.dtx`: Headings for the parts of the user manual
- `helpers/hidoc.sty`: Style definitions for the documentation



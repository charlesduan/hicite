# *Hereinafter*: A Legal Citation Program

This repository provides literate programming documentation for *Hereinafter*, a
LaTeX package for legal citations. It is designed to produce the following
outputs:

1. A distribution of the package, contained in `hicite.tds.zip`
2. A single-file user manual, `hicite.pdf`
3. Individual documentation files for each of the source code modules, in the
   `doc` subdirectory
4. A test suite

The inputs for all three are the `.dtx` files for each of the modules of the
package. This readme describes the structure of each module and the process for
compiling them into each of the outputs.

## Distribution Contents

The following is an outline of the contents of this distribution:

- Source code:
  - `hicite.ins`: The installation file
  - `helpers`: A directory of LaTeX package files used for compiling the
    documentation and testing the package
  - `src`: The package module files with documentation source code
  - `support`: Supporting files such as tables which should be included with an
    installation

- Generated files:
  - `gen`: Generated package files which should be included with an installation
  - `test`: The unit test output
  - `manual`: The compiled user manual

## Installing

The file `hicite.tds.zip` contains all of the files necessary for installation.
It can be generated with the command `make dist`. To install, unzip the contents
of that file into your local `texmf` directory.

## Doc and Docstrip

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


## Source Code File Structure

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

In addition to the module `.dtx` files, there are a few other files to note:

- `intro.dtx`: Introductory text for the user manual and the package code
- `conclusion.dtx`: Conclusory text
- `parts.dtx`: Headings for the parts of the user manual
- `helpers/hidoc.sty`: Style definitions for the documentation

## Producing Module Documentation

To produce documentation for an individual module, run `make doc/[module].pdf`.
This will compile the corresponding file `src/[module].dtx`, including both the
`doc` and `package` sections, thereby producing a
document with commented source code in addition to the user manual text.

## Producing the User Manual and Package Source

To make the user manual, run `make` with no arguments. To make the `hicite.sty`
package file, run `make package`.

Both of these commands will start by compiling the `hicite.ins` file, which
generates the manual source code, the package files, and several auxiliary
files. With no arguments, `make` will further compile the manual source code
into a PDF document.

The manual is made by stripping out only the `doc` sections of all of the module
source code files and combining them into a single document. The package files,
by contrast, consiste of only the `package` sections with comments stripped.

Additional files required for the distribution are in the folder `support`. To
produce a complete distribution, run `make dist`, which will combine all the
necessary files for a distribution into a correctly formed TeX directory tree.

## Running Tests

The tests are run by calling `make test`. This produces a file `test/test.tex`
which, when compiled, checks the operation of the package. Upon compilation, the
resulting document can be reviewed to ensure that all of the test outputs match
expectations. The compilation process attempts to perform as many checks as
possible automatically, but in some cases the best it can do is ensure that the
package's output is the same physical length as the expected result. The latter
types of tests are marked as ``Probably passed.''



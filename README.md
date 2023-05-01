# *Hereinafter*: A Legal Citation Program

This repository provides literate programming documentation for *Hereinafter*, a
LaTeX package for legal citations. It is designed to produce three outputs:

1. A distribution of the package, contained in `hicite.tgz`
2. A single-file user manual, `hicite.pdf`
3. Individual documentation files for each of the source code modules

The inputs for all three are the `.dtx` files for each of the modules of the
package. This readme describes the structure of each module and the process for
compiling them into each of the outputs.

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


## Input File Structure

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

To produce documentation for an individual module, run `latex [module].dtx`.
This will compile code in both the `doc` and `package` sections, producing a
document with commented source code in addition to the user manual text.

## Producing the User Manual and Package Source

The included `.ins` file will produce both the user manual (as a `.tex` file to
be compiled) and the `.sty` file for the package. It does so by running
*docstrip* to extract `doc` guard blocks for the manual and `package` guard
blocks for the package.

Additional files required for the distribution are in the folder `support`. To
produce a complete distribution, run `make dist`.

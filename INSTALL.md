# Installation, Compilation, and Testing


## Quick Start

The [Github repository](https://github.com/charlesduan/hicite) for *Hereinafter*
includes a file `hicite.tds.zip`, which contains all of the files necessary for
installation. Where it is not present, it may be generated with the command
`make dist`. To install, unzip the contents of that file into your local `texmf`
directory.

Alternatively, the package may be installed manually. The files necessary for
installation of the package are:

* The `.sty` files in the top-level directory
* The files in the `tex/` directory

These may be placed in any TeX-appropriate location.



## Generating from Source

The underlying documented source code for the package is the set of `.dtx` files
in the `src/` directory. These files are combined using the installation script
`hicite.ins`, which when compiled generates:

* The main package file, `hicite.sty`
* Several auxiliary packages: `histrings.sty`, `hiabbrev.sty`, `hisort.sty`, and
  `hibib.sty` (these are described in the Supporting Packages section of the
  manual)

As a convenience, `make package` will generate these files.

In addition to the package files, the `tex/` directory contains several static
`.tex` files containing tables of abbreviations and such.




## Tests

The package contains a comprehensive set of tests, which may be run by calling
`make test`. This produces a file `test/test.tex` which, when compiled, checks
the operation of the package.

Upon compilation, the resulting document can be reviewed to ensure that all of
the test outputs match expectations. The compilation process attempts to perform
as many checks as possible automatically, but in some cases the best it can do
is ensure that the package's output is the same physical length as the expected
result. The latter types of tests are marked as ``Probably passed.''

The tests rely on a helper package, `helpers/unittest.sty`. This package is not
necessary for installation.




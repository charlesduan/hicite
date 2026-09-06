# *Hereinafter*: A Legal Citation Program

This package provides automated management and formatting of legal citations in
LaTeX documents. It implements the citation system described in [*The Indigo
Book: A Manual of Legal
Citation*](https://law.resource.org/pub/us/code/blue/IndigoBook.html), and is
also largely compatible with other widely-used legal citation systems such as
those described in *A Uniform System of Citation* (the Bluebook) and the *ALWD
Guide to Legal Citation*. More generally, the package provides a framework with
which other legal citation systems may be implemented, such as the OSCOLA and
Chicago systems.

Legal citation is more complex than other citation formats, due to the many
different ways in which citations are used in legal documents and the wider
range of types of documents cited. Legal citation systems typically provide for
multiple, context-dependent citation forms, different formatting depending on
the nature of the document being written, and stateful interactions among
citations that affect formatting. This package is intended to provide
comprehensive support for the wide range of uses of legal citations, enabling
writers to take advantage of capabilities beyond what general citation
management software typically provides.

To implement these systems, the package introduces a domain-specific language
for input of citations and extends the underlying data model of references and
citations, in order to accommodate distinctive features of legal citation.
It also deals with the unique complexities of legal citation
formatting. It handles the proper selection of various citation forms, such as
selection of long or short citation forms across footnotes, inline textual
citations, and citations parenthetically included inside other citations. It
provides facilities especially important for legal documents, such as
tables of authorities, complex internal cross-referencing, and abbreviation
tracking. And it includes an extensive list of document types that may be cited,
in view of the many different citation forms that legal citation manuals
typically use.

## Author

The author of this package is [Charles Duan][https://www.cduan.com], who may be
reached at [cduan@wcl.american.edu](mailto:cduan@wcl.american.edu). Please
contact him with any comments, bugs, or feature requests.

## License

This package is available under a GNU General Public License, version 3, as
stated in the file `LICENSE.md`. The documentation is available under a Creative
Commons Attribution-NonCommercial-ShareAlike 4.0 International license.


## Further Documentation

The following are the major documentation files needed to get started using this
package:

* `INSTALL.md`: How to install, generate package files from source, and run
  tests
* `DOCUMENTATION.md`: The various forms of documentation provided, and how to
  compile them from the source files
* `manual/hicite-manual.pdf`: The user manual for the package






#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

class IndigoBook

  #BOOK_URL = 'https://law.resource.org/pub/us/code/blue/IndigoBook.html'
  BOOK_URL = 'https://law.resource.org/pub/us/code/blue/indigobook-2.0.html'

  #
  # Retrieves the Indigo Book HTML document and returns it.
  #
  def doc
    return @doc if @doc
    @doc = Nokogiri::HTML(URI.open(BOOK_URL))
    return @doc
  end

  #
  # Returns a single table under a given table number, as an HTML node.
  #
  def get_table(num)
    return doc().at_xpath("//*[@id='t#{num}']/following-sibling::table")
  end

  #
  # Given a table, retrieves each row, extracts the cell text, and yields.
  #
  def each_row_data(table)
    table.xpath('.//tr').each do |row|
      # Ignore rows with bold text
      next unless row.xpath('./td//b').empty?
      elts = row.xpath('./td').map { |td| get_non_sup(td) }
      if elts.count == 2
        # Correct apostrophes, non-breaking spaces
        text, abb = *elts.map { |x|
          x.gsub(/\u2019\s*/, "'").gsub(/\s*\u00a0\s*/, ' ').strip
        }
        next if text == 'Word' && abb == 'Abbreviation'
        if text =~ /\s+\((.*)\)\s*\z/
          text, comment = $`, $1
        end
        abb, alt = abb.split(/\s*\n\s+/)
        # Ignore rows with no abbreviations (these are table subheads)
        next if abb == ''
        # Ignore non-abbreviations
        next if text == abb
        if text =~ /\s+\(or (.*)\)\z/
          text1, text2 = $`, $1
          yield(text1, abb, comment, alt)
          yield(text2.strip, abb, comment, alt)
        else
          yield(text, abb, comment, alt)
        end

      elsif elts.count == 1
      elsif row.xpath('./th').count > 0
      else
        warn("Unexpected row #{row.to_s}")
      end
    end

  end

  #
  # Returns all non-<sup> text from the element.
  #
  def get_non_sup(node)
    return node.content if node.text?
    return node.children.map { |child|
      child.name == 'sup' ? "" : get_non_sup(child)
    }.join()
  end

  #
  # For a given table, retrieves the rows of the table, expands the text of
  # each, and yields for each text/abbreviation pair.
  #
  def each_entry(table_num, **alt_opts)
    each_row_data(get_table(table_num)) do |raw_full, raw_abb, comment, alt|
      each_alternative(raw_full, raw_abb, **alt_opts) do |full, abb|
        yield(full, abb, comment, alt)
      end
    end
  end

  #
  # Given a table text entry, splits it into multiple items if the item contains
  # brackets.
  #
  def split_alternatives(text, **opts)
    if text =~ /\[(.*)\]/
      prefix, suffix = $`, $'
      alt_elts = $1.split(/,\s*/)
      alts = alt_elts.map { |a| prefix + a + suffix }

      # Sometimes there is an alternative of the form:
      #   Electric[ity, al]
      # in which the "null alternative" ought to have been included too. The
      # tables provide no easy way to determine whether this null alternative
      # should be included. We apply the following heuristics:
      if prefix + suffix == ''
        # No null alternative if the result is an empty text
      elsif !(alt_elts & %w(y ion e se ce t)).empty? && alt_elts.count > 1
        # These alternatives clearly indicate an incomplete word
      elsif prefix =~ /'\z/
        # Prefix can't end with just an apostrophe
      elsif prefix =~ /\s$/
        # If the prefix ends with a space, no null alternative unless there is
        # only one other alternative (the brackets make no sense otherwise)
        alts.unshift(prefix.strip + suffix) if alts.count == 1
      else
        # Otherwise assume there is a null alternative
        alts.unshift((prefix + suffix).strip)
      end

      return alts
    elsif opts[:split_commas] && text =~ /, /
      elts = text.split(/,\s*/)
      # If the result of the split is completely unrelated texts, then assume
      # that the comma is part of the text and no splitting should occur. This
      # deals with Table 15's inclusion of commas in ASCAP.
      if elts.count > 1 && !same_elt_prefix(elts[0], elts[1])
        return [ text ]
      else
        return elts
      end
    else
      return [ text ]
    end
  end

  def same_elt_prefix(t1, t2)
    if t1 =~ /\A\w{1,2}/
      return t2.start_with?($&)
    else
      return t1[0] == t2[0]
    end
  end

  #
  # Given an abbreviation definition possibly containing brackets, expands to
  # and yields for each alternative specified by the brackets.
  #
  def each_alternative(fulls, abbs, **opts)
    full_alts = split_alternatives(fulls, **opts)
    abb_alts = split_alternatives(abbs, **opts)
    no_pluralize = {}
    if abb_alts.count == 1

      # Every full alternative maps to the single abbreviation
      full_alts.each do |fa|
        fa = "#$' #$`" if opts[:undo_commas] && fa =~ /, /
        propose_alternative(fa, abbs, full_alts, no_pluralize, **opts) do |f, a|
          yield(f, a)
        end
      end

    else

      # Each full alternative maps to one abbreviation
      # Take off the first full alt if it was extraneous
      full_alts.shift if full_alts.count == abb_alts.count + 1
      unless abb_alts.count == full_alts.count
        warn("Inconsistent alternative counts: #{fulls} => #{abbs}")
      end
      full_alts.zip(abb_alts).each do |fa, aa|
        propose_alternative(fa, aa, full_alts, no_pluralize, **opts) do |f, a|
          yield(f, a)
        end
      end
    end
  end

  def propose_alternative(full, abb, full_alts, no_pluralize, **opts)
    return if abb == ''
    # Yield for the original pair
    yield(full, abb)
    # Deal with internal ampersands
    if full.include?(' & ')
      # I think that the abbreviation script can't handle command sequences in
      # full texts
      #yield(full.gsub(' & ', ' \\\& '), abb)
      yield(full.gsub(' & ', ' and '), abb)
    end
    # Yield for plurals
    if opts[:plurals] && !no_pluralize.include?(full)
      pluralize(full).each do |fp|
        if full_alts.include?(fp)
          no_pluralize[fp] = 1
        else
          yield(fp, pluralize_abb(abb))
        end
      end
    end
  end

  #
  # Returns the plural of a word.
  #
  def pluralize(word)
    case word
    when / \(.*\)\z/
      paren = "#$&"
      return pluralize($`).map { |x| x + paren }
    when /'s?\z/ then return []
    when /es\z/ then return []
    when /um\z/ then return [ "#$`a", "#$`ums" ]
    when /ix\z/ then return [ "#$`ixes", "#$`ices" ]
    when /[^aeiou]y\z/ then return [ word[0..-2] + "ies" ]
    when /(?:s|sh|ch|x|z)\z/ then return [ "#{word}es" ]
    else return [ "#{word}s" ]
    end
  end

  # Returns the plural of an abbreviation.
  def pluralize_abb(abb)
    if abb =~ /\.\z/
      return "#$`s."
    else
      return abb + "s"
    end
  end

end



def tex_escape(text)
  return (text || '').gsub(/[{}&\\_^#$%]/) { |x| "\\#{x}" }
end

def make_statement(text, abb, comment, alt, escape: true)
  abb = tex_escape(abb) if escape
  cmt = comment ? " % #{comment}" : alt ? " % alt: #{alt}" : ""
  return "\\hi@abbrev{#{text}}{#{abb}}#{cmt}"
end

book = IndigoBook.new

place_abbs = {}


########################################################################
#
# PLACE NAMES
#
########################################################################

open('hi-places.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for places, from Indigo Book Table 12
    %
  EOF
  %w(12-1 12-2 12-3).each do |tbl|
    book.each_entry(tbl, undo_commas: true) do |text, abb|
      text = 'New York City' if text == 'New York' && abb == 'N.Y.C.'
      text = 'Georgia*' if text == 'Georgia' && abb == 'Geor.'
      io.puts("\\hi@abbrev{#{text}}{#{tex_escape(abb)}}")
      place_abbs[text] = abb
    end
  end
  io.puts <<~EOF
    %
    % No special treatment is given to "United States"
    %
  EOF
  io.puts("\\hi@abbrev{United States}{U.S.}")
  place_abbs['United States'] = 'U.S.'
  io.puts("\\hi@abbrev{United States of America}{U.S.}")
  place_abbs['United States of America'] = 'U.S.'
end





########################################################################
#
# JOURNAL INSTITUTION NAMES
#
########################################################################


open('hi-jrnplaces.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for journal institution places, from Indigo Book Table 15
    %
  EOF
  book.each_entry('15', split_commas: true) do |text, abb, comment, alt|
    if text == 'California'
      io.puts("\\hi@abbrev{{}California Law Review}{Calif. L. Rev.}")
    elsif place_abbs[text]
      if abb != place_abbs[text]
        warn("Inconsistency: #{text} => [ #{place_abbs[text]}, #{abb} ]")
      end
      # Skip duplicate places
    else
      io.puts(make_statement(text, abb, comment, alt))
      if text =~ /, /
        io.puts("\\hi@abbrev{#{text.gsub(', ', ' ')}}{#{tex_escape(abb)}}")
      end
      place_abbs[text] = abb
    end
  end

  # Fix some errors manually
  io.puts('% To ensure the "Law" is part of institution')
  io.puts('\hi@abbrev{Law School}{L. Sch.} ')
  io.puts('\hi@abbrev{School of Law}{Sch. L.} ')
  place_abbs['Law School'] = 'L. Sch.'
  place_abbs['School of Law'] = 'Sch. L.'

  io.puts('% Additional words treated as institution parts')
  io.puts('\hi@abbrev{University}{U.} ')
  place_abbs['University'] = 'U.'
  io.puts('\hi@abbrev{Universities}{U.} ')
  place_abbs['Universities'] = 'U.'
  #io.puts('\hi@abbrev{College}{C.} ')
  #place_abbs['College'] = 'C.'
  #io.puts('\hi@abbrev{Colleges}{Cs.} ')
  #place_abbs['Colleges'] = 'Cs.'

  io.puts(<<~EOF)
    %
    % The Indigo Book abbreviates Puertorriqueño to "P.R.", but I see no
    % indication that any Puerto Rican journal uses this abbreviation:
    %
    % https://www.academiajurisprudenciapr.org/wp-content/uploads/2022/01/Revista-Volumen-XIX-2021.pdf
    % abbreviates it to "Puert."
    %
    % 56 Revista de Derecho Puertorriqeño 191 abbreviates it to "P."
    %
    % See also https://derecho.pucpr.edu/wp-content/uploads/2020/09/Manual-de-Citaci%C3%B3n-Uniforme.pdf at 56
    %
    % Since neither of the local abbreviations would be easily recognized, I'm
    % instead going to use the abbreviation that the Handbook of Latin American
    % Studies uses.
    %
    \\hi@abbrev{Puertorriqueño}{Puertorriq.}
    \\hi@abbrev{Puertorriqueña}{Puertorriq.}
    \\hi@abbrev{Puertorriqueno}{Puertorriq.}
    \\hi@abbrev{Puertorriquena}{Puertorriq.}
  EOF
  place_abbs['Puertorriqueño'] = 'Puertorriq.'
  place_abbs['Puertorriqueña'] = 'Puertorriq.'
  place_abbs['Puertorriqueno'] = 'Puertorriq.'
  place_abbs['Puertorriquena'] = 'Puertorriq.'
end

########################################################################
#
# NAMES
#
########################################################################

open('hi-names.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for names, from Indigo Book Table 11
    %
  EOF
  open('hi-casenames.tex', 'w') do |case_io|
    case_io.puts <<~EOF
      %
      % Abbreviations for names (cases only), from Indigo Book Table 11
      %
    EOF
    open('hi-jrnwords.tex', 'w') do |jrn_io|
      jrn_io.puts <<~EOF
        %
        % Abbreviations for names (journals only), from Indigo Book Table 11
        %
      EOF


      book.each_entry(
        '11', plurals: true, split_commas: true
      ) do |text, abb, comment, alt|

        # Construct the command and comment text
        command = make_statement(text, abb, comment, alt)

        # The journal version uses \abb@dot for single-letter abbreviations
        jabb = tex_escape(abb).gsub(/\b\w\./) { |x| x[0..-2] + "\\abb@dot " }
        jcommand = make_statement(text, jabb, comment, alt, escape: false)

        if alt == '(periodical titles)'
          jrn_io.puts(jcommand) unless place_abbs[text]
        elsif alt == '(case names)' or place_abbs[text]
          case_io.puts(command)
        elsif command != jcommand
          case_io.puts(command)
          jrn_io.puts(jcommand)
        else
          io.puts(command)
        end
      end
      io.puts("\\hi@abbrev{{}Law}{Law} % When first word in abbreviation")
      io.puts("\\hi@abbrev{{}Laws}{Laws} % When first word in abbreviation")

      jrn_io.puts("% Traditional journal abbreviations")
      jrn_io.puts("\\hi@abbrev{Civil Liberty}{C\\abb@dot L\\abb@dot }")
      jrn_io.puts("\\hi@abbrev{Civil Liberties}{C\\abb@dot L\\abb@dot }")
      jrn_io.puts("\\hi@abbrev{Civil Rights}{C\\abb@dot R\\abb@dot }")

    end
  end
end




########################################################################
#
# COURT DOCUMENTS
#
########################################################################

open('hi-courtdocs.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for court documents, from Indigo Book Table 18
    %
  EOF
  book.each_entry(
    '18', plurals: true, split_commas: true
  ) do |text, abb, comment, alt|
    io.puts(make_statement(text, abb, comment, alt))
  end
  #
  # Additional abbreviations based on my own usage and needs
  #
  io.puts("\\hi@abbrev{Amicus Curiae}{Am. Cur.}")
  io.puts("\\hi@abbrev{Amici Curiae}{Am. Cur.}")
  io.puts("\\hi@abbrev{Affidavit}{Aff.}")
  io.puts("\\hi@abbrev{Affidavits}{Affs.}")
  io.puts("\\hi@abbrev{Complaint}{Compl.}")
  io.puts("\\hi@abbrev{Complaints}{Compls.}")
  io.puts("\\hi@abbrev{Document}{Doc.}")
  io.puts("\\hi@abbrev{Documents}{Docs.}")
  io.puts("\\hi@abbrev{Stipulation}{Stip.}")
  io.puts("\\hi@abbrev{Stipulations}{Stips.}")
  io.puts("\\hi@abbrev{Stipulated}{Stip.}")
  io.puts("\\hi@abbrev{Stipulating}{Stip.}")
  io.puts("\\hi@abbrev{Support}{Supp.}")
  io.puts("\\hi@abbrev{Supporting}{Supp.}")
  io.puts("\\hi@abbrev{and}{\\&}")
  io.puts("\\hi@abbrev{The}{}")
  io.puts("\\hi@abbrev{the}{}")
  io.puts("\\hi@abbrev{A}{}")
  io.puts("\\hi@abbrev{a}{}")
  io.puts("\\hi@abbrev{An}{}")
  io.puts("\\hi@abbrev{an}{}")
  io.puts("\\hi@abbrev{of}{}")
  io.puts("\\hi@abbrev{for}{}")
  io.puts("\\hi@abbrev{from}{}")
  io.puts("\\hi@abbrev{in}{}")
  io.puts("\\hi@abbrev{to}{}")
  io.puts("\\hi@abbrev{at}{}")
  io.puts("\\hi@abbrev{by}{}")
  io.puts("\\hi@abbrev{on}{}")
  io.puts("\\hi@abbrev{over}{}")
  io.puts("\\hi@abbrev{per}{}")
  io.puts("\\hi@abbrev{with}{}")
end


########################################################################
#
# LEGISLATIVE DOCUMENTS
#
########################################################################


open('hi-legis.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for legislative documents, from Indigo Book Table 5
    %
  EOF
  book.each_entry(
    '5', plurals: true, split_commas: true
  ) do |text, abb, comment, alt|
    io.puts(make_statement(text, abb, comment, alt))
  end
  #
  # Additional abbreviations based on my own usage and needs
  #
  io.puts("\\hi@abbrev{and}{\\&}")
  io.puts("\\hi@abbrev{The}{}")
  io.puts("\\hi@abbrev{the}{}")
  io.puts("\\hi@abbrev{A}{}")
  io.puts("\\hi@abbrev{a}{}")
  io.puts("\\hi@abbrev{An}{}")
  io.puts("\\hi@abbrev{an}{}")
  io.puts("\\hi@abbrev{of}{}")
  io.puts("\\hi@abbrev{for}{}")
  io.puts("\\hi@abbrev{from}{}")
  io.puts("\\hi@abbrev{in}{}")
  io.puts("\\hi@abbrev{to}{}")
  io.puts("\\hi@abbrev{at}{}")
  io.puts("\\hi@abbrev{by}{}")
  io.puts("\\hi@abbrev{on}{}")
  io.puts("\\hi@abbrev{over}{}")
  io.puts("\\hi@abbrev{per}{}")
  io.puts("\\hi@abbrev{with}{}")
end


########################################################################
#
# EXPLANATORY PHRASES
#
########################################################################


open('hi-explanatory.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Explanatory phrases, from Indigo Book Table 14
    %
  EOF
  word_table = {
    'acquiescence' => 'acq.',
    'nonacquiescence' => 'nonacq.',
    'affirmed' => "aff'd",
    'affirming' => "aff'g",
    'memorandum' => "mem.",
    'certiorari' => "cert.",
    'rehearing' => "reh'g",
    'probable' => "prob.",
    'jurisdiction' => "juris.",
    'reversed' => "rev'd",
    'reversing' => "rev'g",
    'permission to appeal' => "perm. app.",
  }
  word_table.each do |text, abb|
    io.puts(make_statement(text, abb, nil, nil))
  end
  book.get_table('14').xpath(".//td").each do |td|
    text = td.content().strip.downcase.gsub("\u2019", "'")
    next if text == 'abbreviated phrase'
    word_table.each do |full, abb|
      text = text.gsub(abb, full)
    end
    text, extra, suffix = $`, $1, $' if text =~ /\s+\[(\w+)\]/
    io.puts("\\hi@multi@abbrev{#{text}#{suffix}}")
    if text =~ /\bcourt\b/
      io.puts("\\hi@multi@abbrev{#$`Court#$'#{suffix}}")
    end
    if extra
      text = text.sub(/\b\w+\z/, extra)
      io.puts("\\hi@multi@abbrev{#{text}#{suffix}}")
    end
  end
end



########################################################################
#
# DOCUMENT DIVISIONS
#
########################################################################

open('hi-divisions.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Document divisions, from Indigo Book Table 13
    %
  EOF
  plurals = {}
  opts = { plurals: false, split_commas: true }
  book.each_row_data(book.get_table('13')) do |raw_full, raw_abb, comment, alt|

    # Ignore these items; they need special handling
    next if raw_full =~ /^(?:page|section|paragraph)/
    next if raw_full =~ / in cross-references\z/
    raw_full = raw_full.sub(/ in other references\z/, '')

    #
    # The difficulty is that some plural abbreviations are special, and the
    # special plural abbreviation needs to be known at the time that the
    # singular form is processed. So we do essentially three passes:
    #
    # - First, we collect all the alternative forms, and put them in alts.
    #
    # - Second, for each alternative, we generate its plurals and see if any of
    #   them are already in alts. If so, then the corresponding abbreviation is
    #   the plural abbreviation (and we mark the plural so we don't later try to
    #   pluralize it). Otherwise, the plural defaults to what pluralize_abb()
    #   produces.
    #
    # - Third, we regenerate the plurals for the alternative and produce
    #   abbreviation commands.
    #
    alts = {}
    plurals = {}

    # First pass: collect all alternatives
    book.each_alternative(raw_full, raw_abb, split_commas: true) do |full, abb|
      full = full.gsub(' ', '-')
      alts[full] = abb
    end

    alts.each do |full, abb|

      # Skip if we already saw that this word is a plural
      next if plurals[full]

      # Default abbreviation plural form
      pl_abb = book.pluralize_abb(abb)

      # Pluralize the full form and see if any of the plurals have a defined
      # special abbreviation. If so, replace the abbreviation plural form. Also
      # mark all full-form plurals for skipping purposes above.
      book.pluralize(full).each do |pl_full|
        plurals[pl_full] = 1
        pl_abb = alts[pl_full] if alts[pl_full]
      end

      # Add a space after the dot for every abbreviation but these three
      unless full =~/(?:note|table|figure)\z/
        pl_abb += ' '
        abb += ' '
      end

      # Now generate commands for the word and its plurals, in both lowercase
      # and capital form.
      book.pluralize(full).each do |pl_full|
        io.puts("\\hi@abbrev{#{full}}{#{abb}}{#{pl_full}}{#{pl_abb}}")
        io.puts(
          "\\hi@abbrev{#{full.capitalize}}{#{abb.capitalize}}" +
          "{#{pl_full.capitalize}}{#{pl_abb.capitalize}}"
        )
      end
    end
  end
  io.puts("% Special forms")
  io.puts("\\hi@abbrev{paragraph}{para. }{paragraphs}{paras. }")
  io.puts("\\hi@abbrev{section}{sec. }{sections}{secs. }")
  io.puts("\\hi@abbrev{note}{n.}{notes}{nn.}")
  io.puts("% Additional abbreviations")
  io.puts("\\hi@abbrev{exhibit}{exh. }{exhibits}{exhs. }")
  io.puts("\\hi@abbrev{Exhibit}{Exh. }{Exhibits}{Exhs. }")
  io.puts("\\hi@abbrev{claim}{cl. }{claims}{cls. }")
  io.puts("\\hi@abbrev{Claim}{Cl. }{Claims}{Cls. }")
end



########################################################################
#
# PUBLISHING TERMS
#
########################################################################

open('hi-publish.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for publishing terms, from Indigo Book Table 16
    %
  EOF
  book.each_entry(
    '16', plurals: false, split_commas: true
  ) do |text, abb, comment, alt|
    io.puts(make_statement(text, abb, comment, alt))
  end
  io.puts("% Additional abbreviations")
  io.puts("\\hi@abbrev{translators}{trans.}")
  io.puts("\\hi@abbrev{editors}{eds.}")
  io.puts("\\hi@abbrev{Number}{No.}")
  io.puts("\\hi@abbrev{number}{no.}")
  io.puts("\\hi@abbrev{and}{\\&}")
end

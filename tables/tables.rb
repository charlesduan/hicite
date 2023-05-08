#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

class IndigoBook

  BOOK_URL = 'https://law.resource.org/pub/us/code/blue/IndigoBook.html'

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
    return doc().at_xpath("//*[@id='T#{num}']/following-sibling::table")
  end

  #
  # Given a table, retrieves each row, extracts the cell text, and yields.
  #
  def each_row_data(table)
    table.xpath('.//tr').each do |row|
      elts = row.xpath('./td').map { |td|
        td.children.reject { |c| c.name == 'sup' }.map(&:content).join('')
      }
      if elts.count == 2
        text, abb = *elts
        # Ignore rows with no abbreviations (these are table subheads)
        next if abb == ''
        # Ignore non-abbreviations
        next if text == abb
        if text =~ / \(or (.*)\)\z/
          text1, text2 = $`, $1
          yield(text1.strip, abb.strip)
          yield(text2.strip, abb.strip)
        else
          yield(text.strip, abb.strip)
        end

      elsif elts.count == 1
      elsif row.xpath('./th').count > 0
      else
        warn("Unexpected row #{row.to_s}")
      end
    end

  end

  #
  # For a given table, retrieves the rows of the table, expands the text of
  # each, and yields for each text/abbreviation pair.
  #
  def each_entry(table_num, **alt_opts)
    each_row_data(get_table(table_num)) do |raw_full, raw_abb|
      # Ignore xref entries
      next if raw_full =~ / in cross-references\z/
      raw_full = raw_full.gsub(/ in other references\z/, '')
      # Correct apostrophes
      raw_full = raw_full.gsub(/\u2019\s*/, "'")
      raw_abb = raw_abb.gsub(/\u2019\s*/, "'").split(" or ").first
      each_alternative(raw_full, raw_abb, **alt_opts) do |full, abb|
        yield(full, abb)
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
      elsif alt_elts & %w(y ion e se ce t)
        # These alternatives clearly indicate an incomplete word
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
      return text.split(/,\s*/)
    else
      return [ text ]
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
    return if abb == '' || abb =~ /'\z/
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

book = IndigoBook.new
#
#book.each_entry('13', plurals: true, split_commas: true) do |text, abb|
#  case text
#  when /\Apage/, /\Aparagraph/, /\Asection/ then next
#  when /notes?\z/, /tables?\z/, /figures?\z/
#  else abb = "#{abb} "
#  end
#  puts("\\hi@abbrev{#{tex_escape(text.gsub(/\s+/, '-'))}}{#{tex_escape(abb)}}")
#end
#
#exit

place_abbs = {}

open('hi-places.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for places, from Indigo Book Table 12
    %
  EOF
  %w(12.1 12.2 12.3).each do |tbl|
    book.each_entry(tbl, undo_commas: true) do |text, abb|
      text = 'New York City' if text == 'New York' && abb == 'N.Y.C.'
      text = 'Georgia*' if text == 'Georgia' && abb == 'Geor.'
      io.puts("\\hi@abbrev{#{text}}{#{tex_escape(abb)}}")
      place_abbs[text] = abb
    end
  end
  io.puts("\\hi@abbrev{United States}{U.S.}")
  place_abbs['United States'] = 'U.S.'
  io.puts <<~EOF
    %
    % No special treatment is given to "United States"
    %
  EOF
  io.puts("\\hi@abbrev{United States of America}{U.S.}")
  place_abbs['United States of America'] = 'U.S.'
end

open('hi-jrnplaces.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for journal institution places, from Indigo Book Table 15
    %
  EOF
  book.each_entry('15') do |text, abb|
    if place_abbs[text]
      if abb != place_abbs[text]
        warn("Inconsistency: #{text} => [ #{place_abbs[text]}, #{abb} ]")
      end
      # Skip duplicate places
    elsif text == 'California (California Law Review only)'
      io.puts("\\hi@abbrev{{}California Law Review}{Calif. L. Rev.}")
    else
      io.puts("\\hi@abbrev{#{text}}{#{tex_escape(abb)}}")
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
  io.puts('\hi@abbrev{College}{C.} ')
  place_abbs['College'] = 'C.'
  io.puts('\hi@abbrev{Colleges}{Cs.} ')
  place_abbs['Colleges'] = 'Cs.'

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

open('hi-jrnwords.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for journal words, from Indigo Book Table 18
    %
  EOF
  book.each_entry('18', plurals: true) do |text, abb|
    if text =~ /Puertorriq/
    elsif place_abbs[text]
      if abb != place_abbs[text]
        warn("Inconsistency: #{text} => [ #{place_abbs[text]}, #{abb} ]")
      end
    else
      text = "{}#$`#$'" if text =~ / \(first word\)/
      abb = tex_escape(abb).gsub(/(?<=\b\w)\./, '\\abb@dot ')
      io.puts "\\hi@abbrev{#{text}}{#{abb}}"
    end
  end
end

open('hi-names.tex', 'w') do |io|
  io.puts <<~EOF
    %
    % Abbreviations for names, from Indigo Book Table 11
    %
  EOF
  book.each_entry('11', plurals: true) do |text, abb|
    io.puts "\\hi@abbrev{#{text}}{#{tex_escape(abb)}}"
  end

end


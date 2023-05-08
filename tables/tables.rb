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
        # Ignore rows with no abbreviations (these are table subheads)
        next unless elts[1] != ''
        # Ignore non-abbreviations
        next unless elts[0] != elts[1]
        yield(elts[0].strip, elts[1].strip)
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
      alts = $1.split(/,\s*/).map { |a| prefix + a + suffix }
      unless prefix =~ /\s$/ or prefix + suffix == ''
        alts.unshift(prefix + suffix)
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
      yield(full.gsub(' & ', ' \\\& '), abbs)
      yield(full.gsub(' & ', ' and '), abbs)
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
    if word =~ /um\z/ then return [ "#$`a", "#$`ums" ] end
    if word =~ /ix\z/ then return [ "#$`ixes", "#$`ices" ] end
    if word =~ /[^aeiou]y\z/ then return [ word[0..-2] + "ies" ] end
    if word =~ /(?:s|sh|ch|x|z)\z/ then return [ "#{word}es" ] end
    return [ "#{word}s" ]
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
  return (text || '').gsub(/[{}&\\_^#$%]/, "\\\&")
end


book = IndigoBook.new

book.each_entry('13', plurals: true, split_commas: true) do |text, abb|
  case text
  when /\Apage/, /\Aparagraph/, /\Asection/ then next
  when /notes?\z/, /tables?\z/, /figures?\z/
  else abb = "#{abb} "
  end
  puts("\\hi@abbrev{#{tex_escape(text.gsub(/\s+/, '-'))}}{#{tex_escape(abb)}}")
end

exit

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
      io.puts("\\hi@abbrev{#{tex_escape(text)}}{#{tex_escape(abb)}}")
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
    io.puts "\\hi@abbrev{#{tex_escape(text)}}{#{tex_escape(abb)}}"
  end

end


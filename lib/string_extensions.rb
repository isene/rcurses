# string_extensions.rb

class String
  # 256-color or truecolor RGB foreground
  def fg(color)
    sp, ep = if color.to_s =~ /\A[0-9A-Fa-f]{6}\z/
               r, g, b = color.scan(/../).map { |c| c.to_i(16) }
               ["\e[38;2;#{r};#{g};#{b}m", "\e[0m"]
             else
               ["\e[38;5;#{color}m", "\e[0m"]
             end
    color(self, sp, ep)
  end

  # 256-color or truecolor RGB background
  def bg(color)
    sp, ep = if color.to_s =~ /\A[0-9A-Fa-f]{6}\z/
               r, g, b = color.scan(/../).map { |c| c.to_i(16) }
               ["\e[48;2;#{r};#{g};#{b}m", "\e[0m"]
             else
               ["\e[48;5;#{color}m", "\e[0m"]
             end
    color(self, sp, ep)
  end

  # Both fg and bg in one go
  def fb(fg_color, bg_color)
    parts = []
    if fg_color.to_s =~ /\A[0-9A-Fa-f]{6}\z/
      r, g, b = fg_color.scan(/../).map { |c| c.to_i(16) }
      parts << "38;2;#{r};#{g};#{b}"
    else
      parts << "38;5;#{fg_color}"
    end

    if bg_color.to_s =~ /\A[0-9A-Fa-f]{6}\z/
      r, g, b = bg_color.scan(/../).map { |c| c.to_i(16) }
      parts << "48;2;#{r};#{g};#{b}"
    else
      parts << "48;5;#{bg_color}"
    end

    sp = "\e[#{parts.join(';')}m"
    color(self, sp, "\e[0m")
  end

  # bold, italic, underline, blink, reverse
  def b; color(self, "\e[1m",   "\e[22m"); end
  def i; color(self, "\e[3m",   "\e[23m"); end
  def u; color(self, "\e[4m",   "\e[24m"); end
  def l; color(self, "\e[5m",   "\e[25m"); end
  def r; color(self, "\e[7m",   "\e[27m"); end

  # Internal helper - wraps +text+ in start/end sequences,
  # and re-applies start on every newline.
  def color(text, sp, ep = "\e[0m")
    t = text.gsub("\n", "#{ep}\n#{sp}")
    "#{sp}#{t}#{ep}"
  end

  # Combined code:  "foo".c("FF0000,00FF00,bui")
  # — 6-hex or decimal for fg, then for bg, then letters b/i/u/l/r
  def c(code)
    parts = code.split(',')
    seq   = []

    fg = parts.shift
    if fg =~ /\A[0-9A-Fa-f]{6}\z/
      r,g,b = fg.scan(/../).map{|c|c.to_i(16)}
      seq << "38;2;#{r};#{g};#{b}"
    elsif fg =~ /\A\d+\z/
      seq << "38;5;#{fg}"
    end

    if parts.any?
      bg = parts.shift
      if bg =~ /\A[0-9A-Fa-f]{6}\z/
        r,g,b = bg.scan(/../).map{|c|c.to_i(16)}
        seq << "48;2;#{r};#{g};#{b}"
      elsif bg =~ /\A\d+\z/
        seq << "48;5;#{bg}"
      end
    end

    seq << '1' if code.include?('b')
    seq << '3' if code.include?('i')
    seq << '4' if code.include?('u')
    seq << '5' if code.include?('l')
    seq << '7' if code.include?('r')

    "\e[#{seq.join(';')}m#{self}\e[0m"
  end

  # Strip all ANSI SGR sequences
  def pure
    gsub(/\e\[\d+(?:;\d+)*m/, '')
  end

  # Remove stray leading/trailing reset if the string has no other styling
  def clean_ansi
    gsub(/\A(?:\e\[0m)+/, '').gsub(/\e\[0m\z/, '')
  end

  # Truncate the *visible* length to n, but preserve embedded ANSI
  def shorten(n)
    count = 0
    out   = ''
    i     = 0

    while i < length && count < n
      if self[i] == "\e" && (m = self[i..-1].match(/\A(\e\[\d+(?:;\d+)*m)/))
        out << m[1]
        i   += m[1].length
      else
        out << self[i]
        i   += 1
        count += 1
      end
    end

    out
  end

  # Insert +insertion+ at visible position +pos+ (negative → end),
  # respecting and re-inserting existing ANSI sequences.
  def inject(insertion, pos)
    pure_txt      = pure
    visible_len   = pure_txt.length
    pos           = visible_len if pos < 0

    count, out, i, injected = 0, '', 0, false

    while i < length
      if self[i] == "\e" && (m = self[i..-1].match(/\A(\e\[\d+(?:;\d+)*m)/))
        out << m[1]
        i   += m[1].length
      else
        if count == pos && !injected
          out << insertion
          injected = true
        end
        out << self[i]
        count  += 1
        i      += 1
      end
    end

    unless injected
      if out =~ /(\e\[\d+(?:;\d+)*m)\z/
        trailing = $1
        out      = out[0...-trailing.length] + insertion + trailing
      else
        out << insertion
      end
    end

    out
  end
end


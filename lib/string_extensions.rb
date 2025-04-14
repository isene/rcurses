class String
  # Existing methods...
  def fg(fg)    ; color(self, "\e[38;5;#{fg}m", "\e[0m")  ; end
  def bg(bg)    ; color(self, "\e[48;5;#{bg}m", "\e[0m")  ; end
  def fb(fg, bg); color(self, "\e[38;5;#{fg};48;5;#{bg}m"); end
  def b         ; color(self, "\e[1m", "\e[22m")          ; end
  def i         ; color(self, "\e[3m", "\e[23m")          ; end
  def u         ; color(self, "\e[4m", "\e[24m")          ; end
  def l         ; color(self, "\e[5m", "\e[25m")          ; end
  def r         ; color(self, "\e[7m", "\e[27m")          ; end

  # Internal function
  def color(text, sp, ep = "\e[0m")
    # Replace every newline with a newline followed by the start sequence,
    # so that formatting is reestablished on each new line.
    text = text.gsub("\n", "#{ep}\n#{sp}")
    "#{sp}#{text}#{ep}"
  end

  # Use format "TEST".c("204,45,bui") to print "TEST" in bold, underline, italic, fg=204 and bg=45
  def c(code)
    prop = "\e["
    prop += "38;5;#{code.match(/^\d+/).to_s};"      if code.match(/^\d+/)
    prop += "48;5;#{code.match(/(?<=,)\d+/).to_s};" if code.match(/(?<=,)\d+/)
    prop += "1;" if code.include?('b')
    prop += "3;" if code.include?('i')
    prop += "4;" if code.include?('u')
    prop += "5;" if code.include?('l')
    prop += "7;" if code.include?('r')
    prop.chop! if prop[-1] == ";"
    prop += "m"
    prop += self
    prop += "\e[0m"
    prop
  end

  def clean_ansi
    # Remove a leading and trailing reset code if present, fixing extra \e[0m introduced by some commands
    self.gsub(/\e\[0m(?=\e\[38;5)/, '').gsub(/\A\e\[0m/, '').gsub(/\e\[0m\z/, '')
  end

  def pure
    self.gsub(/\e\[\d+(?:;\d+)*m/, '')
  end

  # Shortens the visible (pure) text to n characters, preserving any ANSI sequences.
  def shorten(n)
    count = 0
    result = ""
    i = 0
    while i < self.length && count < n
      if self[i] == "\e" # start of an ANSI escape sequence
        if m = self[i..-1].match(/\A(\e\[\d+(?:;\d+)*m)/)
          result << m[1]
          i += m[1].length
        else
          # Fallback if pattern doesn’t match: treat as a normal character.
          result << self[i]
          i += 1
          count += 1
        end
      else
        result << self[i]
        count += 1
        i += 1
      end
    end
    result
  end

  # Inserts the given substring at the provided visible character position.
  # A negative position means insertion at the end.
  # When inserting at the end and the string ends with an ANSI escape sequence,
  # the insertion is placed before that trailing ANSI sequence.
  def inject(insertion, pos)
    pure_text = self.pure
    visible_length = pure_text.length
    pos = visible_length if pos < 0

    count = 0
    result = ""
    i = 0
    injected = false

    while i < self.length
      if self[i] == "\e"  # Start of an ANSI sequence.
        if m = self[i..-1].match(/\A(\e\[\d+(?:;\d+)*m)/)
          result << m[1]
          i += m[1].length
        else
          result << self[i]
          i += 1
        end
      else
        if count == pos && !injected
          result << insertion
          injected = true
        end
        result << self[i]
        count += 1
        i += 1
      end
    end

    # If we haven't injected (i.e. pos equals visible_length),
    # check for a trailing ANSI sequence and insert before it.
    unless injected
      if result =~ /(\e\[\d+(?:;\d+)*m)\z/
        trailing = $1
        result = result[0...-trailing.length] + insertion + trailing
      else
        result << insertion
      end
    end

    result
  end
end

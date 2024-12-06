class String
  # Add coloring to strings (with escaping for Readline)
  def fg(fg)    ; color(self, "\e[38;5;#{fg}m", "\e[0m")  ; end
  def bg(bg)    ; color(self, "\e[48;5;#{bg}m", "\e[0m")  ; end
  def fb(fg, bg); color(self, "\e[38;5;#{fg};48;5;#{bg}m"); end
  def b         ; color(self, "\e[1m", "\e[22m")          ; end
  def i         ; color(self, "\e[3m", "\e[23m")          ; end
  def u         ; color(self, "\e[4m", "\e[24m")          ; end
  def l         ; color(self, "\e[5m", "\e[25m")          ; end
  def r         ; color(self, "\e[7m", "\e[27m")          ; end
  # Internal function
  def color(text, sp, ep = "\e[0m"); "#{sp}#{text}#{ep}"; end

  # Use format "TEST".c("204,45,bui") to print "TEST" in bold, underline italic, fg=204 and bg=45
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

  def pure
    self.gsub(/\e\[\d+(?:;\d+)*m/, '')
  end
end

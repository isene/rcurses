# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby, best viewed in VIM
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    0.2 : Initial upload to GitHub

class Pane
  attr_accessor :startx, :starty, :width, :height, :fg, :bg
  attr_accessor :x, :y, :w, :h
  attr_accessor :border, :scroll, :text, :ix, :align, :prompt
  def initialize(startx=1, starty=1, width=1, height=1, fg=nil, bg=nil)
    @startx, @starty, @width, @height, @fg, @bg = startx, starty, width, height, fg, bg
    @text   = ""      # Initialize text variable
    @align  = "l"     # Default alignment
    @scroll = true    # Initialize scroll indicators to true
    @prompt = ""      # Initialize prompt for editline
    @c      = Cursor  # Local cursor object
    @ix     = 0       # Text index (starting text line in pane)
    self.refresh      # Draw the pane upon creation
  end
  def move (x,y)
    self.startx = self.x + x
    self.starty = self.y + y
    self.refresh
  end
  def ansicheck(string, ansi)
    ansi_beg = /\u0001\e\[#{ansi[0].to_s}m\u0002/
    if ansi[0] == 38 or ansi[0] == 48
      ansi_beg = /\u0001\e\[#{ansi[0].to_s}[\d;m]+\u0002/
    end
    ansi_end = /\u0001\e\[#{ansi[1].to_s}m\u0002/
    begix = string.rindex(ansi_beg)
    begix = -1 if begix == nil
    endix = string.rindex(ansi_end)
    endix = -1 if endix == nil
    dirty = string[begix..-1].match(ansi_beg)[0] if begix > endix
    dirty.to_s
  end
  def textformat(cont=self.text)
    @txt = cont.split("\n") # Split text into array
    if @txt.any? { |line| line.length >= self.w } # Splitx for lines breaking width
      @txt = cont.splitx(self.w) 
      if cont != cont.pure # Treat lines that break ANSI escape codes
        @dirty = "" # Initiate dirty flag (for unclosed ANSI escape sequence)
        @txt.each_index do |i|
          if @dirty != "" # If dirty flag is set from previous line then add the ANSI sequence to beginning of this line
            @txt[i] = @dirty + @txt[i]; @dirty = ""
          end
          @dirty += ansicheck(@txt[i], [1,22]) # Bold
          @dirty += ansicheck(@txt[i], [3,23]) # Italic
          @dirty += ansicheck(@txt[i], [4,24]) # Underline
          @dirty += ansicheck(@txt[i], [5,25]) # Blink
          @dirty += ansicheck(@txt[i], [7,27]) # Reverse
          @dirty += ansicheck(@txt[i], [38,0]) # Foreground color
          @dirty += ansicheck(@txt[i], [48,0]) # Background color
          @txt[i].sub!(/[\u0001\u0002\e\[\dm]*$/, '')
        end
      end
    end
    @txt
  end
  def refresh(cont=self.text)
    o_row, o_col = @c.pos
    @c.row(8000); @c.col(8000) # Set for maxrow/maxcol
    @maxrow, @maxcol = @c.pos
    self.x = eval(self.startx.to_s)
    self.y = eval(self.starty.to_s)
    self.w = eval(self.width.to_s)
    self.h = eval(self.height.to_s)
    if self.border # Keep panes inside screen
      self.x = 2 if self.x < 2; self.x = @maxcol - self.w if self.x + self.w > @maxcol
      self.y = 2 if self.y < 2; self.y = @maxrow - self.h if self.y + self.h > @maxrow
    else
      self.x = 1 if self.x < 1; self.x = @maxcol - self.w + 1 if self.x + self.w > @maxcol + 1
      self.y = 1 if self.y < 1; self.y = @maxrow - self.h + 1 if self.y + self.h > @maxrow + 1
    end
    @c.col(self.x); @c.row(self.y) # Cursor to start of pane
    fmt = self.fg.to_s + "," + self.bg.to_s # Format for printing in pane (fg,bg)
    @txt = textformat(cont) # Call function to create an array out of the pane text
    @ix = @txt.length - 1 if @ix > @txt.length - 1; @ix = 0 if @ix < 0 # Ensuring no out-of-bounds
    self.h.times do |i| # Print pane content
      l = @ix + i # The current line to be printed
      if @txt[l].to_s != "" # Print the text line for line
        pl = self.w - @txt[l].pure.length; hl = pl/2 # Get padding width and half width
        print @txt[l].c(fmt) + " ".c(fmt) * pl if self.align == "l"
        print " ".c(fmt) * pl + @txt[l].c(fmt) if self.align == "r"
        print " ".c(fmt) * hl + @txt[l].c(fmt) + " ".c(fmt) * (pl - hl) if self.align == "c"
      else
        print  "".rjust(self.w).bg(self.bg)
      end
      r,c = @c.pos
      @c.row(r + 1)  # Cursor down one line
      @c.col(self.x) # Cursor to start of pane
    end
    if @ix > 0 and self.scroll # Print "more" marker at top
      @c.col(self.x + self.w - 1); @c.row(self.y)
      print "▲".c(fmt)
    end
    if @txt.length - @ix > self.h and self.scroll # Print bottom "more" marker
      @c.col(self.x + self.w - 1); @c.row(self.y + self.h - 1)
      print "▼".c(fmt)
    end
    if self.border # Print border if self.border is set to "true"
      @c.row(self.y - 1); @c.col(self.x - 1)
      print ("┌" + "─" * self.w + "┐").c(fmt) 
      self.h.times do |i|
        @c.row(self.y + i); @c.col(self.x - 1)
        print "│".c(fmt)  
        @c.col(self.x + self.w)
        print "│".c(fmt)
      end
      @c.row(self.y + self.h); @c.col(self.x - 1)
      print ("└" + "─" * self.w + "┘").c(fmt) 
    end
    @c.row(o_row)
    @c.col(o_col)
    @txt
  end
  def right
    if @pos < @txt[self.ix + @line].length
      @pos += 1 
    else
      if @line == self.h
        self.ix += 1 unless self.ix >= @txt.length
        @pos = 0
      elsif @line + self.ix + 2 <= @txt.length
        @line += 1
        @pos = 0
      end
    end
  end
  def left
  if @pos == 0
    if @line == 0
        unless self.ix == 0
          self.ix -= 1 
          @pos = @txt[self.ix + @line].length - 1
        end
      else
        @line -= 1
        @pos = @txt[self.ix + @line].length - 1
      end
    else
      @pos -= 1
    end
  end
  def up
    if @line == 0
      self.ix -= 1 unless self.ix == 0
    else
      @line -= 1
    end
    begin
      @pos = @txt[self.ix + @line].length - 1 if @pos > @txt[self.ix + @line].length - 1
    rescue
    end
  end
  def down
    if @line == self.h - 1
      self.ix += 1 unless self.ix + @line >= @txt.length - 1
    elsif @line + self.ix + 2 <= @txt.length
      @line += 1
    end
    begin
      @pos = @txt[self.ix + @line].length - 1 if @pos > @txt[self.ix + @line].length - 1
    rescue
    end
  end
  def parse(cont)
    cont.gsub!(/\*(.+?)\*/,           '\1'.b)
    cont.gsub!(/\/(.+?)\//,           '\1'.i)
    cont.gsub!(/_(.+?)_/,             '\1'.u)
    cont.gsub!(/#(.+?)#/,             '\1'.r)
    cont.gsub!(/<([^|]+)\|([^>]+)>/) do |m|
      text = $2; codes = $1
      text.c(codes)
    end
    cont
  end
  def edit
    cont = self.text.pure.gsub(/\n/, "¬\n") 
    @line = self.ix
    @pos  = 0
    chr   = ""
    while chr != "ESC" # Keep going with readline until user presses ESC
      @txt = self.refresh(cont)
      @c.row(self.y + @line)
      @c.col(self.x + @pos)
      chr = getchr
      case chr
      when 'C-L'    # Left justify
        self.align = "l"
      when 'C-R'    # Right Justify
        self.align = "r"
      when 'C-C'    # Center justify
        self.align = "c"
      when 'C-Y'    # Copy pane content to clipboard
        system("echo '#{self.text.pure}' | xclip")
      when 'C-S'    # Save edited text back to self.text
        cont = cont.gsub("¬", "\n")
        cont = parse(cont)
        self.text = cont
        chr = "ESC"
      when 'DEL'    # Delete character
        posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
        cont[posx] = ""
      when 'BACK'   # Backspace
        left
        posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
        cont[posx] = ""
      when 'WBACK'  # Word backspace
        posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
        until cont[posx - 1] == " " or @pos == 0
          left
          posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
          cont[posx] = ""
        end
      when 'C-K'    # Kill line
        begin
          prev_l = 0
          line_c = self.ix + @line
          line_c.times {|i| prev_l += @txt[i].length + 1}
          cur_l  = @txt[line_c].length
          cont.slice!(prev_l,cur_l)
        rescue
        end
      when 'UP'     # Up one line
        up
      when 'DOWN'   # Down one line
        down
      when 'RIGHT'  # Right one character
        right
      when 'LEFT'   # Left one character
        left
      when 'HOME'   # Start of line
        @pos = 0
      when 'END'    # End of line
        @pos = @txt[self.ix + @line].length - 1
      when 'C-HOME' # Start of pane
        @line = 0
        @pos = 0
      when 'C-END'  # End of pane
      when 'ENTER'
        posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
        cont.insert(posx,"¬\n")
        right
      when /^.$/
        posx = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
        cont.insert(posx,chr)
      end
      charx = 1
      posx  = 0; (self.ix + @line).times {|i| posx += @txt[i].length + 1}; posx += @pos
      while $stdin.ready?
        chr = $stdin.getc
        charx += 1
        posx  += 1
        cont.insert(posx,chr)
      end
      if chr =~ /^.$/
        self.refresh(cont)
        charx.times {right}
      end

    end
    # Keep?
    @c.row(nil)
    @c.col(nil)
  end
  def editline
    self.x = eval(self.startx.to_s)
    self.y = eval(self.starty.to_s)
    self.w = eval(self.width.to_s)
    self.h = eval(self.height.to_s)
    self.x = 1 if self.x < 1; self.x = @maxcol - self.w + 1 if self.x + self.w > @maxcol + 1
    self.y = 1 if self.y < 1; self.y = @maxrow - self.h + 1 if self.y + self.h > @maxrow + 1
    self.scroll = false
    @c.row(self.y)
    fmt = self.fg.to_s + "," + self.bg.to_s   # Format for printing in pane (fg,bg)
    @c.col(self.x); print self.prompt.c(fmt)  # Print prompt from start of pane
    pl    = self.prompt.pure.length           # Prompt length
    cl    = self.w - pl                       # Available content length
    cont  = self.text.pure                    # Actual content
    @pos  = cont.length                       # Initial position set at end of content
    chr   = ""                                # Initialize chr
    while chr != "ESC"                        # Keep going with readline until user presses ESC
      @c.col(self.x + pl)                     # Set cursor at start of content
      cont = cont.slice(0,cl)                 # Trim content to max length
      print cont.ljust(cl).c(fmt)             # Print content left justified to max length
      @c.col(self.x + pl + @pos)              # Set cursor to current position (@pos)
      chr = getchr                            # Read character from user input
      case chr
      when 'LEFT'                             # One character left
        @pos -= 1 unless @pos == 0
      when 'RIGHT'                            # One character right
        @pos += 1 unless @pos >= cont.length
      when 'HOME'                             # To start of content
        @pos = 0
      when 'END'                              # To end of content
        @pos = cont.length - 1
      when 'DEL'                              # Delete character
        cont[@pos] = ""
      when 'BACK'                             # Backspace
        @pos -= 1 unless @pos == 0
        cont[@pos] = ""
      when 'WBACK'                            # Word backspace
        until cont[@pos - 1] == " " or @pos == 0
          @pos -= 1
          cont[@pos] = ""
        end
      when 'C-K'                              # Kill line (set content to nothing)
        cont = ""
        @pos = 0
      when 'ENTER'                            # Save content to self.text and end
        self.text = parse(cont)
        chr = 'ESC'
      when /^.$/                              # Add character to content
        unless @pos >= cl - 1
          cont.insert(@pos,chr)
          @pos += 1
        end
      end
      while $stdin.ready?                     # Add characters from pasted input  
        chr = $stdin.getc
        unless @pos >= cl - 1
          cont.insert(@pos,chr)
          @pos += 1
        end
      end
    end
    # Keep? Set cursor away from pane
    @c.row(nil)
    @c.col(nil)
  end
end

class String # Add coloring to strings (with escaping for Readline)
  def fg(fg);     color(self, "\001\e[38;5;#{fg}m\002", "\001\e[0m\002"); end # Foreground color code
  def bg(bg);     color(self, "\001\e[48;5;#{bg}m\002", "\001\e[0m\002"); end # Background color code
  def fb(fg, bg); color(self, "\001\e[38;5;#{fg};48;5;#{bg}m\002"); end       # Fore/Background color code
  def b;          color(self, "\001\e[1m\002", "\001\e[22m\002"); end         # Bold
  def i;          color(self, "\001\e[3m\002", "\001\e[23m\002"); end         # Italic
  def u;          color(self, "\001\e[4m\002", "\001\e[24m\002"); end         # Underline
  def l;          color(self, "\001\e[5m\002", "\001\e[25m\002"); end         # Blink
  def r;          color(self, "\001\e[7m\002", "\001\e[27m\002"); end         # Reverse
  def color(text, sp, ep) "#{sp}#{text}#{ep}" end                             # Internal function
  def c(code) # Use format "TEST".c("204,45,bui") to print "TEST" in bold, underline italic, fg=204 and bg=45 
    prop  = "\001\e["
    prop += "38;5;#{code.match(/^\d+/).to_s};"      if code.match(/^\d+/) 
    prop += "48;5;#{code.match(/(?<=,)\d+/).to_s};" if code.match(/(?<=,)\d+/) 
    prop += "1;" if code.match(/b/) 
    prop += "3;" if code.match(/i/) 
    prop += "4;" if code.match(/u/) 
    prop += "5;" if code.match(/l/) 
    prop += "7;" if code.match(/r/) 
    prop.chop! if prop[-1] == ";"
    prop += "m\002"
    prop += self
    prop += "\001\e[0m\002"
    #puts "\n XX\n" + code
    prop
  end
  def pure
    self.gsub(/\u0001.*?\u0002/, '')
  end
  def splitx(x)
    lines = self.split("\n")
    until lines.all? { |line| line.pure.length <= x } do
      lines.map! do |l| 
        if l.pure.length > x and l[0..x].match(/ /)
          @ix = l[0..x].rindex(" ")
          [ l[0...@ix], l[(@ix + 1)..-1] ]
        elsif l.pure.length > x
          [l[0...x], l[x..-1]]
        else
          l
        end
      end
      lines.flatten!
    end
    lines.reject { |e| e.to_s.empty? }
  end
end

module Cursor # Terminal cursor movement ANSI codes (thanks to https://github.com/piotrmurach/tty-cursor)
  module_function
  ESC = "\e".freeze
  CSI = "\e[".freeze
  def save # Save current position
    print(Gem.win_platform? ? CSI + 's' : ESC + '7')
  end
  def restore # Restore cursor position
    print(Gem.win_platform? ? CSI + 'u' : ESC + '8')
  end
  def pos # Query cursor current position
    res = ''
    $stdin.raw do |stdin|
      $stdout << CSI + '6n' # Tha actual ANSI get-position
      $stdout.flush
      while (c = stdin.getc) != 'R'
        res << c if c
      end
    end
    m = res.match /(?<row>\d+);(?<col>\d+)/
    return m[:row].to_i, m[:col].to_i
  end
  def rowget
    row, col = self.pos
    return row
  end
  def colget
    row, col = self.pos
    return col
  end
  def up(n = 1) # Move cursor up by n
    print(CSI + "#{(n || 1)}A")
  end
  def down(n = 1) # Move the cursor down by n
    print(CSI + "#{(n || 1)}B")
  end
  def left(n = 1) # Move the cursor backward by n
    print(CSI + "#{n || 1}D")
  end
  def right(n = 1) # Move the cursor forward by n
    print(CSI + "#{n || 1}C")
  end
  def col(n = 1) # Cursor moves to nth position horizontally in the current line
    print(CSI + "#{n || 1}G")
  end
  def row(n = 1) # Cursor moves to the nth position vertically in the current column
    print(CSI + "#{n || 1}d")
  end
  def next_line # Move cursor down to beginning of next line
    print(CSI + 'E' + CSI + "1G")
  end
  def prev_line # Move cursor up to beginning of previous line
    print(CSI + 'A' +  CSI + "1G")
  end
  def clear_char(n = 1) # Erase n characters from the current cursor position
    print(CSI + "#{n}X")
  end
  def clear_line # Erase the entire current line and return to beginning of the line
    print(CSI + '2K' +  CSI + "1G")
  end
  def clear_line_before # Erase from the beginning of the line up to and including the current cursor position.
    print(CSI + '1K')
  end
  def clear_line_after # Erase from the current position (inclusive) to the end of the line
    print(CSI + '0K')
  end
  def scroll_up # Scroll display up one line
    print(ESC + 'M')
  end
  def scroll_down # Scroll display down one line
    print(ESC + 'D')
  end
  def clear_screen_down # Clear screen down from current row
    print(CSI + 'J')
  end
end

def getchr # Function to process key presses
  c = $stdin.getch
  case c
  when "\e"    # ANSI escape sequences (with only ESC, it should stop right here)
    return "ESC" if $stdin.ready? == nil
    case $stdin.getc
    when '['   # CSI
      case $stdin.getc  # Will get (or ASK) for more (remaining part of special character)
      when 'A' then chr = "UP"
      when 'B' then chr = "DOWN"
      when 'C' then chr = "RIGHT"
      when 'D' then chr = "LEFT"
      when 'Z' then chr = "S-TAB"
      when '2' then chr = "INS"    ; chr = "C-INS"    if $stdin.getc == "^"
      when '3' then chr = "DEL"    ; chr = "C-DEL"    if $stdin.getc == "^"
      when '5' then chr = "PgUP"   ; chr = "C-PgUP"   if $stdin.getc == "^"
      when '6' then chr = "PgDOWN" ; chr = "C-PgDOWN" if $stdin.getc == "^"
      when '7' then chr = "HOME"   ; chr = "C-HOME"   if $stdin.getc == "^"
      when '8' then chr = "END"    ; chr = "C-END"    if $stdin.getc == "^"
      else chr = ""
      end
    when 'O'   # Set Ctrl+ArrowKey equal to ArrowKey; May be used for other purposes in the future
      case $stdin.getc
      when 'a' then chr = "C-UP"
      when 'b' then chr = "C-DOWN"
      when 'c' then chr = "C-RIGHT"
      when 'd' then chr = "C-LEFT"
      else chr = ""
      end
    end
  when "", "" then chr = "BACK"
  when "" then chr = "C-A"
  when "" then chr = "C-B"
  when "" then chr = "C-C"
  when "^D" then chr = "C-D"
  when "" then chr = "C-E"
  when "" then chr = "C-F"
  when "^G" then chr = "C-G"
  when "	" then chr = "C-I"
  when " " then chr = "C-J"
  when "" then chr = "C-K"
  when "" then chr = "C-L"
  when "" then chr = "C-M"
  when "^N" then chr = "C-N"
  when "^O" then chr = "C-O"
  when "^P" then chr = "C-P"
  when "" then chr = "C-Q"
  when "" then chr = "C-R"
  when "^T" then chr = "C-T"
  when "" then chr = "C-U"
  when "" then chr = "C-V"
  when "" then chr = "C-X"
  when "" then chr = "C-Y"
  when "" then chr = "C-Z"
  when "" then chr = "WBACK"
  when "\r" then chr = "ENTER"
  when "\t" then chr = "TAB"
  when "" then chr = "C-S"
  when /[[:print:]]/  then chr = c
  else chr = ""
  end
  return chr
end

# vim: set sw=2 sts=2 et filetype=ruby fdm=syntax fdn=2 fcs=fold\:\ :

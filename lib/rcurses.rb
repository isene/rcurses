# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby, best viewed in VIM
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    1.2: Handling original newlines with ansi carry-over

require 'io/console'
require 'io/wait'

class String 
  # Add coloring to strings (with escaping for Readline)
  def fg(fg);     color(self, "\e[38;5;#{fg}m", "\e[0m"); end   # Foreground color code
  def bg(bg);     color(self, "\e[48;5;#{bg}m", "\e[0m"); end   # Background color code
  def fb(fg, bg); color(self, "\e[38;5;#{fg};48;5;#{bg}m"); end # Fore/Background color code
  def b;          color(self, "\e[1m", "\e[22m"); end           # Bold
  def i;          color(self, "\e[3m", "\e[23m"); end           # Italic
  def u;          color(self, "\e[4m", "\e[24m"); end           # Underline
  def l;          color(self, "\e[5m", "\e[25m"); end           # Blink
  def r;          color(self, "\e[7m", "\e[27m"); end           # Reverse
  def color(text, sp, ep) "#{sp}#{text}#{ep}" end                             # Internal function
  def c(code) # Use format "TEST".c("204,45,bui") to print "TEST" in bold, underline italic, fg=204 and bg=45 
    prop  = "\e["
    prop += "38;5;#{code.match(/^\d+/).to_s};"      if code.match(/^\d+/) 
    prop += "48;5;#{code.match(/(?<=,)\d+/).to_s};" if code.match(/(?<=,)\d+/) 
    prop += "1;" if code.match(/b/) 
    prop += "3;" if code.match(/i/) 
    prop += "4;" if code.match(/u/) 
    prop += "5;" if code.match(/l/) 
    prop += "7;" if code.match(/r/) 
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

module Rcurses
  module Cursor 
    # Terminal cursor movement ANSI codes (inspired by https://github.com/piotrmurach/tty-cursor)
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
  module Rinput
    def getchr 
      # Function to process key presses
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
      when "\r" then chr = "ENTER"
      when "\t" then chr = "TAB"
      when "", "" then chr = "BACK"
      when "" then chr = "C-A"
      when "" then chr = "C-B"
      when "" then chr = "C-C"
      when "^D" then chr = "C-D"
      when "" then chr = "C-E"
      when "" then chr = "C-F"
      when "^G" then chr = "C-G"
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
      when "" then chr = "C-S"
      when /[[:print:]]/  then chr = c
      else chr = ""
      end
      return chr
    end
  end
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
    end
    def move (x,y)
      @startx = @x + x
      @starty = @y + y
      self.refresh
    end
    def refresh(cont=@text)
      # Define the core of the ansi escape sequence handling
      def split_line_with_ansi(line, w)
        # Define opening and closing sequences
        open_sequences = {
          "\e[1m" => "\e[22m",
          "\e[3m" => "\e[23m",
          "\e[4m" => "\e[24m",
          "\e[5m" => "\e[25m",
          "\e[7m" => "\e[27m" }
        # All known closing sequences
        close_sequences = open_sequences.values + ["\e[0m"]
        # Regex to match ANSI escape sequences
        ansi_regex = /\e\[[0-9;]*m/
        result = []
        # Tokenize the line into ANSI sequences and plain text
        tokens = line.scan(/(\e\[[0-9;]*m|[^\e]+)/).flatten.compact
        current_line = ''
        current_line_length = 0
        active_sequences = []
        tokens.each do |token|
          if token.match?(ansi_regex)
            # It's an ANSI sequence
            current_line << token
            if close_sequences.include?(token)
              # It's a closing sequence
              if token == "\e[0m"
                # Reset all sequences
                active_sequences.clear
              else
                # Remove the corresponding opening sequence
                corresponding_open = open_sequences.key(token)
                active_sequences.delete(corresponding_open)
              end
            else
              # It's an opening sequence (or any other ANSI sequence)
              active_sequences << token
            end
          else
            # It's plain text, split into words and spaces
            words = token.scan(/\S+\s*/)
            words.each do |word|
              word_length = word.gsub(ansi_regex, '').length
              if current_line_length + word_length <= w
                # Append word to current line
                current_line << word
                current_line_length += word_length
              else
                # Word doesn't fit in the current line
                if current_line_length > 0
                  # Finish the current line and start a new one
                  result << current_line
                  # Start new line with active ANSI sequences
                  current_line = active_sequences.join
                  current_line_length = 0
                end
                # Handle long words that might need splitting
                while word_length > w
                  # Split the word
                  part = word[0, w]
                  current_line << part
                  result << current_line
                  # Update word and lengths
                  word = word[w..-1]
                  word_length = word.gsub(ansi_regex, '').length
                  # Start new line
                  current_line = active_sequences.join
                  current_line_length = 0
                end
                # Append any remaining part of the word
                if word_length > 0
                  current_line << word
                  current_line_length += word_length
                end
              end
            end
          end
        end
        # Append any remaining text in the current line
        result << current_line unless current_line.empty?
        result
      end
      # Define the main textformat function
      def textformat
        # Split the text by '\n'
        lines = @text.split("\n")
        result = []
        lines.each do |line|
          split_lines = split_line_with_ansi(line, @w)
          result.concat(split_lines)
        end
        result
      end
      # THEN START DOING THE ACTUAL REFRESH
      o_row, o_col = @c.pos
      @x = eval(@startx.to_s)
      @y = eval(@starty.to_s)
      @w = eval(@width.to_s)
      @h = eval(@height.to_s)
      if @border # Keep panes inside screen
        @w = MAXw - 2 if @w > MAXw - 2
        @h = MAXh - 2 if @h > MAXh - 2
        @x = 2 if @x < 2; @x = MAXw - @w if @x + @w > MAXw
        @y = 2 if @y < 2; @y = MAXh - @h if @y + @h > MAXh
      else
        @w = MAXw if @w > MAXw
        @h = MAXh if @h > MAXh
        @x = 1 if @x < 1; @x = MAXw - @w + 1 if @x + @w > MAXw + 1
        @y = 1 if @y < 1; @y = MAXh - @h + 1 if @y + @h > MAXh + 1
      end
      @c.col(@x); @c.row(@y) # Cursor to start of pane
      fmt = @fg.to_s + "," + @bg.to_s # Format for printing in pane (fg,bg)
      @txt = cont.split("\n") # Split text into array
      @txt = self.textformat if @txt.any? { |line| line.pure.length >= @w } # Splitx for lines breaking width
      @ix = @txt.length - 1 if @ix > @txt.length - 1; @ix = 0 if @ix < 0 # Ensuring no out-of-bounds
      @h.times do |i| # Print pane content
        l = @ix + i # The current line to be printed
        if @txt[l].to_s != "" # Print the text line for line
          # Get padding width and half width
          pl = @w - @txt[l].pure.length
          pl = 0 if pl < 0
          hl = pl/2 
          print @txt[l].c(fmt) + " ".c(fmt) * pl if @align == "l"
          print " ".c(fmt) * pl + @txt[l].c(fmt) if @align == "r"
          print " ".c(fmt) * hl + @txt[l].c(fmt) + " ".c(fmt) * (pl - hl) if @align == "c"
        else
          print  "".rjust(@w).bg(@bg)
        end
        @c.col(@x) # Cursor to start of pane
        @c.row(@y + i + 1)
      end
      if @ix > 0 and @scroll # Print "more" marker at top
        @c.col(@x + @w - 1); @c.row(@y)
        print "▲".c(fmt)
      end
      if @txt.length - @ix > @h and @scroll # Print bottom "more" marker
        @c.col(@x + @w - 1); @c.row(@y + @h - 1)
        print "▼".c(fmt)
      end
      if @border # Print border if @border is set to "true"
        @c.row(@y - 1); @c.col(@x - 1)
        print ("┌" + "─" * @w + "┐").c(fmt) 
        @h.times do |i|
          @c.row(@y + i); @c.col(@x - 1)
          print "│".c(fmt)  
          @c.col(@x + @w)
          print "│".c(fmt)
        end
        @c.row(@y + @h); @c.col(@x - 1)
        print ("└" + "─" * @w + "┘").c(fmt) 
      end
      @c.row(o_row)
      @c.col(o_col)
      @txt
    end
    def right
      if @pos < @txt[@ix + @line].length
        @pos += 1 
        if @pos == @w 
          @pos = 0
          if @line == @h - 1
            @ix += 1
          else
            @line += 1
          end
        end
      else
        if @line == @h
          @ix += 1 unless @ix >= @txt.length
          @pos = 0
        elsif @line + @ix + 2 <= @txt.length
          @line += 1
          @pos = 0
        end
      end
    end
    def left
    if @pos == 0
      if @line == 0
          unless @ix == 0
            @ix -= 1 
            @pos = @txt[@ix + @line].length - 1
          end
        else
          @line -= 1
          @pos = @txt[@ix + @line].length - 1
        end
      else
        @pos -= 1
      end
    end
    def up
      if @line == 0
        @ix -= 1 unless @ix == 0
      else
        @line -= 1
      end
      begin
        @pos = @txt[@ix + @line].length - 1 if @pos > @txt[@ix + @line].length - 1
      rescue
      end
    end
    def down
      if @line == @h - 1
        @ix += 1 unless @ix + @line >= @txt.length - 1
      elsif @line + @ix + 2 <= @txt.length
        @line += 1
      end
      begin
        @pos = @txt[@ix + @line].length - 1 if @pos > @txt[@ix + @line].length - 1
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
      `stty raw -echo`
      cont = @text.pure.gsub(/\n/, "¬\n") 
      @line = @ix
      @pos  = 0
      chr   = ""
      while chr != "ESC" # Keep going with readline until user presses ESC
        @txt = self.refresh(cont)
        @c.row(@y + @line)
        @c.col(@x + @pos)
        chr = getchr
        case chr
        when 'C-L'    # Left justify
          @align = "l"
        when 'C-R'    # Right Justify
          @align = "r"
        when 'C-C'    # Center justify
          @align = "c"
        when 'C-Y'    # Copy pane content to clipboard
          system("echo '#{@text.pure}' | xclip")
        when 'C-S'    # Save edited text back to @text
          cont = cont.gsub("¬", "\n")
          cont = parse(cont)
          @text = cont
          chr = "ESC"
        when 'DEL'    # Delete character
          posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
          cont[posx] = ""
        when 'BACK'   # Backspace
          left
          posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
          cont[posx] = ""
        when 'WBACK'  # Word backspace
          posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
          until cont[posx - 1] == " " or @pos == 0
            left
            posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
            cont[posx] = ""
          end
        when 'C-K'    # Kill line
          begin
            prev_l = 0
            line_c = @ix + @line
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
          @pos = @txt[@ix + @line].length - 1
        when 'C-HOME' # Start of pane
          @line = 0
          @pos = 0
        when 'C-END'  # End of pane
        when 'ENTER'
          posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
          cont.insert(posx,"¬\n")
          right
        when /^.$/
          posx = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
          cont.insert(posx,chr)
        end
        charx = 1
        posx  = 0; (@ix + @line).times {|i| posx += @txt[i].length}; posx += @pos
        while $stdin.ready?
          chr = $stdin.getc
          charx += 1
          posx  += 1
          cont.insert(posx,chr)
        end
        if chr =~ /^.$/
          charx.times do 
            self.refresh(cont)
            right
          end
        end
      end
      @c.row(nil); @c.col(nil) # Keep?
      `stty -raw echo`
    end
    def editline
      `stty raw -echo`
      @x = eval(@startx.to_s)
      @y = eval(@starty.to_s)
      @w = eval(@width.to_s)
      @h = eval(@height.to_s)
      @x = 1 if @x < 1; @x = MAXw - @w + 1 if @x + @w > MAXw + 1
      @y = 1 if @y < 1; @y = MAXh - @h + 1 if @y + @h > MAXh + 1
      @scroll = false
      @c.row(@y)
      fmt = @fg.to_s + "," + @bg.to_s   # Format for printing in pane (fg,bg)
      @c.col(@x); print @prompt.c(fmt)  # Print prompt from start of pane
      pl    = @prompt.pure.length           # Prompt length
      cl    = @w - pl                       # Available content length
      cont  = @text.pure                    # Actual content
      @pos  = cont.length                       # Initial position set at end of content
      chr   = ""                                # Initialize chr
      while chr != "ESC"                        # Keep going with readline until user presses ESC
        @c.col(@x + pl)                     # Set cursor at start of content
        cont = cont.slice(0,cl)                 # Trim content to max length
        print cont.ljust(cl).c(fmt)             # Print content left justified to max length
        @c.col(@x + pl + @pos)              # Set cursor to current position (@pos)
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
        when 'ENTER'                            # Save content to @text and end
          @text = parse(cont)
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
      @c.row(nil); @c.col(nil) # Keep?
      `stty -raw echo`
    end
  end
  cursor = Cursor
  cursor.row(8000); cursor.col(8000) # Set for maxrow/maxcol
  MAXh, MAXw = cursor.pos
end

include Rcurses::Rinput

# vim: set sw=2 sts=2 et filetype=ruby fdm=syntax fdn=2 fcs=fold\:\ :

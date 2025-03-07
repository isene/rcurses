module Rcurses
  class Pane
    require 'clipboard'  # Ensure the 'clipboard' gem is installed
    include Cursor
    include Input
    attr_accessor :startx, :starty, :width, :height, :fg, :bg
    attr_accessor :x, :y, :w, :h
    attr_accessor :border, :scroll, :text, :ix, :align, :prompt

    def initialize(startx = 1, starty = 1, width = 1, height = 1, fg = nil, bg = nil)
      # Using Procs or Lambdas instead of eval
      @startx  = startx.is_a?(Proc) ? startx : -> { startx }
      @starty  = starty.is_a?(Proc) ? starty : -> { starty }
      @width   = width.is_a?(Proc)  ? width  : -> { width  }
      @height  = height.is_a?(Proc) ? height : -> { height }
      @fg, @bg = fg, bg
      @text    = ""              # Initialize text variable
      @align   = "l"             # Default alignment
      @scroll  = true            # Initialize scroll indicators to true
      @prompt  = ""              # Initialize prompt for editline
      @ix      = 0               # Text index (starting text line in pane)
      @max_h, @max_w = IO.console.winsize
    end

    def move(x, y)
      @startx = -> { @x + x }
      @starty = -> { @y + y }
      refresh
    end

    def refresh(cont = @text)
      @max_h, @max_w = IO.console.winsize

      # Define the core of the ANSI escape sequence handling
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
      def textformat(cont)
        # Split the content by '\n'
        lines = cont.split("\n")
        result = []
        lines.each do |line|
          split_lines = split_line_with_ansi(line, @w)
          result.concat(split_lines)
        end
        result
      end

      # Start the actual refresh
      o_row, o_col = pos
      @x = @startx.call
      @y = @starty.call
      @w = @width.call
      @h = @height.call

      # Adjust pane dimensions and positions
      if @border # Keep panes inside screen
        @w = @max_w - 2 if @w > @max_w - 2
        @h = @max_h - 2 if @h > @max_h - 2
        @x = 2 if @x < 2; @x = @max_w - @w if @x + @w > @max_w
        @y = 2 if @y < 2; @y = @max_h - @h if @y + @h > @max_h
      else
        @w = @max_w if @w > @max_w
        @h = @max_h if @h > @max_h
        @x = 1 if @x < 1; @x = @max_w - @w + 1 if @x + @w > @max_w + 1
        @y = 1 if @y < 1; @y = @max_h - @h + 1 if @y + @h > @max_h + 1
      end

      col(@x); row(@y) # Cursor to start of pane
      fmt = [@fg, @bg].compact.join(',') # Format for printing in pane (fg,bg)
      @txt = cont.split("\n") # Split content into array
      @txt = textformat(cont) if @txt.any? { |line| line.pure.length >= @w } # Reformat lines if necessary
      @ix = @txt.length - 1 if @ix > @txt.length - 1; @ix = 0 if @ix < 0 # Ensure no out-of-bounds

      @h.times do |i| # Print pane content
        l = @ix + i # The current line to be printed
        if @txt[l].to_s != "" # Print the text line
          # Get padding width and half width
          pl = @w - @txt[l].pure.length
          pl = 0 if pl < 0
          hl = pl / 2
          case @align
          when "l"
            print @txt[l].c(fmt) + " ".c(fmt) * pl
          when "r"
            print " ".c(fmt) * pl + @txt[l].c(fmt)
          when "c"
            print " ".c(fmt) * hl + @txt[l].c(fmt) + " ".c(fmt) * (pl - hl)
          end
        else
          print " ".c(fmt) * @w
        end
        col(@x) # Cursor to start of pane
        row(@y + i + 1)
      end

      if @ix > 0 and @scroll # Print "more" marker at top
        col(@x + @w - 1); row(@y)
        print "▲".c(fmt)
      end

      if @txt.length - @ix > @h and @scroll # Print bottom "more" marker
        col(@x + @w - 1); row(@y + @h - 1)
        print "▼".c(fmt)
      end

      if @border # Print border if @border is set to true
        row(@y - 1); col(@x - 1)
        print ("┌" + "─" * @w + "┐").c(fmt)
        @h.times do |i|
          row(@y + i); col(@x - 1)
          print "│".c(fmt)
          col(@x + @w)
          print "│".c(fmt)
        end
        row(@y + @h); col(@x - 1)
        print ("└" + "─" * @w + "┘").c(fmt)
      end

      row(o_row)
      col(o_col)
      @txt
    end

    def textformat(cont)
      # Split the content by '\n'
      lines = cont.split("\n")
      result = []
      lines.each do |line|
        split_lines = split_line_with_ansi(line, @w)
        result.concat(split_lines)
      end
      result
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
        if @line == @h - 1
          @ix += 1 unless @ix >= @txt.length - @h
          @pos = 0
        elsif @line + @ix + 1 < @txt.length
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
            @pos = @txt[@ix + @line].length
          end
        else
          @line -= 1
          @pos = @txt[@ix + @line].length
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
        @pos = [@pos, @txt[@ix + @line].length].min
      rescue
      end
    end
    def down
      if @line == @h - 1
        @ix += 1 unless @ix + @line >= @txt.length - 1
      elsif @line + @ix + 1 < @txt.length
        @line += 1
      end
      begin
        @pos = [@pos, @txt[@ix + @line].length].min
      rescue
      end
    end

    def parse(cont)
      cont.gsub!(/\*(.+?)\*/,           '\1'.b)
      cont.gsub!(/\/(.+?)\//,           '\1'.i)
      cont.gsub!(/_(.+?)_/,             '\1'.u)
      cont.gsub!(/#(.+?)#/,             '\1'.r)
      cont.gsub!(/<([^|]+)\|([^>]+)>/) do
        text = $2; codes = $1
        text.c(codes)
      end
      cont
    end

    def edit
      begin
        # Switch to raw mode without echoing input
        STDIN.raw!
        Rcurses::Cursor.show
        # Prepare content for editing, replacing newlines with a placeholder
        content = @text.pure.gsub("\n", "¬\n")
        # Initialize cursor position and indices
        @ix        = 0   # Starting index of text lines displayed in the pane
        @line      = 0   # Current line number relative to the pane's visible area
        @pos       = 0   # Position within the current line (character index)
        @txt       = refresh(content)
        input_char = ''

        while input_char != 'ESC'  # Continue until ESC is pressed
          row(@y + @line)          # Move cursor to the correct row
          col(@x + @pos)           # Move cursor to the correct column

          input_char = getchr      # Read user input
          case input_char
          when 'C-L'    # Left justify
            @align = 'l'
          when 'C-R'    # Right justify
            @align = 'r'
          when 'C-C'    # Center justify
            @align = 'c'
          when 'C-Y'    # Copy pane content to clipboard
            Clipboard.copy(@text.pure)
          when 'C-S'    # Save edited text back to @text and exit
            content = content.gsub('¬', "\n")
            content = parse(content)
            @text = content
            input_char = 'ESC'
          when 'DEL'    # Delete character at current position
            posx = calculate_posx
            content.slice!(posx)
          when 'BACK'   # Backspace (delete character before current position)
            if @pos > 0
              left
              posx = calculate_posx
              content.slice!(posx)
            end
          when 'WBACK'  # Word backspace
            while @pos > 0 && content[calculate_posx - 1] != ' '
              left
              posx = calculate_posx
              content.slice!(posx)
            end
          when 'C-K'    # Kill line (delete from cursor to end of line)
            line_start_pos = calculate_line_start_pos
            line_length = @txt[@ix + @line]&.length || 0
            content.slice!(line_start_pos + @pos, line_length - @pos)
          when 'UP'     # Move cursor up one line
            up
          when 'DOWN'   # Move cursor down one line
            down
          when 'RIGHT'  # Move cursor right one character
            right
          when 'LEFT'   # Move cursor left one character
            left
          when 'HOME'   # Move to start of line
            @pos = 0
          when 'END'    # Move to end of line
            current_line_length = @txt[@ix + @line]&.length || 0
            @pos = current_line_length
          when 'C-HOME' # Move to start of pane
            @ix = 0
            @line = 0
            @pos = 0
          when 'C-END'  # Move to end of pane
            total_lines = @txt.length
            @ix = [total_lines - @h, 0].max
            @line = [@h - 1, total_lines - @ix - 1].min
            current_line_length = @txt[@ix + @line]&.length || 0
            @pos = current_line_length
          when 'ENTER'  # Insert newline at current position
            posx = calculate_posx
            content.insert(posx, "¬\n")
            right
          when /^.$/    # Insert character at current position
            posx = calculate_posx
            content.insert(posx, input_char)
            right
          else
            # Handle unrecognized input if necessary
          end

          # Handle pasted input (additional characters in the buffer)
          while IO.select([$stdin], nil, nil, 0)
            input_char = $stdin.read_nonblock(1) rescue nil
            break unless input_char
            posx = calculate_posx
            content.insert(posx, input_char)
            right
          end

          @txt = refresh(content)  # Refresh the pane with the current content
        end
      ensure
        # Restore terminal mode
        STDIN.cooked!
      end
      Rcurses::Cursor.hide
    end

    def editline
      begin
        # Switch to raw mode without echo
        STDIN.raw!
        Rcurses::Cursor.show

        # Initialize position and dimensions
        @x = @startx.call
        @y = @starty.call
        @w = @width.call
        @h = @height.call
        # Ensure pane is within screen bounds
        @x = [[@x, 1].max, @max_w - @w + 1].min
        @y = [[@y, 1].max, @max_h - @h + 1].min

        @scroll = false
        row(@y)

        fmt = [@fg, @bg].compact.join(',')
        col(@x)
        print @prompt.c(fmt)  # Print prompt at the pane's starting position

        prompt_len = @prompt.pure.length
        content_len = @w - prompt_len
        cont = @text.pure.slice(0, content_len)
        @pos = cont.length  # Set initial cursor position at the end of content
        chr = ''

        while chr != 'ESC'  # Continue until ESC is pressed
          col(@x + prompt_len)  # Set cursor at start of content
          cont = cont.slice(0, content_len)  # Trim content to max length
          print cont.ljust(content_len).c(fmt)  # Print content, left-justified
          col(@x + prompt_len + @pos)  # Set cursor to current position

          chr = getchr  # Read user input
          case chr
          when 'LEFT'
            @pos -= 1 if @pos > 0
          when 'RIGHT'
            @pos += 1 if @pos < cont.length
          when 'HOME'
            @pos = 0
          when 'END'
            @pos = cont.length
          when 'DEL'
            cont[@pos] = '' if @pos < cont.length
          when 'BACK'
            if @pos > 0
              @pos -= 1
              cont[@pos] = ''
            end
          when 'WBACK'
            while @pos > 0 && cont[@pos - 1] != ' '
              @pos -= 1
              cont[@pos] = ''
            end
          when 'C-K'
            cont = ''
            @pos = 0
          when 'ENTER'
            @text = parse(cont)
            chr = 'ESC'
          when /^.$/
            if @pos < content_len
              cont.insert(@pos, chr)
              @pos += 1
            end
          end

          # Handle pasted input
          while IO.select([$stdin], nil, nil, 0)
            chr = $stdin.read_nonblock(1) rescue nil
            break unless chr
            if @pos < content_len
              cont.insert(@pos, chr)
              @pos += 1
            end
          end
        end
      ensure
        # Restore terminal mode
        STDIN.cooked!
      end
      Rcurses::Cursor.hide
    end

    private

    # Calculates the position in the content string corresponding to the current cursor position
    def calculate_posx
      total_length = 0
      (@ix + @line).times do |i|
        total_length += @txt[i].pure.length + 1  # +1 for the newline character
      end
      total_length += @pos
      total_length
    end
    # Calculates the starting position of the current line in the content string
    def calculate_line_start_pos
      total_length = 0
      (@ix + @line).times do |i|
        total_length += @txt[i].pure.length + 1  # +1 for the newline character
      end
      total_length
    end
  end
end


module Rcurses
  class Pane
    require 'clipboard'  # Ensure the 'clipboard' gem is installed
    include Cursor
    include Input
    attr_accessor :x, :y, :w, :h, :fg, :bg
    attr_accessor :border, :scroll, :text, :ix, :align, :prompt
    attr_accessor :moreup, :moredown

    def initialize(x = 1, y = 1, w = 1, h = 1, fg = nil, bg = nil)
      @max_h, @max_w = IO.console.winsize
      @x       = x
      @y       = y
      @w       = w
      @h       = h
      @fg, @bg = fg, bg
      @text    = ""     # Initialize text variable
      @align   = "l"    # Default alignment
      @scroll  = true   # Enable scroll indicators
      @prompt  = ""     # Prompt for editline
      @ix      = 0      # Starting text line index
      @prev_frame = nil # Holds the previously rendered frame (array of lines)
      @line = 0         # For cursor tracking during editing:
      @pos  = 0         # For cursor tracking during editing:
    end

    def move(dx, dy)
      @x += dx
      @y += dy
      refresh
    end

    def ask(prompt, text)
      @prompt = prompt
      @text   = text
      editline
      @text
    end

    def puts(text)
      @text = text
      @ix   = 0
      refresh
    end

    def linedown
      @ix += 1
      @ix = @text.split("\n").length if @ix > @text.split("\n").length - 1
      refresh
    end

    def lineup
      @ix -= 1
      @ix = 0 if @ix < 0
      refresh
    end

    def pagedown
      @ix = @ix + @h - 1
      @ix = @text.split("\n").length - @h if @ix > @text.split("\n").length - @h
      refresh
    end

    def pageup
      @ix = @ix - @h + 1
      @ix = 0 if @ix < 0
      refresh
    end

    def bottom
      @ix = @text.split("\n").length - @h
      refresh
    end

    def top
      @ix = 0
      refresh
    end

    # Diff-based refresh that minimizes flicker.
    # Building a frame (an array of lines) that includes borders (if enabled).
    # Content lines are wrapped in vertical border characters when @border is true.
    def refresh(cont = @text)
      @max_h, @max_w = IO.console.winsize

      # Adjust pane dimensions and positions.
      if @border
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

      # Save current cursor position.
      o_row, o_col = pos

      STDOUT.print "\e[?25l"  # Hide cursor

      fmt = [@fg, @bg].compact.join(',')
      @txt = cont.split("\n")
      @txt = textformat(cont) if @txt.any? { |line| line.pure.length >= @w }
      @ix = @txt.length - 1 if @ix > @txt.length - 1
      @ix = 0 if @ix < 0

      # Build the new frame as an array of strings.
      new_frame = []
      if @border
        # Top border spans (@w + 2) characters.
        top_border = ("┌" + "─" * @w + "┐").c(fmt)
        new_frame << top_border
      end

      # Build content lines.
      content_rows = @h
      content_rows.times do |i|
        line_str = ""
        l = @ix + i
        if @txt[l].to_s != ""
          pl = @w - @txt[l].pure.length
          pl = 0 if pl < 0
          hl = pl / 2
          case @align
          when "l"
            line_str = @txt[l].c(fmt) + " ".c(fmt) * pl
          when "r"
            line_str = " ".c(fmt) * pl + @txt[l].c(fmt)
          when "c"
            line_str = " ".c(fmt) * hl + @txt[l].c(fmt) + " ".c(fmt) * (pl - hl)
          end
        else
          line_str = " ".c(fmt) * @w
        end

        # If border is enabled, add vertical border characters.
        if @border
          line_str = "│" + line_str + "│"
        end

        # Add scroll markers (overwrite the last character) if needed.
        if i == 0 and @ix > 0 and @scroll
          line_str[-1] = "∆".c(fmt)
          @moreup = true
        elsif i == content_rows - 1 and @txt.length - @ix > @h and @scroll
          line_str[-1] = "∇".c(fmt)
          @moredown = true
        else
          @moreup = false
          @moredown = false
        end
        new_frame << line_str
      end

      if @border
        # Bottom border.
        bottom_border = ("└" + "─" * @w + "┘").c(fmt)
        new_frame << bottom_border
      end

      # Diff-based update: update only lines that changed.
      diff_buf = ""
      new_frame.each_with_index do |line, i|
        # Determine row number:
        row_num = @border ? (@y - 1 + i) : (@y + i)
        # When border is enabled, all lines (including content) start at column (@x - 1)
        col_num = @border ? (@x - 1) : @x
        if @prev_frame.nil? || @prev_frame[i] != line ||
           (@border && (i == 0 || i == new_frame.size - 1))
          diff_buf << "\e[#{row_num};#{col_num}H" << line
        end
      end

      diff_buf << "\e[#{o_row};#{o_col}H"
      print diff_buf
      #STDOUT.print "\e[?25h"  # Show cursor - but use Cursor.show instead if needed

      @prev_frame = new_frame
      new_frame.join("\n")
    end

    def textformat(cont)
      lines = cont.split("\n")
      result = []
      lines.each do |line|
        split_lines = split_line_with_ansi(line, @w)
        result.concat(split_lines)
      end
      result
    end

    def puts(txt)
      @text = txt
      refresh
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
      cont.gsub!(/\*(.+?)\*/, '\1'.b)
      cont.gsub!(/\/(.+?)\//, '\1'.i)
      cont.gsub!(/_(.+?)_/, '\1'.u)
      cont.gsub!(/#(.+?)#/, '\1'.r)
      cont.gsub!(/<([^|]+)\|([^>]+)>/) do
        text = $2; codes = $1
        text.c(codes)
      end
      cont
    end

    def edit
      begin
        STDIN.raw!
        Rcurses::Cursor.show
        content = @text.pure.gsub("\n", "¬\n")
        @ix    = 0
        @line  = 0
        @pos   = 0
        @txt   = refresh(content)
        input_char = ''

        while input_char != 'ESC'
          row(@y + @line)
          col(@x + @pos)
          input_char = getchr
          case input_char
          when 'C-L'
            @align = 'l'
          when 'C-R'
            @align = 'r'
          when 'C-C'
            @align = 'c'
          when 'C-Y'
            Clipboard.copy(@text.pure)
          when 'C-S'
            content = content.gsub('¬', "\n")
            content = parse(content)
            @text = content
            input_char = 'ESC'
          when 'DEL'
            posx = calculate_posx
            content.slice!(posx)
          when 'BACK'
            if @pos > 0
              left
              posx = calculate_posx
              content.slice!(posx)
            end
          when 'WBACK'
            while @pos > 0 && content[calculate_posx - 1] != ' '
              left
              posx = calculate_posx
              content.slice!(posx)
            end
          when 'C-K'
            line_start_pos = calculate_line_start_pos
            line_length = @txt[@ix + @line]&.length || 0
            content.slice!(line_start_pos + @pos, line_length - @pos)
          when 'UP'
            up
          when 'DOWN'
            down
          when 'RIGHT'
            right
          when 'LEFT'
            left
          when 'HOME'
            @pos = 0
          when 'END'
            current_line_length = @txt[@ix + @line]&.length || 0
            @pos = current_line_length
          when 'C-HOME'
            @ix = 0
            @line = 0
            @pos = 0
          when 'C-END'
            total_lines = @txt.length
            @ix = [total_lines - @h, 0].max
            @line = [@h - 1, total_lines - @ix - 1].min
            current_line_length = @txt[@ix + @line]&.length || 0
            @pos = current_line_length
          when 'ENTER'
            posx = calculate_posx
            content.insert(posx, "¬\n")
            right
          when /^.$/
            posx = calculate_posx
            content.insert(posx, input_char)
            right
          end

          while IO.select([$stdin], nil, nil, 0)
            input_char = $stdin.read_nonblock(1) rescue nil
            break unless input_char
            posx = calculate_posx
            content.insert(posx, input_char)
            right
          end

          @txt = refresh(content)
        end
      ensure
        STDIN.cooked!
      end
      Rcurses::Cursor.hide
    end

    def editline
      begin
        STDIN.raw!
        Rcurses::Cursor.show
        @x = [[@x, 1].max, @max_w - @w + 1].min
        @y = [[@y, 1].max, @max_h - @h + 1].min
        @scroll = false
        @ix = 0
        row(@y)
        fmt = [@fg, @bg].compact.join(',')
        col(@x)
        print @prompt.c(fmt)
        prompt_len = @prompt.pure.length
        content_len = @w - prompt_len
        cont = @text.pure.slice(0, content_len)
        @pos = cont.length
        chr = ''

        while chr != 'ESC'
          col(@x + prompt_len)
          cont = cont.slice(0, content_len)
          print cont.ljust(content_len).c(fmt)
          col(@x + prompt_len + @pos)
          chr = getchr
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
        STDIN.cooked!
      end
      Rcurses::Cursor.hide
    end

    private

    def flush_stdin
      while IO.select([$stdin], nil, nil, 0.005)
        begin
          $stdin.read_nonblock(1024)
        rescue IO::WaitReadable, EOFError
          break
        end
      end
    end

    def calculate_posx
      total_length = 0
      (@ix + @line).times do |i|
        total_length += @txt[i].pure.length + 1  # +1 for newline
      end
      total_length += @pos
      total_length
    end

    def calculate_line_start_pos
      total_length = 0
      (@ix + @line).times do |i|
        total_length += @txt[i].pure.length + 1
      end
      total_length
    end

    def split_line_with_ansi(line, w)
      open_sequences = {
        "\e[1m" => "\e[22m",
        "\e[3m" => "\e[23m",
        "\e[4m" => "\e[24m",
        "\e[5m" => "\e[25m",
        "\e[7m" => "\e[27m"
      }
      close_sequences = open_sequences.values + ["\e[0m"]
      ansi_regex = /\e\[[0-9;]*m/
      result = []
      tokens = line.scan(/(\e\[[0-9;]*m|[^\e]+)/).flatten.compact
      current_line = ''
      current_line_length = 0
      active_sequences = []
      tokens.each do |token|
        if token.match?(ansi_regex)
          current_line << token
          if close_sequences.include?(token)
            if token == "\e[0m"
              active_sequences.clear
            else
              corresponding_open = open_sequences.key(token)
              active_sequences.delete(corresponding_open)
            end
          else
            active_sequences << token
          end
        else
          words = token.scan(/\s+|\S+/)
          words.each do |word|
            word_length = word.gsub(ansi_regex, '').length
            if current_line_length + word_length <= w
              current_line << word
              current_line_length += word_length
            else
              if current_line_length > 0
                result << current_line
                current_line = active_sequences.join
                current_line_length = 0
              end
              while word_length > w
                part = word[0, w]
                current_line << part
                result << current_line
                word = word[w..-1]
                word_length = word.gsub(ansi_regex, '').length
                current_line = active_sequences.join
                current_line_length = 0
              end
              if word_length > 0
                current_line << word
                current_line_length += word_length
              end
            end
          end
        end
      end
      result << current_line unless current_line.empty?
      result
    end
  end
end


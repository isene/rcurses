module Rcurses
  class Pane
    require 'clipboard'  # Ensure the 'clipboard' gem is installed
    include Cursor
    include Input
    attr_accessor :x, :y, :w, :h, :fg, :bg
    attr_accessor :border, :scroll, :text, :ix, :align, :prompt
    attr_accessor :moreup, :moredown

    def initialize(x = 1, y = 1, w = 1, h = 1, fg = nil, bg = nil)
      @x       = x
      @y       = y
      @w       = w
      @h       = h
      @fg, @bg = fg, bg
      @text    = ""              # Initialize text variable
      @align   = "l"             # Default alignment
      @scroll  = true            # Enable scroll indicators
      @prompt  = ""              # Prompt for editline
      @ix      = 0               # Starting text line index
      @max_h, @max_w = IO.console.winsize
    end

    def move(x, y)
      @x += x
      @y += y
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

    # Optimized refresh using double buffering to minimize flicker.
    def refresh(cont = @text)
      @max_h, @max_w = IO.console.winsize

      # Adjust pane dimensions (unchanged logic)
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

      # Hide cursor and switch to alternate screen buffer (if desired). Hide it any case and use Curses.show to bring it back.
      # Note: The alternate screen buffer means your program’s output won’t mix with the normal terminal content.
      STDOUT.print "\e[?25l"  # hide cursor
      # Uncomment the next line to use the alternate screen buffer.
      #STDOUT.print "\e[?1049h"

      buf = ""
      buf << "\e[#{@y};#{@x}H"  # Move cursor to start of pane.
      fmt = [@fg, @bg].compact.join(',')
      @txt = cont.split("\n")
      @txt = textformat(cont) if @txt.any? { |line| line.pure.length >= @w }
      @ix = @txt.length - 1 if @ix > @txt.length - 1
      @ix = 0 if @ix < 0

      @h.times do |i|
        l = @ix + i
        if @txt[l].to_s != ""
          pl = @w - @txt[l].pure.length
          pl = 0 if pl < 0
          hl = pl / 2
          case @align
          when "l"
            buf << @txt[l].c(fmt) << " ".c(fmt) * pl
          when "r"
            buf << " ".c(fmt) * pl << @txt[l].c(fmt)
          when "c"
            buf << " ".c(fmt) * hl << @txt[l].c(fmt) << " ".c(fmt) * (pl - hl)
          end
        else
          buf << " ".c(fmt) * @w
        end
        buf << "\e[#{@y + i + 1};#{@x}H"  # Next line.
      end

      # Draw scroll markers.
      if @ix > 0 and @scroll
        buf << "\e[#{@y};#{@x + @w - 1}H" << "∆".c(fmt)
        @moreup = true
      else
        @moreup = false
      end

      if @txt.length - @ix > @h and @scroll
        buf << "\e[#{@y + @h - 1};#{@x + @w - 1}H" << "∇".c(fmt)
        @moredown = true
      else
        @moredown = false
      end

      # Draw border if enabled.
      if @border
        buf << "\e[#{@y - 1};#{@x - 1}H" << ("┌" + "─" * @w + "┐").c(fmt)
        @h.times do |i|
          buf << "\e[#{@y + i};#{@x - 1}H" << "│".c(fmt)
          buf << "\e[#{@y + i};#{@x + @w}H" << "│".c(fmt)
        end
        buf << "\e[#{@y + @h};#{@x - 1}H" << ("└" + "─" * @w + "┘").c(fmt)
      end

      # Restore original cursor position.
      buf << "\e[#{o_row};#{o_col}H"

      # Print the whole buffer at once.
      print buf

      # Uncomment the next line to switched to the alternate screen buffer.
      #STDOUT.print "\e[?1049l"

      @txt
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
        total_length += @txt[i].pure.length + 1  # +1 for the newline
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


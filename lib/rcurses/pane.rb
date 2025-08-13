module Rcurses
  class Pane
    require 'clipboard'  # Ensure the 'clipboard' gem is installed
    include Cursor
    include Input
    attr_accessor :x, :y, :w, :h, :fg, :bg
    attr_accessor :border, :scroll, :text, :ix, :index, :align, :prompt
    attr_accessor :moreup, :moredown
    attr_accessor :record, :history

    def initialize(x = 1, y = 1, w = 1, h = 1, fg = nil, bg = nil)
      @max_h, @max_w = IO.console ? IO.console.winsize : [24, 80]
      @x          = x
      @y          = y
      @w          = w
      @h          = h
      @fg, @bg    = fg, bg
      @text       = ""     # Initialize text variable
      @align      = "l"    # Default alignment
      @scroll     = true   # Enable scroll indicators
      @prompt     = ""     # Prompt for editline
      @ix         = 0      # Starting text line index
      @prev_frame = nil    # Holds the previously rendered frame (array of lines)
      @line       = 0      # For cursor tracking during editing:
      @pos        = 0      # For cursor tracking during editing:
      @record     = false  # Don't record history unless explicitly set to true
      @history    = []     # History array
      @max_history_size = 100  # Limit history to prevent memory leaks
      
      ObjectSpace.define_finalizer(self, self.class.finalizer_proc)
    end

    def text=(new_text)
      if @record && @text
        @history << @text
        @history.shift while @history.size > @max_history_size
      end
      @text = new_text
    end

    def ask(prompt, text)
      @prompt = prompt
      @text   = text
      editline
      if @record && !@text.empty?
        @history << @text
        @history.shift while @history.size > @max_history_size
      end
      @text
    end 

    def say(text)
      if @record && !text.empty?
        @history << text
        @history.shift while @history.size > @max_history_size
      end
      @text = text
      @ix   = 0
      refresh 
    end 

    def clear
      @text = ""
      @ix   = 0
      full_refresh 
    end

    def cleanup
      @prev_frame = nil
      @lazy_txt = nil
      @raw_txt = nil
      @cached_text = nil
      @txt = nil
      @history.clear if @history
    end

    def self.finalizer_proc
      proc do
        # Cleanup code that doesn't reference instance variables
        # since the object is already being finalized
      end
    end

    def move(dx, dy)
      @x += dx
      @y += dy
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

    # full_refresh forces a complete repaint.
    def full_refresh(cont = @text)
      @prev_frame = nil
      refresh(cont)
    end

    # Refresh only the border
    def border_refresh
      left_col   = @x - 1
      right_col  = @x + @w
      top_row    = @y - 1
      bottom_row = @y + @h

      if @border
        fmt = [@fg.to_s, @bg.to_s].join(',')
        top = ("┌" + "─" * @w + "┐").c(fmt)
        STDOUT.print "\e[#{top_row};#{left_col}H" + top
        (0...@h).each do |i|
          row = @y + i
          STDOUT.print "\e[#{row};#{left_col}H"  + "│".c(fmt)
          STDOUT.print "\e[#{row};#{right_col}H" + "│".c(fmt)
        end
        bottom = ("└" + "─" * @w + "┘").c(fmt)
        STDOUT.print "\e[#{bottom_row};#{left_col}H" + bottom
      else
        STDOUT.print "\e[#{top_row};#{left_col}H" + " " * (@w + 2)
        (0...@h).each do |i|
          row = @y + i
          STDOUT.print "\e[#{row};#{left_col}H"  + " "
          STDOUT.print "\e[#{row};#{right_col}H" + " "
        end
        STDOUT.print "\e[#{bottom_row};#{left_col}H" + " " * (@w + 2)
      end
    end

    # Diff-based refresh that minimizes flicker.
    # In this updated version we lazily process only the raw lines required to fill the pane.
    def refresh(cont = @text)
      begin
        @max_h, @max_w = IO.console.winsize
      rescue => e
        # Fallback to reasonable defaults if terminal size can't be determined
        @max_h, @max_w = 24, 80
      end

      # Ensure minimum viable dimensions
      @max_h = [[@max_h, 3].max, 1000].min  # Between 3 and 1000 rows
      @max_w = [[@max_w, 10].max, 1000].min  # Between 10 and 1000 columns
      
      # Ensure pane dimensions are reasonable
      @w = [[@w, 1].max, @max_w].min
      @h = [[@h, 1].max, @max_h].min

      if @border
        @w = @max_w - 2 if @w > @max_w - 2
        @h = @max_h - 2 if @h > @max_h - 2
        @x = [[2, @x].max, @max_w - @w].min
        @y = [[2, @y].max, @max_h - @h].min
      else
        @w = @max_w if @w > @max_w
        @h = @max_h if @h > @max_h
        @x = [[1, @x].max, @max_w - @w + 1].min
        @y = [[1, @y].max, @max_h - @h + 1].min
      end

      begin
        o_row, o_col = pos
      rescue => e
        # Fallback cursor position
        o_row, o_col = 1, 1
      end

      # Hide cursor, disable auto-wrap, reset all SGR and scroll margins
      # (so stray underline, scroll regions, etc. can’t leak out)
      STDOUT.print "\e[?25l\e[?7l\e[0m\e[r"

      fmt = [@fg.to_s, @bg.to_s].join(',')
      
      # Skip color application if fg and bg are both nil or empty
      @skip_colors = (@fg.nil? && @bg.nil?) || (fmt == ",")
      

      # Lazy evaluation: If the content or pane width has changed, reinitialize the lazy cache.
      if !defined?(@cached_text) || @cached_text != cont || @cached_w != @w
        begin
          @raw_txt   = (cont || "").split("\n").map { |line| line.chomp("\r") }
          @lazy_txt  = []   # This will hold the processed (wrapped) lines as needed.
          @lazy_index = 0   # Pointer to the next raw line to process.
          @cached_text = (cont || "").dup
          @cached_w = @w
        rescue => e
          # Fallback if content processing fails
          @raw_txt = [""]
          @lazy_txt = []
          @lazy_index = 0
          @cached_text = ""
          @cached_w = @w
        end
      end

      content_rows = @h
      # Ensure we have processed enough lines for the current scroll position + visible area.
      required_lines = @ix + content_rows + 50  # Buffer a bit for smoother scrolling
      max_cache_size = 1000  # Prevent excessive memory usage
      
      while @lazy_txt.size < required_lines && @lazy_index < @raw_txt.size && @lazy_txt.size < max_cache_size
        raw_line = @raw_txt[@lazy_index]
        # If the raw line is short, no wrapping is needed.
        if raw_line.respond_to?(:pure) && Rcurses.display_width(raw_line.pure) < @w
          processed = [raw_line]
        else
          processed = split_line_with_ansi(raw_line, @w)
        end
        @lazy_txt.concat(processed)
        @lazy_index += 1
      end
      
      # Simplified: just limit max processing, don't trim existing cache
      # This avoids expensive array operations during scrolling
      
      @txt = @lazy_txt

      @ix = @txt.length - 1 if @ix > @txt.length - 1
      @ix = 0 if @ix < 0

      new_frame = []

      content_rows.times do |i|
        line_str = ""
        l = @ix + i
        if @txt[l].to_s != ""
          pl = @w - Rcurses.display_width(@txt[l].pure)
          pl = 0 if pl < 0
          hl = pl / 2
          # Skip color application if pane has no colors set or text has ANY ANSI codes
          if @skip_colors || @txt[l].include?("\e[")
            # Don't apply pane colors - text already has ANSI sequences
            case @align
            when "l"
              line_str = @txt[l] + " " * pl
            when "r"
              line_str = " " * pl + @txt[l]
            when "c"
              line_str = " " * hl + @txt[l] + " " * (pl - hl)
            end
          else
            # Apply pane colors normally
            case @align
            when "l"
              line_str = @txt[l].c(fmt) + " ".c(fmt) * pl
            when "r"
              line_str = " ".c(fmt) * pl + @txt[l].c(fmt)
            when "c"
              line_str = " ".c(fmt) * hl + @txt[l].c(fmt) + " ".c(fmt) * (pl - hl)
            end
          end
        else
          # Empty line - only apply colors if pane has them
          line_str = @skip_colors ? " " * @w : " ".c(fmt) * @w
        end

        new_frame << line_str
      end

      diff_buf = ""
      new_frame.each_with_index do |line, i|
        row_num = @y + i
        col_num = @x
        if @prev_frame.nil? || @prev_frame[i] != line
          diff_buf << "\e[#{row_num};#{col_num}H" << line
        end
      end

      # restore wrap, then also reset SGR and scroll-region one more time
      diff_buf << "\e[#{o_row};#{o_col}H\e[?7h\e[0m\e[r"
      begin
        # Debug: check what's actually being printed
        if diff_buf.include?("Purpose") && diff_buf.include?("[38;5;")
          File.open("/tmp/rcurses_debug.log", "a") do |f|
            f.puts "=== PRINT DEBUG ==="
            f.puts "diff_buf sample: #{diff_buf[0..200].inspect}"
            f.puts "Has escape byte 27: #{diff_buf.bytes.include?(27)}"
            f.puts "Escape count: #{diff_buf.bytes.count(27)}"
          end
        end
        
        print diff_buf
      rescue => e
        # If printing fails, at least try to restore terminal state
        begin
          print "\e[0m\e[?25h\e[?7h"
        rescue
        end
      end
      @prev_frame = new_frame

      # Draw scroll markers after printing the frame.
      if @scroll
        marker_col = @x + @w - 1
        if @ix > 0
          print "\e[#{@y};#{marker_col}H" + "∆".c(fmt)
        end
        # If there are more processed lines than fit in the pane
        # OR there remain raw lines to process, show the down marker.
        if (@txt.length - @ix) > @h || (@lazy_index < @raw_txt.size)
          print "\e[#{@y + @h - 1};#{marker_col}H" + "∇".c(fmt)
        end
      end

      if @border
        # top
        print "\e[#{@y - 1};#{@x - 1}H" + ("┌" + "─" * @w + "┐").c(fmt)
        # sides
        (0...@h).each do |i|
          print "\e[#{@y + i};#{@x - 1}H"  + "│".c(fmt)
          print "\e[#{@y + i};#{@x + @w}H" + "│".c(fmt)
        end
        # bottom
        print "\e[#{@y + @h};#{@x - 1}H" + ("└" + "─" * @w + "┘").c(fmt)
      end

      new_frame.join("\n")
    end

    def textformat(cont)
      # This method is no longer used in refresh since we process lazily,
      # but is kept here if needed elsewhere.
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
        STDIN.cooked!  rescue nil
        STDIN.echo = true rescue nil
        # Prepare content with visible newline markers
        content = @text.pure.gsub("\n", "¬\n")
        # Reset editing cursor state
        @ix = 0
        @line = 0
        @pos = 0
        # Initial render sets @txt internally for display and cursor math
        refresh(content)
        Rcurses::Cursor.show
        input_char = ''

        while input_char != 'ESC'
          # Move the terminal cursor to the logical text cursor
          row(@y + @line)
          col(@x + @pos)
          input_char = getchr(flush: false)
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
            @ix = 0; @line = 0; @pos = 0
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

          # Handle any buffered input
          while IO.select([$stdin], nil, nil, 0)
            input_char = $stdin.read_nonblock(1) rescue nil
            break unless input_char
            posx = calculate_posx
            content.insert(posx, input_char)
            right
          end

          # Re-render without overwriting the internal @txt
          refresh(content)
          Rcurses::Cursor.show
        end
      ensure
        STDIN.raw!         rescue nil  
        STDIN.echo = false rescue nil
        while IO.select([$stdin], nil, nil, 0)
          $stdin.read_nonblock(4096) rescue break
        end
      end
      Rcurses::Cursor.hide
    end

    def editline
      begin
        STDIN.cooked!  rescue nil
        STDIN.echo = true rescue nil
        Rcurses::Cursor.show
        @x = [[@x, 1].max, @max_w - @w + 1].min
        @y = [[@y, 1].max, @max_h - @h + 1].min
        @scroll = false
        @ix = 0
        row(@y)
        fmt = [@fg.to_s, @bg.to_s].join(',')
        col(@x)
        print @prompt.c(fmt)
        prompt_len = @prompt.pure.length
        content_len = @w - prompt_len
        cont = @text.pure.slice(0, content_len)
        @pos = cont.length
        chr = ''
        history_index = @history.size

        while chr != 'ESC'
          col(@x + prompt_len)
          cont = cont.slice(0, content_len)
          print cont.ljust(content_len).c(fmt)
          col(@x + prompt_len + @pos)
          chr = getchr(flush: false)
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
            @text = cont
            chr = 'ESC'
          when 'UP'
            if @history.any? && history_index > 0
              history_index -= 1
              cont = @history[history_index].pure.slice(0, content_len)
              @pos = cont.length
            end
          when 'DOWN'
            if history_index < @history.size - 1
              history_index += 1
              cont = @history[history_index].pure.slice(0, content_len)
              @pos = cont.length
            elsif history_index == @history.size - 1
              history_index += 1
              cont = ""
              @pos = 0
            end
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
        STDIN.raw!         rescue nil  
        STDIN.echo = false rescue nil
        while IO.select([$stdin], nil, nil, 0)
          $stdin.read_nonblock(4096) rescue break
        end
      end
      prompt_len = @prompt.pure.length
      new_col    = @x + prompt_len + (@pos > 0 ? @pos - 1 : 0)
      col(new_col)
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
        total_length += Rcurses.display_width(@txt[i].pure) + 1  # +1 for newline
      end
      total_length += @pos
      total_length
    end

    def calculate_line_start_pos
      total_length = 0
      (@ix + @line).times do |i|
        total_length += Rcurses.display_width(@txt[i].pure) + 1
      end
      total_length
    end

    def split_line_with_ansi(line, w)
      begin
        return [""] if line.nil? || w <= 0
        
        ansi_regex = /\e\[[0-9;]*m/
        result = []
        tokens = line.scan(/(\e\[[0-9;]*m|[^\e]+)/).flatten.compact
        current_line = ''
        current_line_length = 0
        
        # Track SGR state properly
        sgr_state = {
          bold: false,      # 1/22
          italic: false,    # 3/23  
          underline: false, # 4/24
          blink: false,     # 5/25
          reverse: false,   # 7/27
          fg_color: nil,    # 38/39 (nil means default)
          bg_color: nil     # 48/49 (nil means default)
        }
        
        # Helper to parse SGR parameters
        parse_sgr = lambda do |sequence|
          return unless sequence =~ /\e\[([0-9;]*)m/
          param_str = $1
          params = param_str.empty? ? [0] : param_str.split(';').map(&:to_i)
          i = 0
          while i < params.length
            case params[i]
            when 0  # Reset all
              sgr_state[:bold] = false
              sgr_state[:italic] = false
              sgr_state[:underline] = false
              sgr_state[:blink] = false
              sgr_state[:reverse] = false
              sgr_state[:fg_color] = nil
              sgr_state[:bg_color] = nil
            when 1  then sgr_state[:bold] = true
            when 3  then sgr_state[:italic] = true
            when 4  then sgr_state[:underline] = true
            when 5  then sgr_state[:blink] = true
            when 7  then sgr_state[:reverse] = true
            when 22 then sgr_state[:bold] = false
            when 23 then sgr_state[:italic] = false
            when 24 then sgr_state[:underline] = false
            when 25 then sgr_state[:blink] = false
            when 27 then sgr_state[:reverse] = false
            when 38 # Foreground color
              if params[i+1] == 5 && params[i+2]  # 256 color
                sgr_state[:fg_color] = "38;5;#{params[i+2]}"
                i += 2
              elsif params[i+1] == 2 && params[i+4]  # RGB color
                sgr_state[:fg_color] = "38;2;#{params[i+2]};#{params[i+3]};#{params[i+4]}"
                i += 4
              end
            when 39 then sgr_state[:fg_color] = nil  # Default foreground
            when 48 # Background color
              if params[i+1] == 5 && params[i+2]  # 256 color
                sgr_state[:bg_color] = "48;5;#{params[i+2]}"
                i += 2
              elsif params[i+1] == 2 && params[i+4]  # RGB color
                sgr_state[:bg_color] = "48;2;#{params[i+2]};#{params[i+3]};#{params[i+4]}"
                i += 4
              end
            when 49 then sgr_state[:bg_color] = nil  # Default background
            # Handle legacy 8-color codes (30-37, 40-47, 90-97, 100-107)
            when 30..37 then sgr_state[:fg_color] = params[i].to_s
            when 40..47 then sgr_state[:bg_color] = params[i].to_s
            when 90..97 then sgr_state[:fg_color] = params[i].to_s
            when 100..107 then sgr_state[:bg_color] = params[i].to_s
            end
            i += 1
          end
        end
        
        # Helper to reconstruct SGR sequence from state
        build_sgr = lambda do
          codes = []
          codes << "1" if sgr_state[:bold]
          codes << "3" if sgr_state[:italic]
          codes << "4" if sgr_state[:underline]
          codes << "5" if sgr_state[:blink]
          codes << "7" if sgr_state[:reverse]
          codes << sgr_state[:fg_color] if sgr_state[:fg_color]
          codes << sgr_state[:bg_color] if sgr_state[:bg_color]
          codes.empty? ? "" : "\e[#{codes.join(';')}m"
        end
        
        tokens.each do |token|
          if token.match?(ansi_regex)
            current_line << token
            parse_sgr.call(token)
          else
            words = token.scan(/\s+|\S+/)
            words.each do |word|
              begin
                word_length = Rcurses.display_width(word.gsub(ansi_regex, ''))
                if current_line_length + word_length <= w
                  current_line << word
                  current_line_length += word_length
                else
                  if current_line_length > 0
                    result << current_line
                    # Start new line with current SGR state
                    current_line = build_sgr.call
                    current_line_length = 0
                  end
                  while word_length > w
                    part = word[0, [w, word.length].min]
                    current_line << part
                    result << current_line
                    word = word[[w, word.length].min..-1] || ""
                    word_length = Rcurses.display_width(word.gsub(ansi_regex, ''))
                    # Start new line with current SGR state
                    current_line = build_sgr.call
                    current_line_length = 0
                  end
                  if word_length > 0
                    current_line << word
                    current_line_length += word_length
                  end
                end
              rescue => e
                # Skip problematic word but continue
                next
              end
            end
          end
        end
        result << current_line unless current_line.empty?
        result.empty? ? [""] : result
      rescue => e
        # Complete fallback
        return [""]
      end
    end
  end
end


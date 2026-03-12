module Rcurses
  class Popup < Pane
    # Creates a popup overlay. Defaults to centered, bordered, dark background.
    #
    # Usage:
    #   popup = Rcurses::Popup.new(w: 50, h: 20)          # auto-centered
    #   popup = Rcurses::Popup.new(x: 10, y: 5, w: 50, h: 20)  # explicit position
    #
    #   # Simple modal (blocks until ESC/ENTER, returns selected line index or nil)
    #   result = popup.modal(content_string)
    #
    #   # Manual control
    #   popup.show(content_string)
    #   # ... your own input loop ...
    #   popup.dismiss(refresh_panes: [pane1, pane2])
    #
    def initialize(x: nil, y: nil, w: 40, h: 15, fg: 255, bg: 236)
      max_h, max_w = IO.console ? IO.console.winsize : [24, 80]
      # Auto-center if position not specified
      px = x || ((max_w - w) / 2 + 1)
      py = y || ((max_h - h) / 2 + 1)
      super(px, py, w, h, fg, bg)
      @border = true
      @scroll = true
    end

    # Show content in the popup (non-blocking, just renders)
    def show(content)
      @text = content
      @ix = 0
      full_refresh
    end

    # Modal: show content, handle scroll/navigation, return on ESC or ENTER.
    # Returns the selected line index on ENTER, or nil on ESC.
    # Optional block receives each keypress for custom handling;
    # return :dismiss from the block to close, or a String to return that value.
    def modal(content, &on_key)
      @text = content
      @ix = 0
      @index = 0

      loop do
        full_refresh

        chr = getchr(flush: false)
        case chr
        when 'ESC'
          return nil
        when 'ENTER'
          return @index
        when 'UP', 'k'
          @index = [@index - 1, 0].max
          scroll_to_index
        when 'DOWN', 'j'
          total = (@text || "").split("\n").size
          @index = [@index + 1, total - 1].min
          scroll_to_index
        when 'PgUP'
          @index = [@index - @h + 1, 0].max
          scroll_to_index
        when 'PgDOWN'
          total = (@text || "").split("\n").size
          @index = [@index + @h - 1, total - 1].min
          scroll_to_index
        when 'HOME'
          @index = 0
          @ix = 0
        when 'END'
          total = (@text || "").split("\n").size
          @index = [total - 1, 0].max
          scroll_to_index
        end

        # Custom key handler
        if block_given?
          result = on_key.call(chr, @index)
          return nil if result == :dismiss
          return result if result.is_a?(String)
        end
      end
    end

    # Clear the popup area and optionally refresh underlying panes
    def dismiss(refresh_panes: [])
      clear_area
      refresh_panes.each do |p|
        p.full_refresh if p.respond_to?(:full_refresh)
      end
    end

    # Blank the screen region occupied by this popup (including border)
    def clear_area
      top = @y - (@border ? 1 : 0)
      bot = @y + @h - 1 + (@border ? 1 : 0)
      left = @x - (@border ? 1 : 0)
      width = @w + (@border ? 2 : 0)
      (top..bot).each do |row|
        STDOUT.print "\e[#{row};#{left}H\e[0m#{' ' * width}"
      end
      STDOUT.flush
    end

    private

    def scroll_to_index
      # Keep selected index visible in the pane
      if @index < @ix
        @ix = @index
      elsif @index >= @ix + @h
        @ix = @index - @h + 1
      end
    end
  end
end

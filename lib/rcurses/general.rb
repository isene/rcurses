module Rcurses
  @@terminal_state_saved = false
  @@original_stty_state = nil
  
  def self.clear_screen
    # ANSI code \e[2J clears the screen, and \e[H moves the cursor to the top left.
    print "\e[2J\e[H"
  end
  
  def self.save_terminal_state(install_handlers = false)
    unless @@terminal_state_saved
      @@original_stty_state = `stty -g 2>/dev/null`.chomp rescue nil
      @@terminal_state_saved = true
      setup_signal_handlers if install_handlers
    end
  end
  
  def self.restore_terminal_state
    if @@terminal_state_saved && @@original_stty_state
      begin
        # Restore terminal settings
        system("stty #{@@original_stty_state} 2>/dev/null")
        # Reset terminal
        print "\e[0m\e[?25h\e[?7h\e[r"
        STDOUT.flush
      rescue StandardError
        # Fallback restoration
        begin
          STDIN.cooked! rescue nil
          STDIN.echo = true rescue nil
        rescue StandardError
        end
      end
    end
    @@terminal_state_saved = false
  end
  
  def self.setup_signal_handlers
    ['TERM', 'INT', 'QUIT', 'HUP'].each do |signal|
      Signal.trap(signal) do
        restore_terminal_state
        exit(1)
      end
    end
    
    # Handle WINCH (window size change) gracefully
    Signal.trap('WINCH') do
      # Just ignore for now - applications should handle this themselves
    end
  end
  
  def self.with_terminal_protection(install_handlers = true)
    save_terminal_state(install_handlers)
    begin
      yield
    ensure
      restore_terminal_state
    end
  end
  
  # Display width cache
  @dw_cache = {}
  DW_CACHE_MAX = 2000

  def self.clear_dw_cache
    @dw_cache.clear
  end

  # Simple, fast display_width function (cached)
  def self.display_width(str)
    return 0 if str.nil? || str.empty?
    cached = @dw_cache[str]
    return cached if cached

    width = 0
    prev_regional = false
    after_zwj = false       # Next visible char is joined (zero-width)
    last_was_narrow = false # Previous visible char was 1-wide (for ZWJ promotion)
    str.each_char do |char|
      cp = char.ord

      # Variation selectors: always zero-width
      # FE0F/FE0E behavior is terminal-dependent; treating as zero-width
      # matches libc wcwidth and avoids grid misalignment.
      next if cp == 0xFE0F || cp == 0xFE0E

      # Zero-width: skin tones, tags, combining marks, keycaps
      if (cp >= 0x1F3FB && cp <= 0x1F3FF) ||       # Skin tone modifiers
         (cp >= 0xE0020 && cp <= 0xE007F) ||       # Tag characters (flag subdivisions)
         cp == 0xE0001 || cp == 0x200C ||           # Other zero-width
         (cp >= 0x20D0 && cp <= 0x20FF) ||         # Combining diacritical marks for symbols
         cp == 0x20E3                               # Combining enclosing keycap
        next
      end

      # ZWJ: next visible character merges into current glyph
      if cp == 0x200D
        # ZWJ sequences always render as 2-wide emoji.
        # If the base character was narrow (e.g. ❤ in ❤️‍🔥), promote to 2.
        if last_was_narrow
          width += 1
          last_was_narrow = false
        end
        after_zwj = true
        next
      end

      if cp == 0 || cp < 32 || (cp >= 0x7F && cp < 0xA0)
        # NUL and control characters: no width
        last_was_narrow = false
      # Regional indicator symbols (flags): pair = one 2-wide glyph
      elsif cp >= 0x1F1E6 && cp <= 0x1F1FF
        if prev_regional
          prev_regional = false
          after_zwj = false
          next
        else
          prev_regional = true
          width += 2 unless after_zwj
          after_zwj = false
          next
        end
      # Wide character ranges (CJK, emoji, etc):
      elsif (cp >= 0x1100 && cp <= 0x115F) ||
            cp == 0x2329 || cp == 0x232A ||
            (cp >= 0x231A && cp <= 0x231B) ||   # Watch, hourglass
            (cp >= 0x23E9 && cp <= 0x23F3) ||   # Various symbols
            (cp >= 0x23F8 && cp <= 0x23FA) ||   # Play/pause symbols
            (cp >= 0x25FD && cp <= 0x25FE) ||   # Medium squares
            (cp >= 0x2614 && cp <= 0x2615) ||   # Umbrella, hot beverage
            (cp >= 0x2648 && cp <= 0x2653) ||   # Zodiac signs
            cp == 0x267F || cp == 0x2693 ||     # Wheelchair, anchor
            cp == 0x26A1 || cp == 0x26AA ||     # High voltage, circles
            cp == 0x26AB || cp == 0x26BD ||
            cp == 0x26BE || cp == 0x26C4 ||
            cp == 0x26C5 || cp == 0x26CE ||
            cp == 0x26D4 || cp == 0x26EA ||
            (cp >= 0x26F2 && cp <= 0x26F3) ||
            cp == 0x26F5 || cp == 0x26FA ||
            cp == 0x26FD ||
            cp == 0x2705 ||                            # ✅
            (cp >= 0x270A && cp <= 0x270B) ||          # ✊✋
            cp == 0x2728 ||                            # ✨
            cp == 0x274C || cp == 0x274E ||            # ❌❎
            (cp >= 0x2753 && cp <= 0x2755) ||          # ❓❔❕
            cp == 0x2757 ||                            # ❗
            (cp >= 0x2795 && cp <= 0x2797) ||          # ➕➖➗
            cp == 0x27B0 || cp == 0x27BF ||            # ➰➿
            (cp >= 0x2B1B && cp <= 0x2B1C) ||          # ⬛⬜
            cp == 0x2B50 || cp == 0x2B55 ||            # ⭐⭕
            cp == 0x3030 || cp == 0x303D ||
            cp == 0x3297 || cp == 0x3299 ||
            (cp >= 0x2E80 && cp <= 0xA4CF) ||
            (cp >= 0xAC00 && cp <= 0xD7A3) ||
            (cp >= 0xF900 && cp <= 0xFAFF) ||
            (cp >= 0xFE10 && cp <= 0xFE19) ||
            (cp >= 0xFE30 && cp <= 0xFE6F) ||
            (cp >= 0xFF00 && cp <= 0xFF60) ||
            (cp >= 0xFFE0 && cp <= 0xFFE6) ||
            (cp >= 0x1F000 && cp <= 0x1FFFF) ||  # All emoji blocks
            (cp >= 0x20000 && cp <= 0x2FFFF)     # CJK Extension B+
        width += 2 unless after_zwj
        last_was_narrow = false
      else
        unless after_zwj
          width += 1
          last_was_narrow = true
        else
          last_was_narrow = false
        end
      end
      prev_regional = false
      after_zwj = false
    end
    @dw_cache.clear if @dw_cache.size >= DW_CACHE_MAX
    @dw_cache[str] = width
    width
  end
  
  # Comprehensive Unicode display width (available but not used in performance-critical paths)
  def self.display_width_unicode(str)
    return 0 if str.nil? || str.empty?
    
    # ... full Unicode implementation available when needed ...
    # For now, just delegate to the simple version
    display_width(str)
  end
end

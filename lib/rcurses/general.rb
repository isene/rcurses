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
      rescue
        # Fallback restoration
        begin
          STDIN.cooked! rescue nil
          STDIN.echo = true rescue nil
        rescue
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
  
  # Simple, fast display_width function (like original 4.8.3)
  def self.display_width(str)
    return 0 if str.nil? || str.empty?
    
    width = 0
    str.each_char do |char|
      cp = char.ord
      if cp == 0
        # NUL – no width
      elsif cp < 32 || (cp >= 0x7F && cp < 0xA0)
        # Control characters: no width
        width += 0
      # Approximate common wide ranges:
      elsif (cp >= 0x1100 && cp <= 0x115F) ||
            cp == 0x2329 || cp == 0x232A ||
            (cp >= 0x2E80 && cp <= 0xA4CF) ||
            (cp >= 0xAC00 && cp <= 0xD7A3) ||
            (cp >= 0xF900 && cp <= 0xFAFF) ||
            (cp >= 0xFE10 && cp <= 0xFE19) ||
            (cp >= 0xFE30 && cp <= 0xFE6F) ||
            (cp >= 0xFF00 && cp <= 0xFF60) ||
            (cp >= 0xFFE0 && cp <= 0xFFE6)
        width += 2
      else
        width += 1
      end
    end
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

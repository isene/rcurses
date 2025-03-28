module Rcurses
  def self.clear_screen
    # ANSI code \e[2J clears the screen, and \e[H moves the cursor to the top left.
    print "\e[2J\e[H"
  end
end

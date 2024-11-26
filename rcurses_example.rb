#!/usr/bin/env ruby

require 'rcurses'

# Start by creating the panes; Format:
# pane      = Rcurses::Pane.new(             startx,        starty,               width,            height,  fg,  bg)
pane_top    = Rcurses::Pane.new(                  1,             1,       Rcurses::MAXw,                 1, 255, 236)
pane_bottom = Rcurses::Pane.new(                  1, Rcurses::MAXh,       Rcurses::MAXw,                 1, 236, 254)
pane_left   = Rcurses::Pane.new(                  2,             3, Rcurses::MAXw/2 - 2, Rcurses::MAXh - 4,  52, nil)
pane_right  = Rcurses::Pane.new(Rcurses::MAXw/2 + 1,             2,     Rcurses::MAXw/2, Rcurses::MAXh - 2, 255,  52)

pane_left.border     = true # Adding a border to the left pane

# Add content to the panes
pane_top.text        = Time.now.to_s[0..15].b + "   Welcome to the rcurses example program"
pane_left.text       = `ls --color`
pane_right.text      = "Output of lsblk:\n\n" + `lsblk`
pane_bottom.prompt   = "Enter any text and press ENTER: ".b # The prompt text before the user starts writing content

pane_top.refresh     # This is the order of drawing/refreshing the panes
pane_left.refresh    # ...then the left pane
pane_right.refresh   # ...and the right pane
pane_bottom.editline # Do not use a refresh before editline

# Then create a "pop-up" pane in the middle of the screen
pane_mid             = Rcurses::Pane.new(Rcurses::MAXw/2 - 10, Rcurses::MAXh/2 - 5, 20, 10, 18,  254)
pane_mid.border      = true
pane_mid.text        = "You wrote:" + "\n" + pane_bottom.text.i
pane_mid.align       = "c"
pane_mid.refresh

# Then ask the user to hit ENTER before exiting the program
pane_bottom.prompt   = "Now hit ENTER again "
pane_bottom.text     = ""
pane_bottom.editline

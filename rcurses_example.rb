#!/usr/bin/env ruby

require 'rcurses'

# pane      = Rcurses::Pane.new(             startx,        starty,           width,            height,  fg,  bg)
pane_top    = Rcurses::Pane.new(                  1,             1,   Rcurses::MAXw,                 1, 255, 236)
pane_bottom = Rcurses::Pane.new(                  1, Rcurses::MAXh,   Rcurses::MAXw,                 1, 236, 254)
pane_left   = Rcurses::Pane.new(                  1,             2, Rcurses::MAXw/2, Rcurses::MAXh - 2,  17, 117)
pane_right  = Rcurses::Pane.new(Rcurses::MAXw/2 + 1,             2, Rcurses::MAXw/2, Rcurses::MAXh - 2, 255,  52)

pane_left.align  = "c"
pane_right.align = "r"

pane_top.text      = "This is an information line at the top".b.i
pane_left.text     = "\n\n" + "Here is a pane to be reckoned with".b
pane_right.text    = "\n\n" + "And here is the right pane.  "
pane_bottom.prompt = "Enter any text and press ENTER: ".b

pane_top.refresh   
pane_left.refresh  
pane_right.refresh 
pane_bottom.editline

#!/usr/bin/env ruby

require 'rcurses'

# pane      = Rcurses::Pane.new(             startx,        starty,               width,            height,  fg,  bg)
pane_top    = Rcurses::Pane.new(                  1,             1,       Rcurses::MAXw,                 1, 255, 236)
pane_bottom = Rcurses::Pane.new(                  1, Rcurses::MAXh,       Rcurses::MAXw,                 1, 236, 254)
pane_left   = Rcurses::Pane.new(                  2,             3, Rcurses::MAXw/2 - 2, Rcurses::MAXh - 4,  52, nil)
pane_right  = Rcurses::Pane.new(Rcurses::MAXw/2 + 1,             2,     Rcurses::MAXw/2, Rcurses::MAXh - 2, 255,  52)

pane_left.border   = true

pane_top.text      = Time.now.to_s[0..15].b + "   Welcome to the rcurses example program"
pane_left.text     = `ls --color`
pane_right.text    = "Output of lsblk:\n\n" + `lsblk`
pane_bottom.prompt = "Enter any text and press ENTER: ".b

pane_top.refresh   
pane_left.refresh  
pane_right.refresh 
pane_bottom.editline

pane_mid           = Rcurses::Pane.new(Rcurses::MAXw/2 - 10, Rcurses::MAXh/2 - 5, 20, 10, 18,  254)
pane_mid.border    = true
pane_mid.text      = "You wrote: \n \n" + pane_bottom.text.i
pane_mid.align     = "c"
pane_mid.refresh

pane_bottom.prompt = "Now hit ENTER again "
pane_bottom.text   = ""
pane_bottom.editline

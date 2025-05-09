#!/usr/bin/env ruby

require 'rcurses'
include Rcurses::Input
include Rcurses::Cursor

@max_h, @max_w = IO.console.winsize
@pane    = []
@focused = 3 # Start with pane 3 so that the first keypress focuses back to Pane 0
Rcurses::Cursor.hide

# Start by creating the panes; Format:
# pane    = Rcurses::Pane.new( startx, starty,  width, height,  fg,  bg)
pane_back = Rcurses::Pane.new(      1,      1, @max_w, @max_h, nil, 236)
@pane[0]  = Rcurses::Pane.new(      4,      4,     20,     10, 236, 254)
@pane[1]  = Rcurses::Pane.new(     30,     10,     16,     12, 232, 132)
@pane[2]  = Rcurses::Pane.new(      8,     20,     30,     20, 136,  54)
@pane[3]  = Rcurses::Pane.new(     50,     30,     24,     10, 206,  24)

pane_back.text = "PRESS ANY KEY TO SHIFT FOCUS. PRESS 'ESC' TO QUIT."
@pane.each_index { |i| @pane[i].text = "This is pane " + i.to_s }
pane_back.full_refresh
@pane.each_index { |i| @pane[i].refresh }

input = ''
while input != 'ESC'
  input = getchr
  pane_back.full_refresh
  @focused += 1
  @focused  = 0 if @focused == @pane.size
  @pane.each_index {|i| @pane[i].border = false}
  @pane.each_index {|i| @pane[i].full_refresh}
  @pane[@focused].border = true
  @pane[@focused].full_refresh
end

# Always end an application with these lines:
$stdin.cooked!
$stdin.echo = true
Rcurses.clear_screen
Rcurses::Cursor.show


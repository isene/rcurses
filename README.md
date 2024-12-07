# rcurses - An alternative curses library written in pure Ruby

![Ruby](https://img.shields.io/badge/language-Ruby-red) [![Gem Version](https://badge.fury.io/rb/rcurses.svg)](https://badge.fury.io/rb/rcurses) ![Unlicense](https://img.shields.io/badge/license-Unlicense-green) ![Stay Amazing](https://img.shields.io/badge/Stay-Amazing-important)

<img src="img/rcurses-logo.png" width="150" height="150">

Create curses applications for the terminal easier than ever.

# Why?
Having struggled with the venerable curses library and the ruby interface to it for many years, I finally got around to write an alternative - in pure Ruby.

# Design principles
Simple and with minimum of external dependencies.

# Installation
Simply run `gem install rcurses`.

To use this library do:
```
require 'rcurses'
```

# Features
* Create panes (with the colors and(or border), manipulate the panes and add content
* Dress up text (in panes or anywhere in the terminal) in bold, italic, underline, reverse color, blink and in any 256 terminal colors for foreground and background
* Use a simple editor to let users edit text in panes
* Left, right or center align text in panes
* Cursor movement around the terminal

# The elements
`rcurses` gives you the following elements:
* The class `Pane` to create and manilpulate panes/boxes
* Extensions to the class String to print text in various degrees of fancy and also strip any fanciness
* A module `Cursor` to give you cursor movements around the terminal
* A module `Rinput` providing the function `getchr` to capture a single character input from the user (much better than any Ruby built-ins)

# class Pane
To create a pane do something like this:
```
mypane = Rcurses::Pane.new(80, 30, 30, 10, 19, 229)
```
This will create a pane/box starting at terminal column/x 80 and row/y 30 with the width of 30 characters and a hight of 10 characters and with the foreground color 19 and background color 229 (from the 256 choices available)

The format for creating a pane is:
```
Rcurses::Pane.new(startx, starty, width, height, foregroundcolor, backgroundcolor)
```
You can drop the last two 256-color codes to create a pane with the defaults for your terminal. 

You can add anything as `startx`, `starty`, `width` or `height` as those values will be evaluated and stored in readable variables `x`, `y`, `w` and `h` respectively. 

By adding values for the terminal size in your program:
```
@max_h, @max_w = IO.console.winsize
```
...you can use these values to create proportinally sized panes. So, a hight value of "@max_h/2" is valid to create a pane with the height of half the terminal height (the integer corresponding to half the terminal height will then be accessible as the variable `h`). Use the variables `@max_h` for terminal height and `@max_w` for terminal width.

Avaliable properties/variables:

Property       | Description
---------------|---------------------------------------------------------------
startx         | The `x` value to be "Eval-ed"
x              | The readable x-value for the Pane
starty         | The `y` value to be "Eval-ed"
y              | The readable y-value for the Pane
width          | The Pane width to be "Eval-ed"
w              | The readable w-value for the Pane
height         | The Pane height to be "Eval-ed"
h              | The readable h-value for the Pane
fg             | Foreground color for the Pane
bg             | Background color for the Pane
border         | Draw border around the Pane (=true) or not (=false), default being false
scroll         | Whether to indicate more text to be shown above/below the Pane, default is true
text           | The text/content of the Pane
ix             | "Index" - the line number at the top of the Pane, starts at 0, the first line of text in the Pane
align          | Text alignment in the Pane: "l" = lefts aligned, "c" = center, "r" = right, with the default "l"
prompt         | The prompt to print at the beginning of a one-liner Pane used as an input box

The methods for Pane:

Method         | Description
---------------|---------------------------------------------------------------
new/init       | Initializes a Pane with optional arguments startx, starty, width, height, foregroundcolor and backgroundcolor
move(x,y)      | Move the pane by `x`and `y` (`mypane.move(-4,5)` will move the pane left four characters and five characters down)
refresh        | Refreshes/redraws the Pane with content
edit           | An editor for the Pane. When this is invoked, all existing font dressing is stripped and the user gets to edit the raw text. The user can add font effects similar to Markdown; Use an asterisk before and after text to be drawn in bold, text between forward-slashes become italic, and underline before and after text means the text will be underlined, a hash-sign before and after text makes the text reverse colored. You can also combine a whole set of dressings in this format: `<23,245,biurl|Hello World!>` - this will make "Hello World!" print in the color 23 with the background color 245 (regardless of the Pane's fg/bg setting) in bold, italic, underlined, reversed colored and blinking. Hitting `ESC` while in edit mode will disregard the edits, while `Ctrl-S` will save the edits
editline       | Used for one-line Panes. It will print the content of the property `prompt` and then the property `text` that can then be edited by the user. Hitting `ESC` will disregard the edits, while `ENTER` will save the edited text

# class String extensions
Method extensions provided for the class String:

Method         | Description
---------------|---------------------------------------------------------------
fg(fg)         | Set text to be printed with the foreground color `fg` (example: `"TEST".fg(84)`)
bg(bg)         | Set text to be printed with the background color `bg` (example: `"TEST".bg(196)`)
fb(fg, bg)     | Set text to be printed with the foreground color `fg` and background color `bg` (example: `"TEST".fb(84,196)`)
b              | Set text to be printed in bold (example: `"TEST".b`)
i              | Set text to be printed in italic (example: `"TEST".i`)
u              | Set text to be printed underlined (example: `"TEST".u`)
l              | Set text to be printed blinking (example: `"TEST".l`)
r              | Set text to be printed in reverse colors (example: `"TEST".r`)
c(code)        | Use coded format like "TEST".c("204,45,bui") to print "TEST" in bold, underline italic, fg=204 and bg=45 (the format is `.c("fg,bg,biulr"))
pure           | Strip text of any "dressing" (example: with `text = "TEST".b`, you will have bold text in the variable `text`, then with `text.pure` it will show "uncoded" or pure text)

PS: Blink does not work in conjunction with setting a background color in urxvt. It does work in gnome-terminal. But the overall performance in urxvt as orders of magnitude better than gnome-terminal.

# module Cursor
To use this module, first do `include Rcurses::Cursor`. Create a new cursor object with `mycursor = Cursor`. Then you can apply the following methods to `mycursor`:

Method            | Description
------------------|---------------------------------------------------------------
save              | Save current position
restore           | Restore cursor position
pos               | Query cursor current position (example: `row,col = mycursor.pos`)
colget            | Query cursor current cursor col/x position (example: `row = mycursor.rowget`)
rowget            | Query cursor current cursor row/y position (example: `row = mycursor.rowget`)         
up(n = 1)         | Move cursor up by n (default is 1 character up)
down(n = 1)       | Move cursor down by n (default is 1 character down)
left(n = 1)       | Move cursor backward by n (default is one character)
right(n = 1)      | Move cursor forward by n (default is one character)
col(n = 1)        | Cursor moves to the nth position horizontally in the current line (default = first column)
row(n = 1)        | Cursor moves to the nth position vertically in the current column (default = first/top row)
next_line)        | Move cursor down to beginning of next line
prev_line)        | Move cursor up to beginning of previous line
clear_char(n = 1) | Erase n characters from the current cursor position (default is one character)
clear_line        | Erase the entire current line and return to beginning of the line
clear_line_before | Erase from the beginning of the line up to and including the current cursor position
clear_line_after  | Erase from the current position (inclusive) to the end of the line
scroll_up         | Scroll display up one line
scroll_down       | Scroll display down one line
clear_screen_down | Clear screen down from current row
hide_cursor       | Hide the cursor
show_cursor       | Show cursor

# The function getchr
rcurses provides a vital extension to Ruby in reading characters entered by the user. This is especially needed for curses applications where readline inputs are required.
The function getchr is automatically included in your arsenal when you first do `include Rcurses::Input`.

Simply use `chr = getchr` in a program to read any character input by the user. The returning code (the content of `chr` in this example) could be any of the following:

Key pressed     | string returned
----------------|----------------------------------------------------------
`esc`           | "ESC"
`up`            | "UP"
`ctrl-up`       | "C-UP"
`down`          | "DOWN"
`ctrl-down`     | "C-DOWN"
`right`         | "RIGHT"
`ctrl-right`    | "C-RIGHT"
`left`          | "LEFT"
`ctrl-left`     | "C-LEFT"
`shift-tab`     | "S-TAB"
`insert`        | "INS"   
`ctrl-insert`   | "C-INS"
`del`           | "DEL"   
`ctrl-del`      | "C-DEL"
`pageup`        | "PgUP"  
`ctrl-pageup`   | "C-PgUP"
`pagedown`      | "PgDOWN"
`ctrl-pagedown` | "C-PgDOWN"
`home`          | "HOME"  
`ctrl-home`     | "C-HOME"
`end`           | "END"   
`ctrl-end`      | "C-END"
`backspace`     | "BACK"
`ctrl-h`        | "BACK"
`ctrl-a`        | "C-A"
`ctrl-b`        | "C-B"
`ctrl-c`        | "C-C"
`ctrl-d`        | "C-D"
`ctrl-e`        | "C-E"
`ctrl-f`        | "C-F"
`ctrl-g`        | "C-G"
`ctrl-i`        | "C-I"
`ctrl-j`        | "C-J"
`ctrl-k`        | "C-K"
`ctrl-l`        | "C-L"
`ctrl-m`        | "C-M"
`ctrl-n`        | "C-N"
`ctrl-o`        | "C-O"
`ctrl-p`        | "C-P"
`ctrl-q`        | "C-Q"
`ctrl-r`        | "C-R"
`ctrl-s`        | "C-S"
`ctrl-t`        | "C-T"
`ctrl-u`        | "C-U"
`ctrl-v`        | "C-V"
`ctrl-a`        | "WBACK"
`ctrl-x`        | "C-X"
`ctrl-y`        | "C-Y"
`ctrl-z`        | "C-Z"
`enter`         | "ENTER"
`tab`           | "TAB"

Any other character enter will be returned (to `chr` in the example above).

In order to handle several character pased into STDIN by the user (and not only returned the first character only, your program should empty the STDIN like this:

```
while $stdin.ready?
  chr += $stdin.getc
end
```

# Example

Try this in `irb`:
```
require 'rcurses'
@max_h, @max_w = IO.console.winsize
mypane = Pane.new(@maxw/2, 30, 30, 10, 19, 229)
mypane.border = true
mypane.text = "Hello".i + " World!".b.i + "\n \n" + "rcurses".r + " " + "is cool".c("16,212")
mypane.refresh
mypane.edit
```
... and then try to add some bold text by enclosing it in '*' and italics by enclosing text in '/'. Then press 'ctrl-s' to save your edited text - and then type `mypane.refresh` to see the result.

And - try running the example file `rcurses_example.rb`.

# Not yet implemented
Let me know what other features you like to see.

# License and copyright
Just steal or borrow anything you like. This is now Public Domain.

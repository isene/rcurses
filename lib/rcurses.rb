# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    2.4.2: Added parameters 'min' and 'time' to getchr

require 'io/console' # Basic gem for rcurses
require 'io/wait'    # stdin handling

require_relative 'string_extensions'
require_relative 'rcurses/cursor'
require_relative 'rcurses/input'
require_relative 'rcurses/pane'

# vim: set sw=2 sts=2 et filetype=ruby fdm=syntax fdn=2 fcs=fold\:\ :

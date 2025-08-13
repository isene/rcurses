# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    4.9.4: Added scrolling best practices documentation

require 'io/console' # Basic gem for rcurses
require 'io/wait'    # stdin handling
require 'timeout'

require_relative 'string_extensions'
require_relative 'rcurses/general'
require_relative 'rcurses/cursor'
require_relative 'rcurses/input'
require_relative 'rcurses/pane'

module Rcurses
  class << self
    # Public: Initialize Rcurses. Switches terminal into raw/no-echo
    # and registers cleanup handlers. Idempotent.
    def init!
      return if @initialized
      return unless $stdin.tty?

      # enter raw mode, disable echo
      $stdin.raw!
      $stdin.echo = false

      # ensure cleanup on normal exit
      at_exit { cleanup! }

      # ensure cleanup on signals
      %w[INT TERM].each do |sig|
        trap(sig) { cleanup!; exit }
      end

      @initialized = true
    end

    # Public: Restore terminal to normal mode, clear screen, show cursor.
    # Idempotent: subsequent calls do nothing.
    def cleanup!
      return if @cleaned_up

      $stdin.cooked!
      $stdin.echo = true
      Rcurses.clear_screen
      Cursor.show

      @cleaned_up = true
    end
  end

  # Kick off initialization as soon as the library is required.
  init!
end

# vim: set sw=2 sts=2 et filetype=ruby fdn=2 fcs=fold\:\ :

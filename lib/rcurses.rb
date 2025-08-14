# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    5.1.5: Improved error handling - preserves screen content on crash

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
      at_exit do
        # Capture any unhandled exception
        if $! && !$!.is_a?(SystemExit) && !$!.is_a?(Interrupt)
          @error_to_display = $!
        end
        cleanup!
      end

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

      # Restore terminal to normal mode
      $stdin.cooked!
      $stdin.echo = true
      
      # Only clear screen if there's no error to display
      # This preserves the error context on screen
      if @error_to_display.nil?
        Rcurses.clear_screen
      else
        # Just move cursor to bottom of screen without clearing
        print "\e[999;1H"  # Move to bottom-left
        print "\e[K"       # Clear current line
      end
      
      Cursor.show

      @cleaned_up = true
      
      # Display any captured error after terminal is restored
      if @error_to_display
        display_error(@error_to_display)
      end
    end
    
    # Private: Display error information after terminal cleanup
    def display_error(error)
      # Only display if we're in a TTY and not in a test environment
      return unless $stdout.tty?
      
      # Add some spacing and make the error very visible
      puts "\n\n\e[41;37m                    APPLICATION CRASHED                    \e[0m"
      puts "\e[31m═══════════════════════════════════════════════════════════\e[0m"
      puts "\e[33mError Type:\e[0m #{error.class}"
      puts "\e[33mMessage:\e[0m    #{error.message}"
      
      # Show backtrace if debug mode is enabled
      if ENV['DEBUG'] || ENV['RCURSES_DEBUG']
        puts "\n\e[33mBacktrace:\e[0m"
        error.backtrace.first(15).each do |line|
          puts "  \e[90m#{line}\e[0m"
        end
      else
        puts "\n\e[90mTip: Set DEBUG=1 or RCURSES_DEBUG=1 to see the full backtrace\e[0m"
      end
      
      puts "\e[31m═══════════════════════════════════════════════════════════\e[0m"
      puts "\e[33mNote:\e[0m The application state above shows where the error occurred."
      puts ""
    end
    
    # Public: Run a block with proper error handling and terminal cleanup
    # This ensures errors are displayed after terminal is restored
    def run(&block)
      init!
      begin
        yield
      rescue StandardError => e
        @error_to_display = e
        raise
      ensure
        # cleanup! will be called by at_exit handler
      end
    end
  end

  # Kick off initialization as soon as the library is required.
  init!
end

# vim: set sw=2 sts=2 et filetype=ruby fdn=2 fcs=fold\:\ :

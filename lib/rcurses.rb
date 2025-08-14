# INFORMATION
# Name:       rcurses - Ruby CURSES
# Language:   Pure Ruby
# Author:     Geir Isene <g@isene.com>
# Web_site:   http://isene.com/
# Github:     https://github.com/isene/rcurses
# License:    Public domain
# Version:    5.1.4: Added error handling with terminal restoration

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

      $stdin.cooked!
      $stdin.echo = true
      Rcurses.clear_screen
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
      
      puts "\n\e[31m═══ Application Error ═══\e[0m"
      puts "\e[33m#{error.class}:\e[0m #{error.message}"
      
      # Show backtrace if debug mode is enabled
      if ENV['DEBUG'] || ENV['RCURSES_DEBUG']
        puts "\n\e[90mBacktrace:\e[0m"
        error.backtrace.first(10).each do |line|
          puts "  \e[90m#{line}\e[0m"
        end
      else
        puts "\e[90m(Set DEBUG=1 or RCURSES_DEBUG=1 for backtrace)\e[0m"
      end
      
      puts "\e[31m═══════════════════════\e[0m\n"
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

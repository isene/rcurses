#!/usr/bin/env ruby
# Test rcurses 5.1.6 with Ruby 3.4+ fix

puts "Testing rcurses 5.1.6 Ruby 3.4+ compatibility fix"
puts "Ruby version: #{RUBY_VERSION}"
puts "=" * 50

# Add the lib directory to load path
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rcurses'

puts "rcurses loaded successfully"
puts "Testing initialization..."

begin
  # This should not hang on Ruby 3.4.5
  Rcurses.init!
  puts "✓ Rcurses.init! successful!"
  
  # Do a simple test
  Rcurses.clear_screen
  print "rcurses 5.1.6 works! Press Enter to exit..."
  
  # Wait for user input
  $stdin.gets
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Cleanup
  Rcurses.cleanup!
  puts "\n✓ Cleanup successful!"
end
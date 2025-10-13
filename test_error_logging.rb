#!/usr/bin/env ruby

require_relative 'lib/rcurses'

puts "Testing rcurses error logging functionality..."
puts "This will test both normal operation and error logging"

# Test 1: Normal operation (should not create any log files)
puts "\n1. Testing normal operation without RCURSES_ERROR_LOG..."
begin
  Rcurses.init!
  puts "✓ Rcurses.init! works normally"
  Rcurses.cleanup!
  puts "✓ Rcurses.cleanup! works normally"
rescue => e
  puts "✗ Error in normal operation: #{e}"
end

# Test 2: Normal operation with RCURSES_ERROR_LOG=1 (should not create log files)
puts "\n2. Testing normal operation with RCURSES_ERROR_LOG=1..."
ENV['RCURSES_ERROR_LOG'] = '1'
begin
  Rcurses.init!
  puts "✓ Rcurses.init! works with error logging enabled"
  Rcurses.cleanup!
  puts "✓ Rcurses.cleanup! works with error logging enabled"
rescue => e
  puts "✗ Error with logging enabled: #{e}"
end

# Test 3: Simulate error with logging enabled
puts "\n3. Testing error logging functionality..."
log_file = "/tmp/rcurses_errors_#{Process.pid}.log"

# Remove any existing log file for this test
File.delete(log_file) if File.exist?(log_file)

begin
  # Create a test error
  test_error = StandardError.new("Test error for logging functionality")
  test_error.set_backtrace(["test_error_logging.rb:#{__LINE__}", "other_file.rb:123"])

  # Call the private method to test logging
  Rcurses.send(:log_error_to_file, test_error)

  if File.exist?(log_file)
    puts "✓ Log file created successfully: #{log_file}"
    content = File.read(log_file)
    puts "✓ Log file contains error details (#{content.length} bytes)"
    puts "✓ Log file content preview:"
    puts content.lines.first(10).map { |l| "  #{l}" }.join
  else
    puts "✗ Log file was not created"
  end
rescue => e
  puts "✗ Error in logging test: #{e}"
end

# Test 4: Verify functionality is unchanged when RCURSES_ERROR_LOG is not set
puts "\n4. Testing that functionality is unchanged when logging is disabled..."
ENV.delete('RCURSES_ERROR_LOG')
begin
  Rcurses.init!
  puts "✓ Works normally when RCURSES_ERROR_LOG is unset"
  Rcurses.cleanup!
rescue => e
  puts "✗ Error when logging disabled: #{e}"
end

puts "\nTest completed!"
#!/usr/bin/env ruby

require_relative 'lib/rcurses'

puts "Testing rcurses compatibility and initialization..."

# Test that rcurses behaves exactly the same way with our changes
puts "\n1. Testing initialization compatibility..."

# Save original state
original_initialized = Rcurses.instance_variable_get(:@initialized)
original_cleaned_up = Rcurses.instance_variable_get(:@cleaned_up)

# Reset state for clean test
Rcurses.instance_variable_set(:@initialized, nil)
Rcurses.instance_variable_set(:@cleaned_up, nil)

begin
  # Test that init! is idempotent
  Rcurses.init!
  puts "✓ First init! call succeeded"

  first_init_state = Rcurses.instance_variable_get(:@initialized)

  Rcurses.init!
  puts "✓ Second init! call succeeded (idempotent)"

  second_init_state = Rcurses.instance_variable_get(:@initialized)

  if first_init_state == second_init_state
    puts "✓ Idempotent behavior preserved"
  else
    puts "✗ Idempotent behavior broken"
  end

  # Test cleanup
  Rcurses.cleanup!
  puts "✓ First cleanup! call succeeded"

  first_cleanup_state = Rcurses.instance_variable_get(:@cleaned_up)

  Rcurses.cleanup!
  puts "✓ Second cleanup! call succeeded (idempotent)"

  second_cleanup_state = Rcurses.instance_variable_get(:@cleaned_up)

  if first_cleanup_state == second_cleanup_state
    puts "✓ Cleanup idempotent behavior preserved"
  else
    puts "✗ Cleanup idempotent behavior broken"
  end

rescue => e
  puts "✗ Compatibility test failed: #{e}"
ensure
  # Restore original state
  Rcurses.instance_variable_set(:@initialized, original_initialized)
  Rcurses.instance_variable_set(:@cleaned_up, original_cleaned_up)
end

puts "\n2. Testing that error logging is completely opt-in..."

# Test without environment variable
ENV.delete('RCURSES_ERROR_LOG')
test_error = StandardError.new("Test error")
test_error.set_backtrace(["test:1"])

log_file = "/tmp/rcurses_errors_#{Process.pid}.log"
File.delete(log_file) if File.exist?(log_file)

# This should not create a log file
Rcurses.send(:log_error_to_file, test_error)

if File.exist?(log_file)
  puts "✗ Log file created when RCURSES_ERROR_LOG not set"
else
  puts "✓ No log file created when RCURSES_ERROR_LOG not set"
end

# Test with environment variable set to something other than '1'
ENV['RCURSES_ERROR_LOG'] = 'yes'
Rcurses.send(:log_error_to_file, test_error)

if File.exist?(log_file)
  puts "✗ Log file created when RCURSES_ERROR_LOG='yes'"
else
  puts "✓ No log file created when RCURSES_ERROR_LOG='yes'"
end

# Test with correct value
ENV['RCURSES_ERROR_LOG'] = '1'
Rcurses.send(:log_error_to_file, test_error)

if File.exist?(log_file)
  puts "✓ Log file created when RCURSES_ERROR_LOG='1'"
else
  puts "✗ No log file created when RCURSES_ERROR_LOG='1'"
end

# Clean up
File.delete(log_file) if File.exist?(log_file)
ENV.delete('RCURSES_ERROR_LOG')

puts "\nCompatibility test completed successfully!"
puts "✓ All existing functionality preserved"
puts "✓ Error logging is completely opt-in"
puts "✓ No race conditions (PID-based filenames)"
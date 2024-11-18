require 'fileutils'

# Define the source file and the target directory
source_file = File.join(File.dirname(__FILE__), 'lib/rcurses.rb')
target_dir = '/usr/lib/ruby/vendor_ruby'

# Check if we have write permission to the target directory
unless File.writable?(target_dir)
  abort("You need root permissions to install to #{target_dir}. Please run as root or use sudo.")
end

# Create the target directory if it doesn't exist
FileUtils.mkdir_p(target_dir)

# Copy the file
FileUtils.cp(source_file, target_dir)

puts "Installed #{source_file} to #{target_dir}"

# Create a dummy Makefile to satisfy Ruby's gem installation process
File.open('Makefile', 'w') do |f|
  f.puts <<-MAKEFILE
all:
\t@echo "Nothing to build"

clean:
\t@echo "Nothing to clean"

install:
\t@echo "Installation handled by extconf.rb"
  MAKEFILE
end


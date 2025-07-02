#!/usr/bin/env ruby

$LOAD_PATH.unshift('/home/geir/Main/G/GIT-isene/rcurses/lib')
require 'rcurses'
include Rcurses

puts "=== Testing Pane Color Preservation ==="

# Create a pane and test colored text
pane = Pane.new(1, 1, 30, 5, 255, 232)
pane.say("Regular text")
pane.say("Colored: #{'red'.fg(196)} text")  
pane.say("Bold: #{'bold'.b} text")
pane.say("Mixed: #{'red bold'.fg(196).b} text")

puts "Pane created and text added with colors"
puts "Text content: #{pane.instance_variable_get(:@text).inspect}"

pane.refresh
sleep(3)
pane.clear
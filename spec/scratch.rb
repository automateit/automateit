#!/usr/bin/env ruby
#
$LOAD_PATH << "lib"

require "automateit"

puts "==0"
ai = AutomateIt.new
puts "==1"
ai.sh "ls"
puts "==2"
ai.platform_manager.setup(:default => :struct)

#!/usr/bin/env automateit

puts "Hello world!"
puts "I'm an #{self.class}"
puts "My tags, let me show them to you: %s" % tags.to_a.inspect
writing?("I'm in noop mode") do
  puts "I'm in writing mode"
end

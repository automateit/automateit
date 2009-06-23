#!/usr/bin/env automateit

puts "Hello world!"
puts "I'm an #{self.class}"
puts "My tags, let me show them to you: %s" % tags.to_a.inspect
preview_for("I'm in preview mode") do
  puts "I'm not in preview mode"
end

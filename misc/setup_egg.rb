#!/usr/bin/env automateit

# Install Python's easy_install package manager for 'egg' files

SOURCE = 'http://peak.telecommunity.com/dist/ez_setup.py'

require 'open-uri'

mktemp do |t|
  File.open(t, "w+") {|h| h.write(open(SOURCE).read)}
  sh "python #{t}"
end

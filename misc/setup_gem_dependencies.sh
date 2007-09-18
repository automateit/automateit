#!/bin/sh

cmd = 'gem install -y rake open4 activesupport rspec ruby-breakpoint ruby-debug --no-rdoc --no-ri'

# Run it twice because the first one will usually fail. Oh how I hate gem. :/
$cmd
$cmd

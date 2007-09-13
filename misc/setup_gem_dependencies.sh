#!/bin/sh

# Run it twice because the first one will usually fail. Oh how I hate gem. :/
gem install -y rake open4 activesupport rspec --no-rdoc --no-ri \
    || gem install -y rake open4 activesupport rspec --no-rdoc --no-ri

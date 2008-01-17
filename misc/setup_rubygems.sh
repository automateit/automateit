#!/usr/bin/env bash

# SUMMARY: Installs the rubygems system for managing Ruby libraries

# RELEASES: http://rubyforge.org/frs/?group_id=126

URL="http://rubyforge.org/frs/download.php/29548/rubygems-1.0.1.tgz"
PACKAGE=$(echo $URL | sed "s/\.[^\.]*$//; s/^.*\///")

pushd "/tmp"
  CACHE=`mktemp -d install_rubygems.XXXXXXXXXX`
  pushd "$CACHE"
    wget -c -T20 -q "$URL"
    tar xfz "$PACKAGE.tgz"
    cd "$PACKAGE"
    sudo ruby setup.rb
  popd
popd

# Uninstall, only run this if there's no other version of rubygems on the system or it'll destroy those up too:
### rm -rf /usr/bin/{gem{,1.*},update_rubygems*} /usr/local/lib/site_ruby/1.8/{{,r}ubygems.rb,rubygems} /usr/lib/ruby/gems

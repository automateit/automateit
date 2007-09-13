#!/bin/sh

# RELEASES: http://rubyforge.org/frs/?group_id=126

#PACKAGE="rubygems-0.9.0"
#URL="http://rubyforge.org/frs/download.php/11289/rubygems-0.9.0.tgz"
PACKAGE="rubygems-0.9.3"
URL="http://rubyforge.org/frs/download.php/20585/rubygems-0.9.3.tgz"

CACHE=`mktemp -p /tmp -d install_rubygems.XXXXXXXXXX`
cd "$CACHE"

wget -c -T20 -q "$URL"
tar xfz "$PACKAGE.tgz"
cd "$PACKAGE"
sudo ruby setup.rb

cd /
rm -rf "$CACHE"

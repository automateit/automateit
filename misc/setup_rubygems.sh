#!/usr/bin/env bash

# RELEASES: http://rubyforge.org/frs/?group_id=126

PACKAGE="rubygems-0.9.3"
URL="http://rubyforge.org/frs/download.php/20585/rubygems-0.9.3.tgz"

pushd "/tmp"

CACHE=`mktemp -d install_rubygems.XXXXXXXXXX`
pushd "$CACHE"

wget -c -T20 -q "$URL"
tar xfz "$PACKAGE.tgz"
cd "$PACKAGE"
sudo ruby setup.rb

popd
rm -rf "$CACHE"

popd

#!/usr/bin/env perl

# Example: ./is_available.pl Acme::please CPAN

use warnings "all";
use File::Basename;
my $wrapper = dirname($0)."/cpan_wrapper.pl";
require $wrapper;

@modules = @ARGV;
unless ($#modules >= 0) {
  print "Usage: uninstall.pl mymodule [mymodule]\n";
  exit 1
}

my @available;
my @unavailable;
foreach my $module (@modules) {
  if (CpanWrapper->is_installed($module)) {
    push(@available, $module);
  } else {
    push(@unavailable, $module);
  }
}

sub print_contents {
  my($name, @modules) = @_;
  return if $#modules < 0;
  print "$name:\n";
  foreach my $module (@modules) {
    print "  - $module\n";
  }
}

print "--- %YAML:1.0\n";
print_contents 'available', @available;
print_contents 'unavailable', @unavailable;

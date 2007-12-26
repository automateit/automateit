#!/usr/bin/env perl

# Example: ./install.pl Acme::please

use warnings "all";
use File::Basename;
my $wrapper = dirname($0)."/cpan_wrapper.pl";
require $wrapper;

sub usage {
  my($message) = @_;
  print <<EOB;
usage: install.pl [--quiet|--help|--dryrun] module [modules...]
EOB
  if ($message) {
    print "ERROR: $message\n";
    exit 1;
  } else {
    exit 0;
  }
}

use Getopt::Long;
our $quiet = 0;
our $dryrun = 0;
our $help = 0;
GetOptions(
  'quiet' => \$quiet,
  'dryrun' => \$dryrun,
  'n' => \$dryrun,
  'help' => \$help
);

if (1 == $help) {
  usage(0);
}

@modules = @ARGV;
unless ($#modules >= 0) {
  usage "No modules specified";
}

$CpanWrapper::DRYRUN = $dryrun;
if (0 && $CpanWrapper::DRYRUN) { die } # Squelch warnings

# Uninstall modules
foreach my $module (@modules) {
  if (CpanWrapper->is_installed($module)) {
    print "! Module already installed: $module\n";
    next;
  }

  if (CpanWrapper->install($module)) {
    print "* Installed: $module\n" unless $quiet;
  } else {
    print "! Can't find CPAN module: $module\n";
    exit 1
  }
}

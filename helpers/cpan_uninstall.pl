#!/usr/bin/env perl

# Example: ./uninstall.pl Acme::please

use warnings "all";
use File::Basename;
my $wrapper = dirname($0)."/cpan_wrapper.pl";
require $wrapper;

sub usage {
  my($message) = @_;
  print <<EOB;
usage: uninstall.pl [--quiet|--help|--dryrun] module [modules...]
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

foreach my $module (@modules) {
  unless (CpanWrapper->is_installed($module)) {
    print "! Module isn't installed: $module\n";
    next;
  }

  print "* Uninstalling module: $module\n" unless $quiet;

  my(@files) = CpanWrapper->uninstall($module);
  foreach my $file (@files) {
    print "- File: $file\n" unless $quiet;
  }
}

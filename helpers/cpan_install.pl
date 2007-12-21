#!/usr/bin/env perl

# Example: ./install.pl Acme::please

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

use warnings "all";
use CPAN;
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

foreach my $module (@modules) {
  if (my $module_ref = CPAN::Shell->expand('Module', $module)) {
    print "* Installing: $module\n" unless $quiet;
    $module_ref->install unless $dryrun;
  } else {
    print "! Can't find CPAN module: $module\n";
    exit 1
  }
}

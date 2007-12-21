#!/usr/bin/env perl

# Example: ./uninstall.pl Acme::please

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

use warnings "all";
use ExtUtils::Packlist;
use ExtUtils::Installed;
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

sub nuke {
  my($target) = @_;
  if ($dryrun == 0) {
    unlink($target) || die "$! -- $target"
  }
}

my $packlists = ExtUtils::Installed->new();

foreach my $module (@modules) {
  print "* Uninstalling module: $module\n" unless $quiet;

  foreach my $item ($packlists->files($module)) {
    print "- File: $item\n" unless $quiet;
    nuke $item;
  }

  my $packlist = $packlists->packlist($module)->packlist_file();
  print "- List: $packlist\n" unless $quiet;
  nuke $packlist;
}

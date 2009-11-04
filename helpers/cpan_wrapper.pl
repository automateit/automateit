#!/usr/bin/env perl

# This file can be used as both a Perl library (read the POD below) and a
# stand-alone program (run it with "--help" for instructions).

=head1 NAME

CpanWrapper - Provides a simpler wrapper for the CPAN package manager.

=head1 DESCRIPTION

This module provides easy-to-use methods for installing, uninstalling and
querying the status of CPAN modules.

=over

=cut

use warnings "all";

package CpanWrapper;

require CPAN;
require ExtUtils::Packlist;
require ExtUtils::Installed;
require Tie::Handle;

=head1 CLASS VARIABLES

=item $CpanWrapper::DRYRUN

Should actions really happen? E.g., in dry-run mode, the uninstall will only
pretend to delete files.

=cut

our $DRYRUN = 0;

=head1 CLASS METHODS

=item CpanWrapper->query($module_name)

Query the module and return 1 if it's installed, 0 if not.

=cut
sub query {
  my($class, $module) = @_;
  no warnings;
  my $result = $CPAN::META->has_inst($module);
  use warnings "all";
  return $result;
}

=item CpanWrapper->uninstall($module_name)

Uninstall the module. Returns an array of files removed.

=cut
sub uninstall {
  # /usr/local/lib/perl/5.8.8/auto/ack/.packlist
  my($class, $module) = @_;
  my $packlists = ExtUtils::Installed->new;
  my @result;
  foreach my $file ($packlists->files($module)) {
    push(@result, $file);
    unlink $file unless $DRYRUN;
  }
  my $packlist = $packlists->packlist($module)->packlist_file();
  push(@result, $packlist);
  unlink $packlist unless $DRYRUN;
  return @result;
}

=item CpanWrapper->install($module_name)

Install the module. 

Returns:
1 if successful
0 if can't find module
-1 if module is already installed
=cut
sub install {
  my($class, $module) = @_;

  # Don't install module if already installed.
  if ($class->query($module)) {
      return -1;
  }

  no warnings;
  tie *NO, 'NoHandle';
  open(SAVEIN, ">&STDIN");
  open(STDIN, ">&NO"); # TODO why isn't this enough?
  *STDIN = *NO;
  my $result;
  if (my $module_ref = CPAN::Shell->expand('Module', $module)) {
    unless ($DRYRUN) {
        # Ignore errors from "clean", because it may not exist.
        eval { $module_ref->clean; };
        # Actually install the module.
        $module_ref->install;
    };
    $result = 1;
  } else {
    $result = 0;
  }
  open(STDIN, ">&SAVEIN");
  close NO;
  use warnings "all";
  return $result;
}

=item NoHandle

File handle that responds with "no" to all readline queries. This is used
during the install process to reject CPAN's unreasonable defaults.

=cut
package NoHandle;
sub TIEHANDLE { my $self; bless \$self, shift }
sub WRITE { die }
sub PRINT { die }
sub PRINTF { die }
sub READ { die }
sub READLINE { print "no\n"; return "no\n" }
sub GETC { die }
sub CLOSE { }
sub OPEN { }
sub BINMODE { }
sub EOF { 0 }
sub TELL { }
sub DESTROY { }

#===[ command-line usage ]==============================================

package main;
if ($0 eq __FILE__) {
  sub usage {
    my($message) = @_;
    print <<HERE;
USAGE: cpan_wrapper.pl [OPTIONS] ACTION module [modules...]

OPTIONS:
--help
    Show this help
--quiet
    Don't print anything other than what CPAN generates
--dryrun
    Don't actually perform actions, just pretend to

ACTIONS:

--install
    Install modules
--uninstall
    Uninstall modules
--query
    Display which packages are installed and which aren't
HERE

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
  our $install = 0;
  our $uninstall = 0;
  our $query = 0;
  GetOptions(
    'quiet' => \$quiet,
    'dryrun' => \$dryrun,
    'n' => \$dryrun,
    'help' => \$help,
    'install' => \$install,
    'uninstall' => \$uninstall,
    'query' => \$query,
    'q' => \$query
  );
  my @modules = @ARGV;

  usage(0) if 1 == $help;
  usage("No action specified") unless $install or $uninstall or $query;
  usage("No modules specified") unless $#modules >= 0;

  if ($install) {
    foreach my $module (@modules) {
      my $status = CpanWrapper->install($module);
      if ($status == 1) {
        print "* Installed: $module\n" unless $quiet;
      } elsif ($status == 0) {
        print "! Can't find CPAN module: $module\n";
        exit 1
      } elsif ($status == -1) {
        print "* Already installed: $module\n" unless $quiet;
      } else {
      }
    }
  } elsif ($uninstall) {
    foreach my $module (@modules) {
      print "* Uninstalling module: $module\n" unless $quiet;

      my(@files) = CpanWrapper->uninstall($module);
      foreach my $file (@files) {
        print "- $file\n" unless $quiet;
      }
    }
  } elsif ($query) {
    my @available;
    my @unavailable;
    foreach my $module (@modules) {
      if (CpanWrapper->query($module)) {
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
  }
}

1;

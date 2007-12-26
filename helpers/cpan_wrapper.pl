package CpanWrapper;
use CPAN;
use ExtUtils::Packlist;
use ExtUtils::Installed;

=head1 NAME

CpanWrapper - Provides a simpler wrapper for CPAN package methods.

=head1 DESCRIPTION

This module provides easy-to-use methods for performing typical tasks that the
CPAN module makes difficult for some incomprehensible reason.

=head1 CLASS VARIABLES

=item $CpanWrapper::DRYRUN
  
Should actions really happen? E.g., in dry-run mode, the uninstall will only
pretend to delete files.

=cut

our $DRYRUN = 0;

=item CpanWrapper->is_installed($module_name)

Returns 1 if the module is installed, else 0.

Example:

  CpanWrapper->is_installed('App::Ack')
=cut
sub is_installed {
  my($class, $module) = @_;
  return $CPAN::META->has_inst($module);
}

=item CpanWrapper->uninstall($module_name)

Uninstall the module. Returns an array of files removed.
=cut
sub uninstall {
  my($class, $module) = @_;
  my $packlists = ExtUtils::Installed->new;
  my @result;
  foreach my $file ($packlists->files($module)) {
    push(@result, $file);
    unlink $file unless $DRYRUN;
  }
  return @result;
}

=item CpanWrapper->install($module_name)

Install the module. Returns 0 if can't find module.
=cut
sub install {
  my($class, $module) = @_;
  tie *NO, 'NoHandle';
  open(SAVEIN, ">&STDIN");
  open(STDIN, ">&NO"); # TODO why isn't this enough?
  *STDIN = *NO;
  my $result;
  if (my $module_ref = CPAN::Shell->expand('Module', $module)) {
    $module_ref->install unless $DRYRUN;
    $result = 1;
  } else {
    $result = 0;
  }
  open(STDIN, ">&SAVEIN");
  close NO;
  return $result;
}

=item NoHandle

File handle that responds with "no" to all readline queries. This is used
during the install process to reject CPAN's bad defaults.
=cut
require Tie::Handle;
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
package main;

1;

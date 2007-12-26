package CpanWrapper;
use CPAN;

=head1 NAME

CpanWrapper - Provides a simpler wrapper for CPAN package methods.

=head DESCRIPTION

This module provides easy-to-use methods for performing typical tasks that the
CPAN module makes difficult for some incomprehensible reason.

=cut

=item CpanWrapper->is_installed($module_name)

Returns 1 if the module is installed, else 0.

Example:

  CpanWrapper->is_installed('App::Ack')
=cut
sub is_installed {
  my($class, $module) = @_;
  return $CPAN::META->has_inst($module);
}

=item CpanWrapper->install($module_name)

Install the module.
=cut
sub install {
  die "FIXME";
}

=item CpanWrapper->uninstall($module_name)

Uninstall the module.
=cut
sub uninstall {
  die "FIXME";
}

1;

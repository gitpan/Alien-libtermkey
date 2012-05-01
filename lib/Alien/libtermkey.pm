#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Alien::libtermkey;

our $VERSION = '0.07';

use ExtUtils::PkgConfig;
my $libdir = '@LIBDIR@';
my $module = '@PKGCONFIG_MODULE@';

=head1 NAME

C<Alien::libtermkey> - L<Alien> wrapping for F<libtermkey>

=head1 DESCRIPTION

This CPAN distribution installs a local copy of F<libtermkey>, primarily for
use by the L<Term::TermKey> distribution. It is not intended to be used
directly.

This module bundles F<libtermkey> version 0.15a (including the cursor position
bugfix).

=head1 METHODS

This module behaves like L<ExtUtils::PkgConfig>, responding to the same
methods, except that the module name is implied. Thus, the configuration can
be obtained by calling

 $cflags = Alien::libtermkey->cflags
 $libs = Alien::libtermkey->libs

 $ok = Alien::libtermkey->atleast_version( $version )

 etc...

=cut

# I AM EVIL
sub AUTOLOAD
{
   our $AUTOLOAD =~ s/^.*:://;
   return _get_pkgconfig( $AUTOLOAD, @_ );
}

sub _get_pkgconfig
{
   my ( $method, $self, @args ) = @_;

   local $ENV{PKG_CONFIG_PATH} = "$libdir/pkgconfig/";
   return ExtUtils::PkgConfig->$method( $module, @args );
}

sub libs
{
   # Append RPATH so that runtime linking actually works
   return _get_pkgconfig( libs => @_ ) . " -Wl,-R$libdir";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

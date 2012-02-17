package Alien::libtermkey::Module::Build;

use strict;
use warnings;

use base qw( Module::Build );

use ExtUtils::PkgConfig;
use File::Basename qw( dirname );
use File::Spec;
use File::Path qw( make_path );

use constant SRCDIR => "src";

__PACKAGE__->add_property( 'tarball' );
__PACKAGE__->add_property( 'pkgconfig_module' );

sub _srcdir
{
   my $self = shift;
   return File::Spec->catdir( $self->base_dir, SRCDIR );
}

sub in_srcdir
{
   my $self = shift;

   chdir( $self->_srcdir ) or
      die "Unable to chdir to srcdir - $!";

   shift->();
}

sub ACTION_src
{
   my $self = shift;

   -d $self->_srcdir and return;

   my $tarball = $self->tarball;

   system( "tar", "xzf", $tarball ) == 0 or
      die "Unable to untar $tarball - $!";

   ( my $untardir = $tarball ) =~ s{\.tar\.[a-z]+$}{};

   -d $untardir or
      die "Expected to find a directory called $untardir\n";

   rename( $untardir, $self->_srcdir ) or
      die "Unable to rename src dir - $!";
}

sub ACTION_code
{
   my $self = shift;

   $self->depends_on( 'src' );

   $self->in_srcdir( sub {
      system( "make" ) == 0 or
         die "Unable to make - $!";
   } );
}

sub ACTION_install
{
   my $self = shift;

   $self->depends_on( 'code' );

   my $libdir = $self->install_destination( "arch" );
   my $incdir = File::Spec->catdir( $libdir, "include" );
   my $man3dir = $self->install_destination( "libdoc" );
   my $man7dir = $self->install_destination( "libdoc" );

   $self->in_srcdir( sub {
      system( "make", "install", "LIBDIR=$libdir", "INCDIR=$incdir", "MAN3DIR=$man3dir", "MAN7DIR=$man7dir" ) == 0 or
         die "Unable to make install - $!";
   } );

   my %replace = (
      LIBDIR           => $libdir,
      PKGCONFIG_MODULE => $self->pkgconfig_module,
   );

   # Turn ' into \' in replacements
   s/'/\\'/g for values %replace;

   my @module_file = split m/::/, $self->module_name . ".pm";

   $self->cp_file_with_replacement(
      srcfile => File::Spec->catfile( $self->base_dir, "lib", @module_file ),
      dstfile => File::Spec->catfile( $self->install_destination( "lib" ), @module_file ),
      replace => \%replace,
   );
}

sub cp_file_with_replacement
{
   my $self = shift;
   my %args = @_;

   my $srcfile = $args{srcfile};
   my $dstfile = $args{dstfile};
   my $replace = $args{replace};

   make_path( dirname( $dstfile ), 0, 0777 );

   open( my $inh,  "<", $srcfile ) or die "Cannot read $srcfile - $!";
   open( my $outh, ">", $dstfile ) or die "Cannot write $dstfile - $!";

   print "Installing $srcfile as $dstfile\n";

   while( my $line = <$inh> ) {
      $line =~ s/\@$_\@/$replace->{$_}/g for keys %$replace;
      print $outh $line;
   }
}

sub ACTION_clean
{
   my $self = shift;

   if( -d $self->_srcdir ) {
      $self->in_srcdir( sub {
         system( "make", "clean" ) == 0 or
            die "Unable to make clean - $!";
      } );
   }
}

sub ACTION_realclean
{
   my $self = shift;

   if( -d $self->_srcdir ) {
      system( "rm", "-rf", $self->_srcdir ); # best effort; ignore failure
   }

   $self->SUPER::ACTION_realclean;
}

0x55AA;

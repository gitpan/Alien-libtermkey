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

   my $blib = File::Spec->catdir( $self->base_dir, "blib" );

   my $libdir = File::Spec->catdir( $blib, "arch" );
   my $incdir = File::Spec->catdir( $libdir, "include" );
   my $mandir = File::Spec->catdir( $blib, "libdoc" );

   # TODO: Find a better condition than this. Also this sucks because this
   # line alone is libtermkey-specific :(
   unless( -f "$libdir/libtermkey.so" ) {
      $self->depends_on( 'src' );

      $self->in_srcdir( sub {
         system( "make" ) == 0 or
            die "Unable to make - $!";
      } );

      $self->in_srcdir( sub {
         system( "make", "install", "LIBDIR=$libdir", "INCDIR=$incdir", "MAN3DIR=$mandir", "MAN7DIR=$mandir" ) == 0 or
            die "Unable to make install - $!";
      } );
   }

   my @module_file = split m/::/, $self->module_name . ".pm";
   my $srcfile = File::Spec->catfile( $self->base_dir, "lib", @module_file );
   my $dstfile = File::Spec->catfile( $blib, "lib", @module_file );

   unless( $self->up_to_date( $srcfile, $dstfile ) ) {
      my $real_libdir = $self->install_destination( "arch" );

      my $pkgconfig_module = $self->pkgconfig_module;

      my %replace = (
         LIBDIR           => $libdir,
         PKGCONFIG_MODULE => $pkgconfig_module,
      );

      # Turn ' into \' in replacements
      s/'/\\'/g for values %replace;

      $self->cp_file_with_replacement(
         srcfile => $srcfile,
         dstfile => $dstfile,
         replace => \%replace,
      );
   }
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

   while( my $line = <$inh> ) {
      $line =~ s/\@$_\@/$replace->{$_}/g for keys %$replace;
      print $outh $line;
   }
}

sub ACTION_test
{
   my $self = shift;

   $self->depends_on( "code" );

   $self->in_srcdir( sub {
      system( "make", "test" ) == 0 or
         die "Unable to make test - $!";
   } );
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

   $self->SUPER::ACTION_clean;
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

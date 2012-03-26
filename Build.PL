use strict;
use warnings;

use lib 'inc';
use Alien::libtermkey::Module::Build;

my $build = Alien::libtermkey::Module::Build->new(
   module_name => 'Alien::libtermkey',
   tarball => 'libtermkey-0.14.tar.gz',
   pkgconfig_module => "termkey",

   configure_requires => {
      'ExtUtils::PkgConfig' => 0,
      'Module::Build' => 0,
   },
   requires => {
      'ExtUtils::PkgConfig' => 0,
      'File::Basename' => 0,
      'File::Path' => 0,
      'File::Spec' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;

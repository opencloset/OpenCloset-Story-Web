use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.17;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "lib\/OpenCloset\/Story\/Web\/files";


my %WriteMakefileArgs = (
  "ABSTRACT" => "OpenCloset story web",
  "AUTHOR" => "\x{ae40}\x{b3c4}\x{d615} - Keedi Kim <keedi\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17",
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "OpenCloset-Story-Web",
  "EXE_FILES" => [
    "bin/opencloset-story-web.pl"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "OpenCloset::Story::Web",
  "PREREQ_PM" => {
    "File::ShareDir" => 0,
    "Mojo::Base" => 0,
    "Mojo::Util" => 0,
    "Mojolicious::Commands" => 0,
    "Mojolicious::Plugin::AssetPack" => "1.04",
    "Mojolicious::Plugin::Authentication" => 0,
    "OpenCloset::Constants::Category" => 0,
    "OpenCloset::Schema" => "0.027",
    "Path::Tiny" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ExtUtils::MakeMaker" => 0,
  "File::ShareDir" => 0,
  "File::Spec" => 0,
  "Mojo::Base" => 0,
  "Mojo::Util" => 0,
  "Mojolicious::Commands" => 0,
  "Mojolicious::Plugin::AssetPack" => "1.04",
  "Mojolicious::Plugin::Authentication" => 0,
  "OpenCloset::Constants::Category" => 0,
  "OpenCloset::Schema" => "0.027",
  "Path::Tiny" => 0,
  "Test::More" => 0,
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}

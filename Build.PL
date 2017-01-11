use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'P4::Objects',
    license             => 'perl',
    dist_author         => 'Stephen Vance <steve@vance.com>',
    dist_version_from   => 'lib/P4/Objects.pm',
    requires            => {
        'Date::Parse'           => 0,
        'Error'                 => 0,
        'Error::Exception'      => 0,
        'Exception::Class'      => 0,
        'Log::Log4perl'         => 0,
        'P4'                    => 0,
    },
    build_requires => {
        'Module::Locate'        => 0,
        'P4::Server'            => 0.07,
        'Test::More'            => 0,
        'Test::Unit'            => 0,
    },
    add_to_cleanup      => [ 'P4-Objects-*' ],
);

$builder->create_build_script();

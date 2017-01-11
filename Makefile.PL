use strict;
use warnings;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';
if( $@ ) {
    warn "Optional ExtUtils::MakeMaker::Coverage not available\n";
}
else {
    my $covconfig = ExtUtils::MakeMaker::Coverage->config();
    # Ignore the test exceptions in the coverage stats
    $covconfig->ignore( [
                '/Exception.pm',
                'P4/Server.pm',
                'P4/Server/BasicException.pm',
    ] );
    # Subroutine coverage doesn't work for Class::Std PRIVATE and RESTRICTED
    $covconfig->cover_subroutine( 0 );
    # We don't need POD testing here since we have a separate POD test
    $covconfig->cover_pod( 0 );
}

WriteMakefile(
    NAME                => 'P4::Objects',
    AUTHOR              => 'Stephen Vance <steve@vance.com>',
    VERSION_FROM        => 'lib/P4/Objects.pm',
    ABSTRACT_FROM       => 'lib/P4/Objects.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Date::Parse'           => 0,
        'Error'                 => 0,
        'Error::Exception'      => 0,
        'Exception::Class'      => 0,
        'Log::Log4perl'         => 0,
        'Module::Locate'        => 0,       # Build and test
        'P4'                    => 0,
        'P4::Server'            => 0.07,    # Build and test
        'Test::More'            => 0,       # Build and test
        'Test::Unit'            => 0,       # Build and test
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'P4-Objects-*' },
);

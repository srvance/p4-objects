# Copyright (C) 2007 Stephen Vance
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
#
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
#
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package P4::Objects::Test::Session;

use strict;
use warnings;

use Error qw( :try );

use Cwd qw( abs_path );
use Data::Dumper;
use File::Spec::Functions;
use File::Temp qw( tempdir );
use P4::Objects::Session;
use P4::Objects::Test::Helper::Session::NewFailRepository;
use P4::Objects::Test::Helper::Session::NewFailConnection;

use Cwd;
use File::Spec::Functions;

use base qw( P4::Objects::Test::Helper::TestCase );

our $dirtemplate = File::Spec->catfile(
    File::Spec->tmpdir(),
    'p4objects-sessiontest-XXXXXX'
);

our $ws_name = 'mybiglongprobablyuniquelynamedworkspace';

our %parm_cache = ();
our @supported_parms = (
            'P4USER',
            'P4PORT',
            'P4HOST',
            'P4CLIENT',
            'P4CHARSET',
);
our @unsupported_parms = (
            'P4CONFIG', # Doesn't work from Perl on Windows
            'P4COMMANDCHARSET',
            'P4DIFF',
            'P4DIFFUNICODE',
            'P4EDITOR',
            'P4LANGUAGE',
            'P4MERGE',
            'P4MERGEUNICODE',
            'P4PAGER',
            'P4TICKETS',
);
our @all_parms = ( @supported_parms, @unsupported_parms );
our %test_env_values = (
            'P4USER'             =>  'myself',
            'P4PORT'             =>  'myserver:1717',
            'P4HOST'             =>  'mymachine',
            'P4CLIENT'           =>  'probablyuniqueworkspacename',
            'P4CHARSET'          =>  'shiftjis',
            'P4CONFIG'           =>  'stupidconfigfilename',
            'P4COMMANDCHARSET'   =>  'iso8859-1',
            'P4DIFF'             =>  'nonexistantdiffprogram',
            'P4DIFFUNICODE'      =>  'nonexistantunicodediffprogram',
            'P4EDITOR'           =>  'nonexistanteditor',
            'P4LANGUAGE'         =>  'yupikeskimo',
            'P4MERGE'            =>  'nonexistantmergeprogram',
            'P4MERGEUNICODE'     =>  'nonexistantunicodemergeprogram',
            'P4PAGER'            =>  'same',
            'P4TICKETS'          =>  'bogusticketlocation',
);

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

my %saved_env;
sub set_up {
    %saved_env = %ENV;
}

sub tear_down {
    # Windows has problems with this for some reason.
    %ENV = %saved_env if( $^O ne 'MSWin32' );
}

sub test_new {
    my $self = shift;
    my $session = P4::Objects::Session->new();
    $self->assert_not_null( $session );

    return;
}

sub test_new_repository {
    my $self = shift;
    my $session = P4::Objects::Session->new();
    $self->assert_not_null( $session );

    my $repo = $session->get_repository();
    $self->assert_not_null( $repo );

    $self->assert_equals( $session, $repo->get_session() );

    return;
}

sub test_new_repository_fail {
    my $self = shift;
    my $session = undef;

    try {
        $session = P4::Objects::Test::Helper::Session::NewFailRepository->new();
    }
    catch P4::Objects::Exception::BadAlloc with {
        # Correct behavior
    }
    otherwise {
        $self->assert( 0, "No error or unexpected error" );
    }
    finally {
        $self->assert_null( $session );
    };

    return;
}

sub test_new_connection {
    my $self = shift;
    my $session = P4::Objects::Session->new();
    $self->assert_not_null( $session );

    my $conn = $session->get_connection();
    $self->assert_not_null( $conn );

    $self->assert_equals( $session, $conn->get_session() );

    return;
}

sub test_new_connection_fail {
    my $self = shift;
    my $session = undef;

    try {
        $session = P4::Objects::Test::Helper::Session::NewFailConnection->new();
    }
    catch P4::Objects::Exception::BadAlloc with {
        # Correct behavior
    }
    otherwise {
        $self->assert( 0, "No error or unexpected error" );
    }
    finally {
        $self->assert_null( $session );
    };

    return;
}

sub test_new_environment_env {
    my $self = shift;

    return if( $^O eq 'MSWin32' );

    # Cache prior values and set our own for verification
    $self->_cache_environment( @supported_parms );
    $self->_set_environment( %test_env_values );

    my $session = P4::Objects::Session->new();

    $self->_validate_test_parms( $session, @supported_parms );

    # Clean up.
    $self->_restore_cached_environment();

    return;
}

sub test_new_environment_config {
    my $self = shift;

    # Windows doesn't reflect the change in environment (PWD) the same way as
    # Unix-like platforms, and there's no way to invoke P4::SetCwd() before
    # the P4 object is allocated, so this test doesn't work on Windows.
    return if( $^O eq 'MSWin32' );

    my $p4config = $ENV{P4CONFIG};
    return if( ! defined( $p4config ) );

    my $testdir = tempdir( $dirtemplate, CLEANUP => 1 );

    # Set our own values for verification
    my $olddir = $self->_set_config( $testdir, $p4config, %test_env_values );

    try {
        my $session = P4::Objects::Session->new();

        $self->_validate_test_parms( $session, @supported_parms );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    }
    finally {
        # Clean up.
        $self->_remove_config( $olddir, $p4config );
    };

    return;
}

sub test_refresh_environment_env {
    my $self = shift;

    return if( $^O eq 'MSWin32' );

    my $session = P4::Objects::Session->new();

    # Assert valid initial conditions
    foreach my $parm ( @supported_parms ) {
        $self->assert_not_equals( $test_env_values{$parm}, $ENV{$parm} );

        my $getter = $self->_getter_from_parm( $parm );
        my $gotten_attr = scalar $session->$getter();
        $self->assert_not_equals( $test_env_values{$parm}, $gotten_attr );
    }

    $self->_cache_environment( @supported_parms );

    $self->_set_environment( %test_env_values );

    $session->refresh_environment();

    $self->_validate_test_parms( $session, @supported_parms );

    $self->_restore_cached_environment( %parm_cache );

    return;
}

sub test_refresh_environment_config {
    my $self = shift;

    # Windows doesn't reflect the change in environment (PWD) the same way as
    # Unix-like platforms, and there's no way to invoke P4::SetCwd() before
    # the P4 object is allocated, so this test doesn't work on Windows.
    return if( $^O eq 'MSWin32' );

    my $p4config = $ENV{P4CONFIG};
    return if( ! defined( $p4config ) );

    my $testdir = tempdir( $dirtemplate, CLEANUP => 1 );

    my $session = P4::Objects::Session->new();

    # Assert valid initial conditions
    foreach my $parm ( @supported_parms ) {
        $self->assert_not_equals( $test_env_values{$parm}, $ENV{$parm} );

        my $getter = $self->_getter_from_parm( $parm );
        my $gotten_attr = scalar $session->$getter();
        $self->assert_not_equals( $test_env_values{$parm}, $gotten_attr );
    }

    my $olddir = $self->_set_config( $testdir, $p4config, %test_env_values );

    try {
        $session->refresh_environment();

        $self->_validate_test_parms( $session, @supported_parms );
    }
    finally {
        $self->_remove_config( $olddir, $p4config );
    };

    return;
}

#
# This test is for checking the behavior of $connection->reload() after setting parameters
# properly after making a connection
#
sub test_reload_connection {
    my $self = shift;

    my $ws1         = 'client1';
    my $ws2         = 'client2';
    my $user1       = 'testuser1';
    my $user2       = 'testuser2';
    my $clientroot1 = 'CLIENTROOT1';
    my $clientroot2 = 'CLIENTROOT2';

    # We need to have the workspace and user in the server.
    my $checkpoint = <<EOC;
\@pv\@ 1 \@db.counters\@ \@journal\@ \@1\@
\@pv\@ 1 \@db.counters\@ \@upgrade\@ \@19\@
\@ex\@ 5693 1239982392
\@pv\@ 3 \@db.user\@ \@testuser1\@ \@testuser1\@\@jmicco-deb4-32\@ \@\@ 1239982380 1239982380 \@testuser1\@ \@\@ 0 \@\@ 0
\@pv\@ 3 \@db.user\@ \@testuser2\@ \@testuser2\@\@jmicco-deb4-32\@ \@\@ 1239982303 1239982303 \@testuser2\@ \@\@ 0 \@\@ 0
\@ex\@ 5693 1239982392
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@
\@ex\@ 5693 1239982392
\@pv\@ 4 \@db.domain\@ \@client1\@ 99 \@\@ \@CLIENTROOT1\@ \@\@ \@\@ \@testuser\@ 1239982329 1239982329 0 \@Created by testuser.
\@
\@pv\@ 4 \@db.domain\@ \@client2\@ 99 \@\@ \@CLIENTROOT2\@ \@\@ \@\@ \@testuser\@ 1239982349 1239982349 0 \@Created by testuser.
\@
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1239982271 1239982271 135765617 \@Default depot\@
\@ex\@ 5693 1239982392
\@pv\@ 1 \@db.view\@ \@client1\@ 0 0 \@//client1/...\@ \@//depot/...\@
\@pv\@ 1 \@db.view\@ \@client2\@ 0 0 \@//client2/...\@ \@//depot/...\@
\@ex\@ 5693 1239982392
EOC
    my $server = $self->_create_p4d( {
        journal => $checkpoint,
    } );
    my $port = $server->get_port();
    my $session = P4::Objects::Session->new();

    my $connection = $session->get_connection();
    $session->set_port( $port );
    $session->set_user( $user1 );
    $session->set_workspace( $ws1 );

    my $info = $connection->run('info');
#    print Data::Dumper::Dumper($info);
    my ($iserver,$iport) = split( ':', $info->{serverAddress});

    $self->assert_equals( $ws1,         $info->{clientName} );
    $self->assert_equals( $clientroot1, $info->{clientRoot} );
    $self->assert_equals( $user1,       $info->{userName}   );
    $self->assert_equals( $port,        $iport              );

    $session->set_workspace( $ws2 );
    $session->set_user( $user2 );
    $connection->reload();

    $info = $connection->run('info');
#    print Data::Dumper::Dumper($info);
    ($iserver,$iport) = split( ':', $info->{serverAddress});

    $self->assert_equals( $ws2,         $info->{clientName} );
    $self->assert_equals( $clientroot2, $info->{clientRoot} );
    $self->assert_equals( $user2,       $info->{userName}   );
    $self->assert_equals( $port,        $iport              );
}

sub test_get_repository {
    my $self = shift;

    my $session = P4::Objects::Session->new();
    my $repo = $session->get_repository();
    $self->assert_not_null( $repo );

    $self->assert_equals( 'P4::Objects::Repository', ref( $repo ) );

    return;
}

sub test_get_connection {
    my $self = shift;

    my $session = P4::Objects::Session->new();
    my $conn = $session->get_connection();
    $self->assert_not_null( $conn );

    $self->assert_equals( 'P4::Objects::Connection', ref( $conn ) );

    return;
}

sub test_get_raw_connection {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testuser';
    my $wsname = 'testws';

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );
    my $raw = $session->get_raw_connection();

    $self->assert_not_null( $raw );
    $self->assert_equals( 'P4::Objects::RawConnection', ref( $raw ) );

    return;
}

sub test_set_get_workspace {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testuser';

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );

    $session->set_workspace( $ws_name );
    my $gotten_ws = $session->get_workspace();
    $self->assert_not_null( $gotten_ws );
    $self->assert_equals( 'P4::Objects::Workspace', ref( $gotten_ws ) );
    $self->assert_equals( $ws_name, $gotten_ws->get_name() );
    $self->assert_equals( $session, $gotten_ws->get_session() );
    $self->assert_str_equals( $ws_name,
            $gotten_ws->get_session()->get_workspace() );

    return;
}

sub test_get_workspace_object_with_name {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $new_wsname = 'somethingtotallydifferent';
    my $user = 'testuser';

    # Assert pre-conditions
    $self->assert_not_equals( $ws_name, $new_wsname );

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );

    $session->set_workspace( $ws_name );
    my $gotten_ws = $session->get_workspace( $new_wsname );

    $self->assert_not_null( $gotten_ws );
    $self->assert_equals( 'P4::Objects::Workspace', ref( $gotten_ws ) );
    $self->assert_equals( $new_wsname, $gotten_ws->get_name() );

    return;
}

sub test_set_cwd {
    my $self = shift;

    my $session = P4::Objects::Session->new();
    my $dirname = abs_path( tempdir( $dirtemplate, CLEANUP => 1 ) );
    # A little paranoia
    $self->assert( -e $dirname && -d $dirname );

    $session->set_cwd( $dirname );

    $self->assert_equals( $dirname, getcwd() );
    $self->assert_equals( $dirname, $ENV{PWD} );
    $self->assert_equals( $dirname, $session->get_connection()->get_cwd() );

    chdir( '..' );

    return;
}

sub test_set_cwd_no_dir {
    my $self = shift;

    my $session = P4::Objects::Session->new();
    try {
        $session->set_cwd();
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Correct behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected error: ' . Dumper( $e ) );
    };

    return;
}

sub test_set_cwd_bad_dir {
    my $self = shift;
    my $baddirname = '/some/directory/unlikely/to/exist';

    my $session = P4::Objects::Session->new();
    # Assert the pre-conditions
    $self->assert( ! -d $baddirname );

    try {
        $session->set_cwd( $baddirname );
    }
    catch P4::Objects::Exception::InvalidDirectory with {
        # Correct behavior
        my $e = shift;
        $self->assert_equals( $baddirname, $e->directory() );
    }
    otherwise {
        $self->assert( 0, "No error or unexpected error" );
    };

    return;
}

sub test_stringify {
    my $self = shift;

    my $port = 'strangehost.example.com:1717';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    $self->assert_equals( $port, $session );

    return;
}

# PRIVATE METHODS

sub _cache_environment {
    my ($self, @parmlist) = @_;

    # Clear parm_cache
    for my $entry ( keys %parm_cache ) {
        delete $parm_cache{$entry};
    }

    foreach my $parm (@parmlist) {
        $parm_cache{$parm} = $ENV{$parm} if( defined( $ENV{$parm} ) );
    }

    return;
}

sub _set_environment {
    my ($self, %settings) = @_;

    foreach my $key ( keys %settings ) {
        $ENV{$key} = $settings{$key};
    }

    return;
}

sub _restore_cached_environment {
    my ($self) = @_;

    $self->_set_environment( %parm_cache );

    return;
}

sub _set_config {
    my ($self, $dir, $configfile, %settings) = @_;
    my $curdir = getcwd();

    chdir( $dir );
    $ENV{PWD} = $dir;
    open CFH, ">$configfile";
    for my $key ( keys %settings ) {
        print CFH "$key=$settings{$key}\n" if( defined( $settings{$key} ) );
    }
    close CFH;

    return $curdir;
}

sub _remove_config {
    my ($self, $dir, $configfile) = @_;

    unlink( $configfile );
    chdir( $dir );
    $ENV{PWD} = $dir;

    return;
}

sub _getter_from_parm {
    my ($self, $parm) = @_;

    $parm =~ s/P4//;
    $parm = ($parm eq 'CLIENT') ? '_get_workspace_name' : 'get_' . lc $parm;
    return $parm;
}

sub _validate_test_parms {
    my ($self, $session, @parms) = @_;

    foreach my $parm ( @parms ) {
        my $getter = $self->_getter_from_parm( $parm );

        my $gotten_attr = scalar $session->$getter();
        $self->assert_not_null( $gotten_attr, 'for attribute ' . $parm );
        $self->assert_equals( $test_env_values{$parm}, $gotten_attr,
                                $test_env_values{$parm} . ' ne ' . $gotten_attr
                                . ' for attribute ' . $parm );
    }

    return;
}

1;

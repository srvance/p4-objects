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

package P4::Objects::Test::BasicConnection;

use strict;
use warnings;

use Cwd qw( abs_path getcwd );
use Data::Dumper;
use Error qw( :try );
use P4::Objects::Exception;
use P4::Objects::Test::Helper::BasicConnection::Minimal;
use P4::Objects::Test::Helper::BasicConnection::NoopInitP4;
use P4::Objects::Test::Helper::Session::Mock;

use P4::Objects::BasicConnection;
use P4::Objects::Test::Helper::P4Fail;

use base qw( P4::Objects::Test::Helper::TestCase );

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {

    return;
}

sub tear_down {

    return;
}

sub test_new {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    $self->assert_not_null( $conn );
    $self->assert( $conn->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_new_p4 {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    $self->assert_not_null( $conn->get_p4() );

    return;
}

sub test_new_p4_bad_package {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = undef;

    try {
        $conn = P4::Objects::BasicConnection->new( {
            session     => $session,
            p4_class    => 'BadP4',
        } );
    }
    catch P4::Objects::Exception::BadPackage with {
        # Correct behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , "No error or unexpected error: " . ref( $e ) );
    }
    finally {
        $self->assert_null( $conn );
    };

    return;
}

sub test_new_p4_failure {
    my $self = shift;

    my $p4_class = 'P4::Objects::Test::Helper::P4Fail';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = undef;
    
    try {
        $conn = P4::Objects::BasicConnection->new( {
            session     => $session,
            p4_class    => $p4_class,
        } );
    }
    catch P4::Objects::Exception::BadAlloc with {
        # Correct behavior
        my $e = shift;

        $self->assert_equals( $p4_class, $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , "No error or unexpected error: " . ref( $e ) );
    }
    finally {
        $self->assert_null( $conn );
    };

    return;
}

sub test_new_session {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    my $gotten_session = $conn->get_session();
    $self->assert_equals( $session, $gotten_session );

    return;
}

sub test_new_p4_class {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    my $class = $conn->get_p4_class();
    $self->assert_equals( "P4", $class );

    return;
}

sub test_passthru_get_attrs {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    # TODO: For now just verify that they can be called. Some verification of
    # values is ideal, however.
    foreach my $attr ( $conn->get_supported_attrs() ) {
        my $getter = 'get_' . $attr;
        my $result = $conn->$getter();
    }

    return;
}

sub test_passthru_get_bad_attr {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    try {
        my $value = $conn->get_bad_attr();
    }
    otherwise {
        # Throws something defined by Class::Std
        # Would love to test the type of the exception, but
        # Class::Std::AUTOLOAD doesn't allow AUTOMETHODs to throw exceptions.
        $self->assert_not_null( $@ );
    };

    return;
}

sub test_reload {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );

    my $conn = P4::Objects::Test::Helper::BasicConnection::NoopInitP4->new( {
        session     => $session,
    } );

    $self->assert_not_null( $conn );
    my $old_p4 = $conn->get_p4();

    try {
        $conn->reload();
    }
    otherwise {
        # For some reason, $@ is defined as the empty string here.
        $self->assert( ! defined( $@ ) || $@ eq "" );
    };

    my $new_p4 = $conn->get_p4();

    $self->assert_not_null( $new_p4 );
    $self->assert_not_equals( $old_p4, $new_p4 );

    return;
}

# Can't test reload failure due to failed P4 allocation because we can't
# create an allocation failure without triggering it in new or without overly
# complicated logic in the substitute P4 class.

sub test_bad_automethod {
    my $self = shift;
    my $badmethodname = 'bad_method';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );
    my $result = undef;

    # Assert preconditions
    $self->assert( ! $conn->can( $badmethodname ) );

    try {
        $result = $conn->$badmethodname();
    }
    otherwise {
        # Correct behavior
        $self->assert_null( $result );
    };

    return;
}

sub test_run {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );

    my $results;
    try {
        $results = $conn->run( 'info' );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert( 'P4::Objects::RawConnection', $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    return;
}

sub test_run_failure {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => 'me',
    } );

    # Call the run method with a bad Perforce sub-command.
    my $results;
    try {
        $results = $conn->run( 'badcmd' );
    }
    catch P4::Objects::Exception::P4::RunError with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 1, $e->errorcount() );
        $self->assert( $e->errors()->[0] =~ /Unknown command/ );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . Dumper( $e ) );
    };

    return;
}

# Coverage motivated
sub test_run_cover_requires_arrayref {
    my $self = shift;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    my $conn = P4::Objects::Test::Helper::BasicConnection::NoopInitP4->new( {
        session     => $session,
    } );

    my $results;
    try {
        $results = $conn->run( 'info' );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert( 'P4::Objects::RawConnection', $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    return;
}

sub test_run_different_workspace {
    my $self = shift;

    my $defaultws = 'defaultws';
    my $overridews = 'overridews';
    my $user = 'me';
    my $timestamp = '3209 1186098162';
    my $host = 'thelonehost';
    my $wsroot = '/some/workspace/root';

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$host\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$defaultws\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@ 
\@pv\@ 4 \@db.domain\@ \@$overridews\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$defaultws\@ 0 0 \@//$defaultws/...\@ \@//depot/...\@ 
\@pv\@ 1 \@db.view\@ \@$overridews\@ 0 0 \@//$overridews/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_workspace( $defaultws );
    my $conn = P4::Objects::Test::Helper::BasicConnection::Minimal->new( {
        session     => $session,
    } );

    my $results = $conn->run( 'info' );

    $self->assert_equals( $defaultws, $results->{clientName} );

    $results = $conn->run( { workspace => $overridews }, 'info' );

    $self->assert_equals( $overridews, $results->{clientName} );

    return;
}

sub test_connect {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );

    try {
        $conn->connect();
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert( 'P4::Objects::RawConnection', $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    return;
}

sub test_set_get_cwd {
    my $self = shift;

    # No need to create server. Should never connect.
    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => 1717,
        user        => 'notme',
    } );

    # This is a little delicate. We have to save and restore the starting
    # directory because tmpdir() behaves differently if you're in it's result.
    my $startdir = getcwd();

    # Get a directory we know should always exist
    my $dir = File::Spec->tmpdir();

    # Assert pre-conditions
    my $cwd = $conn->get_cwd();
    $self->assert( ! defined( $cwd ) || $dir ne $cwd );

    $conn->set_cwd( $dir );

    $cwd = $conn->get_cwd();

    $self->assert_not_null( $cwd );
    $self->assert_equals( $dir, $cwd );

    chdir( $startdir );

    return;
}

sub test_stringify {
    my $self = shift;

    my $port = 'somehost.example.com:1717';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );

    $self->assert_equals( $port, $conn );

    return;
}

sub test_stringify_no_port {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::BasicConnection->new( { session => $session } );

    $self->assert_equals( '', $conn );

    return;
}

1;

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

package P4::Objects::Test::RawConnection;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Exception;
use P4::Objects::Test::Helper::Session::Mock;
use P4::Objects::Test::Helper::P4::AlwaysDropped;
use P4::Objects::Test::Helper::P4::NeverConnects;

use P4::Objects::RawConnection;
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
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $self->assert_not_null( $conn );
    $self->assert( $conn->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_new_p4 {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $self->assert_not_null( $conn->get_p4() );

    return;
}

sub test_new_p4_bad_package {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = undef;

    try {
        $conn = P4::Objects::RawConnection->new( {
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
        $conn = P4::Objects::RawConnection->new( {
            session     => $session,
            p4_class    => $p4_class,
        } );
    }
    catch P4::Objects::Exception::BadAlloc with {
        # Expected behavior
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
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    my $gotten_session = $conn->get_session();
    $self->assert_equals( $session, $gotten_session );

    return;
}

sub test_new_p4_class {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    my $class = $conn->get_p4_class();
    $self->assert_equals( "P4", $class );

    return;
}

sub test_passthru_get_attrs {
    my ($self) = @_;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    # TODO: For now just verify that they can be called. Some verification of
    # values is ideal, however.
    foreach my $attr ( $conn->get_supported_attrs() ) {
        my $getter = 'get_' . $attr;
        my $result = $conn->$getter();
    }

    return;
}

sub test_passthru_get_bad_attr {
    my ($self) = @_;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
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
    my ($self) = @_;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );

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
    my ($self) = @_;
    my $badmethodname = 'bad_method';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    my $result = undef;

    # Assert preconditions
    $self->assert( ! $conn->can( $badmethodname ) );

    try {
        $result = $conn->$badmethodname();
    }
    otherwise {
        # Expected behavior
        $self->assert_null( $result );
    };

    return;
}

sub test_run {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $session->set_connection( $conn );

    my $results;
    try {
        $results = $conn->run( 'info' );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        my $errors = $e->errors();
        $self->assert( 0, "Unexpected Perforce error: "
                            . join( "\n", @$errors)
        );
    };

    # Arbitrary number of lines but good enough for 'info' results
    $self->_assert_array( $results );
    # Verify that it's scalar
    $self->assert_equals( "", ref( $results->[0] ) );
    $self->assert_equals( "User name: $user", $results->[0] );

    return;
}

sub test_run_failure {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $session->set_connection( $conn );

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
        $self->assert( 0, "No or unexpected exception");
    };

    return;
}

sub test_run_empty_result {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $session->set_connection( $conn );

    # Run a command that requires an array result, but that we know will
    # produce no results.
    my $results;
    try {
        $results = $conn->run( 'clients' );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        my $errors = $e->errors();
        $self->assert( 0, "Unexpected Perforce error: "
                            . join( "\n", @$errors)
        );
    };

    $self->assert_not_null( $results );
    $self->assert_equals( 0, scalar @$results );

    return;
}

sub test_connect {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $session->set_connection( $conn );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    # TODO: Verify that the connection happened with the right parameters.
    #       This may have to happen in a run test instead of here, so we can
    #       successfully use 'info'.

    return;
}

sub test_connect_twice {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );
    $session->set_connection( $conn );

    # This line motivated by coverage. Could be done in any of these tests.
    $conn->get_session()->set_charset( 'utf8' );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    return;
}

# Coverage motivated
sub test_connect_dropped {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    # This line motivated by coverage. Could be done in any of these tests.
    $session->set_charset( '' );
    my $conn = P4::Objects::RawConnection->new( {
        session     => $session,
        p4_class    => 'P4::Objects::Test::Helper::P4::AlwaysDropped',
    } );
    $session->set_connection( $conn );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    return;
}

# Coverage motivated
sub test_connect_fails {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();
    my $user = 'me';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    # This line motivated by coverage. Could be done in any of these tests.
    $session->set_charset( 'utf8' );
    my $conn = P4::Objects::RawConnection->new( {
        session     => $session,
        p4_class    => 'P4::Objects::Test::Helper::P4::NeverConnects',
    } );
    $session->set_connection( $conn );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        # Expected result
    }
    otherwise {
        $self->assert( 0, "Unexpected connection success" );
    };

    return;
}

sub test_stringify {
    my $self = shift;

    my $port = 'somehost.example.com:1717';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    my $conn = P4::Objects::RawConnection->new( { session => $session } );

    $self->assert_equals( $port, $conn );

    return;
}

sub test_stringify_no_port {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::RawConnection->new( { session => $session } );

    $self->assert_equals( '', $conn );

    return;
}

1;

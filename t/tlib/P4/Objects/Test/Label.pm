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

package P4::Objects::Test::Label;

use strict;
use warnings;

use P4::Objects::Label;

use base qw( P4::Objects::Test::Helper::TestCase );

my $user = 'testuser';

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

sub test_new_get_name {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $labelname = 'testlabel';

    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    $self->assert_not_null( $lbl );
    $self->assert( $lbl->isa( 'P4::Objects::Common::Base' ) );
    $self->assert_equals( 'P4::Objects::Label', ref( $lbl ) );
    $self->assert( $lbl->isa( 'P4::Objects::Common::Form' ),
            'Label should inherit from Form' );
    $self->assert_equals( $session, $lbl->get_session() );
    $self->assert_equals( $labelname, $lbl->get_name() );

    $self->assert_null( $lbl->get_access() );
    $self->assert_null( $lbl->get_update() );
    $self->assert( $lbl->is_new() );

    my $gotten_owner = $lbl->get_owner();
    $self->assert_not_null( $gotten_owner );
    $self->assert_equals( $user, $gotten_owner );

    my $gotten_description = $lbl->get_description();
    $self->assert_not_null( $gotten_description );
    $self->assert_equals( "Created by $user.\n", $gotten_description );

    my $gotten_options = $lbl->get_options();
    $self->assert_not_null( $gotten_options );
    $self->assert_equals(
        'P4::Objects::Common::BinaryOptions',
        ref( $gotten_options )
    );
    $self->assert_equals( 'unlocked', $gotten_options );

    my $gotten_view = $lbl->get_view();
    $self->assert_not_null( $gotten_view );
    $self->_assert_array( $gotten_view );
    $self->assert_deep_equals( [ '//depot/...' ],  $gotten_view );

    return;
}

sub test_set_get_owner {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $labelname = 'testlabel';
    my $owner = 'anotheruser';

    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    # Assert pre-condition
    $self->assert_not_equals( $owner, $lbl->get_owner() );

    $lbl->set_owner( $owner );

    $self->assert_equals( $owner, $lbl->get_owner() );

    return;
}

sub test_set_get_description {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $labelname = 'testlabel';
    my $description = 'This is a label for testing purposes';

    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    # Assert pre-condition
    $self->assert_not_equals( $description, $lbl->get_description() );

    $lbl->set_description( $description );

    $self->assert_equals( $description, $lbl->get_description() );

    return;
}

sub test_set_get_revision {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $labelname = 'testlabel';
    my $revision = '@12345';

    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    # Assert pre-condition
    $self->assert_not_equals( $revision, $lbl->get_revision() );

    $lbl->set_revision( $revision );

    $self->assert_equals( $revision, $lbl->get_revision() );

    return;
}

sub test_set_get_view {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $labelname = 'testlabel';
    my $view = [ '/some/depot/path/...' ];

    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    # Assert pre-condition
    # Since there isn't an assert_deep_not_equals(), we'll build a series of
    # conditions that will reasonably suffice.
    my $gotten_view = $lbl->get_view();
    $self->assert( ! defined( $gotten_view )
                    || ref( $gotten_view ) ne 'ARRAY'
                    || scalar @{$view} != scalar @{$gotten_view}
                    || $view->[0] ne $gotten_view->[0]
    );

    $lbl->set_view( $view );

    $self->assert_deep_equals( $view, $lbl->get_view() );

    return;
}

sub test_commit {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    # Assert pre-conditions
    my @output = `p4 -p $port labels`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my $labelname = 'testlabel';
    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => $labelname,
    } );

    $lbl->commit();

    # Assert results
    @output = `p4 -p $port labels`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );

    $self->assert( $lbl->is_existing() );

    return;
}

sub test_stringify {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    my $labelname = 'areallycoollabelname';
    my $lbl = P4::Objects::Label->new( {
        session => $session,
        name    => $labelname,
    } );

    $self->assert_equals( $labelname, $lbl );

    return;
}

1;

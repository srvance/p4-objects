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

package P4::Objects::Test::WorkspaceRevision;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Exception;
use P4::Objects::Session;
use P4::Objects::Workspace;
use P4::Objects::WorkspaceRevision;

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

sub test_new_get_all {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    my $ws = P4::Objects::Workspace->new( {
        name        => 'someworkspacename',
        session     => $session,
    } );
    my $localname = 'This is a local name';
    my $depotname = 'This is a depot name';
    my $revision = 17;
    my $action = 'add';
    my $filesize = 1717;

    my $wr = P4::Objects::WorkspaceRevision->new( {
        session     => $session,
        workspace   => $ws,
        clientFile  => $localname,
        depotFile   => $depotname,
        rev         => $revision,
        action      => $action,
        fileSize    => $filesize,
    } );

    $self->assert_not_null( $wr );
    $self->assert( $wr->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $session, $wr->get_session() );
    my $newws = $wr->get_workspace();
    $self->assert_not_null( $newws );
    $self->assert_equals( 'P4::Objects::Workspace', ref( $newws ) );
    $self->assert_equals( $ws, $newws );
    $self->assert_str_equals( $ws, $newws );
    $self->assert_equals( $localname, $wr->get_localname() );
    $self->assert_equals( $depotname, $wr->get_depotname() );
    $self->assert_equals( $revision, $wr->get_revision() );
    $self->assert_equals( $action, $wr->get_action() );
    $self->assert_equals( $filesize, $wr->get_filesize() );

    return;
}

sub test_new_invalid_workspace {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $wsname = 'someworkspacename';
    my $localname = 'This is a local name';
    my $depotname = 'This is a depot name';
    my $revision = 17;
    my $action = 'add';
    my $filesize = 1717;

    try {
        my $wr = P4::Objects::WorkspaceRevision->new( {
            session     => $sessionid,
            workspace   => $wsname,
            clientFile  => $localname,
            depotFile   => $depotname,
            rev         => $revision,
            action      => $action,
            fileSize    => $filesize,
        } );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::InvalidParameter with {
        my $e = shift;

        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

1;

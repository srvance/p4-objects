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

package P4::Objects::Test::OpenRevision;

use strict;
use warnings;

use P4::Objects::OpenRevision;
use P4::Objects::Session;
use P4::Objects::Workspace;

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
    my $user = 'memyselfandi';
    my $changelist = 'default';

    my $or = P4::Objects::OpenRevision->new( {
        session     => $session,
        workspace   => $ws,
        clientFile  => $localname,
        depotFile   => $depotname,
        rev         => $revision,
        action      => $action,
        fileSize    => $filesize,
        user        => $user,
        change      => $changelist,
    } );

    $self->assert_not_null( $or );
    $self->assert( $or->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $session, $or->get_session() );
    $self->assert_equals( $ws, $or->get_workspace() );
    $self->assert_equals( $localname, $or->get_localname() );
    $self->assert_equals( $depotname, $or->get_depotname() );
    $self->assert_equals( $revision, $or->get_revision() );
    $self->assert_equals( $action, $or->get_action() );
    $self->assert_equals( $filesize, $or->get_filesize() );
    $self->assert_equals( $user, $or->get_user() );
    $self->assert_equals( $changelist, $or->get_changelist() );

    return;
}

1;

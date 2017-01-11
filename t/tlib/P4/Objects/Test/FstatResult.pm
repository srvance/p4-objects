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

package P4::Objects::Test::FstatResult;

use strict;
use warnings;

use P4::Objects::FstatResult;

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

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $localname = '/local/file/name';
    my $depotaction = 'add';
    my $depottype = 'text+x';
    my $depottime = 1200975501;
    my $depotrevision = 16;
    my $depotchange = 1024;
    my $depotmodtime = 1200973839;
    my $haverevision = 19;
    my $action = 'edit';
    my $change = 2048;
    my $type = 'text';
    my $user = 'someone';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        clientFile  => $localname,
        headAction  => $depotaction,
        headType    => $depottype,
        headTime    => $depottime,
        headRev     => $depotrevision,
        headChange  => $depotchange,
        headModTime => $depotmodtime,
        haveRev     => $haverevision,
        action      => $action,
        change      => $change,
        type        => $type,
        actionOwner => $user,
    } );

    $self->assert_not_null( $fr );
    $self->assert( $fr->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $sessionid, $fr->get_session() );
    $self->assert_equals( $depotname, $fr->get_depotname() );
    $self->assert_equals( $localname, $fr->get_localname() );
    $self->assert_equals( $depotaction, $fr->get_depotaction() );
    $self->assert( $fr->get_depottype()->isa( 'P4::Objects::FileType' ) );
    $self->assert_equals( $depottype, $fr->get_depottype() );
    $self->assert_equals( $depottime, $fr->get_depottime() );
    $self->assert_equals( $depotrevision, $fr->get_depotrevision() );
    $self->assert_equals( $depotchange, $fr->get_depotchange() );
    $self->assert_equals( $depotmodtime, $fr->get_depotmodtime() );
    $self->assert_equals( $haverevision, $fr->get_haverevision() );
    $self->assert_equals( $action, $fr->get_openaction() );
    $self->assert_equals( $change, $fr->get_openchange() );
    $self->assert( $fr->get_opentype()->isa( 'P4::Objects::FileType' ) );
    $self->assert_equals( $type, $fr->get_opentype() );
    $self->assert_equals( $user, $fr->get_openuser() );

    return;
}

sub test_new_minimal {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
    } );

    $self->assert_not_null( $fr );

    $self->assert_equals( $sessionid, $fr->get_session() );
    $self->assert_equals( $depotname, $fr->get_depotname() );
    $self->assert_null( $fr->get_localname() );
    $self->assert_null( $fr->get_depotaction() );
    $self->assert_null( $fr->get_depottype() );
    $self->assert_null( $fr->get_depottime() );
    $self->assert_null( $fr->get_depotrevision() );
    $self->assert_null( $fr->get_depotchange() );
    $self->assert_null( $fr->get_depotmodtime() );
    $self->assert_null( $fr->get_haverevision() );
    $self->assert_null( $fr->get_openaction() );
    $self->assert_null( $fr->get_openchange() );
    $self->assert_null( $fr->get_opentype() );
    $self->assert_null( $fr->get_openuser() );

    return;
}

sub test_is_known {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $localname = '/local/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        clientFile  => $localname,
    } );

    $self->assert_not_null( $fr );

    $self->assert( $fr->is_known() );

    return;
}

sub test_is_known_false {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        clientFile  => undef,
    } );

    $self->assert_not_null( $fr );

    $self->assert( ! $fr->is_known() );

    return;
}

sub test_is_open {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $action = 'edit';
    my $change = 2048;
    my $type = 'text';
    my $user = 'someone';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        action      => $action,
        change      => $change,
        type        => $type,
        actionOwner => $user,
    } );

    $self->assert_not_null( $fr );

    $self->assert( $fr->is_open() );

    return;
}

sub test_is_open_false {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        action      => undef,
        change      => undef,
        type        => undef,
        actionOwner => undef,
    } );

    $self->assert_not_null( $fr );

    $self->assert( ! $fr->is_open() );

    return;
}

sub test_is_submitted {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $depotaction = 'add';
    my $depottype = 'xtext';
    my $depottime = 1200975501;
    my $depotrevision = 16;
    my $depotchange = 1024;
    my $depotmodtime = 1200973839;

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        headAction  => $depotaction,
        headType    => $depottype,
        headTime    => $depottime,
        headRev     => $depotrevision,
        headChange  => $depotchange,
        headModTime => $depotmodtime,
    } );

    $self->assert_not_null( $fr );

    $self->assert( $fr->is_submitted() );

    return;
}

sub test_is_submitted_false {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        headAction  => undef,
        headType    => undef,
        headTime    => undef,
        headRev     => undef,
        headChange  => undef,
        headModTime => undef,
    } );

    $self->assert_not_null( $fr );

    $self->assert( ! $fr->is_submitted() );

    return;
}

sub test_is_synced {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $haverevision = 19;

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        haveRev     => $haverevision,
    } );

    $self->assert_not_null( $fr );

    $self->assert( $fr->is_synced() );

    return;
}

sub test_is_synced_false {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        haveRev     => undef,
    } );

    $self->assert_not_null( $fr );

    $self->assert( ! $fr->is_synced() );

    return;
}

sub test_stringify_synced {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $haverevision = 19;

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        haveRev     => $haverevision,
    } );

    $self->assert_equals( "$depotname#$haverevision", $fr );

    return;
}

sub test_stringify_known {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = '//depot/file/name';
    my $localname = '/some/path/to/the/file/name';
    my $haverevision = undef;

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        clientFile  => $localname,
        haveRev     => $haverevision,
    } );

    $self->assert_equals( $localname, $fr );

    return;
}

sub test_stringify_unknown {
    my $self = shift;

    my $sessionid = 0xbeeffeed;
    my $depotname = undef;
    my $localname = undef;
    my $haverevision = undef;

    my $fr = P4::Objects::FstatResult->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        clientFile  => $localname,
        haveRev     => $haverevision,
    } );

    $self->assert_equals( '', $fr );

    return;
}

1;

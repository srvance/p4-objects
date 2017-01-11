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

package P4::Objects::Test::Revision;

use strict;
use warnings;

use P4::Objects::Revision;

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
    my $depotname = 'This is a depot name';
    my $revision = 17;
    my $type = 'text';
    my $action = 'add';
    my $filesize = 1717;

    my $sr = P4::Objects::Revision->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        rev         => $revision,
        type        => $type,
        action      => $action,
        fileSize    => $filesize,
    } );

    $self->assert_not_null( $sr );
    $self->assert( $sr->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $sessionid, $sr->get_session() );
    $self->assert_equals( $depotname, $sr->get_depotname() );
    $self->assert_equals( $revision, $sr->get_revision() );
    $self->assert( $sr->get_type()->isa( 'P4::Objects::FileType' ) );
    $self->assert_equals( $type, $sr->get_type() );
    $self->assert_equals( $action, $sr->get_action() );
    $self->assert_equals( $filesize, $sr->get_filesize() );

    return;
}

sub test_stringify {
    my $self = shift;

    my $sessionid = 0xad0befad;
    my $depotname = '//some/depot/path/to/a/file.txt';
    my $revision = 17;
    my $type = 'text';
    my $action = 'edit';
    my $filesize = 42;

    my $rev = P4::Objects::Revision->new( {
        session     => $sessionid,
        depotFile   => $depotname,
        rev         => $revision,
        type        => $type,
        action      => $action,
        fileSize    => $filesize,
    } );

    $self->assert_not_null( $rev );

    my $expected_stringification = "$depotname#$revision";

    $self->assert_equals( $expected_stringification, scalar $rev );

    return;
}

1;

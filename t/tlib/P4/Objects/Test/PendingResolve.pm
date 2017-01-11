# Copyright (C) 2008 Stephen Vance
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

package P4::Objects::Test::PendingResolve;

use strict;
use warnings;

use P4::Objects::PendingResolve;

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
    my $localname = 'This is a local name';
    my $source = 'This is a depot name';
    my $startfromrev = 1;
    my $endfromrev = 17;

    my $sr = P4::Objects::PendingResolve->new( {
        session         => $sessionid,
        clientFile      => $localname,
        fromFile        => $source,
        startFromRev    => $startfromrev,
        endFromRev      => $endfromrev,
    } );

    $self->assert_not_null( $sr );
    $self->assert( $sr->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $sessionid, $sr->get_session() );
    $self->assert_equals( $localname, $sr->get_localname() );
    $self->assert_equals( $source, $sr->get_source() );
    $self->assert_equals( $startfromrev, $sr->get_startfromrev() );
    $self->assert_equals( $endfromrev, $sr->get_endfromrev() );

    return;
}

sub test_stringify {
    my $self = shift;

    my $sessionid = 0xad0befad;
    my $localname = 'This is a local name';
    my $source = 'This is a depot name';
    my $startfromrev = 1;
    my $endfromrev = 17;

    my $rev = P4::Objects::PendingResolve->new( {
        session         => $sessionid,
        clientFile      => $localname,
        fromFile        => $source,
        startFromRev    => $startfromrev,
        endFromRev      => $endfromrev,
    } );

    $self->assert_not_null( $rev );

    my $expected_stringification = $localname;

    $self->assert_equals( $expected_stringification, scalar $rev );

    return;
}

1;

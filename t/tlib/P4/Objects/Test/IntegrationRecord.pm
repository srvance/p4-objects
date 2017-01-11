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

package P4::Objects::Test::IntegrationRecord;

use strict;
use warnings;

use Error qw( :try );
use P4::Objects::Exception;
use P4::Objects::IntegrationRecord;

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
    my $target = 'This is a target depot name';
    my $source = 'This is a source depot name';
    my $startfromrev = 1;
    my $endfromrev = 17;
    my $starttorev = 1234;
    my $endtorev = 4321;
    my $how = 'copy from';
    my $changeno = 1717;

    my $sr = P4::Objects::IntegrationRecord->new( {
        session         => $sessionid,
        path            => $localname,
        toFile          => $target,
        fromFile        => $source,
        startToRev      => $starttorev,
        endToRev        => $endtorev,
        startFromRev    => $startfromrev,
        endFromRev      => $endfromrev,
        how             => $how,
        change          => $changeno,
    } );

    $self->assert_not_null( $sr );
    $self->assert( $sr->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $sessionid, $sr->get_session() );
    $self->assert_equals( $localname, $sr->get_localname() );
    $self->assert_equals( $target, $sr->get_target() );
    $self->assert_equals( $source, $sr->get_source() );
    $self->assert_equals( $starttorev, $sr->get_starttorev() );
    $self->assert_equals( $endtorev, $sr->get_endtorev() );
    $self->assert_equals( $startfromrev, $sr->get_startfromrev() );
    $self->assert_equals( $endfromrev, $sr->get_endfromrev() );
    $self->assert_equals( $how, $sr->get_how() );
    $self->assert_equals( $changeno, $sr->get_changeno() );

    return;
}

sub test_stringify {
    my $self = shift;

    my $sessionid = 0xad0befad;
    my $localname = 'This is a local name';
    my $target = 'This is a target depot name';
    my $source = 'This is a source depot name';
    my $startfromrev = '#1';
    my $endfromrev = '#17';
    my $starttorev = '#1234';
    my $endtorev = '#4321';
    my $how = 'copy from';

    my $rev = P4::Objects::IntegrationRecord->new( {
        session         => $sessionid,
        path            => $localname,
        toFile          => $target,
        fromFile        => $source,
        startToRev      => $starttorev,
        endToRev        => $endtorev,
        startFromRev    => $startfromrev,
        endFromRev      => $endfromrev,
        how             => $how,
    } );

    $self->assert_not_null( $rev );

    my $expected_stringification = "$target$starttorev,$endtorev - $how $source$startfromrev,$endfromrev";

    $self->assert_equals( $expected_stringification, scalar $rev );

    return;
}

sub test_stringify_no_starts {
    my $self = shift;

    my $sessionid = 0xad0befad;
    my $localname = 'This is a local name';
    my $target = 'This is a target depot name';
    my $source = 'This is a source depot name';
    my $startfromrev = '#none';
    my $endfromrev = '#17';
    my $starttorev = '#none';
    my $endtorev = '#4321';
    my $how = 'copy from';

    my $rev = P4::Objects::IntegrationRecord->new( {
        session         => $sessionid,
        path            => $localname,
        toFile          => $target,
        fromFile        => $source,
        startToRev      => $starttorev,
        endToRev        => $endtorev,
        startFromRev    => $startfromrev,
        endFromRev      => $endfromrev,
        how             => $how,
    } );

    $self->assert_not_null( $rev );

    my $expected_stringification = "$target$endtorev - $how $source$endfromrev";

    $self->assert_equals( $expected_stringification, scalar $rev );

    return;
}

1;

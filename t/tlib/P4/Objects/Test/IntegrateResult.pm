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

package P4::Objects::Test::IntegrateResult;

use strict;
use warnings;

use Error qw( :try );
use P4::Objects::Exception;
use P4::Objects::IntegrateResult;

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

my $sessionid    = 0xbeeffeed;
my $localname    = 'This is a client path name';
my $otheraction  = 'sync';
my $workingrev   = 2;
my $endfromrev   = 3;
my $startfromrev = 4;
my $baserev      = 5;
my $source       = 'This is a source depot name';
my $depotfile    = 'This is a target depot name';
my $action       = 'integrate';
my $starttorev   = 1234;
my $endtorev     = 4321;
my $how          = 'copy from';
my $changeno     = 1717;
my $basename     = 'This is a base name';

sub _construct_integrate_result {
    my ($variant) = @_;

    my $new_arg = {
            session      => $sessionid,
            fromFile     => $source,
            otherAction  => $otheraction,
            workRev      => $workingrev,
            endFromRev   => $endfromrev,
            startFromRev => $startfromrev,
            baseRev      => $baserev,
            clientFile   => $localname,
            action       => $action,
            baseName     => $basename,
            depotFile    => $depotfile
    };
    if ($variant) {
        delete $new_arg->{baseName};
        delete $new_arg->{baseRev};
        $new_arg->{endFromRev} = $new_arg->{startFromRev};
    }
    return P4::Objects::IntegrateResult->new( $new_arg );

}

sub test_new_get_all {
    my $self = shift;

    my $ir = _construct_integrate_result();


    $self->assert_not_null( $ir );
    $self->assert( $ir->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $sessionid,               $ir->get_session() );
    $self->assert_equals( $source,                  $ir->get_source() );
    $self->assert_equals( $otheraction,             $ir->get_otheraction() );
    $self->assert_equals( $workingrev,              $ir->get_workingrev() );
    $self->assert_equals( $endfromrev,              $ir->get_endfromrev() );
    $self->assert_equals( $startfromrev,            $ir->get_startfromrev() );
    $self->assert_equals( $baserev,                 $ir->get_baserev() );
    $self->assert_equals( $localname,               $ir->get_localname() );
    $self->assert_equals( $action,                  $ir->get_action() );
    $self->assert_equals( $basename,                $ir->get_basename() );
    $self->assert_equals( $depotfile,               $ir->get_depotfile() );
    $self->assert_equals( "$source#$endfromrev",    $ir->get_source_revision() );
    $self->assert_equals( "$depotfile#$workingrev", $ir->get_target_revision() );
    $self->assert_equals( "$basename#$baserev",     $ir->get_base_revision() );

    return;
}

sub test_stringify {
     my $self = shift;

     my $ir = _construct_integrate_result();

     $self->assert_not_null( $ir );

     my $expected_stringification = "$depotfile#$workingrev - $action from $source#$startfromrev,$endfromrev using base $basename#$baserev";
     $self->assert_equals( $expected_stringification, scalar $ir );
     return;
}

sub test_stringify_nobase_onlystartrev {
     my $self = shift;

     my $ir = _construct_integrate_result(1);

     $self->assert_not_null( $ir );

     my $expected_stringification = "$depotfile#$workingrev - $action from $source#$startfromrev";
     $self->assert_equals( $expected_stringification, scalar $ir );
     return;
}


1;

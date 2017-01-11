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

package P4::Objects::Test::IntegrateResults;

use strict;
use warnings;

use P4::Objects::Exception;
use P4::Objects::IntegrateResults;
use P4::Objects::Session;
use Error qw( :try );

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

my $target_name = 'target_name';
my $source_name = 'source_name';
my $otheraction = 'otheraction';
my $startfromrev = 2;
my $endfromrev = 3;

my $results = [
    {
        session      => 0xbeeffeed,
        fromFile     => $source_name,
        otherAction  => $otheraction,
        workRev      => 1,
        endFromRev   => $endfromrev,
        startFromRev => $startfromrev,
        baseRev      => 1,
        clientFile   => 'local_name',
        action       => 'integrate',
        baseName     => 'base_name',
        depotFile    => 'depot_file'
    },
    "$target_name - can\'t integrate from $source_name#$endfromrev without -i flag",
    "$target_name - can\'t integrate from $source_name#$startfromrev,#$endfromrev without -i flag",
];


sub test_new {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $ws = P4::Objects::Workspace->new( { name => 'someworkspace', session => $session } );
    my $irs = P4::Objects::IntegrateResults->new(
        {
            session   => $session,
            workspace => $ws,
            results   => $results,
            warnings  => []
        } );

    $self->assert_not_null( $irs );
    $self->assert( $irs->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $session, $irs->get_session() );
    $self->assert_equals( $ws, $irs->get_workspace() );
    $self->assert_equals( 0, scalar @{$irs->get_warnings()} );

    my $results = $irs->get_results();
    $self->assert_equals( 3, scalar @{$results} );

    for my $result (@{$results}) {
        $self->assert_not_null( $result );
        $self->assert( $result->isa( 'P4::Objects::IntegrateResult' ) );
    }
    my $result = $results->[1];
    $self->assert_equals( '',               $result->get_baserev() );
    $self->assert_equals( '',               $result->get_otheraction() );
    $self->assert_equals( 'cant_integrate', $result->get_action() );
    $self->assert_equals( '',               $result->get_basename() );
    $self->assert_equals( undef,            $result->get_workingrev() );
    $self->assert_equals( $target_name,     $result->get_depotfile() );
    $self->assert_equals( $endfromrev,      $result->get_startfromrev() );
    $self->assert_equals( $source_name,     $result->get_source() );
    $self->assert_equals( '',               $result->get_localname() );
    $self->assert_equals( $endfromrev,      $result->get_endfromrev() );

    $result = $results->[2];
    $self->assert_equals( $source_name,     $result->get_source() );
    $self->assert_equals( $startfromrev,    $result->get_startfromrev() );
    $self->assert_equals( $endfromrev,      $result->get_endfromrev() );
}

sub _test_new_exception {
    my ($self, $results, $exception) = @_;
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $ws = P4::Objects::Workspace->new( { name => 'someworkspace', session => $session } );
    try {
        my $irs = P4::Objects::IntegrateResults->new( {
            session   => $session,
            workspace => $ws,
            results   => $results,
            warnings  => []
        } );
        $self->assert(0, 'Unexpected return with value IntegrateResults' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        my $e = shift;
        $self->assert_equals( 'results', $e->parameter() );
    }
    catch P4::Objects::Exception::P4::UnexpectedIntegrateResult with {
        my $e = shift;
        $self->assert_equals( 'badstring from perforce integrate', $e->badresult() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Data::Dumper::Dumper( $e ) );
    };

    return;
}

sub test_new_unexpected_integrate_result {
    my $self = shift;

    $self->_test_new_exception(
        [ @{$results},
          'badstring from perforce integrate' ] );

    return;
}

sub test_new_no_results {
    my $self = shift;

    $self->_test_new_exception();

    return;
}

1;

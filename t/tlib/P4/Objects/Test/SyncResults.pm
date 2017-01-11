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

package P4::Objects::Test::SyncResults;

use strict;
use warnings;

use Error qw( :try );
use P4::Objects::Session;
use P4::Objects::SyncResults;
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

    my $warning = 'This is a non-hash result entry';
    my $results_list = [
        {
            clientFile      => 'This is the first local name',
            depotFile       => 'This is the first depot name',
            rev             => 17,
            action          => 'add',
            fileSize        => 1717,
        },
        {
            clientFile      => 'This is the second local name',
            depotFile       => 'This is the second depot name',
            rev             => 49,
            action          => 'edit',
            fileSize        => 4949,
        },
        $warning,
    ];
    my $total_file_count = scalar @{$results_list} - 1;
    my $total_file_size = 1717 + 4949;
    $results_list->[0]{totalFileSize} = $total_file_size;
    $results_list->[0]{totalFileCount} = $total_file_count;

    my $init = {
        session     => $session,
        workspace   => P4::Objects::Workspace->new( {
                            name        => 'someworkspacename',
                            session     => $session,
                        } ),
        results     => $results_list,
        warnings    => [
            'The first warning',
            'The second warning',
        ],
    };

    my $srs = P4::Objects::SyncResults->new( $init );

    $self->assert_not_null( $srs );
    $self->assert( $srs->isa( 'P4::Objects::Common::Base' ) );

    $self->assert_equals( $init->{session}, $srs->get_session() );
    $self->assert_equals( $init->{workspace}, $srs->get_workspace() );
    $self->assert_equals( $total_file_size, $srs->get_totalfilesize() );
    $self->assert_equals( $total_file_count, $srs->get_totalfilecount() );

    my $stored_results = $srs->get_results();
    $self->assert_not_null( $stored_results );
    $self->assert_equals( $total_file_count, scalar @{$stored_results} );
    $self->assert_equals(
        $results_list->[0]->{clientFile},
        $stored_results->[0]->get_localname()
    );
    $self->assert_equals(
        $results_list->[0]->{depotFile},
        $stored_results->[0]->get_depotname()
    );
    $self->assert_equals(
        $results_list->[0]->{rev},
        $stored_results->[0]->get_revision()
    );

    my $warnings = $srs->get_warnings();
    $self->assert_equals( 3, scalar @{$warnings} );
    $self->assert_equals( $warning, $warnings->[-1] );

    return;
}

sub test_new_no_results {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $init = {
        session     => $session,
        workspace   => P4::Objects::Workspace->new( {
                            name        => 'someworkspacename',
                            session     => $session,
                        } ),
        warnings    => [
            'The first warning',
            'The second warning',
        ],
    };

    try {
        my $srs = P4::Objects::SyncResults->new( $init );
        $self->assert( 0, 'Did not get an exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'results', $e->parameter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . ref( $e ) );
    };

    return;
}

sub test_new_empty_results {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $init = {
        session     => $session,
        workspace   => P4::Objects::Workspace->new( {
                            name        => 'someworkspacename',
                            session     => $session,
                        } ),
        results     => [],
        warnings    => [
            'The first warning',
            'The second warning',
        ],
    };

    my $srs = P4::Objects::SyncResults->new( $init );

    $self->assert_not_null( $srs );

    $self->assert_equals( 0, $srs->get_totalfilesize() );
    $self->assert_equals( 0, $srs->get_totalfilecount() );

    my $results = $srs->get_results();
    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 0, scalar @{$results} );

    return;
}

sub test_new_no_totalfilesize {
    my $self = shift;

    my $results_list = [
        {
            clientFile      => 'This is the first local name',
            depotFile       => 'This is the first depot name',
            rev             => 17,
            action          => 'add',
            fileSize        => 1717,
        },
        {
            clientFile      => 'This is the second local name',
            depotFile       => 'This is the second depot name',
            rev             => 49,
            action          => 'edit',
            fileSize        => 4949,
        },
    ];
    my $total_file_count = scalar @{$results_list};
    $results_list->[0]{totalFileCount} = $total_file_count;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $init = {
        session     => $session,
        workspace   => P4::Objects::Workspace->new( {
                            name        => 'someworkspacename',
                            session     => $session,
                        } ),
        results     => $results_list,
        warnings    => [
            'The first warning',
            'The second warning',
        ],
    };

    my $srs = P4::Objects::SyncResults->new( $init );

    $self->assert_not_null( $srs );

    $self->assert_equals( $init->{session}, $srs->get_session() );
    $self->assert_equals( $init->{workspace}, $srs->get_workspace() );
    $self->assert_equals( 0, $srs->get_totalfilesize() );
    $self->assert_equals( $total_file_count, $srs->get_totalfilecount() );

    return;
}

sub test_new_no_totalfilecount {
    my $self = shift;

    my $results_list = [
        {
            clientFile      => 'This is the first local name',
            depotFile       => 'This is the first depot name',
            rev             => 17,
            action          => 'add',
            fileSize        => 1717,
        },
        {
            clientFile      => 'This is the second local name',
            depotFile       => 'This is the second depot name',
            rev             => 49,
            action          => 'edit',
            fileSize        => 4949,
        },
    ];
    my $total_file_size = 1717 + 4949;
    $results_list->[0]{totalFileSize} = $total_file_size;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $init = {
        session     => $session,
        workspace   => P4::Objects::Workspace->new( {
                            name        => 'someworkspacename',
                            session     => $session,
                        } ),
        results     => $results_list,
        warnings    => [
            'The first warning',
            'The second warning',
        ],
    };

    my $srs = P4::Objects::SyncResults->new( $init );

    $self->assert_not_null( $srs );

    $self->assert_equals( $init->{session}, $srs->get_session() );
    $self->assert_equals( $init->{workspace}, $srs->get_workspace() );
    $self->assert_equals( $total_file_size, $srs->get_totalfilesize() );
    $self->assert_equals( 0, $srs->get_totalfilecount() );

    return;
}

1;

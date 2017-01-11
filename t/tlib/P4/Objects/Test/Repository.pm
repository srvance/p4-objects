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

package P4::Objects::Test::Repository;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Repository;
use P4::Objects::Session;
use P4::Objects::Test::Helper::P4::RunSettableError;
use P4::Objects::Test::Helper::Session::Mock;
use P4::Server;

use base qw( P4::Objects::Test::Helper::TestCase );

our $repo;
our $session;

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {
    $session = P4::Objects::Test::Helper::Session::Mock->new();
    $repo = P4::Objects::Repository->new( { 'session' => $session } );

    return;
}

sub tear_down {
    $repo = undef;
    $session = undef;

    return;
}

sub test_new {
    my $self = shift;

    $self->assert_not_null( $repo );
    $self->assert( $repo->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_get_session {
    my $self = shift;

    $self->assert_equals( $session, $repo->get_session() );

    return;
}

# Test both single and multiple because of anecdotal information that P4Perl
# is inconsistent on how it returns singular results.

sub test_get_workspaces_single {
    my $self = shift;
    my @wslist = (
        'thisworkspace',
    );

    $self->_get_workspaces_helper( @wslist );

    return;
}

sub test_get_workspaces_multiple {
    my $self = shift;
    my @wslist = (
        'thisworkspace',
        'thatworkspace',
        'theotherworkspace',
        'anotherworkspace',
    );

    $self->_get_workspaces_helper( sort @wslist );

    return;
}

sub test_get_changelists_single {
    my $self = shift;
    my $values = {
            numChanges      => 1,
    };

    $self->_get_changelists_helper( $values );

    return;
}

sub test_get_changelists_multiple {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };

    $self->_get_changelists_helper( $values );

    return;
}

sub test_get_changelists_filtered_max {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };
    my $filter = { maxReturned => 1 };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_submitted {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };
    my $filter = { status => 'submitted' };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_pending {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };
    my $filter = { status => 'pending' };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_workspace {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };
    my $filter = { workspace => 'therightworkspace' };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_bad_filter_parm {
    my $self = shift;
    my $values = {
            numChanges      => 7,
    };
    my $badparmname = 'badparm';
    my $filter = { $badparmname => 'badvalue' };

    try {
        $self->_get_changelists_helper( $values, $filter );
        $self->assert( 0 , 'Did not get an exception as expected' );
    }
    catch P4::Objects::Exception::UnsupportedFilter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $badparmname, $e->filter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , 'Unexpected exception: ', Dumper( $e ) );
    };

    return;
}

sub test_get_changelists_filtered_filespec_string {
    my $self = shift;
    my $workspace = 'wsname';
    my $values = {
            numChanges      => 7,
            wsname          => [ $workspace, "other$workspace" ],
    };
    my $filter = { filespec => "\@$workspace" };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_filespec_array {
    my $self = shift;
    my $workspace = 'wsname';
    my $values = {
            numChanges      => 7,
            wsname          => [ $workspace, "other$workspace" ],
    };
    my $filter = { filespec => [ "\@$workspace", "//$workspace/..." ], };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_filespec_range {
    my $self = shift;
    my $workspace = 'wsname';
    my $values = {
            numChanges      => 7,
            wsname          => [ $workspace, "other$workspace" ],
    };
    my $filter = { filespec => '@2,@5' };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_get_changelists_filtered_filespec_relative_range {
    my $self = shift;
    my $workspace = 'wsname';
    my $values = {
            numChanges      => 7,
            wsname          => [ $workspace, "other$workspace" ],
    };
    my $filter = { filespec => '@>2,@<=5' };

    $self->_get_changelists_helper( $values, $filter );

    return;
}

sub test_fstat {
    my $self = shift;

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $depotfile = '//depot/afile.txt';

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( 'testuser' ); # From the checkpoint

    my $repo = $session->get_repository();

    my $results = $repo->fstat( $depotfile );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );

    my $stat = $results->[0];
    $self->assert_equals( 'P4::Objects::FstatResult', ref( $stat ) );

    return;
}

sub test_fixes {
    my $self = shift;

    my @job = ( 'ajob', 'bjob' );
    my $mainfile = 'afile.txt';
    my $branchfile = 'bfile.txt';

    my ($server, $session) = $self->_get_fixes_helper(
        $mainfile,
        $branchfile,
        @job
    );

    my $repo = $session->get_repository();

    my $results = $repo->get_fixes( "//depot/$mainfile#1" );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );

    my $fix = $results->[0];
    $self->assert_equals( '', ref( $fix ) );
    $self->assert_equals( $fix, $job[0] );

    return;
}

sub test_fixes_history {
    my $self = shift;

    my @job = ( 'ajob', 'bjob' );
    my $mainfile = 'afile.txt';
    my $branchfile = 'bfile.txt';

    my ($server, $session) = $self->_get_fixes_helper(
        $mainfile,
        $branchfile,
        @job
    );

    my $repo = $session->get_repository();

    my $results = $repo->get_fixes(
        {
            report_integrate_history    => 1,
        },
        "//depot/$branchfile#1",
    );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 2, scalar @{$results} );

    my $first_fix = $results->[0];
    $self->assert_equals( '', ref( $first_fix ) );
    $self->assert_equals( $first_fix, $job[0] );

    my $second_fix = $results->[1];
    $self->assert_equals( '', ref( $second_fix ) );
    $self->assert_equals( $second_fix, $job[1] );

    return;
}

sub test_fixes_no_history {
    my $self = shift;

    my @job = ( 'ajob', 'bjob' );
    my $mainfile = 'afile.txt';
    my $branchfile = 'bfile.txt';

    my ($server, $session) = $self->_get_fixes_helper(
        $mainfile,
        $branchfile,
        @job
    );

    my $repo = $session->get_repository();

    my $results = $repo->get_fixes(
        {
            report_integrate_history    => 0,
        },
        "//depot/$branchfile#1",
    );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );

    my $first_fix = $results->[0];
    $self->assert_equals( '', ref( $first_fix ) );
    $self->assert_equals( $first_fix, $job[1] );

    return;
}

sub test_fixes_bad_option {
    my $self = shift;

    my @job = ( 'ajob', 'bjob' );
    my $mainfile = 'afile.txt';
    my $branchfile = 'bfile.txt';

    my ($server, $session) = $self->_get_fixes_helper(
        $mainfile,
        $branchfile,
        @job
    );

    my $repo = $session->get_repository();

    my $results = $repo->get_fixes(
        {
            some_unsupported_option     => 1,
        },
        "//depot/$mainfile#1",
    );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );

    my $fix = $results->[0];
    $self->assert_equals( '', ref( $fix ) );
    $self->assert_equals( $fix, $job[0] );

    return;
}

sub _get_fixes_helper {
    my ($self, $mainfile, $branchfile, @job) = @_;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $timestamp = '44077 1204577244';

    my $journal = <<EOJ;
\@pv\@ 0 \@db.counters\@ \@change\@ 2 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1204318432 1204577244 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1204318416 1204318416 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@DUMMYROOT\@ \@\@ \@\@ \@$user\@ 1204318441 1204318809 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.integed\@ \@//depot/$mainfile\@ \@//depot/$branchfile\@ 0 1 0 1 3 2 
\@pv\@ 0 \@db.integed\@ \@//depot/$branchfile\@ \@//depot/$mainfile\@ 0 1 0 1 2 2 
\@ex\@ $timestamp
\@pv\@ 0 \@db.archmap\@ \@//depot/b*\@ \@//depot/a*\@ 
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/$mainfile\@ 1 0 0 1 1204318746 1204318684 2BBE46E39E80CB897E789C7207FEECBC 17 0 0 \@//depot/$mainfile\@ \@1.1\@ 0 
\@pv\@ 7 \@db.rev\@ \@//depot/$branchfile\@ 1 0 3 2 1204318828 1204318684 2BBE46E39E80CB897E789C7207FEECBC 17 0 1 \@//depot/$mainfile\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ 2 \@//depot/$branchfile\@ 1 3 
\@pv\@ 0 \@db.revcx\@ 1 \@//depot/$mainfile\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/$mainfile\@ 1 0 0 1 1204318746 1204318684 2BBE46E39E80CB897E789C7207FEECBC 17 0 0 \@//depot/$mainfile\@ \@1.1\@ 0 
\@pv\@ 7 \@db.revhx\@ \@//depot/$branchfile\@ 1 0 3 2 1204318828 1204318684 2BBE46E39E80CB897E789C7207FEECBC 17 0 1 \@//depot/$mainfile\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 2 2 \@$wsname\@ \@$user\@ 1204318828 1 \@Branch the file for testing.
\@ 
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1204318746 1 \@First file checkin.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 2 \@Branch the file for testing.
\@ 
\@pv\@ 0 \@db.desc\@ 1 \@First file checkin.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.job\@ \@$job[0]\@ \@\@ 0 0 \@First job for file $mainfile
\@ 
\@pv\@ 0 \@db.job\@ \@$job[1]\@ \@\@ 0 0 \@Second job for file $branchfile
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.fix\@ \@$job[0]\@ 1 1204318910 \@closed\@ \@$wsname\@ \@$user\@ 
\@pv\@ 1 \@db.fix\@ \@$job[1]\@ 2 1204318917 \@closed\@ \@$wsname\@ \@$user\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.fixrev\@ \@$job[1]\@ 2 1204318917 \@closed\@ \@$wsname\@ \@$user\@ 
\@pv\@ 1 \@db.fixrev\@ \@$job[0]\@ 1 1204318910 \@closed\@ \@$wsname\@ \@$user\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.boddate\@ \@$job[0]\@ 104 1204318910 
\@pv\@ 0 \@db.boddate\@ \@$job[1]\@ 104 1204318917 
\@ex\@ $timestamp
\@pv\@ 0 \@db.bodtext\@ \@$job[0]\@ 101 \@$job[0]\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[0]\@ 102 \@closed\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[0]\@ 103 \@$user\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[0]\@ 105 \@First job for file $mainfile
\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[1]\@ 101 \@$job[1]\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[1]\@ 102 \@closed\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[1]\@ 103 \@$user\@ 
\@pv\@ 0 \@db.bodtext\@ \@$job[1]\@ 105 \@Second job for file $branchfile
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.ixdate\@ 1204318910 104 \@$job[0]\@ 
\@pv\@ 0 \@db.ixdate\@ 1204318917 104 \@$job[1]\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.ixtext\@ \@afile\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$mainfile\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$job[0]\@ 101 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@bfile\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$branchfile\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$job[1]\@ 101 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@closed\@ 102 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@closed\@ 102 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@file\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@file\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@first\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@for\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@for\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@job\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@job\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@second\@ 105 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$user\@ 103 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@$user\@ 103 \@$job[1]\@ 
\@pv\@ 0 \@db.ixtext\@ \@txt\@ 105 \@$job[0]\@ 
\@pv\@ 0 \@db.ixtext\@ \@txt\@ 105 \@$job[1]\@ 
\@ex\@ $timestamp
EOJ

    my $server = $self->_create_p4d( {
        journal     => $journal,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );

    return ($server, $session );
}

sub test_get_changelist_pending {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $timestamp = '44077 1204577244';

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@stephen-vances-computer\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@/Users/steve/testws\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 2 \@db.locks\@ \@//depot/dummyfile\@ \@$wsname\@ \@$user\@ 1 0 1 
\@ex\@ $timestamp
\@pv\@ 8 \@db.working\@ \@//$wsname/dummyfile\@ \@//depot/dummyfile\@ \@$wsname\@ \@$user\@ 1 1 0 0 1 1 0 0 00000000000000000000000000000000 -1 0 0 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1203534770 0 \@Test description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.changex\@ 1 1 \@$wsname\@ \@$user\@ 1203534770 0 \@Test description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 1 \@Test description\@
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $cl = $repo->get_changelist( 1 );

    $self->assert_not_null( $cl );
    $self->assert_equals( 'P4::Objects::PendingChangelist', ref( $cl ) );
    $self->assert( $cl->is_pending() );
    $self->assert_equals( 1, $cl->get_changeno() );

    return;
}

sub test_get_changelist_submitted {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $timestamp = '44077 1204577244';

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@stephen-vances-computer\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@/Users/steve/testws\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/dummyfile\@ 1 0 0 1 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ 1 \@//depot/dummyfile\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/dummyfile\@ 1 0 0 1 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1186098224 1 \@Test description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 1 \@Test description\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $cl = $repo->get_changelist( 1 );

    $self->assert_not_null( $cl );
    $self->assert_equals( 'P4::Objects::SubmittedChangelist', ref( $cl ) );
    $self->assert( $cl->is_submitted() );
    $self->assert_equals( 1, $cl->get_changeno() );

    return;
}

sub test_get_changelist_none {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $cl = $repo->get_changelist( 1 );

    $self->assert_null( $cl );

    return;
}

sub test_get_changelist_other_runerror {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    # Set up the client code
    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );
    my $conn = P4::Objects::Connection->new( {
        session     => $session,
        p4_class
            => 'P4::Objects::Test::Helper::P4::RunSettableError',
    } );
    $session->set_connection( $conn );

    my $repo = P4::Objects::Repository->new( {
        session => $session,
    } );

    my $p4 = $conn->get_p4();
    my $expected_errors = [ 'Some random error', 'Another random error' ];
    $p4->set_errors( $expected_errors );

    try {
        $repo->get_changelist( 1 );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::P4::RunError with {
        # Expected behavior
        my $e = shift;

        $self->assert_deep_equals( $expected_errors, $e->errors() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_integrated {
    my $self = shift;

    my ($server, $session) = $self->_integrated_helper();
    my $repo = $session->get_repository();

    my $results = $repo->integrated();

    $self->assert_not_null( $results );
    $self->_assert_array( $results );

    my $expected_results = 2;
    $self->assert_equals( $expected_results, scalar @{$results} );
    $self->assert_equals(
        $expected_results,
        scalar grep {
            ref( $_ ) eq 'P4::Objects::IntegrationRecord'
        } @{$results}
    );

    $self->assert_equals(
        $expected_results,
        scalar grep { $_->get_changeno() == 2 } @{$results}
    );
    $self->assert_equals(
        $expected_results / 2, # Symmetric integration records
        scalar grep { $_->get_source() eq '//depot/a.txt' } @{$results}
    );
    $self->assert_equals(
        $expected_results / 2, # Symmetric integration records
        scalar grep { $_->get_source() eq '//depot/b.txt' } @{$results}
    );

    return;
}

sub test_integrated_file_arg {
    my $self = shift;

    my ($server, $session) = $self->_integrated_helper();
    my $repo = $session->get_repository();

    my $filename = '//depot/a.txt';

    my $results = $repo->integrated( $filename );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );

    my $expected_results = 1;
    $self->assert_equals( $expected_results, scalar @{$results} );
    $self->assert_equals(
        $expected_results,
        scalar grep {
            ref( $_ ) eq 'P4::Objects::IntegrationRecord'
        } @{$results}
    );

    $self->assert_equals(
        $expected_results,
        scalar grep { $_->get_changeno() == 2 } @{$results}
    );
    $self->assert_equals(
        $expected_results,
        scalar grep { $_->get_target() eq $filename } @{$results}
    );

    return;
}

sub test_stringify {
    my $self = shift;

    my $port = 'thevoid.example.com:1717';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    $self->assert_equals( $port, $repo );

    return;
}

sub test_stringify_no_port {
    my $self = shift;

    my $session = P4::Objects::Session->new();
    $session->set_port( undef );

    my $repo = $session->get_repository();

    $self->assert_equals( '', $repo );

    return;
}

sub test_files_single {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $filename = '//depot/text.txt';
    my $changeno = 1;

    my $timestamp = '10740 1189630265';
    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1189629934 1189630265 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@$filename\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filename\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@$filename\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@$filename\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filename\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1189630224 1 \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Seed the depot.
\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $files = $repo->files( $filename );

    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 1, scalar @{$files} );

    my $file = $files->[0];
    $self->assert_equals( 'P4::Objects::ChangelistRevision', ref( $file ) );
    $self->assert_equals( $filename, $file->get_depotname() );
    $self->assert_equals( $changeno, $file->get_changelist() );

    return;
}

sub test_files_multiple {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $filebase = '//depot/file';
    my $num_changes = 7;

    my $timestamp = '10740 1189630265';
    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1189629934 1189630265 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    for my $changeno ( 1..$num_changes ) {
        $checkpoint .=<<EOF;
\@pv\@ 7 \@db.rev\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@$filebase$changeno\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1189630224 1 \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Seed the depot.
\@ 
\@ex\@ $timestamp
EOF
    }

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $files = $repo->files( $filebase . '...' );

    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( $num_changes, scalar @{$files} );

    $self->assert_equals(
        $num_changes,
        scalar grep { 'P4::Objects::ChangelistRevision' eq ref( $_ ) } @{$files}
    );
    $self->assert_equals(
        $num_changes,
        scalar grep { $_->get_depotname() eq $filebase . $_->get_changelist() } @{$files}
    );

    return;
}

sub test_files_multiple_range {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $filebase = '//depot/file';
    my $num_changes = 7;

    my $timestamp = '10740 1189630265';
    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1189629934 1189630265 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    for my $changeno ( 1..$num_changes ) {
        $checkpoint .=<<EOF;
\@pv\@ 7 \@db.rev\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@$filebase$changeno\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1189630224 1 \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Seed the depot.
\@ 
\@ex\@ $timestamp
EOF
    }

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $files = $repo->files( $filebase . '...@2,@' . ( $num_changes - 1 ) );

    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    my $expected_files = $num_changes - 2;
    $self->assert_equals( $expected_files, scalar @{$files} );

    $self->assert_equals(
        $expected_files,
        scalar grep { 'P4::Objects::ChangelistRevision' eq ref( $_ ) } @{$files}
    );
    $self->assert_equals(
        $expected_files,
        scalar grep { $_->get_changelist() < $num_changes
            && $_->get_changelist() > 1 } @{$files}
    );
    $self->assert_equals(
        $expected_files,
        scalar grep { $_->get_depotname() eq $filebase . $_->get_changelist() } @{$files}
    );

    return;
}

sub test_files_multiple_relative_range {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $filebase = '//depot/file';
    my $num_changes = 7;

    my $timestamp = '10740 1189630265';
    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1189629934 1189630265 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    for my $changeno ( 1..$num_changes ) {
        $checkpoint .=<<EOF;
\@pv\@ 7 \@db.rev\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@$filebase$changeno\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@$filebase$changeno\@ 1 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@$filebase$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1189630224 1 \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Seed the depot.
\@ 
\@ex\@ $timestamp
EOF
    }

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    my $repo = $session->get_repository();

    my $files = $repo->files( $filebase . '...@>2,@<=' . ( $num_changes - 1 ) );

    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    my $expected_files = $num_changes - 3;
    $self->assert_equals( $expected_files, scalar @{$files} );

    $self->assert_equals(
        $expected_files,
        scalar grep { 'P4::Objects::ChangelistRevision' eq ref( $_ ) } @{$files}
    );
    $self->assert_equals(
        $expected_files,
        scalar grep { $_->get_changelist() < $num_changes
            && $_->get_changelist() > 2 } @{$files}
    );
    $self->assert_equals(
        $expected_files,
        scalar grep { $_->get_depotname() eq $filebase . $_->get_changelist() } @{$files}
    );

    return;
}

sub test_get_jobs_single {
    my $self = shift;

    my $num_items = 1;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $jobs = $repo->get_jobs();

    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $num_items, scalar @{$jobs} );

    my $job = $jobs->[0];
    $self->assert_not_null( $job );
    $self->assert_equals( '', ref( $job ) );

    return;
}

sub test_get_jobs_single_empty_filter {
    my $self = shift;

    my $num_items = 1;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $jobs = $repo->get_jobs( {} );

    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $num_items, scalar @{$jobs} );

    my $job = $jobs->[0];
    $self->assert_not_null( $job );
    $self->assert_equals( '', ref( $job ) );

    return;
}

sub test_get_jobs_multiple {
    my $self = shift;

    my $num_items = 7;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $jobs = $repo->get_jobs();

    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $num_items, scalar @{$jobs} );

    $self->assert_equals(
        $num_items,
        scalar grep { ref( $_ ) eq '' } @{$jobs}
    );
    $self->assert_equals(
        $num_items,
        scalar grep { /job\d/ } @{$jobs}
    );

    return;
}

sub test_get_jobs_multiple_filespec_array {
    my $self = shift;

    my $num_items = 7;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $filespec = [ '@=1', '@=2' ];
    my $jobs = $repo->get_jobs( {
        filespec    => $filespec,
    } );

    my $expected_items = scalar @{$filespec};
    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $expected_items, scalar @{$jobs} );

    $self->assert_equals(
        $expected_items,
        scalar grep { ref( $_ ) eq '' } @{$jobs}
    );
    $self->assert_equals(
        $expected_items,
        scalar grep { /job[12]/ } @{$jobs}
    );

    return;
}

sub test_get_jobs_multiple_range {
    my $self = shift;

    my $num_items = 7;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $range_start = 2;
    my $range_end = $num_items - 1;
    my $filespec = '@' . $range_start . ',@' . $range_end;
    my $jobs = $repo->get_jobs( {
        filespec    => $filespec,
    } );

    # inclusive-inclusive range
    my $expected_items = $range_end - $range_start + 1;
    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $expected_items, scalar @{$jobs} );

    $self->assert_equals(
        $expected_items,
        scalar grep { ref( $_ ) eq '' } @{$jobs}
    );
    # Assumes single digit job numbers for now
    $self->assert_equals(
        $expected_items,
        scalar grep { /job[$range_start-$range_end]/ } @{$jobs}
    );

    return;
}

sub test_get_jobs_multiple_relative_range {
    my $self = shift;

    my $num_items = 7;

    my $checkpoint = $self->_get_jobs_helper( $num_items );

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();

    my $range_start = 2;
    my $range_end = $num_items - 1;
    my $filespec = '@>' . $range_start . ',@<=' . $range_end;
    my $jobs = $repo->get_jobs( {
        filespec    => $filespec,
    } );

    # exclusive-inclusive range
    my $expected_items = $range_end - $range_start;
    $self->assert_not_null( $jobs );
    $self->_assert_array( $jobs );
    $self->assert_equals( $expected_items, scalar @{$jobs} );

    $self->assert_equals(
        $expected_items,
        scalar grep { ref( $_ ) eq '' } @{$jobs}
    );
    # Assumes single digit job numbers for now
    my $result_start = $range_start + 1;
    $self->assert_equals(
        $expected_items,
        scalar grep { /job[$result_start-$range_end]/ } @{$jobs}
    );

    return;
}

# PRIVATE HELPER METHODS

sub _get_workspaces_helper {
    my ($self, @wslist) = @_;

    my $wsrootprefix = '/my/workspace/root';

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();

    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 3221 1184183998
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@stephen-vances-computer\@ \@\@ 1184183998 1184183998 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 3221 1184183998
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1184183985 1184183985 0 \@Default depot\@ 
\@ex\@ 3221 1184183998
EOC

    foreach my $wsname ( @wslist ) {
        my $fragment = <<EOF;
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@$wsrootprefix/$wsname\@ \@\@ \@\@ \@svance\@ 1184184034 1184184034 0 \@Created by svance.
\@ 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 3221 1184183998
EOF

        $checkpoint .= $fragment;
    }

    $server->load_journal_string( $checkpoint );

    # To break the Session dependency with a mock we would introduce an
    # unavoidable dependency on Connection, so save ourselves the trouble.
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $repo = $session->get_repository();
    my $workspaces = $repo->get_workspaces();

    $self->_assert_array( $workspaces );

    my $num_workspaces = scalar @wslist;
    $self->assert_equals( $num_workspaces, scalar @{$workspaces} );

    for my $index ( 0..$num_workspaces - 1 ) {
        $self->assert_str_equals(
            $wslist[$index],
            $workspaces->[$index]
        );
    }

    return;
}

sub _get_changelists_helper {
    my ($self, $values, $filter) = @_;

    my $num_changes = $values->{numChanges};
    my $expected_changes = $num_changes;
    my $first_change = $num_changes;

    if( defined( $filter ) ) {
        $self->assert_equals( 1, scalar keys %$filter,
                                'Only test one filter type at a time'
        );

        if( defined( $filter->{maxReturned} ) ) {
            $expected_changes = $filter->{maxReturned};
            $first_change = $num_changes - $expected_changes + 1;
        }
        elsif( defined( $filter->{status} ) ) {
            my $num_submitted = ($num_changes + 1) / 2;
            my %expected = (
                submitted   => $num_submitted,
                pending     => $num_changes - $num_submitted,
            );

            my $status = $filter->{status};
            $expected_changes = $expected{$status};
            $first_change = $num_changes
                - ( $filter->{status} eq 'submitted'    ?   0
                                                        :   1 );
        }
        elsif( defined( $filter->{workspace} ) ) {
            $expected_changes = ( $num_changes + 1 ) / 2;
            # This may break with an even number of changes. May have to
            # subtract 1 when even.
            $first_change = $num_changes;
        }
        elsif( defined( $filter->{filespec} ) ) {
            my $filespec = $filter->{filespec};
            # Need to handle arrays first and separately so we can do string
            # matching against the filespec
            if( ref( $filespec ) eq 'ARRAY' ) {
                $expected_changes = 0;
            }
            elsif( $filespec =~ m/\@(\d+),\@(\d+)/ ) {
                # inclusive-inclusive range
                $expected_changes = $2 - $1 + 1;
                $first_change = $2;
            }
            elsif( $filespec =~ m/\@>(\d+),\@<=(\d+)/ ) {
                # exclusive-inclusive range
                $expected_changes = $2 - $1;
                $first_change = $2;
            }
            else {
                $expected_changes = 0;
            }
        }
    }
    my @user = ( 'myfirstalias', 'mysecondalias' );
    my @wsname;
    if( defined( $filter ) && defined( $filter->{workspace} ) ) {
        @wsname = ( $filter->{workspace}, 'not' . $filter->{workspace} );
    }
    elsif( defined( $values->{wsname} ) ) {
        @wsname = @{$values->{wsname}};
    }
    else {
        @wsname = ( 'atestworkspace', 'anothertestworkspace' );
    }
    my $timestamp = '3209 1186098162';


    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->set_cleanup( 1 );
    $server->create_temp_root();
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user[0]\@ \@$user[0]\@\@stephen-vances-computer\@ \@\@ 1186098088 1186098088 \@$user[0]\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user[1]\@ \@$user[1]\@\@stephen-vances-computer\@ \@\@ 1186098088 1186098088 \@$user[1]\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname[0]\@ 99 \@\@ \@/Users/steve/testws\@ \@\@ \@\@ \@$user[0]\@ 1186098106 1186098106 0 \@Created by $user[0].
\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname[1]\@ 99 \@\@ \@/Users/steve/testws\@ \@\@ \@\@ \@$user[1]\@ 1186098106 1186098106 0 \@Created by $user[1].
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname[0]/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    my $description = <<EOD;
This is intended to be a very long description so that I can make sure that
neither of the truncation options are in effect. You see, by default the
description is truncated at 31 characters. With the -L flag it is truncated at
250 characters. We really don't want either of those. We want the full
description. Thus, the really long comment block. Hah!
EOD
    my $short_description = substr( $description, 0, 31 );

    for my $changeno ( 1..$num_changes ) {
        my $workspace = $wsname[($changeno + 1) % 2];
        my $fragment;
        if( ( defined( $filter ) && ! defined( $filter->{status} ) )
            || $changeno % 2 == 1
        ) {
            $fragment = <<EOF;
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/dummyfile$changeno\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/dummyfile$changeno\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/dummyfile$changeno\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile$changeno\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$workspace\@ \@$user[0]\@ 1186098224 1 \@$short_description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@$description\@ 
\@ex\@ $timestamp
EOF
        }
        else {
            $fragment = <<EOF;
\@ex\@ $timestamp
\@pv\@ 2 \@db.locks\@ \@//depot/dummyfile$changeno\@ \@$workspace\@ \@$user[0]\@ 1 0 $changeno 
\@ex\@ $timestamp
\@pv\@ 8 \@db.working\@ \@//$workspace/dummyfile$changeno\@ \@//depot/dummyfile$changeno\@ \@$workspace\@ \@$user[0]\@ 1 1 0 0 1 $changeno 0 0 00000000000000000000000000000000 -1 0 0 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$workspace\@ \@$user[0]\@ 1203534770 0 \@$short_description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.changex\@ $changeno $changeno \@$workspace\@ \@$user[0]\@ 1203534770 0 \@$short_description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@$description\@
EOF
        }

        $checkpoint .= $fragment;
    }

    $server->load_journal_string( $checkpoint );

    # To break the Session dependency with a mock we would introduce an
    # unavoidable dependency on Connection, so save ourselves the trouble.
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user[0] );
    $session->set_workspace( $wsname[0] );

    my $repo = $session->get_repository();
    my $changes;
    try {
        $changes = $repo->get_changelists( $filter );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        my $errors = $e->errors();
        $self->assert( 0, join( "\n",
                                "Unexpected Perforce error:",
                                @$errors )
        );
    };

    $self->_assert_array( $changes );

    if( defined( $filter->{status} ) ) {
        $self->assert_equals(
            $expected_changes,
            scalar grep { $_->get_status() eq $filter->{status} } @{$changes},
        );
    }
    else {
        $self->assert_equals( $expected_changes, scalar @{$changes} );
    }

    # Validate the first change if there is one
    if( $expected_changes > 0 ) {
        my $change = $changes->[0];

        # Test for existence and type
        $self->assert_not_null( $change );
        if( defined( $filter )
            && defined( $filter->{status} )
            && $filter->{status} eq 'pending'
        ) {
            $self->assert_equals(
                'P4::Objects::PendingChangelist',
                ref( $change)
            );
        }
        else {
            $self->assert_equals(
                'P4::Objects::SubmittedChangelist',
                ref( $change)
            );
        }

        my $gotten_changeno = $change->get_changeno();
        $self->assert_equals( $first_change, $gotten_changeno );

        my $gotten_description = $change->get_description();
        $self->assert_equals( $description, $gotten_description );

        my $files = $change->get_files();
        $self->assert_not_null( $files );
        $self->assert_equals( 1, scalar @{$files} );
        # Not going to assert all the values; that's the job of the Changelist
        # test. However, I'll assert the type for interface change safety.
        $self->assert_equals( 'P4::Objects::Revision', ref( $files->[0] ) );
    }

    return;
}

sub _integrated_helper {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $timestamp = '86829 1216689472';

    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 3 
\@pv\@ 0 \@db.counters\@ \@journal\@ 3 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1216251087 1216689378 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1216251015 1216251015 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@CLIENTROOT\@ \@\@ \@\@ \@$user\@ 1216251097 1216689387 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.integed\@ \@//depot/a.txt\@ \@//depot/b.txt\@ 0 1 0 1 3 2 
\@pv\@ 0 \@db.integed\@ \@//depot/b.txt\@ \@//depot/a.txt\@ 0 1 0 1 2 2 
\@ex\@ $timestamp
\@pv\@ 2 \@db.have\@ \@//$wsname/a.txt\@ \@//depot/a.txt\@ 2 0 
\@pv\@ 2 \@db.have\@ \@//$wsname/b.txt\@ \@//depot/b.txt\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.archmap\@ \@//depot/b*\@ \@//depot/a*\@ 
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/a.txt\@ 2 0 1 3 1216251166 1216251149 26EE5EDC99264C1A963FE4F44A3A7232 14 0 0 \@//depot/a.txt\@ \@1.3\@ 0 
\@pv\@ 7 \@db.rev\@ \@//depot/a.txt\@ 1 0 0 1 1216251118 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/a.txt\@ \@1.1\@ 0 
\@pv\@ 7 \@db.rev\@ \@//depot/b.txt\@ 1 0 3 2 1216251134 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 1 \@//depot/a.txt\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ 3 \@//depot/a.txt\@ 2 1 
\@pv\@ 0 \@db.revcx\@ 2 \@//depot/b.txt\@ 1 3 
\@pv\@ 0 \@db.revcx\@ 1 \@//depot/a.txt\@ 1 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/a.txt\@ 2 0 1 3 1216251166 1216251149 26EE5EDC99264C1A963FE4F44A3A7232 14 0 0 \@//depot/a.txt\@ \@1.3\@ 0 
\@pv\@ 7 \@db.revhx\@ \@//depot/b.txt\@ 1 0 3 2 1216251134 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 1 \@//depot/a.txt\@ \@1.1\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 3 3 \@$wsname\@ \@$user\@ 1216251166 1 \@Create a change to integrate
\@ 
\@pv\@ 0 \@db.change\@ 2 2 \@$wsname\@ \@$user\@ 1216251134 1 \@Branch the file.
\@ 
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1216251118 1 \@Create a seed file.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 3 \@Create a change to integrate
\@ 
\@pv\@ 0 \@db.desc\@ 2 \@Branch the file.
\@ 
\@pv\@ 0 \@db.desc\@ 1 \@Create a seed file.
\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $wsname );

    # Server and session are both returned so they don't deallocate
    return ($server, $session);
}

sub _get_jobs_helper {
    my ($self, $num_items) = @_;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $timestamp = '81454 1217309654';

    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 2 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1189629934 1217309604 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
EOC

    for my $changeno ( 1..$num_items ) {
        $checkpoint .=<<EOF
\@pv\@ 7 \@db.rev\@ \@//depot/binary.bin\@ $changeno 65539 0 $changeno 1189630224 1189629982 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/binary.bin\@ \@1.$changeno\@ 65539 
\@pv\@ 7 \@db.rev\@ \@//depot/text.txt\@ $changeno 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/text.txt\@ \@1.$changeno\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/binary.bin\@ $changeno 0 
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/text.txt\@ $changeno 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/binary.bin\@ $changeno 65539 0 $changeno 1189630224 1189629982 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/binary.bin\@ \@1.$changeno\@ 65539 
\@pv\@ 7 \@db.revhx\@ \@//depot/text.txt\@ $changeno 0 0 $changeno 1189630224 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/text.txt\@ \@1.$changeno\@ 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1189630224 1 \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Seed the depot.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.job\@ \@job$changeno\@ \@\@ 0 0 \@Test job.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.fix\@ \@job$changeno\@ $changeno 1217309646 \@closed\@ \@$wsname\@ \@$user\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.fixrev\@ \@job$changeno\@ $changeno 1217309646 \@closed\@ \@$wsname\@ \@$user\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.boddate\@ \@job$changeno\@ 104 1217309646 
\@ex\@ $timestamp
\@pv\@ 0 \@db.bodtext\@ \@job$changeno\@ 101 \@job$changeno\@ 
\@pv\@ 0 \@db.bodtext\@ \@job$changeno\@ 102 \@closed\@ 
\@pv\@ 0 \@db.bodtext\@ \@job$changeno\@ 103 \@$user\@ 
\@pv\@ 0 \@db.bodtext\@ \@job$changeno\@ 105 \@Test job.
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.ixdate\@ 1217309646 104 \@job$changeno\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.ixtext\@ \@closed\@ 102 \@job$changeno\@ 
\@pv\@ 0 \@db.ixtext\@ \@job\@ 105 \@job$changeno\@ 
\@pv\@ 0 \@db.ixtext\@ \@job.\@ 105 \@job$changeno\@ 
\@pv\@ 0 \@db.ixtext\@ \@job$changeno\@ 101 \@job$changeno\@ 
\@pv\@ 0 \@db.ixtext\@ \@test\@ 105 \@job$changeno\@ 
\@pv\@ 0 \@db.ixtext\@ \@$user\@ 103 \@job$changeno\@ 
\@ex\@ $timestamp
EOF
    }

    return $checkpoint;
}

1;

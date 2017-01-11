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

package P4::Objects::Test::Changelist;

use strict;
use warnings;

use Data::Dumper;
use Date::Parse;
use Error qw( :try );
use P4::Objects::Changelist;
use P4::Objects::Session;
use P4::Objects::Test::Helper::Changelist::NoopLoadSpec;
use P4::Objects::Test::Helper::Changelist::IncompleteGetCache;
use P4::Objects::Test::Helper::Changelist::IncompleteSaveCache;

use base qw( P4::Objects::Test::Helper::TestCase );

our $session_id = 0xaccede;
our $wsname = 'unusualworkspace';
our $changeno = 17;

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub test_new {
    my $self = shift;

    my $cl;
    try {
        $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
        } );
    }
    catch P4::Objects::Exception::MissingParameter with {
        my $e = shift;
        $self->assert( 0, 'Parameter processing failed for' . $e->parameter );
    }
    otherwise {
        $self->assert( 0, 'Unexpected exception' );
    };
    $self->assert_not_null( $cl );
    $self->assert( $cl->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_new_by_attr {
    my $self = shift;

    my $cl;
    try {
        $cl = P4::Objects::Changelist->new( {
                        session     => $session_id,
                        attrs       => {
                            changeno    => $changeno,
                        },
        } );
    }
    catch P4::Objects::Exception::MissingParameter with {
        my $e = shift;
        $self->assert( 0, 'Parameter processing failed for ' . $e->parameter );
    };
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception ' . $e );
    };
    $self->assert_not_null( $cl );

    return;
}

sub test_new_no_changeno {
    my $self = shift;

    try {
        my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                            session     => $session_id,
        } );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'changeno', $e->parameter );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

# This test strictly shouldn't be necessary, but versions previous to 0.50
# required the workspace as a parameter, so this verifies that that constraint
# no longer exists.
sub test_new_no_workspace {
    my $self = shift;

    try {
        my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                            session     => $session_id,
                            changeno    => $changeno,
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub _test_incomplete_exception {
    my ($self, $code, $expected_class) = @_;

    $expected_class ||= 'P4::Objects::Changelist';
    try {
        &{$code}();
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        my $e = shift;
        $self->assert_equals( $expected_class, $e->class );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };
    return;
}

sub test_new_abstract {
    my $self = shift;

    $self->_test_incomplete_exception(
        sub {
        my $cl = P4::Objects::Changelist->new( {
            session     => $session_id,
            changeno    => $changeno,
        } );
    } );

    return;
}

sub test_stringify {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
        session     => $session_id,
        changeno    => $changeno,
    } );

    $self->assert_str_equals( $changeno, $cl );

    return;
}

sub test_get_session {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
    } );
    $self->assert_equals( $session_id, $cl->get_session() );

    return;
}

sub test_get_workspace {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );
    $self->assert_equals( $wsname, $cl->get_workspace() );

    return;
}

sub test_set_get_date_number {
    my $self = shift;
    my $expected_date = 1186014538;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_date() );

    {
        package P4::Objects::Changelist;
        $cl->_set_date( $expected_date );
    }
    my $gotten_date = $cl->get_date();

    $self->assert_equals( $expected_date, $gotten_date );

    return;
}

sub test_set_get_date_formatted {
    my $self = shift;
    my $input_date = '2007/08/02 10:28:58';
    my $expected_date = str2time( $input_date );

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_date() );

    {
        package P4::Objects::Changelist;
        $cl->_set_date( $input_date );
    }
    my $gotten_date = $cl->get_date();

    $self->assert_equals( $expected_date, $gotten_date );

    return;
}

sub test_set_get_user {
    my $self = shift;
    my $expected_user = 'anothernameforme';

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_user() );

    {
        package P4::Objects::Changelist;
        $cl->_set_user( $expected_user );
    }
    my $gotten_user = $cl->get_user();

    $self->assert_equals( $expected_user, $gotten_user );

    return;
}

sub test_set_get_description {
    my $self = shift;
    my $expected_description = 'Is this really likely text for a description?';

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_description() );

    {
        package P4::Objects::Changelist;
        $cl->_set_description( $expected_description );
    }
    my $gotten_description = $cl->get_description();

    $self->assert_equals( $expected_description, $gotten_description );

    return;
}

sub test_set_get_status {
    my $self = shift;
    my $expected_status = 'submitted';

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_status() );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( $expected_status );
    }
    my $gotten_status = $cl->get_status();

    $self->assert_equals( $expected_status, $gotten_status );

    return;
}

sub test_set_get_jobs {
    my $self = shift;

    my $expected_jobs = [ 'job1', 'job2' ];

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
        session     => $session_id,
        changeno    => $changeno,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_jobs( $expected_jobs );
    }
    my $gotten_jobs = $cl->get_jobs();

    $self->assert_equals( $expected_jobs, $gotten_jobs );
    $self->assert_deep_equals( $expected_jobs, $gotten_jobs );

    return;
}

sub test_get_jobs_none {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
        session     => $session_id,
        changeno    => $changeno,
    } );

    my $gotten_jobs = $cl->get_jobs();

    $self->_assert_array( $gotten_jobs );
    $self->assert_equals( 0, scalar @{$gotten_jobs} );

    return;
}

sub test_get_files_none_pending {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
        session         => $session_id,
        changeno        => 'default',
    } );

    # Have to set status to make it a pending changelist
    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    my $gotten_files = $cl->get_files();
    $self->assert_not_null( $gotten_files );
    $self->_assert_array( $gotten_files );
    $self->assert_equals( 0, scalar @{$gotten_files} );

    return;
}

sub test_get_files_none_new {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
        session         => $session_id,
        changeno        => 'new',
    } );
    # Have to set status to make it a new changelist
    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    my $gotten_files = $cl->get_files();

    $self->assert_not_null( $gotten_files );
    $self->_assert_array( $gotten_files );
    $self->assert_equals( 0, scalar @{$gotten_files} );

    return;
}

sub test_is_new_true {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( $cl->is_new() );

    return;
}

sub test_is_new_false_changeno {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( ! $cl->is_new() );

    return;
}

sub test_is_existing_true_pending {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 3,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( $cl->is_existing() );

    return;
}

sub test_is_existing_true_submitted {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 3,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'submitted' );
    }

    $self->assert( $cl->is_existing() );

    return;
}

sub test_is_existing_false {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( ! $cl->is_existing() );

    return;
}

sub test_is_new_false_status {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( ! $cl->is_new() );

    return;
}

sub test_is_pending_true {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( $cl->is_pending() );

    return;
}

sub test_is_pending_false_changeno {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( ! $cl->is_pending() );

    return;
}

sub test_is_pending_false_status {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( ! $cl->is_pending() );

    return;
}

sub test_is_numbered_true {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    $self->assert( $cl->is_numbered() );

    return;
}

sub test_is_numbered_false_all_string {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    $self->assert( ! $cl->is_numbered() );

    return;
}

sub test_is_numbered_false_string_initial_number {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => '123new',
    } );

    $self->assert( ! $cl->is_numbered() );

    return;
}

sub test_is_numbered_false_string_final_number {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new123',
    } );

    $self->assert( ! $cl->is_numbered() );

    return;
}

sub test_is_submitted_true {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'submitted' );
    }

    $self->assert( $cl->is_submitted() );

    return;
}

sub test_is_submitted_false_changeno {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'submitted' );
    }

    $self->assert( ! $cl->is_submitted() );

    return;
}

sub test_is_submitted_false_status {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( ! $cl->is_submitted() );

    return;
}

sub test_is_default_true {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'default',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( $cl->is_default() );

    return;
}

sub test_is_default_false_new {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'new',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( ! $cl->is_default() );

    return;
}

sub test_is_default_false_numbered_pending {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 17,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'pending' );
    }

    $self->assert( ! $cl->is_default() );

    return;
}

sub test_is_default_false_new_pending {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::Changelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        changeno    => 'default',
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_status( 'new' );
    }

    $self->assert( ! $cl->is_default() );

    return;
}

sub _test_get_files_server {
    my ($self, $classname) = @_;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $changeno = 1;
    my $timestamp = '3209 1186098162';

    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@stephen-vances-computer\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/Users/steve/testws\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname/...\@ \@//depot/...\@
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/dummyfile1\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile1\@ \@1.1\@ 0
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/dummyfile1\@ 1 0
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/dummyfile1\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile1\@ \@1.1\@ 0
\@ex\@ $timestamp
\@pv\@ 7 \@db.rev\@ \@//depot/dummyfile2\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile2\@ \@1.1\@ 0
\@ex\@ $timestamp
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/dummyfile2\@ 1 0
\@ex\@ $timestamp
\@pv\@ 7 \@db.revhx\@ \@//depot/dummyfile2\@ 1 0 0 $changeno 1186098224 1186098153 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/dummyfile2\@ \@1.1\@ 0
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$wsname\@ \@$user\@ 1186098224 1 \@Change submission.
\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ $changeno \@Change submission.
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

    my $cl = $classname->new( {
        session     => $session,
        changeno    => $changeno,
    } );

    my $files = $cl->get_files();

    $self->assert_not_null( $files );
    $self->assert_equals( 2, scalar @{$files} );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( '//depot/dummyfile1', $first_file->get_depotname() );
    $self->assert_equals( 1, $first_file->get_revision() );
    $self->assert_equals( 'text', $first_file->get_type() );
    $self->assert_equals( 'add', $first_file->get_action() );
    $self->assert_equals( 0, $first_file->get_filesize() );

    return;
}

sub test_get_files_server {
    my ($self) = @_;
    return $self->_test_get_files_server( 'P4::Objects::Test::Helper::Changelist::NoopLoadSpec' );
}

sub test_get_files_server_incomplete_get_cache {
    my ($self) = @_;

    my $class = 'P4::Objects::Test::Helper::Changelist::IncompleteGetCache';
    $self->_test_incomplete_exception( sub {
        return $self->_test_get_files_server( $class );
    }, $class );
}

sub test_get_files_server_incomplete_set_cache {
    my ($self) = @_;

    my $class = 'P4::Objects::Test::Helper::Changelist::IncompleteSaveCache';
    $self->_test_incomplete_exception( sub {
        return $self->_test_get_files_server( $class );
    }, $class );
}

1;

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

package P4::Objects::Test::PendingChangelist;

use strict;
use warnings;

use Data::Dumper;
use Date::Parse;
use Error qw( :try );
use File::Spec::Functions;
use File::Temp qw( tempdir );
use IO::File;
use P4::Objects::PendingChangelist;
use P4::Objects::Session;
use P4::Server;
use Scalar::Util qw( looks_like_number );

use base qw( P4::Objects::Test::Helper::TestCase );

our $server;
our $session;
our $port;
our $wsname = 'unusualworkspace';
our $wsroot = '/some/workspace/root';
our $user = 'me';
our $timestamp = '3209 1186098162';
our $host = 'thelonehost';
our $dirtemplate = File::Spec->catfile(
    File::Spec->tmpdir(),
    'p4objects-ws-XXXXXX'
);

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {
    my $self = shift;

    # Set up a server for the test
    $self->_start_server();

    # Set up a session for the test
    $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    # Set up a temporary workspace root
    $wsroot = tempdir( $dirtemplate, CLEANUP => 1 );

    return;
}

sub tear_down {
    my $self = shift;

    $wsroot = undef;

    $session = undef;

    $server->stop_p4d();
    $server = undef;

    return;
}

sub test_new_default_workspace {
    my $self = shift;
    $self->_load_basic_checkpoint();

    my $cl;
    try {
        $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
        } );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught Perforce exception: ' . ref( $e ) . ': '
                            . join( "\n", @{$e->errors()} ) );
    };

    $self->assert_not_null( $cl );
    $self->assert( $cl->isa( 'P4::Objects::Common::Base' ) );

    return;
}

# Found that pending changelists submitted against the non-default workspace
# weren't being handled correctly
sub test_new_nondefault_workspace {
    my $self = shift;
    my $badws = 'nonexistantworkspacename';

    $session->set_workspace( $badws );
    $self->_load_basic_checkpoint();

    my $cl;
    try {
        $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
        } );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught Perforce exception: ' . ref( $e ) . ': '
                            . join( "\n", @{$e->errors()} ) );
    };

    $self->assert_not_null( $cl );
    $self->assert( $cl->isa( 'P4::Objects::Common::Base' ) );
    $self->assert( $cl->is_new() );
    $self->assert_equals( $wsname, $cl->get_workspace() );

    return;
}

sub test_new_numbered_changelist {
    my $self = shift;
    $self->_load_numbered_pending_checkpoint();
    my $expected_changeno = 1;

    # Assert pre-conditions
    my @output = `p4 -p $port -u $user changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( $expected_changeno, scalar @output );
    $self->assert( $output[0] =~ /\AChange $expected_changeno on / );

    my $cl;
    try {
        $cl = P4::Objects::PendingChangelist->new( {
                            session     => $session,
                            workspace   => $wsname,
                            changeno    => $expected_changeno,
        } );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught Perforce exception: ' . ref( $e ) . ': '
                            . join( "\n", @{$e->errors()} ) );
    };

    $self->assert_not_null( $cl );
    $self->assert_equals( $expected_changeno, $cl->get_changeno() );

    return;
}

sub test_new_numbered_changelist_submitted_number {
    my $self = shift;

    my $server = $self->_create_p4d( {
        archive => 'single_file.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $user = 'testuser';
    my $wsname = 'testws';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    try {
        my $cl = P4::Objects::PendingChangelist->new( {
            session     => $session,
            workspace   => $wsname,
            changeno    => 1,   # Known to be submitted in the data file
        } );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::InappropriateChangelist with {
        my $e = shift;
        $self->assert_equals( 1, $e->changeno() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

# TODO: test_new_numbered_changelist_nonexistant_number

sub test_get_session {
    my $self = shift;
    $self->_load_basic_checkpoint();

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );
    $self->assert_equals( $session, $cl->get_session() );

    return;
}

sub test_get_workspace {
    my $self = shift;
    $self->_load_basic_checkpoint();

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );
    $self->assert_equals( $wsname, $cl->get_workspace() );

    return;
}

sub test_new_values {
    my $self = shift;
    $self->_load_basic_checkpoint();

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    $self->assert_equals( 'new', $cl->get_changeno() );
    $self->assert_equals( 'new', $cl->get_status() );
    $self->assert_equals( $wsname, $cl->get_workspace() );
    $self->assert_equals( $user, $cl->get_user() );
    $self->assert_not_null( $cl->get_description() );
    # Changelist::get_files() now triggers a trip to the server. We just want
    # to test values.
    {
        package P4::Objects::Changelist;

        $self->assert_null( $cl->_get_files_cache() );
    }

    return;
}

sub test_set_get_date_number {
    my $self = shift;
    $self->_load_basic_checkpoint();
    my $expected_date = 1186014538;

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
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
    $self->_load_basic_checkpoint();

    my $input_date = '2007/08/02 10:28:58';
    my $expected_date = str2time( $input_date );

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
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
    $self->_load_basic_checkpoint();
    my $expected_user = 'anothernameforme';

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    $self->assert_not_equals( $expected_user, $cl->get_user() );

    $cl->set_user( $expected_user );
    my $gotten_user = $cl->get_user();

    $self->assert_equals( $expected_user, $gotten_user );

    return;
}

sub test_set_get_description {
    my $self = shift;
    $self->_load_basic_checkpoint();
    my $expected_description = 'Is this really likely text for a description?';

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    $self->assert_not_equals( $expected_description,  $cl->get_description() );

    $cl->set_description( $expected_description );
    my $gotten_description = $cl->get_description();

    $self->assert_equals( $expected_description, $gotten_description );

    return;
}

sub test_commit_new_changelist {
    my $self = shift;
    $self->_load_basic_checkpoint();
    my $expected_changeno = 'new';
    my $expected_status = 'new';

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    # Assert pre-conditions
    $self->assert_equals( $expected_changeno, $cl->get_changeno() );
    $self->assert_equals( $expected_status, $cl->get_status() );
    {
        package P4::Objects::Changelist;

        $self->assert_null( $cl->_get_files_cache() );
    }

    $cl->set_description( 'Some new description' );

    my $returned_changeno;
    try {
        $returned_changeno = $cl->commit();
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception:\n" . Dumper( $e ) );
    };

    $self->assert_not_null( $returned_changeno );

    my $new_changeno = $cl->get_changeno();
    $self->assert_not_null( $new_changeno );
    $self->assert_not_equals( $expected_changeno, $new_changeno );
    $self->assert( $new_changeno =~ /\A\d+\Z/ );
    my $new_status = $cl->get_status();
    $self->assert_not_equals( $expected_status, $new_status );
    # We haven't set up any files in the default changelist, but if we had, we
    # don't want them automatically transferred over in programmatic usage.
    # TODO: Set up files in the default changelist
    {
        package P4::Objects::Changelist;

        $self->assert_null( $cl->_get_files_cache() );
    }

    return;
}

# TODO: test_commit_numbered_changelist

# TODO: test_commit_unchanged_changelist

sub test_commit_retrieve_changelist {
    my $self = shift;

    $self->_load_basic_checkpoint();

    # Changeno will be assigned
    # Date will be assigned
    my $expected_workspace = $wsname;
    my $expected_user = $user;
    # Status will be assigned
    my $expected_description = "My test description.\n";
    my $expected_jobs = [ 'testjob' ];
    # TODO: Leave files verification for the respective file operations

    my $new_cl = P4::Objects::PendingChangelist->new( {
        session     => $session,
        workspace   => $wsname,
    } );

    $new_cl->set_user( $expected_user );
    $new_cl->set_description( $expected_description );
    {
        package P4::Objects::PendingChangelist;
        $new_cl->_set_jobs( $expected_jobs );
    }

    my $saved_changeno;
    try {
        $saved_changeno = $new_cl->commit();
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    my $saved_cl = P4::Objects::PendingChangelist->new( {
        session     => $session,
        workspace   => $wsname,
        changeno    => $saved_changeno,
    } );

    $self->assert_equals( $saved_changeno, $saved_cl->get_changeno() );
    $self->assert_not_null( $saved_cl->get_date() );
    $self->assert(
        looks_like_number( $saved_cl->get_date() ),
        'Expected number, got ' . $saved_cl->get_date() );
    $self->assert_equals( $expected_workspace, $saved_cl->get_workspace() );
    $self->assert_equals( $expected_user, $saved_cl->get_user() );
    $self->assert_not_null( $saved_cl->get_status() );
    $self->assert_equals(
        $expected_description,
        $saved_cl->get_description()
    );
    my $saved_jobs = $saved_cl->get_jobs();
    $self->assert_not_null( $saved_jobs );
    $self->assert_deep_equals( $expected_jobs, $saved_jobs );

    return;
}

sub test_reopen_files {
    my ($self) = @_;

    $self->_test_reopen_submit_common();

    return;
}

sub test_submit_files {
    my ($self) = @_;

    my ($cl, $expected_filenames) = $self->_test_reopen_submit_common();

#
# Pending change lists with multiple files were not submitted properly
# This test case ensures that the two files being submitted in the pending
# change list are submitted and the submitted change list contains them
#

    my $newchange = $cl->submit();
    $cl = P4::Objects::SubmittedChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
                        changeno    => $newchange } );
    my $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 2, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( $expected_filenames->[0], $first_file->get_depotname() );
    my $second_file = $files->[1];
    $self->assert_equals( 'P4::Objects::Revision', ref( $second_file ) );
    $self->assert_equals( $expected_filenames->[1], $second_file->get_depotname() );

    return;
}

sub test_add_files {
    my $self = shift;
    _test_add_reopen_common( $self );
    return;
}

sub test_add_files_special_characters {
    my $self = shift;
    $self->_load_numbered_pending_checkpoint();
    my $expected_changeno = 1;
    my $expected_filename = '//depot/a@#%*file.txt';

    # Assert pre-conditions
    my @output = `p4 -p $port -u $user changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( $expected_changeno, scalar @output );
    $self->assert( $output[0] =~ /\AChange $expected_changeno on / );

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
                        changeno    => $expected_changeno,
    } );

    # A little paranoia and nicety
    $self->assert_not_null( $cl );

    my $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    try {
        $cl->add_files( $expected_filename );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught ' . ref( $e ) . 'with errors '
                                    . join( "\n", @{$e->errors()} ) );
    };

    $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 1, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals(
        $first_file->translate_special_chars_to_codes( $expected_filename ),
        $first_file->get_depotname()
    );

    return;
}

# TODO: test_add_files_to_new_changelist

sub test_edit_files {
    my $self = shift;

    my $server = $self->_create_p4d( {
        archive => 'single_file.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $user = 'testuser';
    my $wsname = 'testws';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    # I'm comfortable relying on this other functionality now because of
    # the sequence of development.
    my $ws = $session->get_workspace();
    my $results = $ws->sync();
    $self->assert_equals( 1, $results->get_totalfilecount() );

    # Verify the attributes of the sync that are expected to change with edit
    my $revision = $results->get_results()->[0];
    my $localfile = $revision->get_localname();
    $self->assert( -r $localfile );
    $self->assert( ! -w $localfile );

    # Get the depot name so we can verify it's in the submit list.
    my $depotfile = $revision->get_depotname();

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    # A little paranoia and nicety even though it's supposed to throw an
    # exception
    $self->assert_not_null( $cl );

    $cl->set_description( 'Test comment for changelist.' );
    $cl->commit();
    $self->assert( ! $cl->is_new() );

    my $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    try {
        $cl->edit_files( $localfile );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught ' . ref( $e ) . 'with errors '
                                    . join( "\n", @{$e->errors()} ) );
    };

    # Verify that the file is now writable
    $self->assert( -w $localfile );

    # Make sure it shows up in the changelist
    $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 1, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( $depotfile, $first_file->get_depotname() );

    return;
}

sub test_delete_files {
    my $self = shift;

    my $server = $self->_create_p4d( {
        archive => 'single_file.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $user = 'testuser';
    my $wsname = 'testws';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    # I'm comfortable relying on this other functionality now because of
    # the sequence of development.
    my $ws = $session->get_workspace();
    my $results = $ws->sync();
    $self->assert_equals( 1, $results->get_totalfilecount() );

    # Verify the attributes of the sync that are expected to change with edit
    my $revision = $results->get_results()->[0];
    my $localfile = $revision->get_localname();
    $self->assert( -r $localfile );
    $self->assert( ! -w $localfile );

    # Get the depot name so we can verify it's in the submit list.
    my $depotfile = $revision->get_depotname();

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
    } );

    # A little paranoia and nicety even though it's supposed to throw an
    # exception
    $self->assert_not_null( $cl );

    $cl->set_description( 'Test comment for changelist.' );
    $cl->commit();
    $self->assert( ! $cl->is_new() );

    my $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    try {
        $cl->delete_files( $localfile );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught ' . ref( $e ) . 'with errors '
                                    . join( "\n", @{$e->errors()} ) );
    };

    # Verify that the file gone
    $self->assert( ! -f $localfile );

    # Make sure it shows up in the changelist
    $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 1, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( $depotfile, $first_file->get_depotname() );

    return;
}

sub test_submit {
    my $self = shift;
    $self->_load_numbered_pending_checkpoint();
    my $expected_changeno = 1;
    my $expected_filename = 'anewfile.txt';
    my $expected_depotpath = "//depot/$expected_filename";
    my $expected_localpath = File::Spec->catfile( $wsroot, $expected_filename );

    # Assert pre-conditions
    # Verify that we have our pending changelist ready
    my @output = `p4 -p $port -u $user changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( $expected_changeno, scalar @output );
    $self->assert( $output[0] =~ /\AChange $expected_changeno on / );

    # Verify that there aren't any submitted changelists
    @output = `p4 -p $port -u $user changes -s submitted`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
                        changeno    => $expected_changeno,
    } );

    # Add the file to the changelist
    $cl->add_files( $expected_depotpath );

    # Create the file with some contents
    my $fh = IO::File->new( "> $expected_localpath" );
    print $fh "Some text for the file\n";
    close $fh;

    my $newcl;
    try {
        $newcl = $cl->submit();
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        $self->assert( 0, 'Unexpected P4 exception: ' . ref( $e )
                            . ': ' . join( "\n", @{$e->errors()} ) );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, 'Unexpected P4::Objects exception: ' . ref( $e ) );
    };

    $self->assert_not_null( $newcl );
    $self->assert_equals( $expected_changeno, $newcl );

    # Verify that we have no pending changelists
    @output = `p4 -p $port -u $user changes -s pending`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    # Verify that there is exactly one submitted changelist
    @output = `p4 -p $port -u $user changes -s submitted`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( $expected_changeno, scalar @output );

    return;
}

# Motivated by discovery that non-default workspaces were not being properly
# applied to a submission.
sub test_submit_nondefault_workspace {
    my $self = shift;

    my $otherws = 'anotherws';

    $self->assert_not_equals( $otherws, $wsname );
    my $newws = $session->get_workspace($otherws);
    $newws->set_root( $wsroot );
    $newws->set_view( [ "//depot/... //$otherws/..." ] );
    $newws->commit();

    my $cl = P4::Objects::PendingChangelist->new( {
        session   => $session,
        workspace => $newws,
    } );

    $cl->set_description( 'Just another comment to make this changelist work' );
    $cl->commit();

    my $filename = catfile( $wsroot, 'filename.txt' );
    open TEMPFH, ">$filename";
    close TEMPFH;

    $cl->add_files($filename);
    try {
        my $changeno = $cl->submit();
    }
    catch P4::Objects::Exception::P4::RunError with {
        my $e = shift;

        my $message = $e->errors()->[0];
        my $expected_message_start = "Client '"
            . $session->get_workspace()
            . "' unknown";
        if( $message =~ /\A$expected_message_start/ ) {
            $self->assert( 0,
                'Submission used default workspace instead of specified workspace'
            );
        }
        else {
            $self->assert( 0, 'Caught unexpected RunError: ' . Dumper( $e ) );
        }
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_get_files_static_default {
    my $self = shift;

    my $session = 0xfeedf00d;
    my $wsname = 'testws';

    my $cl;
    try {
        $cl = P4::Objects::PendingChangelist->new( {
            session     => $session,
            attrs       => {
                changeno    => 'default',
                status      => 'pending',
            },
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };


    $self->assert( $cl->is_default() );

    return;
}

# PRIVATE METHODS

sub _start_server {
    my ($self) = @_;

    $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    $port = $server->get_port();

    return;
}

sub _load_basic_checkpoint {
    my ($self) = @_;

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$host\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname/...\@ \@//depot/...\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.job\@ \@testjob\@ \@\@ 0 0 \@A first simple test job.
\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.boddate\@ \@testjob\@ 104 1203632203
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 101 \@testjob\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 102 \@closed\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 103 \@$user\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 105 \@A first simple test job.
\@
\@ex\@ $timestamp
EOC

    $server->load_journal_string( $checkpoint );

    return;
}

sub _load_numbered_pending_checkpoint {
    my ($self) = @_;

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1
\@pv\@ 0 \@db.counters\@ \@journal\@ 1
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1187245101 1187245101 \@$user\@ \@\@ 0 \@\@ 0
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1187244715 1187244715 0 \@Default depot\@
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1187245179 1187245179 0 \@Created by $user.
\@
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1187245241 0 \@A new changelist
\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.changex\@ 1 1 \@$wsname\@ \@$user\@ 1187245241 0 \@A new changelist
\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 1 \@A new changelist
\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.job\@ \@testjob\@ \@\@ 0 0 \@A first simple test job.
\@
\@ex\@ $timestamp
\@pv\@ 1 \@db.fix\@ \@testjob\@ 1 1203632203 \@closed\@ \@$wsname\@ \@$user\@
\@ex\@ $timestamp
\@pv\@ 1 \@db.fixrev\@ \@testjob\@ 1 1203632203 \@closed\@ \@$wsname\@ \@$user\@
\@ex\@ $timestamp
\@pv\@ 0 \@db.boddate\@ \@testjob\@ 104 1203632203
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 101 \@testjob\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 102 \@closed\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 103 \@$user\@
\@pv\@ 0 \@db.bodtext\@ \@testjob\@ 105 \@A first simple test job.
\@
\@ex\@ $timestamp
EOC

    $server->load_journal_string( $checkpoint );

    return;
}

sub _test_add_reopen_common {
    my ($self) = @_;

    $self->_load_numbered_pending_checkpoint();
    my $expected_changeno = 1;

    my @files = ( 'anewfile.txt', 'anewfile2.txt' );

    my @expected_filenames = map { '//depot/' . $_ } @files;

    my @expected_localpaths = map { File::Spec->catfile( $wsroot, $_ ) } @files;

    for my $expected_localpath (@expected_localpaths) {
        my $fh = IO::File->new( "> $expected_localpath" );
        print $fh "Some text for the file\n";
        close $fh;
    }

    # Assert pre-conditions
    my @output = `p4 -p $port -u $user changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( $expected_changeno, scalar @output );
    $self->assert( $output[0] =~ /\AChange $expected_changeno on / );

    my $cl = P4::Objects::PendingChangelist->new( {
                        session     => $session,
                        workspace   => $wsname,
                        changeno    => $expected_changeno,
    } );

    # A little paranoia and nicety
    $self->assert_not_null( $cl );

    my $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    try {
        $cl->add_files( @expected_filenames );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught ' . ref( $e ) . 'with errors '
                                    . join( "\n", @{$e->errors()} ) );
    };
    $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 2, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( $expected_filenames[0], $first_file->get_depotname() );
    my $second_file = $files->[1];
    $self->assert_equals( 'P4::Objects::Revision', ref( $second_file ) );
    $self->assert_equals( $expected_filenames[1], $second_file->get_depotname() );
    return ($cl,\@expected_filenames);
}

sub  _test_reopen_submit_common {
    my ($self) = @_;
    my ($cl, $expected_filenames) = _test_add_reopen_common( $self );

    my $new_cl = P4::Objects::PendingChangelist->new( {
                     session     => $session,
                     workspace   => $wsname,
    } );
    # A little paranoia and nicety
    $self->assert_not_null( $new_cl );
    $new_cl->set_description( 'Some other new description from test_reopen_files' );

    $new_cl->commit();  # Add this changelist
    my $files = $new_cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    try {
        $new_cl->reopen_files( @{$expected_filenames} );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;

        $self->assert( 0, 'Caught ' . ref( $e ) . 'with errors '
                                    . join( "\n", @{$e->errors()} ) );
    };
    $files = $new_cl->get_files();
    $self->assert_not_null( $files );
    $self->assert_equals( 2, scalar @$files );
    my $first_file = $files->[0];
    $self->assert_equals( 'P4::Objects::Revision', ref( $first_file ) );
    $self->assert_equals( $expected_filenames->[0], $first_file->get_depotname() );
    my $second_file = $files->[1];
    $self->assert_equals( 'P4::Objects::Revision', ref( $second_file ) );
    $self->assert_equals( $expected_filenames->[1], $second_file->get_depotname() );

    $files = $cl->get_files();
    $self->assert_not_null( $files );
    $self->_assert_array( $files );
    $self->assert_equals( 0, scalar @{$files} );

    return ( $new_cl, $expected_filenames );
}

1;

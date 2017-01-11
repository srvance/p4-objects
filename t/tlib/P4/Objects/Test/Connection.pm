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

package P4::Objects::Test::Connection;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use File::Spec::Functions;
use File::Temp qw( tempdir );
use P4::Objects::Exception;
use P4::Objects::Test::Helper::Session::Mock;
use P4::Objects::Test::Helper::P4::AlwaysDropped;
use P4::Objects::Test::Helper::P4::NeverConnects;
use P4::Objects::Test::Helper::P4::SaveChangeBadResults;

use P4::Objects::Connection;
use P4::Objects::Test::Helper::P4Fail;

use base qw( P4::Objects::Test::Helper::TestCase );

our $dirtemplate = File::Spec->catfile(
    File::Spec->tmpdir(),
    'p4objects-ws-XXXXXX'
);

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

sub test_new {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::Connection->new( { session => $session } );
    $self->assert_not_null( $conn );
    $self->assert( $conn->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_new_p4 {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::Connection->new( { session => $session } );
    $self->assert_not_null( $conn->get_p4() );

    return;
}

sub test_new_p4_bad_package {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = undef;

    try {
        $conn = P4::Objects::Connection->new( {
            session     => $session,
            p4_class    => 'BadP4',
        } );
    }
    catch P4::Objects::Exception::BadPackage with {
        # Correct behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , "No error or unexpected error: " . ref( $e ) );
    }
    finally {
        $self->assert_null( $conn );
    };

    return;
}

sub test_new_p4_failure {
    my $self = shift;

    my $p4_class = 'P4::Objects::Test::Helper::P4Fail';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = undef;

    try {
        $conn = P4::Objects::Connection->new( {
            session     => $session,
            p4_class    => $p4_class,
        } );
    }
    catch P4::Objects::Exception::BadAlloc with {
        # Correct behavior
        my $e = shift;

        $self->assert_equals( $p4_class, $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , "No error or unexpected error: " . ref( $e ) );
    }
    finally {
        $self->assert_null( $conn );
    };

    return;
}

sub test_new_session {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::Connection->new( { session => $session } );
    my $gotten_session = $conn->get_session();
    $self->assert_equals( $session, $gotten_session );

    return;
}

sub test_new_p4_class {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::Connection->new( { session => $session } );
    my $class = $conn->get_p4_class();
    $self->assert_equals( "P4", $class );

    return;
}

sub test_save_workspace {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $client = 'testclientname';
    my %spec = (
        Client          => $client,
        Root            => '/some/root',
        View            => [ "//depot/... //$client/..." ],
        Owner           => $user,
        LineEnd         => 'share',
        Host            => 'testclienthost',
        Description     => 'testclientdescription',
        SubmitOptions   => 'revertunchanged',
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port clients`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_workspace( \%spec );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port clients`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );
    my @fields = split( / /, $output[0] );
    $self->assert_equals( $spec{Client}, $fields[1] );
    $self->assert_equals( $spec{Root}, $fields[4] );
    # TODO: Validate more fields?

    return;
}

sub test_save_branch {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testbranchowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $branch = 'testbranchname';

    my $b = $conn->run( 'branch', '-o', $branch );
    $b->{View} = [ "//depot/dir1/... //depot/dir2/..." ];

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port branches`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 branches command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_branch( $b );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port branches`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 branches command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );
    my @fields = split( / /, $output[0] );
    $self->assert_equals( $branch, $fields[1] );
    # TODO: Validate more fields?

    return;
}

sub test_save_workspace_failed {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
    } );

    my $client = 'testclientname';
    my %spec = (
        Client          => $client,
        # Omit Root as our error condition
        View            => [ "//depot/... //$client/..." ],
        Owner           => $user,
        LineEnd         => 'share',
        Host            => 'testclienthost',
        Description     => 'testclientdescription',
        SubmitOptions   => 'revertunchanged',
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port clients`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_workspace( \%spec );
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        # Expected result
        my $e = shift;
        $self->assert( 1, $e->errorcount() );
        my $errors = $e->errors();
        $self->assert( scalar @$errors > 0 );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected P4::Objects exception " . ref( $e ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception " . ref( $e ) );
    };

    @output = `p4 -u $user -p $port clients`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    return;
}

sub test_save_changelist_new_changelist {
    my $self = shift;
    my $user = 'testclientowner';
    my $client = 'testclientname';
    my $wsrootprefix = '/my/workspace/root';

    # Set up the server

    # We need to have the workspace and user in the server.
    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 3221 1184183998
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@example.com\@ \@\@ 1184183998 1184183998 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 3221 1184183998
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1184183985 1184183985 0 \@Default depot\@ 
\@ex\@ 3221 1184183998
\@pv\@ 4 \@db.domain\@ \@$client\@ 99 \@\@ \@$wsrootprefix/$client\@ \@\@ \@\@ \@$user\@ 1184184034 1184184034 0 \@Created by $user.
\@ 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.view\@ \@$client\@ 0 0 \@//$client/...\@ \@//depot/...\@ 
\@ex\@ 3221 1184183998
EOC

    my $server = $self->_create_p4d( {
        journal => $checkpoint,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
                        workspace   => $client,
    } );

    my %spec = (
        Change          => 'new',
        # No date on a new changelist
        Client          => $client,
        User            => $user,
        Status          => 'new',
        Description     => 'testdescription',
        # No files to worry about here.
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port changes`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    # Fresh server should not have any changelists
    $self->assert_equals( 0, scalar @output );

    my $result;
    try {
        $result = $conn->save_changelist( \%spec );
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        my $e = shift;
        $self->assert( 0, "Perforce error: " . join( "\n", @{$e->errors()} ) );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . ref( $e ) );
    };

    @output = `p4 -u $user -p $port changes`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );
    $self->assert_equals( 1, $result );

    return;
}

# TODO: Implement this.
#sub test_save_changelist_existing_changelist {
#    my $self = shift;
#
#    $self->assert( 0 );
#
#    return;
#}

sub test_save_changelist_failure {
    my $self = shift;
    my $user = 'testclientowner';
    my $client = 'testclientname';

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
                        workspace   => $client,
    } );

    my %spec = (
        Change          => 'new',
        # No date on a new changelist
        Client          => $client,
        User            => $user,
        Status          => 'new',
        Description     => 'testdescription',
        # No files to worry about here.
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port changes`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    # Fresh server should not have any changelists
    $self->assert_equals( 0, scalar @output );

    my $result;
    try {
        $result = $conn->save_changelist( \%spec );
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        # Expected behavior
        my $e = shift;
        $self->assert( $e->errorcount() > 0 );
        $self->assert( scalar @{$e->errors()} > 0 );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_save_changelist_failure_unexpected_output {
    my $self = shift;
    my $user = 'testclientowner';
    my $wsname = 'testclientname';

    # We need to have the workspace and user in the server.
    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 3221 1184183998
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@example.com\@ \@\@ 1184183998 1184183998 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 3221 1184183998
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1184183985 1184183985 0 \@Default depot\@ 
\@ex\@ 3221 1184183998
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@/some/client/root\@ \@\@ \@\@ \@$user\@ 1184184034 1184184034 0 \@Created by $user.
\@ 
\@ex\@ 3221 1184183998
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 3221 1184183998
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session;
    my $conn;
    try {
        ($session, $conn) = $self->_create_connection_with_mock_session( {
            port        => $port,
            user        => $user,
            workspace   => $wsname,
            p4_class    => 'P4::Objects::Test::Helper::P4::SaveChangeBadResults',
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    my %spec = (
        Change          => 'new',
        # No date on a new changelist
        Client          => $wsname,
        User            => $user,
        Status          => 'new',
        Description     => 'testdescription',
        # No files to worry about here.
    );

    my $result;
    try {
        $result = $conn->save_changelist( \%spec );
        $self->assert( 0, 'Did not receive an  exception as expected.' );
    }
    catch P4::Objects::Exception::P4::UnexpectedOutput with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'Change submission result', $e->type() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . ref( $e ) );
    };

    return;
}

sub test_submit_changelist {
    my $self = shift;

    my $user = 'testclientowner';
    my $client = 'testclientname';
    my $timestamp = '3209 1186098162';
    my $wsroot = tempdir( $dirtemplate, CLEANUP => 1 );
    my $description = 'Test description.';

    my $addfile = 'newfile.txt';
    my $localpath = File::Spec->catfile( $wsroot, $addfile );
    my $clientpath = "//$client/$addfile";
    my $depotpath = "//depot/$addfile";

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$client\@ \@\@ 1188332048 1188332048 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1188332011 1188332011 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$client\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1188332065 1188332065 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$client\@ 0 0 \@//$client/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 2 \@db.locks\@ \@$depotpath\@ \@$client\@ \@$user\@ 0 0 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.working\@ \@$clientpath\@ \@$depotpath\@ \@$client\@ \@$user\@ 0 1 0 0 0 0 0 0 00000000000000000000000000000000 -1 0 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 1 1 \@$client\@ \@$user\@ 1188332082 0 \@$description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.changex\@ 1 1 \@$client\@ \@$user\@ 1188332082 0 \@$description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 1 \@Test changelist
\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal => $checkpoint,
    } );
    my $port = $server->get_port();

    # Assert pre-conditions
    # Ensure we have a pending changelist
    my @output = `p4 -u $user -p $port changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );

    # Ensure we have no submitted changelists
    @output = `p4 -u $user -p $port changes -s submitted`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
                        workspace   => $client,
    } );

    # Create the file with some contents
    my $fh = IO::File->new( "> $localpath" );
    print $fh "Some text for the file\n";
    close $fh;

    my %spec = (
        Change          => "1", # Must be a string because of a P4Perl bug
        Client          => $client,
        User            => $user,
        Status          => 'pending',
        Description     => $description,
        Files           => [ $depotpath ],
    );

    my $result;
    try {
        $result = $conn->submit_changelist( \%spec );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        $self->assert( 0, "Unexpected P4 exception: " . ref( $e )
                    . ", " . join( "\n", @{$e->errors()} ) );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected P4::Objects exception: " . ref( $e ) );
    };

    $self->assert_not_null( $result );
    $self->assert( $result =~ /\A\d+\Z/ );

    # Ensure we have no pending changelists
    @output = `p4 -u $user -p $port changes -s pending`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    # Ensure we have one submitted changelist
    @output = `p4 -u $user -p $port changes -s submitted`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );

    return;
}

sub test_submit_changelist_failure {
    my $self = shift;

    my $user = 'testclientowner';
    my $client = 'testclientname';
    my $timestamp = '3209 1186098162';
    my $wsroot = tempdir( $dirtemplate, CLEANUP => 1 );
    my $description = 'Test description.';

    my $addfile = 'newfile.txt';
    my $localpath = File::Spec->catfile( $wsroot, $addfile );
    my $clientpath = "//$client/$addfile";
    my $depotpath = "//depot/$addfile";

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ $timestamp
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$client\@ \@\@ 1188332048 1188332048 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ $timestamp
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1188332011 1188332011 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$client\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1188332065 1188332065 0 \@Created by $user.
\@ 
\@ex\@ $timestamp
\@pv\@ 1 \@db.view\@ \@$client\@ 0 0 \@//$client/...\@ \@//depot/...\@ 
\@ex\@ $timestamp
\@pv\@ 2 \@db.locks\@ \@$depotpath\@ \@$client\@ \@$user\@ 0 0 0 
\@ex\@ $timestamp
\@pv\@ 7 \@db.working\@ \@$clientpath\@ \@$depotpath\@ \@$client\@ \@$user\@ 0 1 0 0 0 0 0 0 00000000000000000000000000000000 -1 0 0 
\@ex\@ $timestamp
\@pv\@ 0 \@db.change\@ 1 1 \@$client\@ \@$user\@ 1188332082 0 \@$description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.changex\@ 1 1 \@$client\@ \@$user\@ 1188332082 0 \@$description
\@ 
\@ex\@ $timestamp
\@pv\@ 0 \@db.desc\@ 1 \@Test changelist
\@ 
\@ex\@ $timestamp
EOC

    my $server = $self->_create_p4d( {
        journal => $checkpoint,
    } );
    my $port = $server->get_port();

    # Assert pre-conditions
    # Ensure we have a pending changelist
    my @output = `p4 -u $user -p $port changes -s pending`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );

    # Ensure we have no submitted changelists
    @output = `p4 -u $user -p $port changes -s submitted`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 changes command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => $user,
                        workspace   => $client,
    } );

    # Create the file with some contents
    my $fh = IO::File->new( "> $localpath" );
    print $fh "Some text for the file\n";
    close $fh;

    my %spec = (
        # Omit the change number
        Client          => $client,
        User            => $user,
        Status          => 'pending',
        Description     => $description,
        Files           => [ $depotpath ],
    );

    my $result;
    try {
        $result = $conn->submit_changelist( \%spec );
    }
    catch P4::Objects::Exception::P4 with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals(
            'P4::Objects::Exception::P4::BadSpec',
            ref( $e )
        );
        $self->assert( $e->errorcount() > 0 );
        $self->assert( scalar @{$e->errors()} > 0 );
        $self->assert_null( $result );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "No or unexpected exception: " . ref( $e ) );
    };

    return;
}

# Leave this here because it invokes connect() which invokes overridden
# methods.
sub test_run {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => 'me',
    } );

    my $results;
    try {
        $results = $conn->run( 'info' );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        my $errors = $e->errors();
        $self->assert( 0, "Unexpected Perforce error: "
                            . join( "\n", @$errors)
        );
    };

    # Arbitrary number of lines but good enough for 'info' results
    $self->assert_equals( 'HASH', ref( $results ) );
    $self->assert( scalar keys %$results > 8 );
    # TODO: Do we want to verify some of the data or at least some of the keys?

    return;
}

# This is specific to a standard connection
sub test_run_empty_result {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => 'me',
    } );

    # Run a command that requires an array result, but that we know will
    # produce no results.
    my $results;
    try {
        $results = $conn->run( 'clients' );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        my $errors = $e->errors();
        $self->assert( 0, "Unexpected Perforce error: "
                            . join( "\n", @$errors)
        );
    };

    $self->assert_not_null( $results );
    $self->assert_equals( 0, scalar @$results );

    return;
}

sub test_connect {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => 'me',
    } );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    # TODO: Verify that the connection happened with the right parameters.
    #       This may have to happen in a run test instead of here, so we can
    #       successfully use 'info'.

    return;
}

sub test_connect_twice {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                        port        => $port,
                        user        => 'me',
    } );
    # This line motivated by coverage. Could be done in any of these tests.
    $conn->get_session()->set_charset( 'utf8' );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    return;
}

# Coverage motivated
sub test_connect_dropped {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => 'me',
                p4_class    => 'P4::Objects::Test::Helper::P4::AlwaysDropped',
    } );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        $self->assert( 0, "Unexpected connection failure" );
    };

    return;
}

# Coverage motivated
sub test_connect_fails {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => 'me',
                p4_class    => 'P4::Objects::Test::Helper::P4::NeverConnects',
    } );

    try {
        $conn->connect();
    }
    catch P4::Objects::Exception::P4::CantConnect with {
        # Expected result
    }
    otherwise {
        $self->assert( 0, "Unexpected connection success" );
    };

    return;
}

# Coverage motivated
sub test_private_is_connected {
    my ($self) = @_;

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => 1717,
                user        => 'me',
    } );

    my $result;
    {
        package P4::Objects::Connection;
        $conn->_set_P4( undef );
        $result = $conn->_is_connected();
    }

    $self->assert_not_null( $result );
    $self->assert( ! $result );

    return;
}

sub test_sync_workspace {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my $results;
    my $warnings;
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace => $workspace,
        } );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        Error::flush();
        $self->assert(0, "Caught exception with " . $e->errorcount()
                .  " errors:\n"
                . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: "
                            . ref( $e )
                            . "\nErrors: "
                            . $e->text()
                            . "at line " . $e->line() . " in " . $e->file()
        );
    };

    # Assert the results
    $self->assert_not_null( $results );
    $self->assert_equals( 2, scalar @$results );
    $self->assert_not_null( $warnings );
    $self->assert_equals( 0, scalar @$warnings );

    # Assert the file system effects
    $self->assert( -d $rootdir, "Workspace root $rootdir doesn't exist" );
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    return;
}

sub test_sync_workspace_with_filespec {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my ($results, $warnings);
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace   => $workspace,
            filespec    => '@1',
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    $self->assert_not_null( $results );
    $self->assert_equals( 1, scalar @{$results},
        "Wrong number of results. Warnings:\n"
        . join( "\n", @$warnings ) );
    # We verified warnings in another test case. Nothing new to test here.

    my $rev = $results->[0];
    $self->assert_equals( '//depot/text.txt', $rev->{depotFile} );
    $self->assert_equals( 1, $rev->{rev} );
    $self->assert_equals( 0, $rev->{fileSize} );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    # We know by construction that the file has zero size.
    $self->assert( -z $textfile );

    return;
}

sub test_sync_workspace_with_filespec_list {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';
    my @synclist = ( '//depot/text.txt', '//depot/binary.bin' );

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my ($results, $warnings);
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace   => $workspace,
            filespec    => \@synclist,
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    $self->assert_not_null( $results );
    $self->assert_equals( scalar @synclist, scalar @{$results},
        "Wrong number of results. Warnings:\n"
        . join( "\n", @$warnings ) );
    # We verified warnings in another test case. Nothing new to test here.

    my $rev = $results->[0];
    $self->assert_equals( $synclist[0], $rev->{depotFile} );
    $self->assert_equals( 1, $rev->{rev} );
    $self->assert_equals( 0, $rev->{fileSize} );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    # We know by construction that the file has zero size.
    $self->assert( -z $textfile );

    $rev = $results->[1];
    $self->assert_equals( $synclist[1], $rev->{depotFile} );
    $self->assert_equals( 1, $rev->{rev} );
    $self->assert_equals( 0, $rev->{fileSize} );
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );

    # We know by construction that the file has zero size.
    $self->assert( -z $binfile );

    return;
}

sub test_sync_workspace_omit_files_with_filespec {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my ($results, $warnings) = $conn->sync_workspace( {
        workspace   => $workspace,
        filespec    => '@1',
        omit_files  => 1,
    } );

    $self->assert_not_null( $results );
    $self->assert_equals( 1, scalar @{$results},
        "Wrong number of results. Warnings:\n"
        . join( "\n", @$warnings ) );
    # We verified warnings in another test case. Nothing new to test here.

    my $rev = $results->[0];
    $self->assert_equals( '//depot/text.txt', $rev->{depotFile} );
    $self->assert_equals( 1, $rev->{rev} );
    $self->assert_equals( 0, $rev->{fileSize} );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( ! -f $textfile, "Text file $textfile exists" );

    return;
}

sub test_sync_workspace_omit_files_false {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my $results;
    my $warnings;
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace   => $workspace,
            omit_files  => 0,
        } );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        Error::flush();
        $self->assert(0, "Caught exception with " . $e->errorcount()
                .  " errors:\n"
                . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: "
                            . ref( $e )
                            . "\nErrors: "
                            . $e->text()
                            . "at line " . $e->line() . " in " . $e->file()
        );
    };

    # Assert the results
    $self->assert_not_null( $results );
    $self->assert_equals( 2, scalar @$results );
    $self->assert_not_null( $warnings );
    $self->assert_equals( 0, scalar @$warnings );

    # Assert the file system effects
    $self->assert( -d $rootdir, "Workspace root $rootdir doesn't exist" );
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    return;
}

sub test_sync_workspace_fail_no_workspace {
    my $self = shift;

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => 1717,
    } );

    try {
        my ($results, $warnings) = $conn->sync_workspace();
        $self->assert( 0, "No exception thrown" );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . ref( $e ) );
    };

    return;
}

sub test_integrate_workspace_fail_no_workspace {
    my $self = shift;

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => 1717,
    } );

    try {
        my ($results, $warnings) = $conn->integrate_workspace();
        $self->assert( 0, "No exception thrown" );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Unexpected exception: ' . ref( $e ) );
    };

    return;
}

sub test_sync_workspace_with_warnings {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    # Flush the client. We know this generates a warning and no results.
    my @output = `p4 -p $port -u $user -c $workspace sync -k`;
    $self->assert_equals( 0, $?, 'p4 sync -k failed' );
    $self->assert_equals( 2, scalar @output );   

    my $results;
    my $warnings;
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace => $workspace,
        } );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        $self->assert(0, "Caught exception with " . $e->errorcount()
                .  " errors:\n"
                . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    # Assert the results
    $self->assert_not_null( $results );
    $self->assert_equals( 0, scalar @$results );
    $self->assert_not_null( $warnings );
    $self->assert_equals( 1, scalar @$warnings );
    $self->assert_equals( "File(s) up-to-date.\n", $warnings->[0] );

    # Assert no file system effects
    # Skip the directory check. It's created by the tempdir call.
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( ! -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( ! -f $textfile, "Text file $textfile doens't exist" );

    return;
}

sub test_sync_workspace_fail_with_errors {
    my $self = shift;

    # TODO: chmod()-based tests don't work under Windows. Skip this test.
    return if( $^O eq 'MSWin32' );

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    $self->assert_equals( 1, chmod( 0, $rootdir ) );

    my $results;
    my $warnings;
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace => $workspace,
        } );
        $self->assert( 0, 'Unexpected continuation' );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        # Expected behavior
        my $e = shift;
        $self->assert( $e->errorcount() > 0 );
        $self->assert( @{$e->errors()} > 0 );
        # The results have one for each file even though they failed.
        $self->assert_equals( 2, scalar @{$e->results()} );
    }
    catch P4::Objects::Exception::P4 with {
        my $e = shift;
        $self->assert(0, "Caught exception " . ref( $e ) . " with "
                . $e->errorcount()
                .  " errors:\n"
                . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    return;
}

sub test_sync_workspace_force_sync {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';
    my $expected_revisions = 2; # Known from the archive

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my ($results, $warnings) = $conn->sync_workspace( {
        workspace   => $workspace,
    } );

    $self->assert_equals( $expected_revisions, scalar @{$results} );

    ($results, $warnings) = $conn->sync_workspace( {
        workspace   => $workspace,
    } );

    $self->assert_equals( 0, scalar @{$results} );
    $self->assert_equals( 1, scalar @{$warnings} );
    $self->assert_equals( "File(s) up-to-date.\n", $warnings->[0] );

    try {
        ($results, $warnings) = $conn->sync_workspace( {
            workspace   => $workspace,
            force_sync  => 1,
        } );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_equals( $expected_revisions, scalar @{$results} );

    return;
}

sub test_sync_workspace_invalid_parm {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';
    my $port = 1717; # Fixed because it won't actually be used
    my $bogusoption = 'somebogusoption';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    try {
        $conn->sync_workspace( {
            workspace       => $workspace,
            $bogusoption    => 1,
        } );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::InvalidParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $bogusoption, $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    return;
}

sub test_sync_workspace_preview {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my $results;
    my $warnings;
    try {
        ($results, $warnings) = $conn->sync_workspace( {
            preview     => 1,
            workspace   => $workspace,
        } );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        Error::flush();
        $self->assert(0, "Caught exception with " . $e->errorcount()
                .  " errors:\n"
                . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    # Assert the results
    $self->assert_not_null( $results );
    $self->assert_equals( 2, scalar @$results );
    $self->assert_not_null( $warnings );
    $self->assert_equals( 0, scalar @$warnings );

    # Assert the file system effects
    $self->assert( -d $rootdir, "Workspace root $rootdir doesn't exist" );
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( ! -f $binfile, "Binary file $binfile exists but shouldn't" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( ! -f $textfile, "Text file $textfile exists but shouldn't" );

    return;
}

sub test_save_job {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    my %job_spec = (
        Job           => 'new',
        Status        => 'open',
        User          => $user,
        Description   => 'test job',
    );

    # Assert pre-conditions - No jobs present for this server/port
    my @output = `p4 -u $user -p $port jobs`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 jobs command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_job( \%job_spec );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port jobs`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 jobs command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );
    my @fields = split( / /, $output[0], 7 );
    $self->assert_equals( $job_spec{User}, $fields[4] );
    $self->assert_equals( "'" . $job_spec{Description} . " '\n", $fields[6] );
    # TODO: Validate more fields?

    return;
}

sub test_save_job_failure {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    my %job_spec = (
	# Omit the Job required attribute
        Status        => 'open',
        Owner         => $user,
        Description   => 'test job',
    );

    # Assert pre-conditions - No jobs present for this server/port
    my @output = `p4 -u $user -p $port jobs`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 jobs command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_job( \%job_spec );
        $self->assert( 0, 'Did not receive expected exception' );
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port jobs`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 jobs command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    return;
}

sub test_save_label {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    my $labelname = 'testlabelname';
    my %spec = (
        Label           => $labelname,
        Owner           => $user,
        Description     => 'testlabeldescription',
        Options         => 'unlocked',
        Revision        => '@12345',
        View            => [ '//depot/nowhere/...' ],
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port labels`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_label( \%spec );
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port labels`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );
    my @fields = split( / /, $output[0] );
    $self->assert_equals( $spec{Label}, $fields[1] );
    # TODO: Validate more fields?

    return;
}

sub test_save_label_failure {
    my ($self) = @_;

    # Set up the server
    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'testclientowner';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
    } );

    my %spec = (
        # Omit the required label name
        Owner           => $user,
        Description     => 'testlabeldescription',
        Options         => 'unlocked',
        Revision        => '@12345',
        View            => [ '//depot/nowhere/...' ],
    );

    # Assert pre-conditions
    my @output = `p4 -u $user -p $port labels`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    try {
        $conn->save_label( \%spec );
        $self->assert( 0, 'Did not receive expected exception' );
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    @output = `p4 -u $user -p $port labels`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 labels command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    return;
}

sub test_get_workspace_opened {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $wsroot = "/Users/$user/ws/$wsname";
    my $filename = 'newfile.txt';
    my $depotfile = "//depot/$filename";
    my $wsfile = "//$wsname/$filename";

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 28911 1197409763
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1197409722 1197409722 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 28911 1197409763
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 28911 1197409763
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1197409713 1197409713 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@$wsroot\@ \@\@ \@\@ \@$user\@ 1197409729 1197409729 0 \@Created by $user.
\@ 
\@ex\@ 28911 1197409763
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 28911 1197409763
\@pv\@ 2 \@db.locks\@ \@$depotfile\@ \@$wsname\@ \@$user\@ 0 0 0 
\@ex\@ 28911 1197409763
\@pv\@ 8 \@db.working\@ \@$wsfile\@ \@$depotfile\@ \@$wsname\@ \@$user\@ 0 1 0 0 0 0 0 0 00000000000000000000000000000000 -1 0 0 0 
\@ex\@ 28911 1197409763
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $results = $conn->get_workspace_opened( $wsname );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );
    my $first_result = $results->[0];
    $self->assert_equals( 'HASH', ref( $first_result ) );
    $self->assert_equals( $depotfile, $first_result->{depotFile} );
    $self->assert_equals( $wsfile, $first_result->{clientFile} );
    $self->assert_equals( $user, $first_result->{user} );
    $self->assert_equals( 'default', $first_result->{change} );
    $self->assert_equals( 'add', $first_result->{action} );
    $self->assert_equals( '1', $first_result->{rev} );
    $self->assert_equals( 'text', $first_result->{type} );

    return;
}

sub test_get_workspace_opened_fail_no_arg {
    my $self = shift;

    # No need to create server. Should never connect.
    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port        => 1717,
        user        => 'notme',
    } );

    try {
        my $results = $conn->get_workspace_opened();
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ', Dumper( $e ) );
    };

    return;
}

sub test_resolve_files {
    my $self = shift;

    my $user = 'testuser';
    my $workspace = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'resolve_test_single.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );

    my ($results, $warnings) = $conn->resolve_files( {
        preview     => 1,
        workspace   => $workspace,
    } );

    $self->assert_not_null( $results );
    $self->assert_not_equals( 0, scalar @{$results} );
    $self->assert_equals( '//depot/a.txt', $results->[0]->{fromFile} );
    $self->assert_equals( 1, $results->[0]->{startFromRev} );
    $self->assert_equals( 2, $results->[0]->{endFromRev} );

    return;
}

sub test_resolve_files_no_workspace {
    my $self = shift;

    my $user = 'testuser';
    my $port = 1717; # Won't be used

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    try {
        my ($results, $warnings) = $conn->resolve_files( {
            preview     => 1,
            # Omit workspace
        } );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_resolve_files_no_preview {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $port = 1717; # Won't be used

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    try {
        my ($results, $warnings) = $conn->resolve_files( {
            # Omit preview
            workspace   => $wsname,
        } );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'preview', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_resolve_files_false_preview {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $port = 1717; # Won't be used

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    try {
        my ($results, $warnings) = $conn->resolve_files( {
            preview     => 0,
            workspace   => $wsname,
        } );
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::InvalidParameter with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'preview', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_resolved_no_files {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $journal =<<EOJ;
\@pv\@ 0 \@db.counters\@ \@change\@ 3 
\@pv\@ 0 \@db.counters\@ \@journal\@ 2 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 29635 1216343123
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1216251087 1216343123 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 29635 1216343123
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 29635 1216343123
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1216251015 1216251015 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@CLIENTROOT\@ \@\@ \@\@ \@$user\@ 1216251097 1216338664 0 \@Created by $user.
\@ 
\@ex\@ 29635 1216343123
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.integed\@ \@//depot/a.txt\@ \@//depot/b.txt\@ 0 1 0 1 3 2 
\@pv\@ 0 \@db.integed\@ \@//depot/b.txt\@ \@//depot/a.txt\@ 0 1 0 1 2 2 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.resolve\@ \@//$wsname/b.txt\@ \@//depot/a.txt\@ 1 2 0 0 4 1 \@//depot/a.txt\@ 1 
\@ex\@ 29635 1216343123
\@pv\@ 2 \@db.have\@ \@//$wsname/a.txt\@ \@//depot/a.txt\@ 2 0 
\@pv\@ 2 \@db.have\@ \@//$wsname/b.txt\@ \@//depot/b.txt\@ 1 0 
\@ex\@ 29635 1216343123
\@pv\@ 2 \@db.locks\@ \@//depot/b.txt\@ \@$wsname\@ \@$user\@ 4 0 0 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.archmap\@ \@//depot/b*\@ \@//depot/a*\@ 
\@ex\@ 29635 1216343123
\@pv\@ 7 \@db.rev\@ \@//depot/a.txt\@ 2 0 1 3 1216251166 1216251149 26EE5EDC99264C1A963FE4F44A3A7232 14 0 0 \@//depot/a.txt\@ \@1.3\@ 0 
\@pv\@ 7 \@db.rev\@ \@//depot/a.txt\@ 1 0 0 1 1216251118 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/a.txt\@ \@1.1\@ 0 
\@pv\@ 7 \@db.rev\@ \@//depot/b.txt\@ 1 0 3 2 1216251134 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 1 \@//depot/a.txt\@ \@1.1\@ 0 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.revcx\@ 3 \@//depot/a.txt\@ 2 1 
\@pv\@ 0 \@db.revcx\@ 2 \@//depot/b.txt\@ 1 3 
\@pv\@ 0 \@db.revcx\@ 1 \@//depot/a.txt\@ 1 0 
\@ex\@ 29635 1216343123
\@pv\@ 7 \@db.revhx\@ \@//depot/a.txt\@ 2 0 1 3 1216251166 1216251149 26EE5EDC99264C1A963FE4F44A3A7232 14 0 0 \@//depot/a.txt\@ \@1.3\@ 0 
\@pv\@ 7 \@db.revhx\@ \@//depot/b.txt\@ 1 0 3 2 1216251134 1216251084 D41D8CD98F00B204E9800998ECF8427E 0 0 1 \@//depot/a.txt\@ \@1.1\@ 0 
\@ex\@ 29635 1216343123
\@pv\@ 8 \@db.working\@ \@//$wsname/b.txt\@ \@//depot/b.txt\@ \@$wsname\@ \@$user\@ 1 1 0 0 4 0 0 0 26EE5EDC99264C1A963FE4F44A3A7232 -1 0 1 0 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.change\@ 3 3 \@$wsname\@ \@$user\@ 1216251166 1 \@Create a change to integrate
\@ 
\@pv\@ 0 \@db.change\@ 2 2 \@$wsname\@ \@$user\@ 1216251134 1 \@Branch the file.
\@ 
\@pv\@ 0 \@db.change\@ 1 1 \@$wsname\@ \@$user\@ 1216251118 1 \@Create a seed file.
\@ 
\@ex\@ 29635 1216343123
\@pv\@ 0 \@db.desc\@ 3 \@Create a change to integrate
\@ 
\@pv\@ 0 \@db.desc\@ 2 \@Branch the file.
\@ 
\@pv\@ 0 \@db.desc\@ 1 \@Create a seed file.
\@ 
\@ex\@ 29635 1216343123
EOJ

    my $server = $self->_create_p4d( {
        journal => $journal,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
                port        => $port,
                user        => $user,
    } );

    my $ws = $session->get_workspace();

    my $results = $conn->resolved_files( $wsname );

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );
    my $resolve = $results->[0];
    $self->assert_equals( '//testws/b.txt', $resolve->{toFile} );
    $self->assert_equals( '//depot/a.txt', $resolve->{fromFile} );

    return;
}

sub test_resolved_no_workspace {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';
    my $port = 1717; # Won't be used

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    try {
        my $results = $conn->resolved_files();
        $self->assert( 0, 'Did not receive exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_diff_files_find_edits {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    $conn->sync_workspace( { workspace => $wsname } );

    my $testfilename = 'afile.txt';
    my $localpath = catfile( $rootdir, $testfilename );
    my $depotpath = "//depot/$testfilename";

    $self->assert( -f $localpath );

    $self->assert_equals( 1, chmod( 0644, $localpath ) );

    $self->assert_not_null( open TFH, ">$localpath" );
    $self->assert( print TFH "This is the replacement text\n" );
    $self->assert( close TFH );

    my $edits = $conn->diff_files( {
        workspace   => $wsname,
        find_edits  => 1,
    } );

    $self->assert_not_null( $edits );
    $self->_assert_array( $edits );
    $self->assert_equals( 1, scalar @{$edits} );
    my $edit = $edits->[0];
    $self->assert_equals( 'HASH', ref( $edit ) );
    $self->assert_equals( $localpath, $edit->{clientFile} );
    $self->assert_equals( $depotpath, $edit->{depotFile} );

    return;
}

sub test_diff_files_find_deletes {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => $port,
        user    => $user,
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    $conn->sync_workspace( { workspace => $wsname } );

    my $testfilename = 'afile.txt';
    my $localpath = catfile( $rootdir, $testfilename );
    my $depotpath = "//depot/$testfilename";

    $self->assert( -f $localpath );

    $self->assert_equals( 1, unlink( $localpath ) );

    $self->assert( ! -f $localpath );

    my $deletes = $conn->diff_files( {
        workspace       => $wsname,
        find_deletes    => 1,
    } );

    $self->assert_not_null( $deletes );
    $self->_assert_array( $deletes );
    $self->assert_equals( 1, scalar @{$deletes} );
    my $del = $deletes->[0];
    $self->assert_equals( 'HASH', ref( $del ) );
    $self->assert_equals( $localpath, $del->{clientFile} );
    $self->assert_equals( $depotpath, $del->{depotFile} );

    return;
}

sub test_diff_files_no_workspace {
    my $self = shift;

    my $user = 'testuser';

    my ($session, $conn) = $self->_create_connection_with_mock_session( {
        port    => 1717, # Not used
        user    => $user,
    } );

    try {
        $conn->diff_files( {
            # Deliberately omit workspace
        } );
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'workspace', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_stringify {
    my $self = shift;

    my $port = 'somehost.example.com:1717';

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port );
    my $conn = P4::Objects::Connection->new( { session => $session } );

    $self->assert_equals( $port, $conn );

    return;
}

sub test_stringify_no_port {
    my $self = shift;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    my $conn = P4::Objects::Connection->new( { session => $session } );

    $self->assert_equals( '', $conn );

    return;
}

1;

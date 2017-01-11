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

package P4::Objects::Test::Helper::TestCase;

use strict;
use warnings;

use Cwd qw( getcwd abs_path );
use File::Basename;
use File::Spec::Functions;
use File::Temp qw( tempdir );
use Module::Locate;
use P4::Objects::Connection;
use P4::Objects::Test::Helper::Session::Mock;
use P4::Server;

use base qw( Test::Unit::TestCase );

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub _get_package_dir {
    my ($self, $package) = @_;

    my $loc = Module::Locate::locate( $package );
    $self->assert_not_equals( '', $loc, "Failed to get test package" );

    my $path = abs_path( $loc );
    my $parentdir = dirname( $path );

    $self->assert( -d $parentdir,
                    "Package directory $parentdir does not exist" );

    return $parentdir;
}

sub _get_test_data_dir {
    my ($self, $package) = @_;

    my $parentdir = $self->_get_package_dir( $package );
    my $datadir = catfile( $parentdir, 'data' );
    $self->assert( -d $datadir, "Test data dir $datadir does not exist" );

    return $datadir;
}

sub _get_test_data_file_name {
    my ($self, $package, $filename) = @_;

    my $dir = $self->_get_test_data_dir( $package );

    my $path = catfile( $dir, $filename );
    $self->assert( -f $path, "Test data file $path does not exist" );

    return $path;
}

sub _create_connection_with_mock_session {
    my ($self, $settings) = @_;

    my $port = $settings->{port};
    my $user = $settings->{user};
    my $client = $settings->{workspace};
    my $p4_class = $settings->{p4_class};

    # Set up the client code
    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_port( $port ) if( defined( $port ) );
    $session->set_user( $user ) if( defined( $user ) );
    $session->set_workspace( $client ) if( defined( $client ) );
    my $conn;
    if( defined( $p4_class ) ) {
        $conn = P4::Objects::Connection->new( {
            session     => $session,
            p4_class    => $p4_class,
        } );
    }
    else {
        $conn = P4::Objects::Connection->new( {
            session     => $session,
        } );
    }
    $session->set_connection( $conn );

    return ($session, $conn);
}

sub _create_p4d {
    my ($self, $settings) = @_;

    my $journal = $settings->{journal};
    my $archive = $settings->{archive};
    my $package = $settings->{package};

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->set_cleanup( 1 );
    $server->create_temp_root();

    # Archive has precedence over journal.
    if( defined( $archive ) ) {
        my $archive_path = $self->_get_test_data_file_name(
            $package, $archive
        );
        $server->unpack_archive_to_root_dir( $archive_path );

        # If the archive has a checkpoint, load it
        my $checkpoint = catfile( $server->get_root(), 'checkpoint' );
        $server->load_journal_file( $checkpoint ) if( -f $checkpoint );
    }
    elsif( defined( $journal ) ) {
        $server->load_journal_string( $journal );
    }

    $server->start_p4d();
    return $server;
}

sub _create_and_replace_client_root {
    my ($self, $settings) = @_;
    
    my $port = $settings->{port};
    my $user = $settings->{user};
    my $workspace = $settings->{workspace};

    # Transform the client root
    my $roottemplate = File::Spec->catfile(
        File::Spec->tmpdir(),
        'p4objects-ws-XXXXXX'
    );
    my $rootdir = tempdir( $roottemplate, CLEANUP => 1 );
    my $spec = `p4 -p $port -u $user client -o $workspace`;
    $self->assert_equals( 0, $?, 'p4 client -o failed' );
    $spec =~ s/CLIENTROOT/$rootdir/;
    my $pid = open( OFH, "| p4 -p $port -u $user client -i > "
                            . File::Spec->devnull()
    );
    $self->assert( $pid, 'p4 client -i failed' );
    print OFH $spec;
    close( OFH );    

    return $rootdir;
}

sub _assert_array {
    my ($self, $ref) = @_;

    $self->assert_equals( 'ARRAY', ref( $ref ) );

    return;
}

1;

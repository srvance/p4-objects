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

package P4::Objects::Test::Workspace;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use File::Spec::Functions;
use IO::File;
use P4::Objects::Exception;
use P4::Objects::Session;
use P4::Objects::Test::Helper::Workspace::NoopLoadSpec;
use P4::Objects::Workspace;
use P4::Server;
use Scalar::Util qw( looks_like_number );

use base qw( P4::Objects::Test::Helper::TestCase );

our $wsname = 'someveryunlikelynameforaworkspace';
our $sessionid = 0xaccede;

my $branch_name = 'Bmi__Ami-to-Bmi';

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {
}

sub tear_down {
}

sub test_new_no_name {
    my $self = shift;
    my $ws;

    try {
        $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session => undef,
                            name    => undef,
                            } );
        $self->assert( 0, "Did not get expection as expected" );
    }
    catch P4::Objects::Exception::MissingWorkspaceName with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_null( $ws );

    return;
}

sub test_new_with_args_static {
    my $self = shift;

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session => $sessionid,
                            name    => $wsname,
                            } );
    $self->assert_not_null( $ws );
    $self->assert( $ws->isa( 'P4::Objects::Common::Base' ) );
    $self->assert( $ws->isa( 'P4::Objects::Common::Form' ),
        'Workspace should be a Form'
    );
    $self->assert( $ws->isa( 'P4::Objects::Common::AccessUpdateForm' ),
        'Workspace should be an AccessUpdateForm'
    );
    $self->assert( $ws->is_new() );

    my $gotten_name = $ws->get_name();
    $self->assert_not_null( $gotten_name );
    $self->assert_equals( $wsname, $gotten_name );

    my $gotten_session = $ws->get_session();
    $self->assert_not_null( $gotten_session );
    $self->assert_equals( $sessionid, $gotten_session );

    return;
}

sub test_new_with_args_server {
    my $self = shift;

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $user = 'memyselfandi';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_user( $user );

    my $ws = P4::Objects::Workspace->new( {
                            session => $session,
                            name    => $wsname,
                            } );
    $self->assert_not_null( $ws );
    $self->assert( $ws->isa( 'P4::Objects::Common::Base' ) );
    $self->assert( $ws->isa( 'P4::Objects::Common::Form' ),
        'Workspace should be a Form'
    );
    $self->assert( $ws->isa( 'P4::Objects::Common::AccessUpdateForm' ),
        'Workspace should be an AccessUpdateForm'
    );
    $self->assert( $ws->is_new() );

    my $gotten_name = $ws->get_name();
    $self->assert_not_null( $gotten_name );
    $self->assert_equals( $wsname, $gotten_name );

    my $gotten_session = $ws->get_session();
    $self->assert_not_null( $gotten_session );
    $self->assert_equals( $session, $gotten_session );

    $self->assert_equals( "Created by $user.\n", $ws->get_description() );

    return;
}

sub test_new_with_hash {
    my $self = shift;

    my $hash = {
        Client          => "$wsname",
        Root            => '/some/strange/path/to/root',
        Options         => 'noallwrite noclobber nocompress'
                            . ' unlocked nomodtime normdir',
        View            => [ "//depot/... //$wsname/..." ],
        Owner           => 'nonexistant',
        LineEnd         => 'shared',
        Host            => 'gracious',
        Description     => 'This is the description',
        SubmitOptions   => 'submitunchanged',
        Update          => 123456789,
        Access          => 987654321,
    };

    my $ws = P4::Objects::Workspace->new( {
                            session => $sessionid,
                            name    => $wsname,
                            attrs   => $hash,
                            } );
    $self->assert_not_null( $ws );
    $self->assert( $ws->isa( 'P4::Objects::Common::Form' ),
        'Workspace should be a Form'
    );
    $self->assert( $ws->isa( 'P4::Objects::Common::AccessUpdateForm' ),
        'Workspace should be an AccessUpdateForm'
    );
    $self->assert( $ws->is_existing() );

    $self->assert_equals( $hash->{Client}, $ws->get_name() );
    $self->assert_equals( $hash->{Root}, $ws->get_root() );

    my $gotten_options = $ws->get_options();
    $self->assert_not_null( $gotten_options );
    $self->assert_equals(
        'P4::Objects::Common::BinaryOptions',
        ref( $gotten_options )
    );
    $self->assert_equals( $hash->{Options}, $ws->get_options() );

    $self->assert_deep_equals( $hash->{View}, $ws->get_view() );
    $self->assert_equals( $hash->{Owner}, $ws->get_owner() );
    $self->assert_equals( $hash->{LineEnd}, $ws->get_lineend() );
    $self->assert_equals( $hash->{Host}, $ws->get_host() );
    $self->assert_equals( $hash->{Description}, $ws->get_description() );
    $self->assert_equals( $hash->{SubmitOptions}, $ws->get_submitoptions() );
    # Access and Updates times should not be supported with new.
}

sub test_new_with_hash_no_name {
    my $self = shift;
    my $ws;

    try {
        $ws = P4::Objects::Workspace->new( {
                            session     => $sessionid,
                            name        => $wsname,
                            attrs       => {
                                Root    => '/some/path',
                            },
                            } );
    }
    catch P4::Objects::Exception::MissingWorkspaceName with {
        # Expected result
    }
    otherwise {
        $self->assert( 0,
            "Expected exception with no workspace name in hash" );
    };

    # Verify that construction failed
    $self->assert_null( $ws );

    return;
}

sub test_new_with_hash_mismatched_name {
    my $self = shift;
    my $ws;
    my $badwsname = 'someothername';

    $self->assert_not_equals( $wsname, $badwsname );

    try {
        $ws = P4::Objects::Workspace->new( {
                            session     => $sessionid,
                            name        => $wsname,
                            attrs       => {
                                Client  => $badwsname,
                                Root    => '/some/path',
                            },
                            } );
    }
    catch P4::Objects::Exception::MismatchedWorkspaceName with {
        # Expected result
    }
    otherwise {
        $self->assert( 0,
            "Expected exception with no workspace name in hash" );
    };

    # Verify that construction failed
    #$self->assert_null( $ws );

    return;
}

sub test_new_with_hash_invalid_view {
    my $self = shift;
    my $ws;

    try {
        $ws = P4::Objects::Workspace->new( {
                            session     => $sessionid,
                            name        => $wsname,
                            attrs       => {
                                Client  => $wsname,
                                View    => "//depot/... //$wsname/...",
                                # To satisfy BinaryOptions construction
                                Options => 'locked',
                            },
        } );
    }
    catch P4::Objects::Exception::InvalidView with {
        # Expected result
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Expected invalid view exception. Got ' . ref( $e ) );
    };

    return;
}

sub test_set_get_name {
    my $self = shift;
    my $firstname = 'initialname';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session => undef,
                            name    => $firstname,
                            } );
    # Assert initial conditions
    $self->assert_equals( $firstname, $ws->get_name() );
    $self->assert_not_equals( $firstname, $wsname );

    $ws->set_name( $wsname );
    my $gotten_name = $ws->get_name();
    $self->assert_not_null( $gotten_name );
    $self->assert_equals( $wsname, $gotten_name );

    return;
}

sub test_set_get_name_change {
    my $self = shift;
    my $firstname = 'initialname';

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $firstname );

    my $hash = {
        Client          => "$firstname",
        Root            => '/some/strange/path/to/root',
        AltRoots        => [ '/first/alt/root', '/second/alt/root' ],
        Options         => 'allwrite clobber compress'
                            . ' locked modtime rmdir',
        View            => [ "//depot/... //$wsname/..." ],
        Owner           => 'nonexistant',
        LineEnd         => 'shared',
        Host            => 'gracious',
        Description     => 'This is the description',
        SubmitOptions   => 'submitunchanged',
        Update          => 123456789,
        Access          => 987654321,
    };

    my $ws = P4::Objects::Workspace->new( {
                            session => $session,
                            name    => $firstname,
                            attrs   => $hash,
                            } );
    # Assert initial conditions
    $self->assert_equals( $firstname, $ws->get_name() );
    $self->assert_not_equals( $firstname, $wsname );

    $self->assert_not_null( $ws->get_root() );
    $self->assert_not_null( $ws->get_altroots() );
    my $gotten_options = $ws->get_options();
    $self->assert_not_null( $gotten_options );
    $self->assert_equals(
        'P4::Objects::Common::BinaryOptions',
        ref( $gotten_options )
    );
    $self->assert_not_null( $ws->get_view() );
    $self->assert_not_null( $ws->get_owner() );
    $self->assert_not_null( $ws->get_lineend() );
    $self->assert_not_null( $ws->get_host() );
    $self->assert_not_null( $ws->get_description() );
    $self->assert_not_null( $ws->get_submitoptions() );

    $ws->set_name( $wsname );
    my $gotten_name = $ws->get_name();
    $self->assert_not_null( $gotten_name );
    $self->assert_equals( $wsname, $gotten_name );
    # Verify that the attributes have been reset
    my $gotten_root = $ws->get_root();
    $self->assert_not_null( $gotten_root );
    $self->assert_not_equals( $hash->{Root}, $gotten_root );
    $self->assert_null( $ws->get_altroots() );
    $gotten_options = $ws->get_options();
    $self->assert_not_null( $gotten_options );
    $self->assert_equals(
        'P4::Objects::Common::BinaryOptions',
        ref( $gotten_options )
    );
    $self->assert_not_equals( $gotten_options, $hash->{Options} );
    $self->assert_not_null( $ws->get_view() );
    $self->assert_not_null( $ws->get_owner() );
    $self->assert_not_null( $ws->get_lineend() );
    $self->assert_not_null( $ws->get_host() );
    my $gotten_description = $ws->get_description();
    $self->assert_not_null( $gotten_description );
    $self->assert_not_equals( $hash->{Description}, $gotten_description );
    $self->assert_not_null( $ws->get_submitoptions() );


    return;
}

sub test_set_name_same {
    my $self = shift;
    my $firstname = 'initialname';

    my $hash = {
        Client          => "$firstname",
        Root            => '/some/strange/path/to/root',
        Options         => 'noallwrite noclobber nocompress'
                            . ' unlocked nomodtime normdir',
        View            => [ "//depot/... //$wsname/..." ],
        Owner           => 'nonexistant',
        LineEnd         => 'shared',
        Host            => 'gracious',
        Description     => 'This is the description',
        SubmitOptions   => 'submitunchanged',
        Update          => 123456789,
        Access          => 987654321,
    };

    my $ws = P4::Objects::Workspace->new( {
                            session => undef,
                            name    => $firstname,
                            attrs   => $hash,
                            } );
    # Assert initial conditions
    $self->assert_equals( $firstname, $ws->get_name() );
    $self->assert_not_equals( $firstname, $wsname );

    $self->assert_not_null( $ws->get_root() );
    $self->assert_not_null( $ws->get_options() );
    $self->assert_not_null( $ws->get_view() );
    $self->assert_not_null( $ws->get_owner() );
    $self->assert_not_null( $ws->get_lineend() );
    $self->assert_not_null( $ws->get_host() );
    $self->assert_not_null( $ws->get_description() );
    $self->assert_not_null( $ws->get_submitoptions() );

    $ws->set_name( $firstname );
    my $gotten_name = $ws->get_name();
    $self->assert_not_null( $gotten_name );
    $self->assert_equals( $firstname, $gotten_name );
    # Verify that the attributes have been reset
    $self->assert_not_null( $ws->get_root() );
    $self->assert_not_null( $ws->get_options() );
    $self->assert_not_null( $ws->get_view() );
    $self->assert_not_null( $ws->get_owner() );
    $self->assert_not_null( $ws->get_lineend() );
    $self->assert_not_null( $ws->get_host() );
    $self->assert_not_null( $ws->get_description() );
    $self->assert_not_null( $ws->get_submitoptions() );


    return;
}

sub test_set_name_undef {
    my $self = shift;
    my $firstname = 'initialname';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session => undef,
                            name    => $firstname,
                            } );
    # Assert initial conditions
    $self->assert_equals( $firstname, $ws->get_name() );
    $self->assert_not_equals( $firstname, $wsname );

    try {
        my $undefname = undef;
        $ws->set_name( $undefname );
    }
    catch P4::Objects::Exception::MissingWorkspaceName with {
        # Expected behavior
    }
    otherwise {
        $self->assert( 0, "Undef workspace name succeeded erroneously" );
    };

    # Verify that the workspace name did not change and is defined.
    $self->assert_not_null( $ws->get_name() );
    $self->assert_equals( $firstname, $ws->get_name() );
}

sub test_set_get_root_static {
    my $self = shift;
    my $rootpath = '/some/unlikely/root/path';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_root() );

    $ws->set_root( $rootpath );
    $self->assert_equals( $rootpath, $ws->get_root() );

    return;
}

sub test_get_root_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $wsroot = '/some/madeup/path';

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@$wsroot\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 0 \@Created by svance.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newroot = $ws->get_root();

    $self->assert_equals( $wsroot, $newroot );

    return;
}

sub test_set_get_owner_static {
    my $self = shift;
    my $owner = 'someoneelse';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_owner() );

    $ws->set_owner( $owner );
    $self->assert_equals( $owner, $ws->get_owner() );

    return;
}

sub test_get_owner_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $owner = 'notme';

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@$owner\@ \@$owner\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@$owner\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@
\@/some/path\@ \@\@ \@\@ \@$owner\@ 1183668658 1183668658 0 \@Created by svance.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newowner = $ws->get_owner();

    $self->assert_equals( $owner, $newowner );

    return;
}

sub test_set_get_lineend_static {
    my $self = shift;
    my $lineend = 'share';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_lineend() );

    $ws->set_lineend( $lineend );
    $self->assert_equals( $lineend, $ws->get_lineend() );

    return;
}

sub test_get_lineend_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $lineend = 'share';
    my $domainopts = 0x0400; # Checkpoint representation for 'share'

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 $domainopts \@Created by svance.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newlineend = $ws->get_lineend();

    $self->assert_equals( $lineend, $newlineend );

    return;
}

sub test_set_get_host_static {
    my $self = shift;
    my $host = 'thelittlemachinethatcould';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_host() );

    $ws->set_host( $host );
    $self->assert_equals( $host, $ws->get_host() );

    return;
}

sub test_get_host_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $host = 'anotherhostbitesthedust';

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@$host\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 0 \@Created by svance.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newhost = $ws->get_host();

    $self->assert_equals( $host, $newhost );

    return;
}

sub test_set_get_description_static {
    my $self = shift;
    my $description = 'This describes something.';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_description() );

    $ws->set_description( $description );
    $self->assert_equals( $description, $ws->get_description() );

    return;
}

sub test_get_description_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    # Perforce normalizes the description to always have one newline at the
    # end. If there are more, it's normalized to one. The newline is necessary
    # to pass the string comparison test.
    my $description = "Something I made up.\n";

    my $server = P4::Server->new(  );
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 0 \@$description
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newdescription = $ws->get_description();

    $self->assert_equals( $description, $newdescription );

    return;
}

sub test_set_get_submitoptions_static {
    my $self = shift;
    my $submitoptions = 'submitunchanged';

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_submitoptions() );

    $ws->set_submitoptions( $submitoptions );
    $self->assert_equals( $submitoptions, $ws->get_submitoptions() );

    return;
}

sub test_get_submitoptions_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    # The Perforce schema documentation is missing this info. This is from
    # Perforce support.
    #   Value    Explanation
    #   0x1000   revertunchanged files
    #   0x2000   leave unchanged files
    #   0x4000   reopen submitted files
    my $submitoptions = 'revertunchanged+reopen';
    my $submitflags = 0x5000;

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 $submitflags \@Some description.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newsubmitoptions = $ws->get_submitoptions();

    $self->assert_equals( $submitoptions, $newsubmitoptions );

    return;
}

sub test_get_options_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    # This is documented in the Perforce schema documentation.
    my $options = 'allwrite clobber compress locked modtime rmdir';
    my $optionflags = 0x0004 | 0x0002 | 0x0020 | 0x0008 | 0x0001 | 0x0040;;

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 $optionflags \@Some description.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newoptions = $ws->get_options();

    $self->assert_not_null( $newoptions );
    $self->assert_equals(
        'P4::Objects::Common::BinaryOptions',
        ref( $newoptions )
    );
    $self->assert_equals( $options, $newoptions );

    return;
}

sub test_set_get_view_static {
    my $self = shift;
    my $view = [ "//depot/... //$wsname/..." ];

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_view() );

    $ws->set_view( $view );
    my $newview = $ws->get_view();
    $self->_assert_array( $newview );
    $self->assert_deep_equals( $view, $newview );

    return;
}

sub test_get_view_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $viewleft = '//depot/...';
    my $viewright = "//$wsname/...";
    my $view = join( " ", $viewleft, $viewright );

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ 1183668658 1183668658 0 \@Some description.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@$viewright\@ \@$viewleft\@
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newview = $ws->get_view();

    $self->assert_equals( 1, scalar @$newview );
    $self->assert_equals( $view, $newview->[0] );

    return;
}

sub test_set_view_invalid {
    my $self = shift;

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            name        => $wsname,
                            session     => $sessionid,
    } );

    try {
        $ws->set_view( "//depot/... //$wsname/..." );
    }
    catch P4::Objects::Exception::InvalidView with {
        # Expected behavior
    }
    otherwise {
        $self->assert( 0, 'Did not get expected exception for invalid view' );
    };

    return;
}

sub test_set_get_update_static {
    my $self = shift;
    my $access = 1183668658;
    my $update = 1183668617;

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_update() );

    {
        package P4::Objects::Workspace;

        $ws->_set_access_and_update( $access, $update );
    }
    $self->assert_equals( $update, $ws->get_update() );

    return;
}

sub test_get_update_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $update = 1183668617;
    my $access = 1183668658;

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ $update $access 0 \@Some description.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@
\@ex\@ 20089 1183668670
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );

    my $ws = $session->get_workspace();
    my $newupdate = $ws->get_update();

    # Verify the format looks like a Unix epoch time
    $self->assert_not_null( $newupdate );
    $self->assert( looks_like_number( $newupdate ), "Found date $newupdate" );

    $self->assert_equals( $update, $newupdate );

    return;
}

sub test_set_get_access_static {
    my $self = shift;
    my $access = 1183668658;
    my $update = 1183668617;

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_access() );

    {
        package P4::Objects::Workspace;

        $ws->_set_access_and_update( $access, $update );
    }
    $self->assert_equals( $access, $ws->get_access() );

    return;
}

sub test_get_access_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $update = 1183668617;
    my $access = 1183668658;

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@/some/path\@ \@\@ \@\@ \@svance\@ $update $access 0 \@Some description.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@
\@ex\@ 20089 1183668670
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );

    my $ws = $session->get_workspace();
    my $newaccess = $ws->get_access();

    # Verify the format looks like a Unix epoch time
    $self->assert( looks_like_number( $newaccess ) );

    $self->assert_equals( $access, $newaccess );

    return;
}

sub test_set_get_altroots_static {
    my $self = shift;
    my $altroots = [
        '/some/unlikely/alternate/root/path',
        '/another/unlikely/alternate/root/path',
    ];

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session =>  $sessionid,
                            name    =>  $wsname,
                            } );

    # Assert initial conditions
    $self->assert_null( $ws->get_altroots() );

    $ws->set_altroots( $altroots );
    $self->assert_equals( $altroots, $ws->get_altroots() );

    return;
}

sub test_get_altroots_server {
    my $self = shift;

    # Set up the server
    my $wsname = 'testworkspace';
    my $wsroot = '/some/madeup/path';
    my $altroots = [
        '/first/alternate/root',
        '/second/alternate/root',
    ];

    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 20089 1183668670
\@pv\@ 3 \@db.user\@ \@svance\@ \@svance\@\@svance.mac_p4objects\@ \@\@ 1183668627 1183668627 \@svance\@ \@\@ 0 \@\@ 0 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 20089 1183668670
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1183668583 1183668583 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@stephen-vances-computer.local\@ \@$wsroot\@ \@$altroots->[0]\@ \@$altroots->[1]\@ \@svance\@ 1183668658 1183668658 0 \@Created by svance.
\@ 
\@ex\@ 20089 1183668670
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 20089 1183668670
EOC

    $server->load_journal_string( $checkpoint );

    # Set up the client code
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    my $ws = $session->get_workspace();
    my $newaltroots = $ws->get_altroots();

    $self->assert_not_null( $newaltroots );
    $self->_assert_array( $newaltroots );
    $self->assert_deep_equals( $altroots, $newaltroots );

    return;
}

sub test_commit {
    my $self = shift;

    # Set up the server
    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $wsname = 'somereallyunlikelyworkspacename';
    my $owner = 'me';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $owner );

    my $ws = $session->get_workspace();

    # Assert pre-conditions
    my @output = `p4 -p $port clients`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my $host = 'somemachine';
    my $description = 'This is a dummy description.';
    my $root = '/the/root/of/the/workspace';
    my $altroots = [ '/one/alt/root', '/another/alt/root' ];
    my $submitoptions = 'submitunchanged';
    my $lineend = 'share';
    my @view = [ "//depot/... //$wsname/..." ];

    $ws->set_host( $host );
    $ws->set_owner( $owner );
    $ws->set_description( $description );
    $ws->set_root( $root );
    $ws->set_altroots( $altroots );
    $ws->set_submitoptions( $submitoptions );
    $ws->set_lineend( $lineend );
    $ws->set_view( @view );

    try {
        $ws->commit();
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Caught unexpected exception: $e" );
    };

    @output = `p4 -p $port clients`;
    $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 1, scalar @output );

    my @client = split( / /, $output[0] );
    $self->assert_equals( $wsname, $client[1] );
    $self->assert_equals( $root, $client[4] );

    my $new_ws = $session->get_workspace( $wsname );
    $self->assert_equals( $wsname, $new_ws );
    $self->assert_equals( $root, $new_ws->get_root() );
    my $new_altroots = $new_ws->get_altroots();
    $self->assert_not_null( $new_altroots );
    $self->_assert_array( $new_altroots );
    $self->assert_deep_equals( $altroots, $new_altroots );

    return;
}

sub test_commit_bad_spec {
    my $self = shift;

    # Set up the server
    my $server = P4::Server->new();
    $server->set_port( undef );
    $server->create_temp_root();
    $server->set_cleanup( 1 );
    $server->start_p4d();
    my $port = $server->get_port();

    my $wsname = 'somereallyunlikelyworkspacename';
    my $owner = 'me';
    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $owner );

    my $ws = $session->get_workspace();

    # Assert pre-conditions
    my @output = `p4 -p $port clients`;
    my $retval = $?;
    $self->assert_equals( 0, $retval, "p4 clients command failed ($retval)" );
    $self->assert_equals( 0, scalar @output );

    my $host = 'somemachine';
    my $description = 'This is a dummy description.';
    my $root = '/the/root/of/the/workspace';
    my $submitoptions = 'submitunchanged';
    my $lineend = 'share';
    my @view = [ "//depot/... //$wsname/..." ];

    $ws->set_host( $host );
    $ws->set_description( $description );
    # Cause a failure by omitting the root.
    $ws->set_submitoptions( $submitoptions );
    $ws->set_lineend( $lineend );
    $ws->set_view( @view );

    try {
        $ws->commit();
    }
    catch P4::Objects::Exception::P4::BadSpec with {
        # Expected behavior
        my $e = shift;
        $self->assert( $e->errorcount() > 0 );
        $self->assert( scalar $e->errors() > 0 );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Caught unexpected exception: $e" );
    };

    return;
}

sub test_new_changelist {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $checkpoint = <<EOC;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 3209 1186098162
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@testhost\@ \@\@ 1186098088 1186098088 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 3209 1186098162
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 3209 1186098162
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1186098052 1186098052 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@/some/workspace/root\@ \@\@ \@\@ \@$user\@ 1186098106 1186098106 0 \@Created by $user.
\@ 
\@ex\@ 3209 1186098162
\@pv\@ 1 \@db.view\@ \@t\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 3209 1186098162
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_workspace( $wsname );
    $session->set_port( $port );
    $session->set_user( $user );

    my $ws = $session->get_workspace();

    my $cl;
    try {
        $cl = $ws->new_changelist();
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) . "\n"
                            . Dumper( $e ) . "\n"
        );
    };

    $self->assert_not_null( $cl );

    return;
}

sub test_sync {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->sync();
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    $self->assert_not_null( $srs->get_results() );
    $self->assert_equals( 2, scalar @{$srs->get_results()} );

    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    return;
}

sub test_sync_force_sync {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;

    # Set up pre-conditions
    $srs = $ws->sync();

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    $self->assert_not_null( $srs->get_results() );
    $self->assert_equals( 2, scalar @{$srs->get_results()} );

    $srs = $ws->sync();

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    $self->assert_not_null( $srs->get_results() );
    $self->assert_equals( 0, scalar @{$srs->get_results()} );

    try {
        $srs = $ws->sync( { force_sync => 1 } );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    $self->assert_not_null( $srs->get_results() );
    $self->assert_equals( 2, scalar @{$srs->get_results()} );

    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    return;
}

sub test_sync_with_filespec {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->sync( '@1' );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    my $results = $srs->get_results();
    $self->assert_equals( 1, scalar @{$results} );
    $self->assert_equals( 0, scalar @{$srs->get_warnings()} );

    my $sr = $results->[0];
    $self->assert_not_null( $sr );
    $self->assert_equals( '//depot/text.txt', $sr->get_depotname() );
    $self->assert_equals( 1, $sr->get_revision() );

    $self->assert( -f $sr->get_localname() );

    return;
}

sub test_sync_with_filespec_list {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';
    my @synclist = ( '//depot/text.txt', '//depot/binary.bin' );

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->sync( @synclist );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    my $results = $srs->get_results();
    $self->assert_equals( scalar @synclist, scalar @{$results} );
    $self->assert_equals( 0, scalar @{$srs->get_warnings()} );

    my $sr = $results->[0];
    $self->assert_not_null( $sr );
    $self->assert_equals( $synclist[0], $sr->get_depotname() );
    $self->assert_equals( 1, $sr->get_revision() );

    $self->assert( -f $sr->get_localname() );

    $sr = $results->[1];
    $self->assert_not_null( $sr );
    $self->assert_equals( $synclist[1], $sr->get_depotname() );
    $self->assert_equals( 1, $sr->get_revision() );

    $self->assert( -f $sr->get_localname() );

    return;
}

sub test_sync_with_filespec_long_list {
    my $self = shift;

    # TODO: Remove this when the test hang issue is resolved.
    return if( $^O eq 'solaris' );

    my $wsname = 'testws';
    my $user = 'testuser';
    my $filename = '//depot/text.txt';
    my $filecount = 10000;
    my @synclist = ( $filename ) x $filecount;

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        # Use force_sync because we're syncing the same file repeatedly
        $srs = $ws->sync( { force_sync => 1 }, @synclist );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    my $results = $srs->get_results();
    $self->assert_equals( scalar @synclist, scalar @{$results} );
    $self->assert_equals( 0, scalar @{$srs->get_warnings()} );

    # Let's assume that they're all the same if there are the right number and
    # only verify the first one.
    my $sr = $results->[0];
    $self->assert_not_null( $sr );
    $self->assert_equals( $synclist[0], $sr->get_depotname() );
    $self->assert_equals( 1, $sr->get_revision() );

    $self->assert( -f $sr->get_localname() );

    return;
}

sub test_sync_omit_files_with_filespec {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    # Assert pre-conditions
    # Make sure there's nothing in the have list
    my $devnull = File::Spec->devnull();
    my @output = `p4 -p $port -u $user -c $wsname have 2> $devnull`;
    my $result = $?;
    $self->assert_equals( 0, $result, 'p4 have failed' );
    $self->assert_equals( 0, scalar @output );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->sync( { omit_files => 1 }, '@1' );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_not_null( $srs );
    my $results = $srs->get_results();
    $self->assert_equals( 1, scalar @{$results} );
    $self->assert_equals( 0, scalar @{$srs->get_warnings()} );

    my $sr = $results->[0];
    $self->assert_not_null( $sr );
    $self->assert_equals( '//depot/text.txt', $sr->get_depotname() );
    $self->assert_equals( 1, $sr->get_revision() );

    $self->assert( ! -f $sr->get_localname() );

    # Assert that we have a have list now.
    @output = `p4 -p $port -u $user -c $wsname have`;
    $result = $?;
    $self->assert_equals( 0, $result, 'p4 have failed' );
    $self->assert_equals( 1, scalar @output );

    return;
}

# Added for user story 29, but doesn't test new behavior. Simply verifies
# existing behavior.
sub test_sync_over_open_file {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();
    my $srs = $ws->sync();

    my $cl = $ws->new_changelist();
    $cl->set_description( 'Syncing open file test' );
    $cl->commit();
    my $syncfile = '//depot/text.txt';
    try {
        $cl->edit_files( $syncfile );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    try {
        $srs = $ws->sync( { force_sync => 1 }, $syncfile );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    my $results = $srs->get_results();
    $self->assert_not_null( $results );
    $self->assert_equals( 0, scalar @{$results} );

    my $warnings = $srs->get_warnings();
    $self->assert_equals( 1, scalar @{$warnings} );
    $self->assert(
        $warnings->[0] =~ / - file(s) up-to-date\./,
        "Unexpected warning message: $warnings->[0]"
    );

    return;
}

# Added for user story 29, but doesn't test new behavior. Simply verifies
# existing behavior.
sub test_sync_requiring_resolve {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();
    my $srs = $ws->sync( '@1' );

    my $cl = $ws->new_changelist();
    $cl->set_description( 'Syncing open file test' );
    $cl->commit();
    my $syncfile = '//depot/text.txt';
    try {
        $cl->edit_files( $syncfile );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    try {
        $srs = $ws->sync( { force_sync => 1 }, $syncfile );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    my $results = $srs->get_results();
    $self->assert_not_null( $results );
    $self->assert_equals( 0, scalar @{$results} );

    my $warnings = $srs->get_warnings();
    $self->assert_equals( 2, scalar @{$warnings} );
    $self->assert(
        $warnings->[0] =~ / - file(s) up-to-date\./,
        "Unexpected warning message: $warnings->[0]"
    );

    return;
}

sub test_sync_preview {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->sync( { preview => 1 } );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . ref( $e ) );
    };

    $self->assert_not_null( $srs );
    $self->assert_equals( 'P4::Objects::SyncResults', ref( $srs ) );
    $self->assert_not_null( $srs->get_results() );
    $self->assert_equals( 2, scalar @{$srs->get_results()} );

    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( ! -f $binfile, "Binary file $binfile exists but shouldn't" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( ! -f $textfile, "Text file $textfile exists but shouldn't" );

    return;
}

sub test_is_exactly_at_level_true {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();
    $ws->sync();

    $self->assert( $ws->is_exactly_at_level( '1' ) );

    return;
}

sub test_is_exactly_at_level_false {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    $self->assert( ! $ws->is_exactly_at_level( '1' ) );

    return;
}
sub _test_flush_with_filespec {
    my ($self, @filespec) = @_;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'filespec_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    # Assert pre-conditions
    # Make sure there's nothing in the have list
    my $devnull = File::Spec->devnull();
    my @output = `p4 -p $port -u $user -c $wsname have 2> $devnull`;
    my $result = $?;
    $self->assert_equals( 0, $result, 'p4 have failed' );
    $self->assert_equals( 0, scalar @output );

    my $ws = $session->get_workspace();

    my $srs;
    try {
        $srs = $ws->flush( @filespec );
    }
    catch P4::Objects::Exception::UnexpectedSyncResults with {
        my $e = shift;
        $self->assert( 0, "Unexpected sync results:\n" . $e->cause() );
    }
    catch P4::Objects::Exception::P4::SyncError with {
        my $e = shift;
        $self->assert( 0, 'Caught SyncError: '
                            . join( "\n", @{$e->errors()} ) );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Unexpected exception: " . Dumper( $e ) );
    };

    $self->assert_not_null( $srs );
    my $results = $srs->get_results();
    $self->assert_equals( 1, scalar @{$results} );
    $self->assert_equals( 0, scalar @{$srs->get_warnings()} );

    my $sr = $results->[0];
    $self->assert_not_null( $sr );
    $self->assert_equals( '//depot/text.txt', $sr->get_depotname() );
    $self->assert_equals( (@filespec != 0) ? 1 : 2, $sr->get_revision() );

    $self->assert( ! -f $sr->get_localname() );

    # Assert that we have a have list now.
    @output = `p4 -p $port -u $user -c $wsname have`;
    $result = $?;
    $self->assert_equals( 0, $result, 'p4 have failed' );
    $self->assert_equals( 1, scalar @output );

    return;
}
sub test_flush_with_filespec_string {
    my $self = shift;
    return _test_flush_with_filespec( $self, '@1' );
}
sub test_flush_with_filespec_hash {
    my $self = shift;
    return _test_flush_with_filespec( $self, { filespec => '@1' } );
}
sub test_flush_with_filespec_empty {
    my $self = shift;
    return _test_flush_with_filespec( $self );
}
sub test_delete_no_args {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $checkpoint = <<EOF;
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 2436 1193121495
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$wsname\@ \@\@ 1193121465 1193121465 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 2436 1193121495
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 2436 1193121495
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1193121426 1193121426 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$wsname\@ 99 \@\@ \@/some/root/dir\@ \@\@ \@\@ \@$user\@ 1193121489 1193121489 0 \@Created by $user.
\@ 
\@ex\@ 2436 1193121495
\@pv\@ 1 \@db.view\@ \@$wsname\@ 0 0 \@//$wsname/...\@ \@//depot/...\@ 
\@ex\@ 2436 1193121495
EOF

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    # Assert pre-conditions
    # There should only be one workspace
    my @output = `p4 -p $port clients`;
    my $result = $?;
    $self->assert_equals( 0, $result, 'p4 clients failed' );
    $self->assert_equals( 1, scalar @output );

    my $ws = $session->get_workspace();

    # Assert workspace attributes
    $self->assert_not_null( $ws->get_update() );
    $self->assert_not_null( $ws->get_access() );

    $ws->delete();

    # Assert deletion of the spec
    @output = `p4 -p $port clients`;
    $result = $?;
    $self->assert_equals( 0, $result, 'p4 clients failed' );
    $self->assert_equals( 0, scalar @output );

    # Assert the resultant object state
    $self->assert_null( $ws->get_update() );
    $self->assert_null( $ws->get_access() );

    return;
}

sub test_delete_remove_all_files {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    # Throws exception if error
    my $srs = $ws->sync();

    # Assert pre-conditions
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    $ws->delete( { remove_all_files => 1 } );

    # Assert results
    $self->assert( ! -d $rootdir, "Root directory $rootdir shouldn't exist" );
    $self->assert( ! -f $binfile, "Binary file $binfile shouldn't exist" );
    $self->assert( ! -f $textfile, "Text file $textfile shouldn't exist" );
}

sub test_delete_remove_all_files_altroot {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    # Throws exception if error
    my $srs = $ws->sync();

    $ws->set_root( '/some/nonexistent/path' );
    $ws->set_altroots( [ $rootdir ] );
    $ws->commit();

    # Assert pre-conditions
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    $ws->delete( { remove_all_files => 1 } );

    # Assert results
    $self->assert( ! -d $rootdir, "Root directory $rootdir shouldn't exist" );
    $self->assert( ! -f $binfile, "Binary file $binfile shouldn't exist" );
    $self->assert( ! -f $textfile, "Text file $textfile shouldn't exist" );
}

sub test_delete_remove_all_files_false {
    my $self = shift;

    my $wsname = 'testws';
    my $user = 'testuser';

    my $server = $self->_create_p4d( {
        archive => 'basic_sync_test.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    # Throws exception if error
    my $srs = $ws->sync();

    # Assert pre-conditions
    my $binfile = catfile( $rootdir, 'binary.bin' );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    my $textfile = catfile( $rootdir, 'text.txt' );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );

    $ws->delete( { remove_all_files => 0 } );

    # Assert results
    $self->assert( -d $rootdir, "Root directory $rootdir doesn't exist" );
    $self->assert( -f $binfile, "Binary file $binfile doesn't exist" );
    $self->assert( -f $textfile, "Text file $textfile doesn't exist" );
}

sub test_stringify {
    my $self = shift;

    my $ws = P4::Objects::Test::Helper::Workspace::NoopLoadSpec->new( {
                            session => undef,
                            name    => $wsname,
                            } );
    # Assert initial conditions
    $self->assert_equals( $wsname, $ws->get_name() );

    # Assert results
    $self->assert_str_equals( $wsname, $ws );

    return;
}

sub test_opened {
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

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $ws = $session->get_workspace();

    my $ors = $ws->opened();

    $self->assert_not_null( $ors );
    $self->_assert_array( $ors );
    $self->assert_equals( 1, scalar @{$ors} );
    my $first_result = $ors->[0];
    $self->assert_equals(
        'P4::Objects::OpenRevision',
        ref( $first_result)
    );

    return;
}

sub test_resolve_preview {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive => 'resolve_test_single.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $ws = $session->get_workspace();

    my $rrs = $ws->resolve( { preview => 1 } );

    my $expected_resolves = 1;

    $self->assert_not_null( $rrs );
    $self->_assert_array( $rrs );
    $self->assert_equals( $expected_resolves, scalar @{$rrs} );
    my $resolve = $rrs->[0];
    $self->assert_equals( 'P4::Objects::PendingResolve', ref( $resolve ) );

    return;
}

# TODO: Remove this when we generalize the resolve command
sub test_resolve_no_args {
    my $self = shift;

    my $user = 'me';
    my $wsname = 'myworkspace';

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $ws = $session->get_workspace();

    try {
        my $rrs = $ws->resolve();
        $self->assert( 0, 'Did not throw exception as expected' );
    }
    catch P4::Objects::Exception::MissingParameter with {
        my $e = shift;

        $self->assert_equals( 'options', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };
}

# TODO: Remove this when we generalize the resolve command
sub test_resolve_no_options {
    my $self = shift;

    my $user = 'me';
    my $wsname = 'myworkspace';

    my $server = $self->_create_p4d();
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $ws = $session->get_workspace();

    try {
        my $rrs = $ws->resolve( 'Some non-hash argument' );
        $self->assert( 0, 'Did not throw exception as expected' );
    }
    catch P4::Objects::Exception::InvalidParameter with {
        my $e = shift;

        $self->assert_equals( 'options', $e->parameter() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };
}

sub test_resolved_no_args {
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
        journal     => $journal,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $results = $ws->resolved();

    $self->assert_not_null( $results );
    $self->_assert_array( $results );
    $self->assert_equals( 1, scalar @{$results} );
    my $resolved = $results->[0];
    $self->assert_equals( 'P4::Objects::IntegrationRecord', ref( $resolved ) );

    return;
}

sub test_diff_find_edits {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    $ws->sync();

    my $testfilename = 'afile.txt';
    my $localpath = catfile( $rootdir, $testfilename );
    my $depotpath = "//depot/$testfilename";

    $self->assert( -f $localpath );

    $self->assert_equals( 1, chmod( 0644, $localpath ) );

    $self->assert_not_null( open TFH, ">$localpath" );
    $self->assert( print TFH "This is the replacement text\n" );
    $self->assert( close TFH );

    my $edits = $ws->diff( { find_edits => 1 } );

    $self->assert_not_null( $edits );
    $self->_assert_array( $edits );
    $self->assert_equals( 1, scalar @{$edits} );

    my $edit = $edits->[0];
    $self->assert_not_null( $edit );
    $self->assert_equals( '', ref( $edit ) );
    $self->assert_equals( $localpath, $edit );

    return;
}

sub test_diff_find_deletes {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    $ws->sync();

    my $testfilename = 'afile.txt';
    my $localpath = catfile( $rootdir, $testfilename );
    my $depotpath = "//depot/$testfilename";

    $self->assert( -f $localpath );

    $self->assert_equals( 1, unlink( $localpath ) );

    my $deletes = $ws->diff( { find_deletes => 1 } );

    $self->assert_not_null( $deletes );
    $self->_assert_array( $deletes );
    $self->assert_equals( 1, scalar @{$deletes} );

    my $del = $deletes->[0];
    $self->assert_not_null( $del );
    $self->assert_equals( '', ref( $del ) );
    $self->assert_equals( $localpath, $del );

    return;
}

sub test_get_highest_changelist {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'filespec_sync_test.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $expected_change = 1;
    $ws->sync( '@' . $expected_change );

    my $change = $ws->get_highest_changelist();

    $self->assert_equals( $expected_change, $change );

    return;
}

sub test_get_highest_changelist_no_files {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'filespec_sync_test.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $change = $ws->get_highest_changelist();

    $self->assert_null( $change );

    return;
}

sub test_integrate {
    my $self = shift;

    my $user = 'jmicco';
    my $workspace = 'Bmi_workspace';

    my $server = $self->_create_p4d( {
        archive => 'SCMTestGenerator.tgz',
        package => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $workspace );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $workspace,
    } );
    $self->assert_not_null( $rootdir );

    my $ws = $session->get_workspace($workspace);

    my $ir = $ws->integrate( { branch => $branch_name } );
    $self->assert_not_null( $ir );

    my $results = $ir->get_results();

    my %partition;
    for my $result (@{$results}) {
        push @{$partition{$result->get_action()}}, $result;
    }

    #
    # The expected results table is the number of files in each branch
    # category from the archived repository
    #
    my %expected_results = (
        branch         => 86,
        delete         => 27,
        integrate      => 24,
        cant_branch    => 24,
        cant_delete    => 48,
        cant_integrate => 63
    );
    my $total;

    for my $action (sort keys %expected_results) {
        my $count = @{$partition{$action}};
        $total += $count;
        $self->assert_equals( $expected_results{$action}, $count );
    }
    $self->assert_equals( $total, scalar @{$results} );

    return;
}

sub test_integrate_no_args {
    my $self = shift;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    try {
        $ws->integrate();
        $self->assert(0, 'Unexpected - exception not thrown for integrate w/o arguments' );
    }
    catch P4::Objects::Exception::P4::IntegrationError with {
        my $e = shift;

        $self->assert_equals( 1, $e->errorcount() );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };
    return;
}

sub _test_integrate_one_file {
    my ($self, @args ) = @_;

    my $user = 'testuser';
    my $wsname = 'testws';

    my $server = $self->_create_p4d( {
        archive     => 'single_file.tgz',
        package     => __PACKAGE__,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );
    $session->set_workspace( $wsname );
    $session->set_user( $user );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $port,
        user        => $user,
        workspace   => $wsname,
    } );

    my $ws = $session->get_workspace();

    my $ir = $ws->integrate( @args );

    $self->assert_not_null( $ir );
    my $results = $ir->get_results();
    $self->assert_equals( 1, scalar @{$results} );
    my $result = $results->[0];
    $self->assert_equals( '//depot/bfile.txt', $result->get_depotfile(),  );

    my $or = $ws->opened();
    if (@{$or}==1) {
        return $or->[0];
    }
    return;
}

sub test_integrate_one_file {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( '//depot/afile.txt', '//depot/bfile.txt' );
    $self->assert_not_null($file );
}

sub test_integrate_one_file_non_default_args {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( { ignore_deletes => 0, compute_base => 0 },
                                                 '//depot/afile.txt', '//depot/bfile.txt' );
    $self->assert_not_null($file );
}

sub test_integrate_one_file_preview {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( { preview => 1 },
                                                 '//depot/afile.txt', '//depot/bfile.txt' );
    $self->assert_null( $file );
}

sub test_integrate_one_file_branchspec {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( { ignore_deletes => 0, compute_base => 0, branch => 'test_branch' } );
    $self->assert_not_null($file );
}

sub test_integrate_one_file_reverse_branchspec {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( { ignore_deletes => 0, compute_base => 0, branch => 'test_reverse_branch', reverse => 1 } );
    $self->assert_not_null($file );
}

sub test_integrate_one_file_from_branchrev {
    my $self = shift;
    my $file = $self->_test_integrate_one_file( { ignore_deletes => 0, compute_base => 0, branch => 'test_branch', from_branchrev => '@1' } );
    $self->assert_not_null($file );
}

1;

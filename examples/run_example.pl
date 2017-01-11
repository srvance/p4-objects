use strict;
use warnings;

# The stars of the show
use P4::Objects '0.34';     # Functionally useless but tells and enforces the
                            # version we expect
use P4::Objects::Session;   # Every P4::Objects program uses this
use P4::Server 0.08;

# In support of P4::Objects usage
use Error qw( :try );

# General uses
use Carp;
use Cwd;
use Data::Dumper;
use File::Path;
use File::Spec::Functions;

MAIN:
my $server = create_p4d( 'test_archive.tgz' );

example_code( $server );

exit;

# SUPPORT FUNCTIONS

sub create_p4d {
    my ($archive) = @_;

    if( ! defined( $archive ) ) {
        die "Must define archive file";
    }

    my $server_root = create_clean_subdirectory( 'p4root' );

    # We'll deliberately let the exceptions fly here
    my $server = P4::Server->new();
    $server->set_port( undef );         # Dynamically allocated port
    $server->set_cleanup( 0 );          # For post-run inspection
    $server->set_root( $server_root );  # In current directory
    $server->start_p4d();               # Start the server
    $server->unpack_archive_to_root_dir( $archive );

    # Load the checkpoint that's supposed to be in the archive
    my $checkpoint = catfile( $server->get_root(), 'checkpoint' );

    if( ! -f $checkpoint ) {
        croak "Expected checkpoint not in archive file $archive";
    }

    $server->load_journal_file( $checkpoint );

    return $server;
}

sub example_code {
    my ($server) = @_;

    my $port = $server->get_port();

    # We know these values to be fact from the test data
    my $user = 'testuser';
    my $workspace = 'testws';

    my $session = setup_session( $port, $user, $workspace );

    # Repository stuff is pretty self-contained
    repository_examples( $session );

    # Workspace examples include obtaining, editing, committing and syncing
    my $ws = workspace_examples( $session );

    # Pending changelist examples include modification, commit,
    # add, edit, delete, and submit
    pending_changelist_examples( $ws );

    return;
}

sub setup_session {
    my ($port, $user, $workspace) = @_;

    # Every program does this unless the session was passed in
    my $session;
    try {
        $session = P4::Objects::Session->new();
    }
    # Catch any P4::Objects exception
    catch P4::Objects::Exception with {
        # There's not much we can do if this fails other than report it
        my $e = shift;
        croak "Session allocation failed with " . Dumper( $e );
    }
    # Catch unexpected exceptions
    otherwise {
        my $e = shift;
        croak "Unexpected exception: " . Dumper( $e );
    }; # Must have the semi-colon!!!

    # Since we're not using a config file and the environment probably isn't
    # right, set the important attributes here.
    $session->set_port( $port );
    $session->set_user( $user );
    $session->set_workspace( $workspace );

    return $session;
}

sub repository_examples {
    my ($session) = @_;

    print "== Repository examples:\n\n";

    my $repo = $session->get_repository();

    # Get and print the list of workspaces with information
    my $workspaces = $repo->get_workspaces();
    print 'Found ' . scalar @{$workspaces} . " workspaces:\n";
    for my $ws ( @{$workspaces} ) {
        my $desc = $ws->get_description();
        chomp( $desc );
        print join( ' ',
                    $ws,                    # Stringification
                    scalar localtime(
                        $ws->get_update()   # From Common::Form
                    ),
                    $ws->get_owner(),
                    $ws->get_root(),
                    "'" . $desc . "'",
                ),
                "\n";
    }

    # $repo->get_workspaces() follows the same pattern

    # $repo->get_changelists() has some extra twists
    my $cls;
    try {
        $cls = $repo->get_changelists();
    }
    catch P4::Objects::Exception with {
        my $e = shift;
        # If we croak here, the otherwise block will catch it
        print 'Failed get_changelists with exception ' . Dumper( $e ) .  "\n";
    }
    otherwise {
        my $e = shift;
        croak "Unexpected exception: " . Dumper( $e );
    };

    if( defined( $cls ) ) {
        print "\nFound " . scalar @{$cls} . " changelists:\n";
        for my $cl ( @{$cls} ) {
            display_changelist( $cl );
        }
    }

    # Here are some filter examples for get_changelists()
    # Ignore exception handling for brevity
    my $last_cl = $repo->get_changelists( { maxReturned => 1 } );
    print "\nLatest changelist:\n";
    print display_changelist( $last_cl->[0] );

    my $submitted_cls = $repo->get_changelists( { status => 'submitted' } );
    my $pending_cls = $repo->get_changelists( { status => 'pending' } );

    print "\nThere are " . scalar @{$submitted_cls} . ' submitted and '
            .  scalar @{$pending_cls} . " pending changelists.\n";

    my $text_cls = $repo->get_changelists( {
        filespec => '//depot/text.txt',
    } );

    print "\nThe following "
            . scalar @{$text_cls}
            . " changelists applied to //depot/text.txt:\n";
    print "\t" . join( ' ', @{$text_cls} ) . "\n";
    print "\n== Finished repository examples\n\n";

    return;
}

sub display_changelist {
    my ($cl) = @_;

    print join( ' ',
                'Change',
                $cl,        # Stringification
                'on',
                scalar localtime(
                    $cl->get_date()
                ),
                'by',
                $cl->get_user() . '@' . $cl->get_workspace(),
                $cl->is_pending()   ? '*pending*'
                                    : '',
                $cl->get_description(),
            );

    return;
}

sub workspace_examples {
    my ($session) = @_;

    print "== Workspace examples:\n\n";

    my $ws = workspace_create_and_modify_examples( $session );

    workspace_sync_examples( $ws );

    print "== Finished workspace examples\n\n";

    return $ws;
}

sub workspace_create_and_modify_examples {
    my ($session) = @_;

    # Create our workspace root
    my $ws_root = create_clean_subdirectory( 'ws' );

    # Gets the workspace object for the current settings in the Session
    my $ws;
    try {
        $ws = $session->get_workspace();
    }
    catch P4::Objects::Exception with {
        # There's not much we can do if this fails other than report it
        my $e = shift;
        croak "Workspace allocation failed with " . Dumper( $e );
    }
    otherwise {
        my $e = shift;
        croak "Unexpected exception: " . Dumper( $e );
    };

    # For right now, we need to do this to force a load of the spec
    $ws->get_root();

    # The examples have a dummy root to make them portable. Change it here.
    $ws->set_root( $ws_root );
    # Let exception pass. In this case, we can't fix the spec automatically.
    $ws->commit();  # Saves the workspace spec

    return $ws;
}

sub workspace_sync_examples {
    my ($ws) = @_;

    # Populate our workspace
    my $sync_results;
    try {
        $sync_results = $ws->sync();
    }
    catch P4::Objects::Exception with {
        # We can do other things if this fails
        my $e = shift;
        print 'Problem with the sync: ' . Dumper( $e );
    }
    otherwise {
        my $e = shift;
        print 'Unexpected problem with the sync: ' . Dumper( $e );
    };

    # Either exception path will leave sync_results undefined
    if( ! defined( $sync_results ) ) {
        print "Aborting workspace examples\n\n";
        return;
    }

    display_sync_results( $sync_results, 'First sync' );

    # We'll skip the try-catch here since it should have succeeded before.
    # We're expecting nothing this time with a warning.
    $sync_results = $ws->sync();

    display_sync_results( $sync_results, 'Sync that should do nothing' );

    return;
}

sub pending_changelist_examples {
    my ($ws) = @_;

    print "== Pending changelist examples:\n\n";

    # First, let's get a new changelist for our changes
    # We can't use it until we commit it
    my $cl = $ws->new_changelist();

    # We at least have to set the description before we commit it
    $cl->set_description( 'Changes for usage examples' );

    # Now let's commit it so we get a number
    # Also, ignore exceptions as we can't recover anyway
    my $changeno = $cl->commit();

    print "Working with numbered pending changelist $changeno\n";

    # Next, let's edit the file we know exists using depot syntax.
    # Let exceptions pass because something will be really wrong
    $cl->edit_files( '//depot/text.txt' );

    # Now we can add a file after we create it.
    # Let's make sure we're in the right directory first
    my $curdir = getcwd();
    print "\nOriginally in directory: $curdir\n";

    my $ws_root = $ws->get_root();
    if( $curdir ne $ws_root ) {
        # You can always get the session from an object
        my $session = $ws->get_session();

        $session->set_cwd( $ws_root );
    }

    print "Directory may have been changed to: $ws_root\n";

    # Now that we're in the right place, let's create the file
    my $addfile = 'newfile.txt';
    open NEWFILE, "> $addfile" or croak "Unable to create file $addfile";
    print NEWFILE 'Some text for the new file';
    close NEWFILE;

    # Now we'll finally add the file using relative local file syntax
    # Again, ignore exceptions because we can't fix them
    $cl->add_files( $addfile );

    # Let's examine what we have open via the changelist right now.
    my $files = $cl->get_files();

    print "\nThe changelist has " . scalar @{$files} . " open files:\n";
    display_revision_list( $files );

    # Now show it via the workspace
    my $opened = $ws->opened();

    print "\nThe workspace shows " . scalar @{$opened} . " open files:\n";
    display_revision_list( $opened );

    # Submit the changelist
    my $new_changeno = $cl->submit();

    print "\nSubmitted changelist $changeno as changelist $new_changeno\n";

    # Now let's re-use a known pending changelist to delete a file
    $cl = P4::Objects::PendingChangelist->new( {
        session     => $ws->get_session(),
        workspace   => $ws,
        changeno    => 2,
    } );

    print "\nUsing changelist $cl for another operation.\n"; # Stringification

    # Delete the file we just added
    $cl->delete_files( $addfile );

    $new_changeno = $cl->submit();

    print "\nSubmitted changelist $cl as changelist $new_changeno\n";

    print "\n== Finished pending changelist examples\n";

    return;
}

sub display_revision_list {
    my ($revs) = @_;

    for my $r ( @{$revs} ) {
        print "\t",
            $r->get_depotname(),
            '#',
            $r->get_revision(),
            ' ',
            $r->get_action(),
            "\n";
    }

    return;
}

sub create_clean_subdirectory {
    my ($subdir) = @_;

    my $dir = catfile( getcwd(), $subdir );

    # Delete the server root if it already exists
    if( -d $dir ) {
        rmtree( $dir );
    }

    if( ! -d $dir ) {
        mkpath( $dir );
    }

    return $dir;
}

sub display_sync_results {
    my ($sync_results, $description) = @_;

    # Because a sync can have partial success, it can be useful to see if
    # there are warnings
    my $warnings = $sync_results->get_warnings();
    print "--$description--\n";
    print 'Synced ',
        $sync_results->get_totalfilecount(),
        ' files totaling ',
        $sync_results->get_totalfilesize(),
        ' bytes with ',
        scalar @{$warnings},
        " warnings";
    if( scalar @{$warnings} > 0 ) {
        print ":\n\t",
            join( "\t", @{$warnings} );
    }
    else {
        print ".\n";
    }

    my $files = $sync_results->get_results();
    if( scalar @{$files} > 0 ) {
        print "Revisions were:\n",
            "\t",
            join( "\n\t", @{$files} ),  # Exploit Revision stringification
            "\n";
    }

    print "\n";

    return;
}

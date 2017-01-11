# Example code implementing Story 22: Edit file
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# Get the current workspace
my $ws = $session->get_workspace_object();

my $cl = $ws->new_changelist();
$cl->set_description( 'Some description' );
$cl->commit();

# o $cl is a PendingChangelist
$cl->edit_files( '/some/file/name.pl' );

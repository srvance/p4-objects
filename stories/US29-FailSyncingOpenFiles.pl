# Example code implementing Story 29: Report the results nicely when syncing
# an open file
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# Get the current workspace
my $ws = $session->get_workspace_object();
my $cl = $ws->new_changelist();

my $file = '//some/file.c';
$cl->edit_file( $file );

# Whether the situation is reported as an error or a warning is TBD
my $results = $ws->sync( { force_sync => 1 }, $file );

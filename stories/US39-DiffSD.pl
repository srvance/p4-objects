# Example code implementing User Story 39: Implement 'diff -sd'
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace();

# Don't need file arguments yet
my $deleted_files = $ws->diff( { unopened_missing => 1 } );

# Format of deleted_files TBD. May use WorkspaceRevision
# Data content is:
#   depotFile
#   clientFile
#   rev
#   type
# Known Perforce bug: 'diff -sd' returns files that are open for delete as
#   well as files that aren't, contrary to documented behavior. Should
#   P4::Objects compensate? This is present in 2007.2 and not fixed in 2007.3.

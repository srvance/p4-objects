# Example code implementing User Story 38: Implement 'diff -se'
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace();

# Don't need file arguments yet
my $different_files = $ws->diff( { unopened_different => 1 } );

# Format of different_files TBD. May use WorkspaceRevision
# Data content is:
#   depotFile
#   clientFile
#   rev
#   type


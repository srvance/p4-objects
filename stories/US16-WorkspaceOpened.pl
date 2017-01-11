# Example code implementing Story 16: Implement Workspace::opened()
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

# Create Session which holds environment. initializes according to
# standard client rules (e.g. P4CONFIG, environment, etc.)
# Also creates Repository, Connection, and P4 (via Connection) but
# does leave an open connection to the server. Note: It may open a
# connection if necessary to run 'p4 info'.
my $session = P4::Objects::Session->new();

# Returns P4::Objects::Workspace object for the default workspace
my $ws = $session->get_workspace_object();

# Invokes Connection::opened( { workspace => $ws } )
# Refactor SyncResult to create a WorkspaceRevision that inherits from
#     Revision and that SyncResult will become identical to or will change to.
# The workspace reference in SyncResult and things derived from it should
#     become an object instead of a string now that the stringify is in place.
# The return will be a reference to a list of OpenRevision objects.
my $opened = $ws->opened();

for my $wrev ( @{$opened} ) {
    my $localname = $wrev->get_localname();
}

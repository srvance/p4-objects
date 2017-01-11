# Example code implementing Story 10: Delete workspace
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

# On success the object will be valid but the update and access form fields will
# be reset to undef. This will allow the creation of a new workspace with the
# same name and values if desired. The optional "remove_all_files" flag will
# clean up the directory tree under the workspace root once the workspace form
# is deleted.
$ws->delete( { remove_all_files => 1 } );

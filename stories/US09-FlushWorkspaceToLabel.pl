# Example code implementing Story 9: Flush a workspace to a label
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

# Get the current workspace
my $ws = $session->get_workspace_object();

# Sync the workspace to label LKG
$ws->sync( { omit_files => 1 }, '@LKG' );

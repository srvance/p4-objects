# Example code implementing Story 7: Sync a workspace to a change level
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

# Sync the workspace to change level 12345
my $results = $ws->sync( '@12345' );

print $results->get_totalfilecount() . " files synced:\n";
my $result_list = $results->get_results();
print "\t\t", join( "\t\t\n", map { $_->get_depotname() } ), "\n";

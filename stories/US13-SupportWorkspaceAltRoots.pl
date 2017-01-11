# Example code implementing Story 13: Support workspace AltRoots
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

# Returns list of workspace objects associated with the current server
# populated as completely as possible from 'p4 changes -s submitted'
my $ws = $session->get_workspace_object();

my $altroots = $ws->get_altroots();
$ws->set_altroots( [ 'C:/first/alt/root', '/second/alt/root' ] );

$ws->commit(); # Saves spec

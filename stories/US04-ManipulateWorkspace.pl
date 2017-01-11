# Example code implementing Story 4: Get client object. Query and set attributes
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

# Returns P4::Repository object
my $repo = $session->get_repository();

# Returns list of workspace objects associated with the current server
# populated as completely as possible from 'p4 changes -s submitted'
my $workspaces = $repo->get_workspaces();

# Up to now is entirely the context from story 3, which sets the stage for
# the new functionality in this story
# *** NOTE *** The return type changed with user story 14. The following code
#              to get a workspace is obsolete, but it doesn't change what you
#              do with the workspace.
my $wsname = (keys %$workspaces)[0]; # For example. Any will do
my $ws = $workspaces->{$wsname};

my $root = $ws->get_root();
$root =~ s,OLDROOT,NEWROOT,g;
$ws->set_root( $root);

$ws->commit(); # Saves spec

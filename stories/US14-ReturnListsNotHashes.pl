# Example code implementing Story 14: Return lists not hashes
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

# Returns list of workspace objects populated as completely as possible from
# 'p4 changes -s submitted'
my $workspaces = $repo->get_workspaces();

foreach my $ws ( @$workspaces ) {
    # Workspace has a stringification method that is equivalent to get_name()
    print "Processing workspace $ws\n";
    # Do something with $ws
};

my $changelists = $repo->get_changelists();
for my $cl ( @$changelists ) {
    # Workspace has a stringification method that is equivalent to
    # get_changeno()
    print "Processing changelist $cl\n";
    # Do something with $cl
}

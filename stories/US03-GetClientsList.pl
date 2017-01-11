# Example code implementing Story 3: Get clients list
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

# *** NOTE *** This return type was obsoleted with user story 14.
# Returns hash of workspace objects keyed by name that are associated with the
# current server populated as completely as possible from
# 'p4 changes -s submitted'
my $workspaces = $repo->get_workspaces();

foreach my $wsname ( keys %$workspaces ) {
    my $ws = $workspaces->{$wsname};
    # Do something with $ws
};

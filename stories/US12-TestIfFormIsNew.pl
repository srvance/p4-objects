# Example code implementing Story 12: Is a form new or existing?
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::PendingChangelist;
use P4::Objects::Session;

# Create Session which holds environment. initializes according to
# standard client rules (e.g. P4CONFIG, environment, etc.)
# Also creates Repository, Connection, and P4 (via Connection) but
# does leave an open connection to the server. Note: It may open a
# connection if necessary to run 'p4 info'.
my $session = P4::Objects::Session->new();

# Get the current workspace
my $ws = $session->get_workspace_object();
my $is_ws_new = $ws->is_new();

# We're going to need some sort of changelist factory or factory method (on
# Repository?) because when we request a changelist by number, we don't
# necessarily know its status.
my $cl = P4::Objects::PendingChangelist->new( {
    session     => $session,
    changeno    => 1234,
});
my $is_cl_new = $cl->is_new();

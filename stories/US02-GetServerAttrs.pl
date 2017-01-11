# Example code implementing Story 2: Get server attributes
# Michael Mirman's code only requires client name and root. He
# obtains it from 'p4 info' but this is more OO-correct.
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Exception;
use P4::Objects::Session;

# Create Session which holds environment. initializes according to
# standard client rules (e.g. P4CONFIG, environment, etc.)
# Also creates Repository, Connection, and P4 (via Connection) but
# does leave an open connection to the server. Note: It may open a
# connection if necessary to run 'p4 info'.
my $session = P4::Objects::Session->new();

# Returns lazy-loaded P4::Workspace object
my $ws = $session->get_workspace_object();
my $ws_name = $ws->get_name();
try {
    my $ws_root = $ws->get_root();
}
catch P4::Objects::Exception::P4::RunError with {
    # Ooops!
};

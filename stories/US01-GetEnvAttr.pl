# Example code implementing Story 1: Set environment variables
# From Yu Wang's MWP4test::new()
use strict;
use warnings;

use P4::Objects::Session;

# Create Session which holds environment. initializes according to
# standard client rules (e.g. P4CONFIG, environment, etc.)
# Also creates Repository, Connection, and P4 (via Connection) but
# does leave an open connection to the server. Note: It may open a
# connection if necessary to run 'p4 info'.
my $session = P4::Objects::Session->new();

# Environment refresh is not automatic.
$session->set_cwd( "/usr/jdoe/ws/jdoe.ws/scm" );

# If refresh is necessary
# $session->refresh_environment();

$session->set_workspace("jdoe.ws");

# Accessors must be implemented for testing
my $curdir = $session->get_cwd();

# Returns lazy-loaded P4::Workspace object
my $ws = $session->get_workspace();
my $ws_name = $ws->get_name();

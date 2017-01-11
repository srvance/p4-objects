# Example code implementing Story 6: Submit numbered pending changelist
# without a form.
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

# Get a new numbered PendingChangelist for the workspace
# Defaults to current user, host, etc. just like a new Perforce changelist
my $cl = $ws->new_changelist();

$cl->add_file( '/some/file/name.pl' );

$cl->set_description( 'Blah blah blah' );

# Once the changelist is successfully submitted, it should no longer be valid. 
my $changeno = $cl->submit();

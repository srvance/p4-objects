# Example code implementing Story XX: Create a label and labelsync it
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Label;
use P4::Objects::Session;

# Create Session which holds environment. initializes according to
# standard client rules (e.g. P4CONFIG, environment, etc.)
# Also creates Repository, Connection, and P4 (via Connection) but
# does leave an open connection to the server. Note: It may open a
# connection if necessary to run 'p4 info'.
my $session = P4::Objects::Session->new();

# Create a label populating it with the existing or default field values
my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => 'newlabel',
} );

$lbl->commit();

# Invokes
#     Connection::labelsync( {
#         label => $lbl,
#         workspace => $session->get_workspace()
#     } )
#     Default workspace resolution may happen in labelsync() instead.
# Probably implement BasicRevision which contains depotFile, rev & action
#     which will then be the parent of Revision
# Returns reference to a list of BasicRevisions
# Is it necessary to implement a files query yet? I think no.
my $revs = $lbl->sync();    # Sync label to default workspace from session

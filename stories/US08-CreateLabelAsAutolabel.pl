# Example code implementing Story 8: Create a label and populate it as an
# autolabel
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

$lbl->set_revision( '@12345' );
$lbl->set_options( 'locked' );

$lbl->commit();

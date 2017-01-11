# Example code implementing Story 5: Get filtered changes list
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

# Returns list of submitted changelist objects associated with the current
# server populated as completely as possible from the output of 'p4 changes'
my $changes = $repo->get_changelists( {
                                    maxReturned => 1,
                                    status      => 'submitted',
                                    filespec   => '@somews',
                                    } );

# *** NOTE *** This return type was obsoleted with user story 14.
foreach my $changeno ( keys %$changes ) {
    my $change = $changes->{$changeno};
    do_something_with_change( $change );
}

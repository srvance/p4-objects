# Example code implementing Story 26: Support changelist fixes
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

my $repo = $session->get_repository();

my $results = $repo->get_changelists( {
    maxReturned => 10,
    status      => 'submitted',
} );

my $cl = $results->[0];

# Returns reference to list of job numbers as strings
my $jobs = $cl->get_jobs();

for my $j ( @{$jobs} ) {
    do_something_with_job( $j );
}

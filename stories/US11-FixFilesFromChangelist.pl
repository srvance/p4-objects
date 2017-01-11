# Example code implementing Story 11: Fix files from changelist
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

my $repo = $session->get_repository();

my $results = $repo->get_changelists( {
    maxReturned => 10,
    status      => 'submitted',
} );

# *** NOTE *** The return type changed with user story 14. The following code
#              to get a changelist is obsolete, but it doesn't change what you
#              do with the changelist.
my $cl = (values %$results)[0];

my $files = $cl->get_files();

for my $file (@$files) {
    do_something_with_file( $file );
}

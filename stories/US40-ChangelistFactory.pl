# Example code implementing User Story 40: Supply changelist factory so that
# changelists can be requested by number and get the correct type regardless
# of status.
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $repo = $session->get_repository();

my $cl = $repo->get_changelist( 43 );

# cl will be a PendingChangelist or a SubmittedChangelist depending on the
# status returned by the underlying command.
# This needs to be re-used by get_changelists(), so some refactoring is in
# order.
# May just be an alternative use of get_changelists() instead

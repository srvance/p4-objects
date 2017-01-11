# Example code implementing User Story 37: Implement 'resolved'
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace();

my $resolved_files = $ws->resolved(); # Don't need file argument yet.

# Format of resolved_files TBD. May be its own object. Probably similar or
# identical to the integed result.
# Data content is:
#   path
#   toFile
#   fromFile
#   startToRev
#   endToRev
#   startFromRev
#   endFromRev
#   how

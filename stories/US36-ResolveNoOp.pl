# Example code implementing User Story 36: Implement 'resolve -n'
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace();

my $pending_resolves = $ws->resolve( { preview => 1 } );

# Format of pending_resolves TBD. May be its own object. Probably a subset of
# the integed result.
# Data content is:
#   clientFile
#   fromFile
#   startFromRev
#   endFromRev

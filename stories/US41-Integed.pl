# Example code implementing User Story 41: Implement 'integed'
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $repo = $session->get_repository();

# Only need a single path for motivating case. Should arguments be a list of
# paths anyway?
my $integed_files = $repo->integrated( '//some/path/...' );

# Format of integed_files TBD. May be its own object. Similar to the resolved
# result.
# Data content is:
#   toFile
#   fromFile
#   startToRev
#   endToRev
#   startFromRev
#   endFromRev
#   how
#   change

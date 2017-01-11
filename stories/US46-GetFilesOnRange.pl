# Example code implementing Story 45: Get files in a range
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $repo = $session->get_repository();

# This should already work and just needs to be tested.
my $files = $repo->get_files( '@1,@3' );

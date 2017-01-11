# Example code implementing Story 44: Get changelists in a range
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $repo = $session->get_repository();

# This should already work and just needs to be tested.
my $changes = $repo->get_changelists( {
    filespec   => '@1,@3',
} );

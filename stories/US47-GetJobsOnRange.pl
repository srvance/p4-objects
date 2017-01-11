# Example code implementing Story 46: Get jobs in a range
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $repo = $session->get_repository();

# Returns reference to list of job names
# Calls Connection::run()
my $jobs = $repo->get_jobs( {
    filespec   => '@1,@3',
} );


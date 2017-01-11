# Example code implementing Story 18: Randomize the P4::Server port to avoid
# port collisions
use strict;
use warnings;

use Error qw( :try );

use P4::Server;

my $server1 = P4::Server->new();
$server1->create_temp_root();
$server1->set_cleanup( 1 );

# o Allocates a random port if the port number is 0, closes it, and sets the
#   port attribute to it.
# o Does NOT guarantee that nothing is running on that port or even attempt to
#   do so. It is the responsibility of the caller to ensure that the child
#   process starts successfully.
$server1->randomize_port();

try {
    $server1->start_p4d();
    # Passes
}
catch P4::Server::Exception::ChildDied with {
    # Need to get a new port and try again.
}
otherwise {
    # Unexpected exception
};

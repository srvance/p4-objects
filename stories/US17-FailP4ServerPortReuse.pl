# Example code implementing Story 17: P4::Server should fail when attempting
# to start on a port that is already in use.
use strict;
use warnings;

use Error qw( :try );

use P4::Server;

my $port = 1717;

my $server1 = P4::Server->new( {
    port        => $port,
} );
$server1->create_temp_root();
$server1->set_cleanup( 1 );
try {
    $server1->start_p4d();
    # Passes
}
otherwise {
    # Unexpected exception
};

my $server2 = P4::Server->new( {
    port        => $port,
} );
$server2->create_temp_root();
$server2->set_cleanup( 1 );
try {
    $server2->start_p4d();
}
catch P4::Server::Exception::FailedExec with {
    # Expected behavior with a problem spawning the process
}
catch P4::Server::Exception::FailedToStart with {
    # Expected behavior if the server spawns but doesn't service requests
}
catch P4::Server::Exception::P4DQuit with {
    # Expected behavior if the server spawned but quit
}
catch P4::Server::Exception::ServerListening with {
    # Expected behavior if a server is already using the port
}
catch P4::Server::Exception::ServerRunning with {
    # Expected behavior if this object has already started a server
}
otherwise {
    # Unexpected exception
};

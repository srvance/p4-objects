# Example code implementing Story 20: Enable raw output from Connection
use strict;
use warnings;

use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $raw = $session->get_raw_connection();

# Returns list of strings.
my @output = $raw->run( 'info' );

print join( "\n", @output ), "\n";

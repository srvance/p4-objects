# Example code implementing User Story 42: Add common base class
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# This should be the case for all P4::Objects classes
if( ! $session->isa( 'P4::Objects::Common::Base' ) {
    # Error!
}

my $arrayref = [ 1, 2, 3 ];
# Not really callable publicly, but good as an example of what has to exist
if( ! $session->_is_arrayref( $arrayref ) ) {
    # Error!
}

my $hashref = ( key1 => 1, key2 => 2 );
# Not really callable publicly, but good as an example of what has to exist
if( ! $session->_is_hashref( $hashref ) ) {
    # Error!
}

# Not really callable publicly, but good as an example of what has to exist
if( ! $session->_is_arrayref( $session->_ensure_arrayref( 'somestring' ) ) ) {
    # Error!
}

# Other internal convenience methods might be:
# o _extract_options_hash(): pull the options hash out of an argument list
# o Methods to assist in mapping options to command line arguments

my $ws = $session->get_workspace();

# Convenience methods to avoid additional calls
my $conn = $ws->get_connection();
my $repo = $ws->get_repository();

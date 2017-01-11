# Example code implementing Story 30: Is workspace exactly at a change
# level?
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $ws = $session->get_workspace();

# Calls Workspace::sync( { preview => 1 }, "//$wsname/...\@$level" );
# o Level may be anything that can go after an '@' in Perforce revision specs
#   with 'now' being equivalent to '#head'
# Tests result for nothing synced and reports true if so
if( $ws->is_exactly_at_level( '12345' ) ) {
    # Hooray!
}
else {
    # Oops!
}

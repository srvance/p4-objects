# Example code implementing Story 19: Retire Session::get_workspace_object()
use strict;
use warnings;

use P4::Objects::Session;

my $wsname = 'someworkspacename';
my $session = P4::Objects::Session->new();
$session->set_workspace( $wsname );

# DEPRECATED
# my $ws = $session->get_workspace_object();

my $ws = $session->get_workspace();
if( ref( $ws ) ne 'P4::Objects::Workspace' ) {
    # ERROR: Something's very wrong
}

if( $wsname ne $ws ) {
    # ERROR: Something different is also very wrong
}

# Example code implementing User Story 47: Support form options well
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace();

my $rmdir = $ws->get_option_rmdir();

$ws->set_option_rmdir( 1 );

$ws->set_option_locked( 1 );

# This will apply to options for Label and Workspace right now. It will not
#   apply to submitoptions or lineend, since they are not boolean and can only
#   have singular values.
# Internally, this will be resolved with an AUTOMETHOD and the option values
#   will be stored in a hash
# The infrastructure for this will be commonly available to Form objects but
#   will only be applied if there is an Options field.
# Do we need something like get_option_keys()?

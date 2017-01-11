# Example code implementing Story 43: Report highest change level in workspace
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

my $ws = $session->get_workspace_object();

# Implementation will call
#     Repository::get_changelists( {
#         maxReturned   => 1,
#         status        => 'submitted',
#         filespec      => '@' . $ws,
#     } )
# Return will be either a changelist or undef
my $cl = $ws->get_highest_changelist();

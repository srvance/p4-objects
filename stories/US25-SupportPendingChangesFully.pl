# Example code implementing Story 25: Support pending changelists fully,
# especially from Repository::get_changelists()
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $ws = $session->get_workspace();
my $cl = $ws->new_changelist();


my $repo = $session->get_repository();

# o Returns PendingChangelist objects
# o Query that returns submitted and pending changelist will return a list
#   of both types of objects.
my $cls = $repo->get_changelists( {
    status => 'pending',
    filespec        => '@' . $cl->get_changeno(),
} );

my $pending_cl = $cls->[0];
# For $pending_cl, type should be PendingChangelist and status should be
# 'pending'.

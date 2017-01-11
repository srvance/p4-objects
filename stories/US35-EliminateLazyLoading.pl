# Example code implementing Story 35: Eliminate lazy loading
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::PendingChangelist;
use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# Get the current workspace
my $ws = $session->get_workspace_object();
my $is_ws_new = $ws->is_new(); # Should not cause a request to the server
my $wsdesc = $ws->get_description();    # Should return the default description
                                        # with no request to the server

# Loading an existing changelist should load the existing form, but since it's
# pending, checking whether it is new might force a trip to the server.
my $cl = P4::Objects::PendingChangelist->new( {
    session     => $session,
    changeno    => 1234,
});
my $is_cl_new = $cl->is_new(); # Should not force a request to the server
my $cldesc = $cl->get_description();    # Should return the description
                                        # with no request to the server

# The following forms have or might need to have lazy loading behavior:
# o Label: Currently only lazy loaded for access/update times
# o Workspace: Lazy loaded and includes optional fields
# o Changelist: Currently only lazy loading for file lists. Lazy loading makes
#               little sense for submitted changelists, but may be worthwhile
#               for pending changelists

# A reload_spec() method should be provided to complement the new behavior

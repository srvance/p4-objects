# Example code implementing Story 24: Fstat file
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $repo = $session->get_repository();

# Calls Connection::fstat()
# Format of return TBD. Probably derived from WorkspaceRevision or Revision
my $fileinfo = $repo->fstat( '//some/file/in/depot.c' );

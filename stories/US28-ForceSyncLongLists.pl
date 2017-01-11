# Example code implementing Story 28: Force sync a workspace to a long
# list of files
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# Get the current workspace
my $ws = $session->get_workspace_object();

# Long list numbering in the 10s of thousands of files
my @long_list = (
    '//some/file/number1.c',
    ...
);

my $results = $ws->sync( { force_sync => 1 }, @long_list );

# Example code implementing Story 34: Stringify all appropriate objects
# To catch up, this only applies to Label and Revision.
use strict;
use warnings;

use P4::Objects::Label;
use P4::Objects::Revision;
use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# Create a label populating it with the existing or default field values
my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => 'newlabel',
} );

my $labelname = $lbl;

my $repo = $session->get_repository();
my $changelists = $repo->get_changelists( {
    maxReturned => 1,
    status => 'submitted',
} );
my $change = $changelists->[0];

my $files = $change->get_files();
my $first_file = $files->[0];

# Should stringify to filepath#revision
my $filename = $first_file;
my ($depotname, $rev) = split /#/, $filename;

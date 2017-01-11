# Example code implementing Story 42: Stringify all appropriate objects
# To catch up, this only applies to Label and Revision.
use strict;
use warnings;

use P4::Objects::Label;
use P4::Objects::Revision;
use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $sessionstring = scalar $session;    # Should be P4PORT

# Create a label populating it with the existing or default field values
my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => 'newlabel',
} );

my $labelname = scalar $lbl;    # Should be 'newlabel'

my $repo = $session->get_repository();
my $repostring = scalar $repo;  # Should be P4PORT

my $conn = $session->get_connection();
my $connstring = scalar $conn;  # Should be P4PORT
                                # Will be true for all Connections

my $fsr = $repo->fstat( $somepath );
my $fsrstring = scalar $fsr;    # Form will vary depending on situation
                                # May be localname or
                                # depotname#revision or
                                # undef

# SyncResults will not have a stringify

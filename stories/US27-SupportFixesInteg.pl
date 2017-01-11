# Example code implementing Story 27: Support fixes -i <file>@<change>
use strict;
use warnings;

use Error qw( :try );

use P4::Objects::Session;

my $session = P4::Objects::Session->new();
my $repo = $session->get_repository();

# Calls Connection::get_fixes()
# Return will be a reference to a list of TBD content
my $results = $repo->get_fixes( {
        report_integ_history    => 1,
    },
    '//some/file.c@12345',
);

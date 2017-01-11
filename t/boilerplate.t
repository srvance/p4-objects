#!perl -T

use strict;
use warnings;
use Test::More tests => 31;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open my $fh, "<", $filename
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

module_boilerplate_ok('lib/P4/Objects.pm');
module_boilerplate_ok('lib/P4/Objects/BasicConnection.pm');
module_boilerplate_ok('lib/P4/Objects/Changelist.pm');
module_boilerplate_ok('lib/P4/Objects/ChangelistRevision.pm');
module_boilerplate_ok('lib/P4/Objects/Common/AccessUpdateForm.pm');
module_boilerplate_ok('lib/P4/Objects/Common/Base.pm');
module_boilerplate_ok('lib/P4/Objects/Common/BinaryOptions.pm');
module_boilerplate_ok('lib/P4/Objects/Common/Form.pm');
module_boilerplate_ok('lib/P4/Objects/Connection.pm');
module_boilerplate_ok('lib/P4/Objects/Exception.pm');
module_boilerplate_ok('lib/P4/Objects/FileType.pm');
module_boilerplate_ok('lib/P4/Objects/FstatResult.pm');
module_boilerplate_ok('lib/P4/Objects/IntegrationRecord.pm');
module_boilerplate_ok('lib/P4/Objects/Label.pm');
module_boilerplate_ok('lib/P4/Objects/OpenRevision.pm');
module_boilerplate_ok('lib/P4/Objects/PendingChangelist.pm');
module_boilerplate_ok('lib/P4/Objects/PendingResolve.pm');
module_boilerplate_ok('lib/P4/Objects/RawConnection.pm');
module_boilerplate_ok('lib/P4/Objects/Repository.pm');
module_boilerplate_ok('lib/P4/Objects/Revision.pm');
module_boilerplate_ok('lib/P4/Objects/Session.pm');
module_boilerplate_ok('lib/P4/Objects/SubmittedChangelist.pm');
module_boilerplate_ok('lib/P4/Objects/SyncResults.pm');
module_boilerplate_ok('lib/P4/Objects/Workspace.pm');
module_boilerplate_ok('lib/P4/Objects/WorkspaceRevision.pm');
module_boilerplate_ok('lib/P4/Objects/IntegrateResults.pm');
module_boilerplate_ok('lib/P4/Objects/IntegrateResult.pm');
module_boilerplate_ok('lib/P4/Objects/Extensions/MergeResolveData.pm');
module_boilerplate_ok('lib/P4/Objects/Extensions/MergeResolveTracker.pm');

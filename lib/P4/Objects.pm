# Copyright (C) 2007-8 Stephen Vance
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
#
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
#
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package P4::Objects;

use warnings;
use strict;

our $VERSION = '0.52';

1; # End of P4::Objects
__END__

=head1 NAME

P4::Objects - OO wrapper for Perforce's P4Perl module

=head1 VERSION

Version 0.52

=head1 SYNOPSIS

This module creates domain objects for the Perforce system. This module is
a documentation module that establishes the namespace for the family of
modules that supply this functionality.

The modules in the package are:

    P4::Objects (this package)
    P4::Objects::BasicConnection
    P4::Objects::Changelist
    P4::Objects::ChangelistRevision
    P4::Objects::Connection
    P4::Objects::Exception
    P4::Objects::FileType
    P4::Objects::FstatResult
    P4::Objects::IntegrationRecord
    P4::Objects::Label
    P4::Objects::OpenRevision
    P4::Objects::PendingChangelist
    P4::Objects::PendingResolve
    P4::Objects::RawConnection
    P4::Objects::Repository
    P4::Objects::Revision
    P4::Objects::Session
    P4::Objects::SubmittedChangelist
    P4::Objects::SyncResults
    P4::Objects::Workspace
    P4::Objects::WorkspaceRevision
    P4::Objects::Common::AccessUpdateForm
    P4::Objects::Common::Base
    P4::Objects::Common::BinaryOptions
    P4::Objects::Common::Form

The starting point for all usage of P4::Objects is the Session. The start of
most P4::Objects programs resembles:

    use strict;
    use warnings;

    use Error qw( :try );
    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    ...

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >> on behalf of The MathWorks, Inc.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

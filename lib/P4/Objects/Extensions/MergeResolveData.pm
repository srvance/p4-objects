# Copyright (C) 2008 Stephen Vance
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

package P4::Objects::Extensions::MergeResolveData;

use warnings;
use strict;

use Class::Std::Storable;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.52';

my %mergeaction_of       : ATTR( name => 'mergeaction'                                            );
my %resolved_of          : ATTR( name => 'resolved'                                               );
my %p4resolved_of        : ATTR( name => 'p4resolved'                                             );
my %integrateresult_of   : ATTR( name => 'integrateresult'                                        );
my %typemerge_of         : ATTR( name => 'typemerge'                                              );
my %typepropagate_of     : ATTR( name => 'typepropagate'                                          );
my %sourcerevision_of    : ATTR( name => 'sourcerevision'                                         );
my %targetrevision_of    : ATTR( name => 'targetrevision'                                         );
my %baserevision_of      : ATTR( init_arg => 'baserevision', default => '', get => 'baserevision' );
}

1;
__END__

=head1 NAME

P4::Objects::Extensions::MergeResolveData - Includes all data associated with an integrate
from one branch to another.  Handles all of the merge resolutions for renames, deletes and file
type changes that are not handled properly by Perforce.  It is not intended for use outside of the
scope of the MergeResolveTracker.

It inherits from Class::Std::Storable so that it can be stored and retrieved.

=head1 SYNOPSIS

P4::Objects::Extensions::MergeResolveData represents a single file resolution data.

    use P4::Objects::Extensions::MergeResolveData;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $intresults = $ws->integrate( { branch => branchname } ); # Returns reference to
                                                                 # list of IntegrateResult
                                                     # objects
    my $ir = $intresults->get_results()->[0];

    my $mrd = P4::Objects::Extension::MergeResolveData->new {
        mergeaction     => 'trivial',
        resolved        => 1,
        p4resolved      => 1,
        integrateresult => $ir
    });


=head1 FUNCTIONS

=head2 get_mergeaction

Returns the merge type one of:

=over

=item *

trivial - The file was either a branch-into or was resolved with -as meaning only the source branch changed

=item *

non_trivial - The file will require a merge resolution (it may work with an automatic merge)

=item *

cant - The file cannot be handled with Perforce resolve and did not open as part of the integrate.  These files are handled by the MergeResolveTracker

=back

=head3 Throws

Nothing

=head2 get_resolved

Returns whether the file has been resolved or not.  This includes resolving the file types and resolvable deletes not handled by Perforce

=head3 Throws

Nothing

=head2 get_p4resolved

Returns true if this file shows up on the output from p4 resolved

=head3 Throws

Nothing

=head2 get_integrateresult

Returns the corresponding result returned from the integrate command, see P4::Objects::IntegrateResult

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

mergeaction (Required) - One of 'trivial', 'non_trivial', or 'cant'

=item *

resolved (Required) - Whether the file is already resolved or not

=item *

p4resolved (Required) - Whether the file is open and resolved in Perforce

=item *

integrateresult (Required) - The result from opening the file for integrate

=back

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-pendingresolve at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-IntegrateResult>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::IntegrateResult

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-IntegrateResult>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-IntegrateResult>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-IntegrateResult>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-IntegrateResult>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

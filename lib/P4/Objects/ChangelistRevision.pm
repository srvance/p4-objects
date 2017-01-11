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

package P4::Objects::ChangelistRevision;

use warnings;
use strict;

use Data::Dumper;

use Class::Std::Storable;

use base qw( P4::Objects::Revision );

{

our $VERSION = '0.46';

my %changelist_of : ATTR( init_arg => 'change' get => 'changelist' );

}

1;
__END__

=head1 NAME

P4::Objects::ChangelistRevision - Information about a single revision in a
changelist

=head1 SYNOPSIS

P4::Objects::ChangelistRevision encapsulates the state of a single revision in
a changelist.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $repo = $session->get_repository();
    my $crs = $repo->files( '//...' ); # Returns ref to ChangelistRevision array
    ...

=head1 FUNCTIONS

=head2 get_changelist

Returns the changelist number with which the revision is associated

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

The parameters for L<P4::Objects::Revision/new>, as well as

=item *

changelist (Required) - The changelist with which the revision is associated

=back

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-changelistrevision at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-ChangelistRevision>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::ChangelistRevision

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-ChangelistRevision>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-ChangelistRevision>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-ChangelistRevision>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-ChangelistRevision>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

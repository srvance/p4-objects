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

package P4::Objects::PendingResolve;

use warnings;
use strict;

use Class::Std::Storable;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.43';

# TODO: This would allow someone to skip this initialization. Fix? Added to
#       address the mismatch against 'path' from 'resolved'
my %localname_of : ATTR( init_arg => 'clientFile' default => '' get => 'localname' );
my %source_of : ATTR( init_arg => 'fromFile' get => 'source' );
my %startfromrev_of : ATTR( init_arg => 'startFromRev' get => 'startfromrev' );
my %endfromrev_of : ATTR( init_arg => 'endFromRev' get => 'endfromrev' );

# PRIVATE METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;

    return $self->get_localname();
}

sub _set_localname : RESTRICTED {
    my ($self, $name) = @_;

    $localname_of{ident $self} = $name;

    return;
}

}

1; # End of P4::Objects::PendingResolve
__END__

=head1 NAME

P4::Objects::PendingResolve - Information about a single pending resolve

=head1 SYNOPSIS

P4::Objects::PendingResolve represents a single pending resolve. A
PendingResolve object stringifies to its local file name.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $resolves = $ws->resolve( { preview => 1 } ); # Returns reference to
                                                     # list of PendingResolve
                                                     # objects
    my $pr = $resolves->[0];
    my $localname = $pr->get_localname();
    my $source = $pr->get_source();
    ...

=head1 FUNCTIONS

=head2 get_endfromrev

Returns the end revision of the source range for the integration.

=head3 Throws

Nothing

=head2 get_localname

Returns the local filename of the target of the integration.

=head3 Throws

Nothing

=head2 get_source

Returns the depot name of the source of the integration.

=head3 Throws

Nothing

=head2 get_startfromrev

Returns the start revision of the source range for the integration.

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

clientFile (Required) - The local name of the target of the integration
corresponding to the localname attribute.

=item *

endFromRev (Required) - The end revision of the source range for the
integration.

=item *

fromFile (Required) - The depot name of the source of the integration
corresponding to the source attribute.

=item *

startFromRev (Required) - The start revision of the source range for the
integration.

=back

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-pendingresolve at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-PendingResolve>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::PendingResolve

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-PendingResolve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-PendingResolve>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-PendingResolve>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-PendingResolve>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

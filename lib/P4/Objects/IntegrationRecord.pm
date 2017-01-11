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

package P4::Objects::IntegrationRecord;

use warnings;
use strict;

use Class::Std;

use base qw( P4::Objects::PendingResolve );

{

our $VERSION = '0.43';

my %target_of : ATTR( init_arg => 'toFile' get => 'target' );
my %starttorev_of : ATTR( init_arg => 'startToRev' get => 'starttorev' );
my %endtorev_of : ATTR( init_arg => 'endToRev' get => 'endtorev' );
my %how_of : ATTR( init_arg => 'how' get => 'how' );
my %changeno_of : ATTR( init_arg => 'change' default => 0 get => 'changeno' );

sub BUILD {
    my ($self, $ident, $args_ref) = @_;

    if( defined( $args_ref->{path} ) ) {
        $self->_set_localname( $args_ref->{path} );
    }

    return;
}

# PRIVATE METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;

    my $source = $self->get_source();
    my $sourcestart = $self->get_startfromrev() . ',';
    if( $sourcestart eq '#none,' ) {
        $sourcestart = '';
    }
    my $sourceend = $self->get_endfromrev();

    my $target = $self->get_target();
    my $targetstart = $self->get_starttorev() . ',';
    if( $targetstart eq '#none,' ) {
        $targetstart = '';
    }
    my $targetend = $self->get_endtorev();

    my $how = $self->get_how();

    my $str = "$target$targetstart$targetend - $how $source$sourcestart$sourceend";

    return $str;
}

}

1; # End of P4::Objects::IntegrationRecord
__END__

=head1 NAME

P4::Objects::IntegrationRecord - A single integration record

=head1 SYNOPSIS

P4::Objects::IntegrationRecord represents a single integration record. It
inherits from L<P4::Objects::PendingResolve>. It stringifies to an attempted
approximation of the non-ztag output of 'integed'. No guarantee is made for
exact correpondence.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $resolved = $ws->resolved(); # Returns reference to list of
                                    # IntegrationRecord objects
    my $rf = $resolved->[0];
    my $localname = $rf->get_localname();
    my $target = $pr->get_target();
    ...

=head1 FUNCTIONS

=head2 get_endtorev

Returns the end revision of the target range for the integration.

=head3 Throws

Nothing

=head2 get_how

Returns a how the integration was resolved for this file.

=head3 Throws

Nothing

=head2 get_starttorev

Returns the start revision of the target range for the integration.

=head3 Throws

Nothing

=head2 get_target

Returns the depot filename of the target of the integration.

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

change (Optional) - The change number for a submitted integration.

=item *

endToRev (Required) - The end revision of the target range for the integration.

=item *

how (Required) - The explanation for how the file was resolved.

=item *

path (Optional) - The local name of the target of the integration
corresponding to the localname attribute. This is the same as the clientFile
parameter in L<P4::Objects::PendingResolve> and is only available for a
pending resolve.

=item *

startToRev (Required) - The start revision of the source range for the
integration.

=item *

toFile (Required) - The depot name of the target of the integration.

=back

=head3 Throws

Nothing

=head2 BUILD

Pre-initialization constructor invoked by L<Class::Std>.

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-integrationrecord at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-IntegrationRecord>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::IntegrationRecord

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-IntegrationRecord>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-IntegrationRecord>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-IntegrationRecord>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-IntegrationRecord>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

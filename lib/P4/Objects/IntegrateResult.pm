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

package P4::Objects::IntegrateResult;

use warnings;
use strict;

use Class::Std::Storable;

use base qw( P4::Objects::PendingResolve );
{

our $VERSION = '0.52';

my %otheraction_of : ATTR( init_arg => 'otherAction', default => '', get => 'otheraction' );
my %workingrev_of  : ATTR(                                           get => 'workingrev'     );
my %action_of      : ATTR( init_arg => 'action'     ,                get => 'action'      );
my %basename_of    : ATTR( init_arg => 'baseName'   , default => '', get => 'basename'    );
my %baserev_of     : ATTR( init_arg => 'baseRev'    , default => '', get => 'baserev'     );
my %depotfile_of   : ATTR( init_arg => 'depotFile'  ,                get => 'depotfile'   );

sub START {
    my ($self, $ident, $args_ref) = @_;

    $workingrev_of{$ident} = $args_ref->{workRev};

    return;
}

sub _as_str : STRINGIFY {
    my ($self) = @_;

    my $start = $self->get_startfromrev();
    my $end = $self->get_endfromrev();
    my $frev = ($start eq $end) ? $start : "$start,$end";

    my $retval = $self->get_depotfile() . $self->get_workingrev_spec()
      . ' - ' . $self->get_action() . ' from '
      . $self->get_source() . '#' . $frev;
    my $base = $self->get_basename();
    if ($base) {
        $retval .= ' using base ' . $base . '#' . $self->get_baserev();
    }
    return $retval;
}

sub get_workingrev_spec {
    my ($self) = @_;
    my $wr = $self->get_workingrev();
    return defined($wr) ? "#$wr" : '';
}
sub get_source_revision {
    my ($self) = @_;
    return $self->get_source() . '#' . $self->get_endfromrev();
}

sub get_target_revision {
    my ($self) = @_;
    return $self->get_depotfile() . $self->get_workingrev_spec();
}

sub get_base_revision {
    my ($self) = @_;
    my $base = $self->get_basename();
    if ($base) {
        return $base . '#' . $self->get_baserev();
    }
    return;
}

}

1;
__END__

=head1 NAME

P4::Objects::IntegrateResult - Information about a single integrate result.
Inherits from P4::Objects::PendingResolve.

=head1 SYNOPSIS

P4::Objects::IntegrateResult represents a single integrate result. A
IntegrateResult object stringifies to the same string as returned by integrate.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $intresults = $ws->integrate( { branch => branchname } ); # Returns reference to
                                                                 # list of IntegrateResult
                                                                 # objects
    my $ir = $intresults->get_results()->[0];
    my $localname = $ir->get_localname();
    my $source = $ir->get_source();
    ...

=head1 FUNCTIONS

=head2 START

Post-initialization constructor invoked by Class::Std.

=head3 Throws

Nothing

=head2 get_otheraction

Returns the OtherAction field for this integrate result.

=head3 Throws

Nothing

=head2 get_workingrev

Returns the workingrev field for this integrate result

=head3 Throws

Nothing

=head2 get_workingrev_spec

Returns a Perforce revision specification for the working revision of the file either #<rev> or ''

=head3 Throws

Nothing

=head2 get_action

Returns the action field for this integrate result

=head3 Throws

Nothing

=head2 get_basename

Returns the baseName field for this integrate result

=head3 Throws

Nothing

=head2 get_baserev

Returns the baseRev field for this integrate result

=head3 Throws

Nothing

=head2 get_depotfile

Returns the depotFile field for this integrate result

=head3 Throws

Nothing

=head2 get_base_revision

Returns the filename and revision string in depot syntax for the common base
for the merge.

=head3 Throws

Nothing

=head2 get_source_revision

Returns the filename and revision string in depot syntax for the source file of the merge.
It uses the ending from revision for the revision string and does not return a range.

=head3 Throws

Nothing

=head2 get_target_revision

Returns the filename and revision string in depot syntax for the target file of the merge.

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

otherAction (optional) - The otherAction field from the integrate result.

=item *

workingrev (Required) - The working revision in the workspace.

=item *

action (Required) - The integrate action from the integrate result

=item *

baseName (optional) - The base file name from the integrate result (if -o was used)

=item *

baseRev (optional) - The base file revision from the integrate result (if -o was used)

=item *

depotfile (optional) - The depot file that is the target of the integrate

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

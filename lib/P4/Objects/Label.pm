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

package P4::Objects::Label;

use warnings;
use strict;

use P4::Objects::Common::BinaryOptions;

use base qw( P4::Objects::Common::AccessUpdateForm );

use Class::Std;

{

our $VERSION = '0.48';

my %name_of : ATTR( init_arg => 'name' get => 'name' );
my %owner_of : ATTR( get => 'owner' set => 'owner' );
my %description_of : ATTR( get => 'description' set => 'description' );
my %options_of : ATTR( get => 'options' set => 'options' );
my %revision_of : ATTR( get => 'revision' set => 'revision' );
my %view_of : ATTR( default => [] get => 'view' set => 'view' );

sub commit {
    my ($self) = @_;
    my $ident = ident $self;

    my %spec = (
        Label       => $name_of{$ident},
        Owner       => $owner_of{$ident},
        Description => $description_of{$ident},
        Options     => "$options_of{$ident}", # Force stringification
        Revision    => $revision_of{$ident},
        View        => $view_of{$ident},
    );

    my $conn = $self->get_connection();

    # Let exceptions pass
    $conn->save_label( \%spec );

    $self->_load_label();

    return;
}

# PRIVATE METHODS

sub _load_label : PRIVATE {
    my ($self) = @_;

    my $labelname = $self->get_name();

    my @args = (
        '-o',
        $labelname,
    );

    my $conn = $self->get_connection();

    # Pass errors
    my $result = $conn->run( 'label', @args );

    $self->_set_attrs_from_spec( $result );

    return;
}

sub _load_spec : RESTRICTED {
    my ($self) = @_;

    $self->_load_label();

    return;
}

sub _set_attrs_from_spec : PRIVATE {
    my ($self, $spec) = @_;
    my $ident = ident $self;

    # Support the Perforce tag 'Label'
    $name_of{$ident} = $spec->{Label};

    # Support the Perforce tags 'Access' and 'Update'
    $self->_set_access_and_update(
        $spec->{Access},
        $spec->{Update},
    );

    # Support the Perforce tag 'Owner'
    $owner_of{$ident} = $spec->{Owner};

    # Support the Perforce tag 'Description'
    $description_of{$ident} = $spec->{Description};

    # Support the Perforce tag 'Options'
    $options_of{$ident} = P4::Objects::Common::BinaryOptions->new( {
        Options     => $spec->{Options},
    } );

    # Support the Perforce tag 'Revision'
    $revision_of{$ident} = $spec->{Revision};

    # Support the Perforce tag 'View'
    $view_of{$ident} = $spec->{View};

    return;
}

sub _as_str : STRINGIFY {
    my ($self) = @_;

    return $self->get_name();
}

}

1;
__END__

=head1 NAME

P4::Objects::Label - a Perforce label or tag

=head1 INHERITS FROM

L<P4::Objects::Common::Form>

=head1 SYNOPSIS

P4::Objects::Label encapsulates the Perforce label. Currently, only
auto-labels are supported (i.e. the Revision field is supported and labelsync
is not). It stringifies to the label name.

    use P4::Objects::Label;
    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $lbl = P4::Objects::Label->new( {
        session     => $session,
        name        => 'labelname',
    } );
    $lbl->set_description( 'Some description' );
    $lbl->set_revision( '@12345' );
    $lbl->commit();
    ...

=head1 FUNCTIONS

=head2 commit

Saves the label spec to the Perforce server.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/save_label>.

=back

=head2 get_description

Returns the description for this label.

=head3 Throws

Nothing

=head2 get_name

Returns the name of this label.

=head3 Throws

Nothing

=head2 get_options

Returns a L<P4::Objects::Common::BinaryOptions> object containing the
label options for this object.

=head3 Throws

Nothing

=head2 get_owner

Returns the owner of the label.

=head3 Throws

Nothing

=head2 get_revision

Returns the revision field for this label if it is an auto-label or undef
otherwise.

=head3 Throws

Nothing

=head2 get_view

Returns the a reference to a list of strings, one for each line of the view
for this label.

=head3 Throws

Nothing

=head2 new

Constructor for the object.

=head3 Parameters

Parameters are passed in a hash.

=over

=item *

name (Required) - The label name

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>.

=item *

Exceptions from L<P4::Objects::Common::BinaryOptions/new>.

=back

=head2 set_description

Sets the description for the label.

=head3 Throws

Nothing

=head2 set_owner

Sets the owner of the label.

=head3 Throws

Nothing

=head2 set_revision

Sets the revision field for the label, definining it as an auto-label.

=head3 Throws

Nothing

=head2 set_view

Sets the view of the label. The argument should be a list of strings, one
string for each view line.

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by L<Class::Std>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-label at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Label>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Label

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Label>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Label>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Label>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Label>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

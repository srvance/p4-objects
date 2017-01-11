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

package P4::Objects::Common::AccessUpdateForm;

use warnings;
use strict;

use P4::Objects::Exception;

use base qw( P4::Objects::Common::Form );

use Class::Std;

{

our $VERSION = '0.35';

my %access_of : ATTR( get => 'access' );
my %update_of : ATTR( get => 'update' );

sub BUILD {
    my ($self, $ident, $args_ref) = @_;

    $self->_set_access_and_update(
        $args_ref->{access},
        $args_ref->{update},
    );

    return;
}

sub is_new {
    my ($self) = @_;
    my $ident = ident $self;

    # Access storage directly so we don't trigger child overrides of accessors

    return ! $self->get_access()
        && ! $self->get_update();
}

# PRIVATE METHODS

# Throws P4::Objects::Exception::InconsistentFormState

sub _set_access_and_update : RESTRICTED {
    my ($self, $access, $update) = @_;

    # If either is defined without the other, throw an exception
    if( ! defined( $access ) && defined( $update ) )
    {
        P4::Objects::Exception::InconsistentFormState->throw(
            missing     => 'access',
        );
    }

    if( defined( $access ) && ! defined( $update ) )
    {
        P4::Objects::Exception::InconsistentFormState->throw(
            missing     => 'update',
        );
    }

    $access_of{ident $self} = $self->_ensure_epoch_time( $access );
    $update_of{ident $self} = $self->_ensure_epoch_time( $update );

    return;
}

# WARNING: This is here only for coverage testing. Use of this for any
# asymetric setting of access and update other than for that purpose is
# expressly forbidden!
sub _set_access_only : PRIVATE {
    my ($self, $access) = @_;

    $access_of{ident $self} = $access;

    return;
}

}

1; # End of P4::Objects::Common::AccessUpdateForm
__END__

=head1 NAME

P4::Objects::Common::AccessUpdateForm - a common base class for objects that
correspond to Perforce forms with access and update date/time fields (i.e. all
forms except change forms)

=head1 SYNOPSIS

P4::Objects::Common::AccessUpdateForm contains the infrastructure common to the
representation of all Perforce forms with access and update date/time fields.
The functionality this provides on top of the L<P4::Objects::Common::Form>
intterface includes:

=over

=item *

Keeping track of the update and access times

=item *

Time conversions where necessary to ensure the epoch seconds representation

=item *

Query methods to determine whether a form is new or existing based on the
update and access fields

=back

This class is not designed to be used in isolation. By itself, it is a
meaningless subset of form data and functionality. It should only be used by
those enhancing the P4::Objects classes themselves.

    package P4::Objects::SomeFormType;

    use base qw( P4::Objects::Common::AccessUpdateForm );

    ...

    package Some::P4::Objects::User;

    use P4::Objects::SomeFormType;

    my $sft = P4::Objects::SomeFormType( { ... } );
    if( $sft->is_new() ) {
        # Do something with a new form
    }
    elsif( $sft->is_existing() ) {
        my $access_time = $sft->get_access();
        my $update_time = $sft->get_update();
        # Do something different with an existing form
    }
    else {
        # Shouldn't happen. Just wanted conditions for each method.
    }

=head1 METHODS

=head2 get_access

Returns the last accessed time for this form as a number of epoch seconds.

=head3 Throws

Nothing

=head2 get_update

Returns the last updated time for this form as a number of epoch seconds.

=head3 Throws

Nothing

=head2 is_existing

Returns whether the form already exists on the Perforce server or not. This is
the logical complement of L</is_new>.

=head3 Throws

Nothing

=head2 is_new

Returns whether this form is new or not based on the presence or absence of
access and update fields.

=head3 Throws

Nothing

=head2 new

Constructor only intended for use by derived classes. Automatically loads the
form spec if no initialization parameters are passed.

=head3 Parameters

Parameters are passed in an anonymous hash. Although access and update are
optional, if one is supplied, both must be supplied.

=over

=item *

access (Optional) - Sets the last accessed time for this object.

=item *

update (Optional) - Sets the last updated time for this object.

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::InconsistentFormState - if one of access and update
are supplied, but not both

=back

=head2 BUILD

Pre-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-common-accessupdateform at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Common-AccessUpdateForm>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Common::AccessUpdateForm

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Common-AccessUpdateForm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Common-AccessUpdateForm>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Common-AccessUpdateForm>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Common-AccessUpdateForm>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

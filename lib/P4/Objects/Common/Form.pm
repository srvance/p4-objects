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

package P4::Objects::Common::Form;

use warnings;
use strict;

use P4::Objects::Exception;

use base qw( P4::Objects::Common::Base );

use Class::Std;

{

our $VERSION = '0.35';

sub START {
    my ($self, $ident, $args_ref) = @_;

    # Use attributes if supplied. Otherwise, load the default from the server.
    if( defined( $args_ref->{attrs} ) ) {
        $self->_set_attrs_from_spec( $args_ref->{attrs} );
    }
    else
    {
        $self->_load_spec();
    }

    return;
}

sub is_new { ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

sub is_existing {
    my ($self) = @_;

    return ! $self->is_new();
}

# PRIVATE METHODS

sub _set_attrs_from_spec : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

sub _load_spec : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

}

1; # End of P4::Objects::Common::Form
__END__

=head1 NAME

P4::Objects::Common::Form - a common base class for objects that correspond to
Perforce forms

=head1 SYNOPSIS

P4::Objects::Common::Form contains the infrastructure common to the
representation of all Perforce forms. The functionality this provides
includes:

=over

=item *

Automatic loading of the spec on form creation when not explicitly initialized.

=item *

Query methods to determine whether a form is new or existing

=back

This class is not designed to be used in isolation. By itself, it is a
meaningless subset of form data and functionality. It should only be used by
those enhancing the P4::Objects classes themselves.

    package P4::Objects::SomeFormType;

    use base qw( P4::Objects::Common::Form );

    ...

    package Some::P4::Objects::User;

    use P4::Objects::SomeFormType;

    my $sft = P4::Objects::SomeFormType( { ... } );
    if( $sft->is_new() ) {
        # Do something with a new form
    }
    elsif( $sft->is_existing() ) {
        # Do something different with an existing form
    }
    else {
        # Shouldn't happen. Just wanted conditions for each method.
    }

=head1 METHODS

=head2 is_existing

Returns whether the form already exists on the Perforce server or not. This is
the logical complement of L</is_new>.

=head3 Throws

Nothing

=head2 is_new

Returns whether this form is new or not.

=head3 Throws

Nothing

=head2 new

Constructor only intended for use by derived classes. Automatically loads the
form spec if no initialization parameters are passed.

=head3 Parameters

None

=head3 Throws

=over

=item *

P4::Objects::Exception::IncompleteClass - if the class is used without
properly overriding the abstract methods. The methods that need to be
overridden are:

=over

=item *

is_new

=item *

_set_attrs_from_spec

=item *

_load_spec

=back

=back

=head2 START

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-common-form at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Common-Form>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Common::Form

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Common-Form>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Common-Form>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Common-Form>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Common-Form>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

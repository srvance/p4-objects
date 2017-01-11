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

package P4::Objects::Common::Base;

use warnings;
use strict;

use Date::Parse;
use P4::Objects::Exception;
use Scalar::Util qw( looks_like_number weaken );

use Class::Std::Storable;

{

our $VERSION = '0.52';

my %session_of : ATTR( init_arg => 'session' );

sub get_session {
    my ($self) = @_;

    my $session = $session_of{ident $self};
    if( ! defined( $session ) ) {
        P4::Objects::Exception::InvalidSession->throw();
    }

    return $session;
}

sub get_connection {
    my ($self) = shift;

    return $self->get_session()->get_connection();
}

sub get_repository {
    my ($self) = shift;

    return $self->get_session()->get_repository();
}

sub translate_special_chars_to_codes {
    my ($self, $filename) = @_;

    $filename =~ s/%/%25/g;
    $filename =~ s/\@/%40/g;
    $filename =~ s/#/%23/g;
    $filename =~ s/\*/%2A/g;

    return $filename;
}

sub translate_codes_to_special_chars {
    my ($self, $filename) = @_;

    $filename =~ s/%40/\@/g;
    $filename =~ s/%23/#/g;
    $filename =~ s/%2A/*/g;
    $filename =~ s/%25/%/g;

    return $filename;
}

# PRIVATE AND RESTRICTED METHODS

sub _weaken_session : RESTRICTED {
    my ($self) = @_;

    if( defined( $session_of{ident $self } ) ) {
        weaken( $session_of{ident $self } );
    }

    return;
}

sub _ensure_epoch_time : RESTRICTED {
    my ($self, $time) = @_;

    return looks_like_number( $time )
                            ? $time
                            : str2time( $time );
}

sub _ensure_arrayref : RESTRICTED {
    my ($self, @args) = @_;

    #
    # If exactly 1 argument is passed
    #     if it is undef - return []
    #     if it is an array reference - return it.
    #
    if (@args == 1) {
        my ($arg) = @args;
        if ( ! defined( $arg )) {
            return [];
        }
        if ( ref( $arg ) eq 'ARRAY') {
            return $arg;
        }
    }
    #
    # Otherwise return a reference to the passed argument list
    #
    return [ @args ];
}

my $thaw_session;

sub _set_thaw_session :RESTRICTED {
    my ($ses) = @_;
    $thaw_session = $ses;
    return;

}

sub STORABLE_freeze_pre : CUMULATIVE(BASE FIRST) {
    my ($self, $cloning) = @_;

    $session_of{ident $self} = undef;  # The session cannot be serialized

    return;
}

sub STORABLE_thaw_post : CUMULATIVE(BASE FIRST) {
    my ($self, $cloning) = @_;

    $session_of{ident $self} = $thaw_session;

    return;
}

}

1; # End of P4::Objects::Common::Form
__END__

=head1 NAME

P4::Objects::Common::Base - a common base class for all P4::Objects domain
object classes except L<P4::Objects::Session>

=head1 SYNOPSIS

P4::Objects::Common::Base contains the infrastructure common to all
P4::Objects domain object classes except L<P4::Objects::Session> and the
Exception classes.

This class is not designed to be used in isolation. By itself, it is a
meaningless collection of functionality. It should only be used by
those enhancing the P4::Objects classes themselves.

=head1 FUNCTIONS

=head2 get_connection

Returns the connection from the associated L<P4::Objects::Session>.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Session/get_connection>

=back

=head2 get_repository

Returns the repository from the associated L<P4::Objects::Session>.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Session/get_repository>

=back

=head2 get_session

Returns a reference to the L<P4::Objects::Session> object associated with this
object.

=head3 Throws

=over

=item *

P4::Objects::Exception::InvalidSession - If the session reference has become
invalid by the time it is requested.

=back

=head2 new

L<Class::Std> generated constructor for the object.

=head3 Parameters

An anonymous hash, also required by derived classes, containing the following
keys:

=over

=item *

session (Required) - Identifies the P4::Objects::Session with which this
Workspace is associated

=back

=head2 translate_codes_to_special_chars

Takes a string as an argument and returns the string translating embedded
ASCII codes to the corresponding characters that are special to Perforce. The
codes and their corresponding characters are:

=over

=item *

%23 => #

=item *

%25 => %

=item *

%2A => *

=item *

%40 => @

=back

=head3 Throws

Nothing

=head2 translate_special_chars_to_codes

Takes a string as an argument and returns the string translating characters
that are special to Perforce to the corresponding ASCII codes. The special
characters and their corresponding codes are:

=over

=item *

# => %23

=item *

% => %25

=item *

* => %2A

=item *

@ => %40

=back

=head3 Throws

Nothing

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


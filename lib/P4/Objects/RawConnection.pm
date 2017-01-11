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

package P4::Objects::RawConnection;

use warnings;
use strict;

use Class::Std;
use Error qw( :try );
use P4 ();
use P4::Objects::Exception;
use Scalar::Util qw( looks_like_number );

use base qw( P4::Objects::BasicConnection );

{

our $VERSION = '0.43';

my %workspace_of : ATTR( get => 'workspace' );
my %user_of : ATTR( get => 'user' );
my %port_of : ATTR( get => 'port' );
my %host_of : ATTR( get => 'host' );
my %charset_of : ATTR( get => 'charset' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    my $session = $self->get_session();
    $workspace_of{$ident} = $session->get_workspace();
    $user_of{$ident} = $session->get_user();
    $port_of{$ident} = $session->get_port();
    $host_of{$ident} = $session->get_host();
    $charset_of{$ident} = $session->get_charset();

    return;
}

# PRIVATE AND RESTRICTED METHODS

sub _initialize_p4 : RESTRICTED {
    my ($self) = @_;
    my $ident = ident $self;

    my $p4 = $self->get_p4();

    # Apply the cached environment settings. Reapply them in case the P4
    # object was reallocated since the last call.
    $p4->SetPort( $port_of{$ident} );
    $p4->SetUser( $user_of{$ident} );
    $p4->SetHost( $host_of{$ident} );
    $p4->SetClient( $workspace_of{$ident} );
    my $charset = $charset_of{$ident};
    $p4->SetCharset( $charset ) if( defined( $charset ) && length( $charset ) );

    return;
}

sub _requires_arrayref : RESTRICTED {
    my ($self, $cmd) = @_;

    # For now assume everything needs to be an arrayref

    return 1;
}

}

1; # End of P4::Objects::RawConnection
__END__

=head1 NAME

P4::Objects::RawConnection - a convenience class to encapsulate the L<P4>
instance with raw unmarshalled output

=head1 SYNOPSIS

P4::Objects::RawConnection wraps and manages the L<P4> class. It caches the
Session settings from when it is created and only passes the raw text output
of the Perforce commands back to the caller.

Perhaps a little code snippet.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $raw = $session->get_raw_connection();
    ...

=head1 FUNCTIONS

=head2 get_charset

Returns the charset retrieved from the Session when the object was created.

=head2 get_host

Returns the host retrieved from the Session when the object was created.

=head2 get_port

Returns the port retrieved from the Session when the object was created.

=head2 get_user

Returns the user retrieved from the Session when the object was created.

=head2 get_workspace

Returns the workspace retrieved from the Session when the object was created.

=head2 new

Constructor

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

p4_class (Optional) - A string with the name of a class derived from L<P4> to
use instad of the L<P4> class

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::BadPackage

=over

=item *

If a L<P4> substitute is supplied that is not derived from L<P4>

=back

=item *

P4::Objects::Exception::BadAlloc

=over

=item *

For problems allocating the L<P4> instance

=back

=back

=head2 START

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-rawconnection at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-RawConnection>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::RawConnection

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-RawConnection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-RawConnection>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-RawConnection>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-RawConnection>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

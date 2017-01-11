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

package P4::Objects::Session;

use warnings;
use strict;

use P4::Objects::Connection;
use P4::Objects::RawConnection;
use P4::Objects::Repository;
use P4::Objects::Workspace;

use Cwd;

use Class::Std;

{

our $VERSION = '0.43';

my %repository_of : ATTR( get => 'repository' );
my %connection_of : ATTR( get => 'connection' );

# Perforce environment attributes
# Workspace has special handling due to object return
my %workspace_of : ATTR( set => 'workspace' );
my %user_of : ATTR( get => 'user' set => 'user' );
my %port_of : ATTR( get => 'port' set => 'port' );
my %host_of : ATTR( get => 'host' set => 'host' );
my %charset_of : ATTR( get => 'charset' set => 'charset' );
my %commandcharset_of : ATTR( get => 'commandcharset' set => 'commandcharset' );
my %config_of : ATTR( get => 'config' set => 'config' );
my %diff_of : ATTR( get => 'diff' set => 'diff' );
my %diffunicode_of : ATTR( get => 'diffunicode' set => 'diffunicode' );
my %editor_of : ATTR( get => 'editor' set => 'editor' );
my %language_of : ATTR( get => 'language' set => 'language' );
my %merge_of : ATTR( get => 'merge' set => 'merge' );
my %mergeunicode_of : ATTR( get => 'mergeunicode' set => 'mergeunicode' );
my %pager_of : ATTR( get => 'pager' set => 'pager' );
my %tickets_of : ATTR( get => 'tickets' set => 'tickets' );

sub BUILD {
    my ($self, $ident, $args_ref) = @_;

    my $repo = $self->_allocate_repository();
    if( defined( $repo ) ) {
        $repository_of{$ident} = $repo;
    }
    else {
        P4::Objects::Exception::BadAlloc->throw( class => __PACKAGE__ );
    }
    my $conn = $self->_allocate_connection();
    $connection_of{$ident} = $conn;

    # TODO: Does this throw anything? If so, test
    $self->_load_environment( $conn );

    return;
}

sub get_workspace {
    my ($self, $name) = @_;

    my $ws;

    if( defined( $name ) ) {
        $ws = $self->_allocate_workspace( $name );
    }
    else {
        $ws = $self->_allocate_workspace( $workspace_of{ident $self} );
    }

    return $ws;
}

sub set_cwd {
    my ($self, $dir) = @_;

    if ( ! defined( $dir ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter => 'directory'
        )
    }

    chdir( $dir )
        or P4::Objects::Exception::InvalidDirectory->throw(
            directory => $dir,
        );

    $ENV{PWD} = $dir;

    $self->get_connection()->set_cwd( $dir );

    return;
}

sub refresh_environment {
    my ($self) = @_;

    my $conn = $connection_of{ident $self};

    # TODO: Handle exceptions
    $conn->reload();

    # TODO: Does this throw anything? If so, test
    $self->_load_environment( $conn );

    return;
}

sub get_raw_connection {
    my ($self) = @_;

    return P4::Objects::RawConnection->new( {
        session     => $self,
    } );
}

# PRIVATE METHODS

sub _load_environment : PRIVATE {
    my ($self, $conn) = @_;

    # Get the value from P4 through the Connection
    foreach my $attr ( $conn->get_supported_attrs() ) {
        my $setter = 'set_' . $attr;
        my $getter = 'get_' . $attr;
        # TODO: Should we trap an exception here?
        my $val = $conn->$getter();
        $self->$setter( $val );
    }

    return;
}

# Throws P4::Objects::Exception::BadAlloc, P4::Objects::Exception::BadPackage
# Should never throw BadPackage here because we're not overriding the P4.
sub _allocate_connection {
    my ($self) = @_;

    return P4::Objects::Connection->new( { session => $self } );
}

# Throws Nothing

sub _allocate_repository {
    my ($self) = @_;

    return P4::Objects::Repository->new( { session => $self } );
}

# Throws Nothing

sub _allocate_workspace {
    my ($self, $ws_name) = @_;

    my $ws = P4::Objects::Workspace->new( {
        session => $self,
        name    => $ws_name,
    } );

    return $ws;
}

# Throws Nothing

# This is only for use by Connection to avoid recursive invocations on form
# loading. It's also useful for tests that knowingly need to avoid object
# creation instead of creating and destroying a server.
sub _get_workspace_name {
    my ($self) = @_;

    return $workspace_of{ident $self};
}

sub _as_str : STRINGIFY {
    my ($self) = @_;

    return $self->get_port();
}

}

1; # End of P4::Objects::Session
__END__

=head1 NAME

P4::Objects::Session - a single usage of the Perforce server with environment

=head1 SYNOPSIS

P4::Objects::Session is the starting point for usage of the P4::Objects
framework.  All other entities can be obtained through an instance of
P4::Objects::Session. It stringifies to the port value.

    use P4::Objects;

    my $session = P4::Objects::Session->new();
    ...

=head1 FUNCTIONS

=head2 get_port, get_host, get_charset, get_commandcharset, get_config, get_diff, get_diffunicode, get_editor, get_language, get_merge, get_mergeunicode, get_pager, get_tickets

Standard getters for Perforce environment settings. All return strings.

=head3 Throws

Nothing

=head2 get_repository

Returns a reference to the L<P4::Objects::Repository> object associated with
this Session.

=head3 Throws

Nothing

=head2 get_connection

Returns a reference to the L<P4::Objects::Connection> object associated with
this Session.

=head3 Throws

Nothing

=head2 get_raw_connection

Returns a reference to a L<P4::Objects::RawConnection> object with environment
settings copied from this Session.

=head3 Throws

Nothing

=head2 get_workspace

Gets an object of type P4::Objects::Workspace corresponding to the currently
set or specified workspace. A new workspace object is created on each call,
regardless of whether and object for the workspace has previously been
allocated.

=head3 Parameters

=over

=item *

name (Optional) - if specified, a workspace object is created with this name

=back

=head3 Throws

Nothing

=head2 new

Constructor. Allocates Connection and Repository objects on creation, and
obtains the Perforce settings from the environment through standard Perforce
means with standard precedence.

=head3 Parameters

None

=head3 Throws

=over

=item *

P4::Objects::Exception::BadAlloc

=back

=head2 refresh_environment

Reloads the settings from the environment.
NOTE: All P4 settings are taken session object and are not re-sensed from the
environment or configuration files

=head2 set_workspace, set_port, set_host, set_charset, set_commandcharset, set_config, set_diff, set_diffunicode, set_editor, set_language, set_merge, set_mergeunicode, set_pager, set_tickets

Standard setters for Perforce environment settings. All take a single string
as an argument.

=head3 Throws

Nothing

=head2 set_cwd

Changes the current working directory and sets the PWD enviroment variable
correspondingly. Perforce uses PWD for its directory cues. Note that setting
PWD is not effective on Windows, introducing a portability issue.

=head2 BUILD

Constructor invoked by L<Class::Std>.

=head3 Throws

=over

=item *

P4::Objects::Exception::BadAlloc

=over

=item *

If either the subordinate Repository or Connection cannot be allocated.

=back

=item *

P4::Objects::Exception::BadPackage

=over

=item *

From L<P4::Objects::Connection/new>

=back

=back

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-session at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Session>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Session

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Session>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Session>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

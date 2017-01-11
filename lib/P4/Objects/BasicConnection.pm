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

package P4::Objects::BasicConnection;

use warnings;
use strict;

use Class::Std;
use Error qw( :try );
use P4 ();
use P4::Objects::Exception;
use Scalar::Util qw( looks_like_number );

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.52';

my %p4_of : ATTR( get => 'p4' );
my %p4_class_of : ATTR( init_arg => 'p4_class' default => 'P4' get => 'p4_class' );
my %connected_of : ATTR( default => 0 );

my @supported_attrs = (
            'workspace',
            'user',
            'port',
            'host',
            'charset',
            'config',
            # 'commandcharset',
            # 'diff',
            # 'diffunicode',
            # 'editor',
            # 'language',
            # 'merge',
            # 'mergeunicode',
            # 'pager',
            # 'tickets',
);

sub START {
    my ($self, $ident, $args_ref) = @_;

    $self->_weaken_session();

    my $packagename = $p4_class_of{$ident};

    my $status = $packagename->isa( 'P4' );
    if( ! $status ) {
        P4::Objects::Exception::BadPackage->throw(
                    class => $packagename,
        );
    }

    $self->_set_P4( $self->_allocate_P4() );

    return;
}

sub DEMOLISH {
    my ($self) = @_;
    my $ident = ident $self;

    $self->_free_P4();
    return;
}

sub AUTOMETHOD {
    my ($self, $ident, @args) = @_;
    my $subname = $_;

    # Return failure if not a valid pattern.
    # If we return a sub that throws an exception here, then the can() test
    # will succeed, which isn't worth the incremental improvement.
    # TODO: If derived objects need to add their own patterns, this will need
    #       to be refactored.
    my %valid_patterns = (
        '\A get_.* \z'      =>  '_get_handler',
    );

    my $handler;
    foreach my $pat ( keys %valid_patterns ) {
        if( $subname =~ m/$pat/xms ) {
            $handler = $valid_patterns{$pat};
            last;
        }
    }

    # NOTE: Used to have a 'can' test here on the handler, but it was really
    # only useful as a development sanity check. Unfortunately coverage won't
    # tell us if we've covered all of the data cases for the pattern-based
    # method dispatching, so it's up to the developer to be conscientious.
    # Since there will be an error if the handler isn't present, I've opted to
    # get complete coverage rather than test for something that's a
    # development issue and will trigger an error appropriately. This decision
    # should be reversed if the mapping between the method name and the
    # handler becomes more dynamic, allowing for user runtime occurrance.
    # The error you'll see for an unimplemented handler is actually a deep
    # recursion error on AUTOLOAD.
    if( $handler ) {
        local $_ = $subname;
        return $self->$handler( $ident, @args );
    }

    return;
}

sub get_supported_attrs {
    return @supported_attrs;
}

sub reload {
    my ($self) = @_;
    my $ident = ident $self;

    $self->_disconnect();

    $self->_set_P4( undef );

    $self->_set_P4( $self->_allocate_P4() );

    return;
}

sub run {
    my ($self, $cmd, @args) = @_;
    my $ident = ident $self;

    my $options = {};
    if( ref( $cmd ) eq 'HASH' ) {
        $options = $cmd;
        $cmd = shift @args;
    }

    $self->connect();

    my $p4 = $self->get_p4();
    if( defined( $options->{workspace} ) ) {
        $p4->SetClient( $options->{workspace} );
    }

    # TODO: There is actually a lot of logic here that will be required for
    #       autoconnect and related stuff.
    my $result = $p4->Run( $cmd, @args );

    if( $self->_requires_arrayref( $cmd ) ) {
        $result = $self->_ensure_arrayref( $result );
    }

    if( $p4->ErrorCount() > 0 ) {
        my $errors = $self->_get_errors();
        my $warnings = $self->_get_warnings();
        P4::Objects::Exception::P4::RunError->throw(
            results         => $result,
            errorcount      => $p4->ErrorCount(),
            errors          => $errors,
            warningcount    => $p4->WarningCount(),
            warnings        => $warnings,
        );
    }

    return $result;
}

sub connect { ## no critic (ProhibitBuiltinHomonyms)
    my ($self) = @_;
    my $ident = ident $self;
    my $p4 = $self->get_p4();

    if( $self->_is_connected() ) {
        return 1;
    }

    if( $p4->Dropped() ) {
        $p4->Disconnect();
    }

    $self->_initialize_p4();

    if( $p4->Connect() == 0 ) {
        P4::Objects::Exception::P4::CantConnect->throw(
                            port        => $p4->GetPort(),
                            errorcount  => $p4->ErrorCount(),
                            errors      => $self->_get_errors(),
        );
    }

    $connected_of{$ident} = 1;

    return;
}

sub set_cwd {
    my ($self, $dir) = @_;

    $self->get_p4()->SetCwd( $dir );

    return;
}

sub get_cwd {
    my ($self) = @_;

    return $self->get_p4()->GetCwd();
}

# PRIVATE AND RESTRICTED METHODS

sub _get_handler : PRIVATE {
    my ($self, $ident) = @_;
    my $subname = $_;

    my ($mode, $name) = $subname =~ m/\A (get)_(.*) \z/xms;

    my $found = 0;
    foreach my $attr ( @supported_attrs ) {
        if( $attr eq $name ) {
            $found = 1;
            last;
        }
    }
    return if( ! $found );

    # Config can only be set in the environment and isn't directly
    # support by P4Perl, but we can make it consistent at this level.
    # Doesn't address Windows registry variables.
    if( $name eq 'config' ) {
        return sub { return $ENV{'P4CONFIG'} };
    }
    else {
        my $newsub = ($name eq 'workspace') ? 'GetClient' : "Get\u$name";
        return sub { return $self->get_p4()->$newsub() };
    }
}

# Throws P4::Objects::Exception::BadAlloc

sub _set_P4 : RESTRICTED {
    my ($self, $p4) = @_;

    $p4_of{ident $self} = $p4;

    return;
}

sub _allocate_P4 : RESTRICTED {
    my ($self) = @_;

    my $p4 = $self->get_p4_class()->new();

    if( ! $p4 ) {
        P4::Objects::Exception::BadAlloc->throw(
            class => "$p4_class_of{ident $self}"
        );
    }

    return $p4;
}

sub _free_P4 : RESTRICTED {
    my ($self) = shift;
    my $ident = ident $self;

    $self->_disconnect();

    $self->_set_P4( undef );

    return;
}

sub _is_connected : RESTRICTED {
    my ($self) = @_;

    my $p4 = $self->get_p4();
    if( ! defined( $p4 ) ) {
        return 0;
    }

    if( ! $connected_of{ident $self} ) {
        return 0;
    }

    if( $p4->Dropped() ) {
        return 0;
    }

    return 1;
}

sub _disconnect : RESTRICTED {
    my ($self) = @_;

    my $p4 = $self->get_p4();
    if( ! defined( $p4 ) ) {
        return;
    }

    $p4->Disconnect();

    $connected_of{ident $self} = 0;

    return;
}

sub _get_errors : RESTRICTED {
    my ($self) = @_;

    my $errors = $self->get_p4()->Errors();
    return $self->_ensure_arrayref( $errors );
}

sub _get_warnings : RESTRICTED {
    my ($self) = @_;

    my $warnings = $self->get_p4()->Warnings();
    return $self->_ensure_arrayref( $warnings );
}

sub _initialize_p4 : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => __PACKAGE__,
    );
}

sub _requires_arrayref : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self, $cmd) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => __PACKAGE__,
    );
}

sub _as_str : STRINGIFY {
    my ($self) = @_;

    my $session = $self->get_session();
    my $port = $session->get_port();

    # There are some minorly dysfunctional cases in which the port isn't set.
    return defined( $port ) ? $port : '';
}

}

1; # End of P4::Objects::BasicConnection
__END__

=head1 NAME

P4::Objects::BasicConnection - the base class for all P4::Objects Connection
types

=head1 SYNOPSIS

P4::Objects::BasicConnection provides the basis for wrapping and managing the
L<P4> class. It stringifies to the port value from the associated
L<P4::Objects::Session>.

This class should be considered abstract and not directly instantiated.

=head1 FUNCTIONS

=head2 connect

Connect to the Perforce server. Called automatically when necessary.

=head3 Throws

=over

=item *

P4::Objects::Exception::P4::CantConnect - on inability to connect to the
Perforce server.

=back

=head2 get_cwd

Returns the current working directory used by the L<P4::Objects::Connection>
class for all Perforce commands.

=head3 Throws

Nothing

=head2 get_port, get_host, get_charset, get_config, get_workspace

Accessors handled by the AUTOMETHOD that proxy through to the L<P4> object.
For example, get_port() invokes P4::GetPort(). Exceptions are:

=over

=item *

get_workspace() invokes P4::GetClient()

=item *

get_config() retrieves P4CONFIG from $ENV

=back

=head2 get_p4

Returns a reference to the L<P4> object associated with this Connection.

=head3 Throws

Nothing

=head2 get_supported_attrs

Returns the array of supported attributes for proxy to L<P4>. This is
primarily for testing support, but can also be used to check the capabilities
of the class.

=head3 Throws

Nothing

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

=head2 reload

This method destroys the current L<P4> instance and reallocates new one. This
is sometimes necessary because of the way P4Perl loads the environment on
construction.  Any settings from the current sesssion object are re-applied
on the resulting P4 object.  This means that all environment variables and
configuration file settings are ignored for the reload - they are overwritten
from the currently active session

I<NOTE>: Although this method should be harmless for general use, it is only
intended for use by L<P4::Objects::Session> and is only guaranteed to serve
that purpose.

=head3 Throws

=over

=item *

P4::Objects::Exception::BadAlloc

=back

=head2 run

Pass through method for L<P4/Run> with optional additional first argument.

=head3 Parameters

=over

=item *

options (Optional) - An anonymous hash providing for command-specific
overrides to the values stored in the session. The currently supported
overrides are:

=over

=item *

workspace - The name of the workspace in which to apply the command

=back

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::P4::RunError - if there are errors from the Perforce
command

=back

=head2 set_cwd

Pass-through to L<P4/SetCwd>.

=head3 Throws

Nothing

=head2 AUTOMETHOD

Method called by L<Class::Std/AUTOLOAD>.

=head3 Throws

Nothing. L<Class::Std> freaks out when AUTOMETHOD throws an exception directly
and throwing an exception from a returned sub makes it look like the sub is
implemented..

=head2 DEMOLISH

Destructor invoked by L<Class::Std>.

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-basicconnection at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-BasicConnection>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::BasicConnection

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-BasicConnection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-BasicConnection>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-BasicConnection>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-BasicConnection>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

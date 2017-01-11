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

package P4::Objects::FileType;

use warnings;
use strict;

use Class::Std;

# Does not inherit from P4::Objects::Common::Base. So far it has no binding to
# any particular object or context.

{

our $VERSION = '0.49';

my %basetype_of : ATTR( get => 'basetype' set => 'basetype' default => 'text' );
my %modifier_values_of : ATTR;

our %valid_modifiers = (
    'use_modtime'               => 'm',
    'sync_writable'             => 'w',
    'executable'                => 'x',
    'keyword_expansion'         => 'k',
    'old_keyword_expansion'     => 'ko',
    'exclusive_open'            => 'l',
    'store_compressed'          => 'C',
    'store_deltas'              => 'D',
    'store_full_file'           => 'F',
    # stored_revisions (+S[nn]) needs special handling
);

# Taken from the Perforce documentation
our %type_aliases = (
    'ctext'      => 'text+C',
    'cxtext'     => 'text+Cx',
    'ktext'      => 'text+k',
    'kxtext'     => 'text+kx',
    'ltext'      => 'text+F',
    'tempobj'    => 'binary+Sw',
    'ubinary'    => 'binary+F',
    'uresource'  => 'resource+F',
    'uxbinary'   => 'binary+Fx',
    'xbinary'    => 'binary+x',
    'xltext'     => 'text+Fx',
    'xtempobj'   => 'binary+Swx',
    'xtext'      => 'text+x',
    'xunicode'   => 'unicode+x',
    'xutf16'     => 'utf16+x',
);

our %modifiers_by_letter = map { $valid_modifiers{$_} => $_ }
                                keys %valid_modifiers;

sub BUILD {
    my ($self, $ident, $args_ref) = @_;

    my $type = $args_ref->{'type'};
    if( defined( $type ) ) {
        $self->_parse_type( $type );
    }

    return;
}

sub AUTOMETHOD {
    my ($self, $ident, @args) = @_;
    my $subname = $_;

    my ($operation, $modifier) = split( /_/, $subname, 2 );

    if( defined( $modifier )
        && ! $valid_modifiers{$modifier}
        && $modifier ne 'stored_revisions'
    ) {
        return;
    }

    if( $operation eq 'get' ) {
        return sub {
            my $value = $modifier_values_of{$ident}{$modifier};
            if( $modifier eq 'stored_revisions' ) {
                return defined( $value ) ? $value : 0;
            }
            else {
                return $self->_normalize_value( $value );
            }
        }
    }
    elsif( $operation eq 'set' ) {
        return sub {
            # Stored revisions is the only non-binary setting
            if( $modifier eq 'stored_revisions' ) {
                $modifier_values_of{$ident}{$modifier} = $args[0];
            }
            else {
                $modifier_values_of{$ident}{$modifier}
                    = $self->_normalize_value( $args[0] );
            }

            # Special exception for mutual exclusivity of 'k' and 'ko'
            $self->_set_keyword_modifier( $modifier, $args[0] );

            # Special exception for mutual exclusivity of 'C', 'D', and 'F'
            $self->_set_storage_modifier( $modifier, $args[0] );

            return;
        }
    }

    return;
}

sub get_modifiers {
    return ( sort keys %valid_modifiers, 'stored_revisions' );
}

sub get_type_string : STRINGIFY {
    my ($self) = @_;
    my $ident = ident $self;

    my @modifiers = map { $valid_modifiers{$_} }
        grep { $modifier_values_of{$ident}{$_} }
        keys %valid_modifiers;

    my $stored_count = $modifier_values_of{$ident}{'stored_revisions'};
    if( defined( $stored_count ) ) {
        if( $stored_count == 1 ) {
            push @modifiers, 'S';
        }
        else {
            push @modifiers, 'S' . $stored_count;
        }
    }

    if( scalar @modifiers == 0 ) {
        return $basetype_of{$ident};
    }
    else {
        return $basetype_of{$ident}
            . '+'
            . join( '', sort @modifiers );
    }
}

sub equals {
    my ($self, $rhs) = @_;

    # Optimization to avoid an extra object creation
    if( ref( $rhs ) eq ref( $self ) ) {
        return ( $self->get_type_string() eq $rhs->get_type_string() );
    }
    else { # Assuming string or stringifiable
        return ( $self->get_type_string()
            eq P4::Objects::FileType->new( { type => $rhs } )
                ->get_type_string()
        );
    }
}

# PRIVATE METHODS

sub _parse_type : PRIVATE {
    my ($self, $type) = @_;
    my $ident = ident $self;

    # If we were given an alias, transform it into its canonical
    # representation. This assumes that aliases can't have modifiers.
    if( defined( $type_aliases{$type} ) ) {
        $type = $type_aliases{$type};
    }

    my ($base, $modifiers) = split /\+/, $type;

    $basetype_of{$ident} = $base;

    if( ! defined( $modifiers ) ) {
        return;
    }

    # Handle stored revisions separately
    if( $modifiers =~ /S/ ) {
        my $stored_count = $modifiers;
        $stored_count =~ s/[^\d]//g;
        $modifiers =~ s/S\d*//; # Remove the stored revisions
        if( $stored_count eq '' ) {
            $stored_count = 1;
        }
        $self->set_stored_revisions( $stored_count );
    }

    my @mods = split //, $modifiers;

    while( @mods > 0 ) {
        my $mod = shift @mods;
        if( $mod eq 'k' && @mods > 0 && $mods[0] eq 'o' ) {
            $mod .= shift @mods;
        }
        my $method = 'set_' . $modifiers_by_letter{$mod};
        $self->$method( 1 );
    }

    return;
}

sub _normalize_value : PRIVATE {
    my ($self, $value) = @_;

    return !!$value;
}

sub _set_keyword_modifier {
    my ($self, $modifier, $arg) = @_;
    my $ident = ident $self;

    if( $modifier eq 'keyword_expansion' && $arg == 1 ) {
        $modifier_values_of{$ident}{'old_keyword_expansion'} = 0;
    }
    elsif( $modifier eq 'old_keyword_expansion' && $arg == 1 ) {
        $modifier_values_of{$ident}{'keyword_expansion'} = 0;
    }

    return;
}

sub _set_storage_modifier {
    my ($self, $modifier, $arg) = @_;
    my $ident = ident $self;

    if( $modifier eq 'store_compressed' && $arg == 1 ) {
        $modifier_values_of{$ident}{'store_deltas'} = 0;
        $modifier_values_of{$ident}{'store_full_file'} = 0;
    }
    elsif( $modifier eq 'store_deltas' && $arg == 1 ) {
        $modifier_values_of{$ident}{'store_compressed'} = 0;
        $modifier_values_of{$ident}{'store_full_file'} = 0;
    }
    elsif( $modifier eq 'store_full_file' && $arg == 1 ) {
        $modifier_values_of{$ident}{'store_compressed'} = 0;
        $modifier_values_of{$ident}{'store_deltas'} = 0;
    }

    return;
}

}

1; # End of P4::Objects::FileType
__END__

=head1 NAME

P4::Objects::FileType - A representation of a Perforce file type

=head1 SYNOPSIS

P4::Objects::FileType represents a Perforce file type with convenience methods
to aggregate modifiers and compare types.

    use P4::Objects::FileType;

    my $ft = P4::Objects::FileType->new( 'binary+l' );
    my $exclusive = $ft->get_exclusive_open();
    $ft->set_exclusive_open( ! $exclusive );
    my $typestring = $ft; # 'binary'
    ...

Not all modifiers are currently supported. The supported modifiers are
returned by L</get_modifiers>.

=head1 FUNCTIONS

=head2 equals

Returns true if the argument represents exactly the same file type as the
object and false otherwise.

=head3 Parameters

rhs (Required) - A string or object of this type representing a Perforce
file type

=head3 Throws

Nothing

=head2 get_basetype

Returns the base file type for this object.

=head3 Throws

Nothing

=head2 get_executable

Returns the state of the executable attribute (+x) as a boolean.

=head3 Throws

Nothing

=head2 get_exclusive_open

Returns the state of the exclusive open attribute (+l) as a boolean.

=head3 Throws

Nothing

=head2 get_keyword_expansion

Returns the state of the RCS keyword expansion attribute (+k) as a boolean.

=head3 Throws

Nothing

=head2 get_modifiers

Returns a list of the currently supported type modifiers for this
implementation.

=head3 Throws

Nothing

=head2 get_old_keyword_expansion

Returns the state of the old RCS keyword expansion (+ko, Id and Header only)
attribute as a boolean.

=head3 Throws

Nothing

=head2 get_store_compressed

Returns the state of the compressed storage attribute (+C) as a boolean.

=head3 Throws

Nothing

=head2 get_store_deltas

Returns the state of the delta storage attribute (+D) as a boolean.

=head3 Throws

Nothing

=head2 get_store_full_file

Returns the state of the full file storage attribute (+F) as a boolean.

=head3 Throws

Nothing

=head2 get_stored_revisions

Returns the number of revisions to be retained (+S). A value of 0 indicates no
limit.

=head3 Throws

Nothing

=head2 get_sync_writable

Returns the state of the sync as writable attribute (+w) as a boolean.

=head3 Throws

Nothing

=head2 get_type_string

Returns the string version of the object state. This method is the stringifier
for the object.

=head3 Throws

Nothing

=head2 get_use_modtime

Returns the state of the modtime attribute (+m) as a boolean.

=head3 Throws

Nothing

=head2 new

Constructor

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

type (Optional) - The file type to be parsed and manipulated. Defaults to
'text'.

=back

=head3 Throws

Nothing

=head2 set_executable

Sets the state of the executable attribute (+x).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_exclusive_open

Sets the state of the exclusive open attribute (+l).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_keyword_expansion

Sets the state of the RCS keyword expansion attribute (+k).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_old_keyword_expansion

Sets the state of the old RCS keyword expansion (+ko, Id and Header only)
attribute.

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_store_compressed

Sets the state of the compressed storage attribute (+C).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_store_deltas

Sets the state of the delta storage attribute (+D).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_store_full_file

Sets the state of the full file storage attribute (+F).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_stored_revisions

Sets the number of revisions to be retained (+S). A value of 0 or undef
indicates no limit on the number of revisions.

=head3 Parameters

=over

=item *

value (Required) - An integer value

=back

=head3 Throws

Nothing

=head2 set_sync_writable

Sets the state of the sync as writable attribute (+w).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 set_use_modtime

Sets the state of the modtime attribute (+m).

=head3 Parameters

=over

=item *

value (Required) - A boolean value indicating the presence or absence of the
attribute.

=back

=head3 Throws

Nothing

=head2 AUTOMETHOD

Method invoked by L<Class::Std/AUTOLOAD>.

=head2 BUILD

Pre-initialization constructor invoked by L<Class::Std/new>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-revision at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-FileType>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::FileType

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-FileType>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-FileType>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-FileType>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-FileType>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

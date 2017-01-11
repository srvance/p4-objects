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

package P4::Objects::Common::BinaryOptions;

use warnings;
use strict;

use Class::Std;

{

our $VERSION = '0.48';

my %options_of : ATTR( init_arg => 'Options' );
my %parsed_options_of : ATTR;

sub START {
    my ($self, $ident, $args_ref) = @_;

    my @options = split / /, $options_of{$ident};

    my $parsed = {};

    for my $opt ( @options ) {
        my $baseopt = $opt;
        $baseopt =~ s/\A(un|no)//;
        $parsed->{$baseopt} = ( $opt eq $baseopt ) ? 1 : 0;
    }

    $parsed_options_of{$ident} = $parsed;

    return;
}

sub AUTOMETHOD {
    my ($self, $ident, @args) = @_;
    my $subname = $_;

    my ($type, $opt) = split /_/, $subname;
    if( exists $parsed_options_of{$ident}->{$opt} ) {
        if( $type eq 'get' ) {
            return sub { return $parsed_options_of{$ident}->{$opt}; };
        }
        elsif( $type eq 'set' ) {
            return sub {
                my ($self, $value) = @_;

                $parsed_options_of{$ident}->{$opt} = $value;

                return;
            };
        }
    }

    return;
}

# PRIVATE AND RESTRICTED METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;
    my $ident = ident $self;

    my @option_words = map {
        $parsed_options_of{$ident}->{$_}    ?   $_
            : ( $_ eq 'locked' )            ?   'unlocked'
                                            :   'no' . $_;
    } sort keys %{$parsed_options_of{$ident}};

    return join( ' ', @option_words );
}

}

1; # End of P4::Objects::Common::BinaryOptions
__END__

=head1 NAME

P4::Objects::Common::BinaryOptions - a common class representing binary form
options

=head1 SYNOPSIS

P4::Objects::Common::BinaryOptions contains the infrastructure common to
handling binary form options as are found in the workspace and label forms in
the Options field. They are binary in that option X means the feature is
enabled while noX or unX means the feature is disabled. The 'locked' option is
the only one that requires the 'un' prefix and has special handling. These
objects stringify to the Perforce option string alphabetized by the base
option name.

This class is not designed to be used in isolation. It should only be used by
those writing P4::Objects form classes that have an Options field.

    package Some::P4::Objects::User;

    use P4::Objects::SomeFormType;

    my $sft = P4::Objects::SomeFormType( {
        Options => 'one two three',
        ...
    } );
    my $opts = $sft->get_options();
    my $one = $opts->get_one();
    $opts->set_one( ! $one );
    my $optionstring = scalar $opts;

=head1 METHODS

=head2 get_*

For each option included in the initial Options string, an accessor is created
consisting of "get_" followed by the base name of the option, i.e. the option
without a "no" or "un" in front of it. It returns either 0 or 1 depending on
whether the option is enabled.

=head3 Throws

Nothing

=head2 new

Constructor only intended for use by derived classes. Automatically loads the
form spec if no initialization parameters are passed.

=head3 Parameters

=over

=item *

Options (Required) - A string list of Perforce form options. The string is a
space delimited set of lowercase words. The words represent binary options of
the form unlocked/locked or noX/X, where X is any word except "locked." The
constructor will parse this list to determine a static table of the available
options for the lifetime of the object and their initial state.

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::IncompleteClass - if the class is used without
properly overriding the abstract methods. The methods that need to be
overridden are:

=back

=head2 set_*

For each option included in the initial Options string, a setter is created
consisting of "set_" followed by the base name of the option, i.e. the option
without a "no" or "un" in front of it.

=head3 Parameters

=over

=item *

value (Required) - The value (0 or 1) for the option.

=back

=head3 Throws

Nothing

=head2 AUTOMETHOD

Method called by L<Class::Std/AUTOLOAD>. Implements dynamically created
setters and getters for initialization options.

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by L<Class::Std>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-common-binaryoptions at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Common-BinaryOptions>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Common::BinaryOptions

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Common-BinaryOptions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Common-BinaryOptions>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Common-BinaryOptions>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Common-BinaryOptions>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

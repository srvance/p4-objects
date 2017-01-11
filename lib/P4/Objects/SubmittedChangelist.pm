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

package P4::Objects::SubmittedChangelist;

use warnings;
use strict;

use base qw( P4::Objects::Changelist );

use Class::Std;

{

my %files_of : ATTR();

our $VERSION = '0.50';

# PRIVATE METHODS

sub _load_spec : RESTRICTED {
    my ($self) = @_;

    $self->_load_changelist( {
        changeno    => $self->get_changeno(),
    } );

    return;
}

sub _get_files_cache : RESTRICTED {
    my ($self) = @_;

    return $files_of{ident $self};
}

sub _set_files_cache : RESTRICTED {
    my ($self, $files) = @_;

    $files_of{ident $self} = $files;

    return;
}

}

1; # End of P4::Objects::SubmittedChangelist
__END__

=head1 NAME

P4::Objects::SubmittedChangelist - A Perforce submitted changelist

=head1 SYNOPSIS

P4::Objects::SubmittedChangelist models a submitted changelist. It is derived
from L<P4::Objects::Changelist>.

=head1 FUNCTIONS

=head2 get_workspace

Returns the name of the L<P4::Objects::Workspace> with which this Changelist
is associated.

=head3 Throws

Nothing

=head2 new

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

changeno (Required) - The changelist number. The allowed values and defaults
are defined by the derived classes. The values seen in Perforce use are
'default', 'new', and an integer, although 'new' is probably not publicly
valid in a programmatic context.

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Changelist/new>

=back

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-submittedchangelist at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-SubmittedChangelist>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::SubmittedChangelist

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-SubmittedChangelist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-SubmittedChangelist>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-SubmittedChangelist>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-SubmittedChangelist>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

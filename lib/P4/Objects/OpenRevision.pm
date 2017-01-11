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

package P4::Objects::OpenRevision;

use warnings;
use strict;

use Data::Dumper;

use Class::Std;

use base qw( P4::Objects::WorkspaceRevision P4::Objects::ChangelistRevision );

{

our $VERSION = '0.46';

my %user_of : ATTR( init_arg => 'user' get => 'user' );

}

1;
__END__

=head1 NAME

P4::Objects::OpenRevision - Information about a single opened revision

=head1 SYNOPSIS

P4::Objects::OpenRevision encapsulates the state of a single open revision in a
workspace.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $ors = $ws->opened(); # Returns ref to OpenRevision array
    ...

=head1 FUNCTIONS

=head2 get_user

Returns the name of the user who has the revision open

=head3 Throws

Nothing

=head2 get_changelist

Returns the changelist number in which the revision is open

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

The parameters for L<P4::Objects::WorkspaceRevision/new>, as well as

=item *

user (Required) - The name of the user who has the revision open

=item *

changelist (Required) - The changelist in which the revision is open

=back

=head3 Throws

Nothing

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-openrevision at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-OpenRevision>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::OpenRevision

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-OpenRevision>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-OpenRevision>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-OpenRevision>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-OpenRevision>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

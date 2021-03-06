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

package P4::Objects::WorkspaceRevision;

use warnings;
use strict;

use Class::Std;

use base qw( P4::Objects::Revision );

{

our $VERSION = '0.24';

my %workspace_of : ATTR( init_arg => 'workspace' get => 'workspace' );
my %localname_of : ATTR( init_arg => 'clientFile' get => 'localname' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    if( ref( $workspace_of{$ident} ) ne 'P4::Objects::Workspace' ) {
        P4::Objects::Exception::InvalidParameter->throw(
            parameter       => 'workspace',
            reason          => 'Must be reference to P4::Objects::Workspace',
        );
    }

    return;
}

}

1; # End of P4::Objects::WorkspaceRevision
__END__

=head1 NAME

P4::Objects::WorkspaceRevision - Information about a single file in a
workspace

=head1 SYNOPSIS

P4::Objects::WorkspaceRevision encapsulates the state of a single file in a
workspace.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $srs = $ws->sync(); # Returns SyncResults
    my $wr_array_ref = $ws->get_results();
    for my $wr ( @{$wr_array_ref} ) {
        do_something_to_workspacerevision( $wr );
    }

=head1 FUNCTIONS

=head2 get_localname

Returns the local pathname of the synced file.

=head3 Throws

Nothing

=head2 get_workspace

Returns a reference to the workspace with which this set of results is
associated.

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

The parameters for L<P4::Objects::Revision/new>, as well as

=item *

workspace (Required) - A reference to a workspace object

=item *

clientFile (Required) - The name of the synced file in the local filesystem

=back

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by L<Class::Std>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-workspacerevision at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-WorkspaceRevision>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::WorkspaceRevision

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-WorkspaceRevision>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-WorkspaceRevision>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-WorkspaceRevision>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-WorkspaceRevision>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

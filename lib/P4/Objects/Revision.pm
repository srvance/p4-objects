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

package P4::Objects::Revision;

use warnings;
use strict;

use P4::Objects::FileType;

use Class::Std::Storable;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.49';

my %depotname_of : ATTR( init_arg => 'depotFile' get => 'depotname' );
my %revision_of : ATTR( init_arg => 'rev' get => 'revision' );
my %type_of : ATTR( get => 'type' );
my %action_of : ATTR( init_arg => 'action' get => 'action' );
my %filesize_of : ATTR( init_arg => 'fileSize' default => '0' get => 'filesize' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    if( defined( $args_ref->{type} ) ) {
        $type_of{$ident} = P4::Objects::FileType->new( {
            type => $args_ref->{type},
        } );
    }

    return;
}

# PRIVATE METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;
    my $ident = ident $self;

    my $depotname = $depotname_of{$ident};
    my $revision = $revision_of{$ident};

    return "$depotname#$revision";
}

}

1; # End of P4::Objects::Revision
__END__

=head1 NAME

P4::Objects::Revision - Information about a single revision in the depot

=head1 SYNOPSIS

P4::Objects::Revision represents a single revision in the depot. A Revision
object stringifies to its depotname and revision number concatenated with a
hash ('#') in between in standard Perforce revision syntax.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $repo = $session->get_repository();
    my $changes = $repo->get_changelists( { maxReturned => 1 } );
    my $cl = $changes->[0];
    my $files = $cl->get_files(); # Returns list of Revisions
    my $first_rev = $files->[0];
    my $depotname = $first_rev->get_depotname();
    ...

=head1 FUNCTIONS

=head2 get_action

Returns the action that created the revision of the file that was synced.

=head3 Throws

Nothing

=head2 get_depotname

Returns the depot pathname of the synced file.

=head3 Throws

Nothing

=head2 get_filesize

Returns the size of the revision that was synced.

=head3 Throws

Nothing

=head2 get_revision

Returns the revision number that was synced.

=head3 Throws

Nothing

=head2 new

Constructor intended primarily for internal use in building the object.

=head3 Parameters

Parameters are passed in an anonymous hash. The key names are taken from the
names that Perforce gives.

=over

=item *

depotFile (Required) - The name of the synced file from the depot

=item *

rev (Required) - The revision of the file that was synced

=item *

type (Optional) - The Perforce type of the revision. Defaults to ''.

=item *

action (Required) - The action (e.g. add, edit, delete, branch) that created
the synced revision

=item *

fileSize (Optional) - The size of the file that was synced. Defaults to 0.

=back

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by L<Class::Std>.

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-revision at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Revision>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Revision

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Revision>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Revision>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Revision>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Revision>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

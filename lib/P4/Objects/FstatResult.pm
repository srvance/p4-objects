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

package P4::Objects::FstatResult;

use warnings;
use strict;

use P4::Objects::FileType;

use Class::Std;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.49';

my %depotname_of : ATTR( init_arg => 'depotFile' get => 'depotname' );
my %localname_of : ATTR( get => 'localname' );
my %depotaction_of : ATTR( get => 'depotaction' );
my %depottype_of : ATTR( get => 'depottype' );
my %depottime_of : ATTR( get => 'depottime' );
my %depotrevision_of : ATTR( get => 'depotrevision' );
my %depotchange_of : ATTR( get => 'depotchange' );
my %depotmodtime_of : ATTR( get => 'depotmodtime' );
my %haverevision_of : ATTR( get => 'haverevision' );
my %openaction_of : ATTR( get => 'openaction' );
my %openchange_of : ATTR( get => 'openchange' );
my %opentype_of : ATTR( get => 'opentype' );
my %openuser_of : ATTR( get => 'openuser' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    # None of these are required, so init them here.
    $localname_of{$ident} = $args_ref->{clientFile};
    $depotaction_of{$ident} = $args_ref->{headAction};
    if( defined( $args_ref->{headType} ) ) {
        $depottype_of{$ident} = P4::Objects::FileType->new( {
            type => $args_ref->{headType},
        } );
    }
    $depottime_of{$ident} = $args_ref->{headTime};
    $depotrevision_of{$ident} = $args_ref->{headRev};
    $depotchange_of{$ident} = $args_ref->{headChange};
    $depotmodtime_of{$ident} = $args_ref->{headModTime};
    $haverevision_of{$ident} = $args_ref->{haveRev};
    $openaction_of{$ident} = $args_ref->{action};
    $openchange_of{$ident} = $args_ref->{change};
    if( defined( $args_ref->{type} ) ) {
        $opentype_of{$ident} = P4::Objects::FileType->new( {
            type => $args_ref->{type},
        } );
    }
    $openuser_of{$ident} = $args_ref->{actionOwner};

    return;
}

sub is_submitted {
    my ($self) = @_;

    return defined( $depottype_of{ident $self} );
}

sub is_open {
    my ($self) = @_;

    return defined( $opentype_of{ident $self} );
}

sub is_synced {
    my ($self) = @_;

    return defined( $haverevision_of{ident $self} );
}

sub is_known {
    my ($self) = @_;

    return defined( $localname_of{ident $self} );
}

# PRIVATE METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;

    my $str = '';
    if( $self->is_synced() ) {
        $str = $self->get_depotname() . '#' . $self->get_haverevision();
    }
    elsif( $self->is_known() ) {
        $str = $self->get_localname();
    }

    return $str;
}

}

1; # End of P4::Objects::FstatResult
__END__

=head1 NAME

P4::Objects::FstatResult - Fstat information for a single file/revision

=head1 SYNOPSIS

P4::Objects::FstatResult encapsulates the information for a single
file/revision. It stringifies to either depotname#revision or localname
depending on its data content.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $repo = $session->get_repository();
    my $results = $repo->fstat( '//some/file/in/perforce.txt' );
    my $fr = $results->[0];
    my $depotname = $fr->get_depotname();
    ...

The data content in the FstatResult is dependent on the state of the file or
revision being queried. For easy categorization, boolean helper methods are
supplied. The name of the getter methods assists in understanding the
categorization.

=over

=item *

The get_depotname method is always valid.

=item *

The other get_depot* methods are present for files that have been previously
submitted to the depot (i.e. not open for add).

=item *

The get_open* methods are present for files that are open in the current
workspace.

=item *

The get_localname method is valid when the file is in the current workspace
and known to Perforce, including files open for add.

=item *

The get_haverevision method is valid for any file that has been synced into
the workspace.

=back

=head1 METHODS

=head2 get_depotaction

Returns the action of the revision in the depot. If the file is open, it is
the action of the have revision.

=head3 Throws

Nothing

=head2 get_depotchange

Returns the change number of the revision in the depot. If the file is open,
it is the change number of the have revision.

=head3 Throws

Nothing

=head2 get_depotmodtime

Returns the time stamp on the file at the time it was submitted.

=head3 Throws

Nothing

=head2 get_depotname

Returns the depot pathname of the file. This is the only attribute that is
always present.

=head3 Throws

Nothing

=head2 get_depotrevision

Returns the revision number of the revision in the depot.

=head3 Throws

Nothing

=head2 get_depottime

Returns the time stamp of the changelist in which the file was submitted.

=head3 Throws

Nothing

=head2 get_depottype

Returns the type of the revision in the depot. If the file is open, it is the
type of the have revision.

=head3 Throws

Nothing

=head2 get_haverevision

Returns the have revision of the file if it is in the workspace.

=head3 Throws

Nothing

=head2 get_localname

Returns the name of the file in the local file system.

=head3 Throws

Nothing

=head2 get_openaction

Returns the action that opened the file if it is open.

=head3 Throws

Nothing

=head2 get_openchange

Returns the change number in which the file is opened if it is open.

=head3 Throws

Nothing

=head2 get_opentype

Returns the type of the open file if it is open.

=head3 Throws

Nothing

=head2 get_openuser

Returns the user who opened the file if it is open.

=head3 Throws

Nothing

=head2 is_known

Boolean return indicating whether the file is known to Perforce either through
prior submission or current open add operation.

=head3 Throws

Nothing

=head2 is_open

Boolean return indicating whether the file is open in the current workspace.

=head3 Throws

Nothing

=head2 is_submitted

Boolean return indicating whether the file was previously submitted.

=head3 Throws

Nothing

=head2 is_synced

Boolean return indicating whether the file is synced in the current workspace.

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

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-fstatresult at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-FstatResult>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::FstatResult

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-FstatResult>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-FstatResult>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-FstatResult>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-FstatResult>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

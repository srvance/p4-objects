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

package P4::Objects::PendingChangelist;

use warnings;
use strict;

use base qw( P4::Objects::Changelist );

use Class::Std;
use Data::Dumper;

{

our $VERSION = '0.50';

sub set_user {
    my ($self, $user) = @_;

    $self->_set_user( $user );

    return;
}

sub set_description {
    my ($self, $user) = @_;

    $self->_set_description( $user );

    return;
}

sub commit {
    my ($self) = @_;
    my $ident = ident $self;

    my $spec = $self->_create_spec_hash();

    my $conn = $self->get_connection();

    # Let exceptions pass
    my $new_changeno = $conn->save_changelist( $spec );

    $self->_load_changelist( {
        changeno    => $new_changeno,
    } );

    return $new_changeno;
}

# TODO: Should I combine add, edit, and delete into an AUTOMETHOD
sub add_files {
    my ($self, @filelist) = @_;

    # TODO: Ensure that this is not a new changelist

    my $conn = $self->get_connection();

    my @args = (
        '-f', # Force acceptance of special characters
    );

    my $changeno = $self->get_changeno();
    # TODO: Test if this is a numbered changelist if and when we support
    #       default changelists. Pulled the test out for complete coverage.
    push @args, '-c', $changeno;

    push @args, @filelist;

    # Pass errors
    my $result = $conn->run( 'add', @args );
    $self->_load_changelist( {
        changeno    => $changeno,
    } );

    return;
}

sub edit_files {
    my ($self, @filelist) = @_;

    # TODO: Ensure that this is not a new changelist

    my $conn = $self->get_connection();

    my @args = (
    );

    my $changeno = $self->get_changeno();
    # TODO: Test if this is a numbered changelist if and when we support
    #       default changelists. Pulled the test out for complete coverage.
    push @args, '-c', $changeno;

    push @args, @filelist;

    # Pass errors
    my $result = $conn->run( 'edit', @args );
    $self->_load_changelist( {
        changeno    => $changeno,
    } );

    return;
}

sub reopen_files {
    my ($self, @filelist) = @_;

    # TODO: Ensure that this is not a new changelist

    my $conn = $self->get_connection();

    my @args = (
    );

    my $changeno = $self->get_changeno();
    # TODO: Test if this is a numbered changelist if and when we support
    #       default changelists. Pulled the test out for complete coverage.
    push @args, '-c', $changeno;

    push @args, @filelist;

    # Pass errors
    my $result = $conn->run( 'reopen', @args );
    $self->_load_changelist( {
        changeno    => $changeno,
    } );

    return;
}

sub delete_files {
    my ($self, @filelist) = @_;

    # TODO: Ensure that this is not a new changelist

    my $conn = $self->get_connection();

    my @args = (
    );

    my $changeno = $self->get_changeno();
    # TODO: Test if this is a numbered changelist if and when we support
    #       default changelists. Pulled the test out for complete coverage.
    push @args, '-c', $changeno;

    push @args, @filelist;

    # Pass errors
    my $result = $conn->run( 'delete', @args );
    $self->_load_changelist( {
        changeno    => $changeno,
    } );

    return;
}

sub submit {
    my ($self) = @_;

    my $spec = $self->_create_spec_hash();

    my $conn = $self->get_connection();

    # Let exceptions pass
    my $new_changeno = $conn->submit_changelist( $spec );

    return $new_changeno;
}

# PRIVATE METHODS

sub _load_changelist : RESTRICTED {
    my ($self, $args) = @_;

    $self->SUPER::_load_changelist( $args );

    # Ensure that the changelist is pending or new
    if( ! $self->is_pending() && ! $self->is_new() ) {
        P4::Objects::Exception::InappropriateChangelist->throw(
            changeno => $self->get_changeno(),
        );
    }

    return;
}

sub _load_spec {
    my ($self) = @_;

    # TODO: Need to consider both uses cases for new():
    #       1. Creating a new pending changelist by creating a new object
    #       2. Loading  an existing pending changelist in a new object
    if( defined( $self->get_changeno() ) ) {
        $self->_load_changelist( {
            changeno    => $self->get_changeno(),
        } );
    }
    else {
        $self->_load_changelist( {
            workspace   => $self->get_workspace(),
        } );
    }

    return;
}

sub _create_spec_hash {
    my ($self) = @_;

    my $files = $self->get_files();
    return {
        Change          => $self->get_changeno(),
        Date            => $self->get_date(),
        Client          => $self->get_workspace(),
        User            => $self->get_user(),
        Status          => $self->get_status(),
        Description     => $self->get_description(),
        Jobs            => $self->get_jobs(),
        Files           => $self->_ensure_arrayref(
                            map { $_->get_depotname() } @{$files}
                        ),
    };
}

sub _get_files_cache : RESTRICTED {
    return;
}

sub _set_files_cache : RESTRICTED {
    return;
}

}

1; # End of P4::Objects::PendingChangelist
__END__

=head1 NAME

P4::Objects::PendingChangelist - A Perforce pending changelist

=head1 SYNOPSIS

P4::Objects::PendingChangelist models a pending changelist. It is derived
from L<P4::Objects::Changelist>. This can represent a default, new or numbered
pending changelist.

=head1 FUNCTIONS

=head2 add_files

Performs a Perforce add operation on the specified files. Automatically forces
acceptance of special characters.

=head3 Parameters

=over

=item *

files (Required) - One or more files to add to the changelist

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 commit

Saves the state of the changelist. This is only necessary for changes in
attributes, not for changes in open files.

=head3 Returns

The changelist number of the saved spec. This will only change when the spec
being saved was a new spec.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/save_changelist>

=back

=head2 delete_files

Performs a Perforce delete operation on the specified files.

=head3 Parameters

=over

=item *

files (Required) - One or more files to delete in the changelist

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 edit_files

Performs a Perforce edit operation on the specified files.

=head3 Parameters

=over

=item *

files (Required) - One or more files to edit in the changelist

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 reopen_files

Performs a Perforce reopen for the files into the pending changelist

=head3 Parameters

=over

=item *

files (Required) - One or more files to edit in the changelist

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 get_workspace

Returns the name of the L<P4::Objects::Workspace> with which this Changelist
is associated.

=head3 Throws

Nothing

=head2 new

=head3 Parameters

Parameters are passed in an anonymous hash and must include either of the
following:

=over

=item *

changeno - The changelist number for the pending changelist to be retrieved.
If this is present, it will override the presence of the workspace parameter.

=item *

workspace - When provided without the changeno parameter, identifies the
L<P4::Objects::Workspace> with which this new PendingChangelist should be
associated. It is ignored if the changeno parameter is present, as the
workspace for that changeno has already been defined.

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 set_description

Sets the description for the changelist.

=head3 Throws

Nothing

=head2 set_user

Sets the name of the user owning the changelist.

=head3 Throws

Nothing

=head2 submit

Submits the pending changelist. The pending changelist object is invalid after
a successful submission.

=head3 Returns

The number of the resulting submitted changelist.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/submit_changelist>

=back

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-pendingchangelist at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-PendingChangelist>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::PendingChangelist

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-PendingChangelist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-PendingChangelist>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-PendingChangelist>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-PendingChangelist>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

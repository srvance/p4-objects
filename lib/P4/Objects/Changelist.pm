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

package P4::Objects::Changelist;

use warnings;
use strict;

use P4::Objects::Exception;

use Class::Std;

use base qw( P4::Objects::Common::Form );

{

our $VERSION = '0.50';

my %changeno_of : ATTR( get => 'changeno' );
my %date_of : ATTR( get => 'date' );
my %workspace_of : ATTR( get => 'workspace' );
my %user_of : ATTR( get => 'user' );
my %status_of : ATTR( get => 'status' );
my %description_of : ATTR( get => 'description' );
my %jobs_of : ATTR( get => 'jobs' );

sub BUILD {
    my ($self, $ident, $args_ref) = @_;

    if( defined( $args_ref->{changeno} ) ) {
        $changeno_of{$ident} = $args_ref->{changeno};
    }

    if( defined( $args_ref->{workspace} ) ) {
        $workspace_of{$ident} = $args_ref->{workspace};
    }

    return;
}

sub START {
    my ($self, $ident, $args_ref) = @_;

    if( ! defined( $changeno_of{$ident} ) ) {
        P4::Objects::Exception::MissingParameter->throw(
                        parameter => 'changeno'
        );
    }

    if( ! defined( $jobs_of{$ident} ) ) {
        $jobs_of{$ident} = [];
    }

    return;
}

sub is_numbered {
    my ($self) = @_;

    return $self->get_changeno() =~ /\A\d+\Z/;
}

sub is_default {
    my ($self) = @_;

    # This condition ordering was chosen (i.e. empirically determined) for
    # coverage testability. Not all orderings can be fully covered.
    return ! $self->is_new()
        && ! $self->is_numbered()
        && $self->is_pending();
}

sub is_new {
    my ($self) = @_;

    return $self->get_changeno() eq 'new' && $self->get_status() eq 'new';
}

sub is_pending {
    my ($self) = @_;

    return $self->get_changeno() ne 'new' && $self->get_status() eq 'pending';
}

sub is_submitted {
    my ($self) = @_;

    return $self->get_changeno() ne 'new' && $self->get_status() eq 'submitted';
}

sub get_files {
    my ($self) = @_;

    my $files = $self->_get_files_cache();

    # If we've already loaded the files, return them.
    if( defined( $files ) ) {
        return $files;
    }

    # We know it's not defined, but there's no reason not to say it's empty
    if( $self->is_default() || $self->is_new() ) {
        return [];
    }

    # Load the files from the server
    my $conn = $self->get_connection();

    my $result = $conn->run( 'describe', '-s', $self->get_changeno() );

    my $revisions = [];

    # The format here is screwy. The fields of the respective revisions are
    # returned in hash elements in the result. If there is only on revision,
    # the elements have a string as a value. If there are multiple revisions,
    # the elements have a list ref as a value and corresponding elements
    # between the lists go together to define a revision.

    # Here we coerce them all into array refs for common handling.
    my $depotfiles = $self->_ensure_arrayref( $result->{depotFile} );
    my $revs = $self->_ensure_arrayref( $result->{rev} );
    my $types = $self->_ensure_arrayref( $result->{type} );
    my $actions = $self->_ensure_arrayref( $result->{action} );

    my $session = $self->get_session();
    for my $depotfile ( @{$depotfiles} ) {
        push @{$revisions}, P4::Objects::Revision->new( {
            session         => $session,
            depotFile       => $depotfile,
            rev             => shift @{$revs},
            type            => shift @{$types},
            action          => shift @{$actions},
        } );
    }

    $self->_set_files_cache( $revisions );

    return $revisions;
}

# PRIVATE METHODS

sub _set_date : RESTRICTED {
    my ($self, $date) = @_;

    $date_of{ident $self} = $self->_ensure_epoch_time( $date );

    return;
}

sub _set_user : RESTRICTED {
    my ($self, $user) = @_;

    $user_of{ident $self} = $user;

    return;
}

sub _set_description : RESTRICTED {
    my ($self, $description) = @_;

    $description_of{ident $self} = $description;

    return;
}

sub _set_status : RESTRICTED {
    my ($self, $status) = @_;

    $status_of{ident $self} = $status;

    return;
}

sub _get_files_cache : RESTRICTED {  ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

sub _set_jobs : RESTRICTED {
    my ($self, $jobs) = @_;

    $jobs_of{ident $self} = $jobs;

    return;
}

sub _set_files_cache : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self, $files) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

sub _set_attrs_from_spec : RESTRICTED {
    my ($self, $spec) = @_;
    my $ident = $self->ident();

    # Support the Perforce tag 'change' and 'Change'
    # and the P4::Objects tag 'changeno'
    $changeno_of{$ident} = $spec->{change}
                                ? $spec->{change}
                                : $spec->{Change}
                                    ? $spec->{Change}
                                    : $spec->{changeno};
    # Support both the Perforce tags 'time' and 'Date'
    # the P4::Objects tag 'date'
    $self->_set_date(
            $spec->{time}       ? $spec->{time}
        :   $spec->{Date}       ? $spec->{Date}
        :   $spec->{date}
    );
    # Support both variations on the Perforce tag, 'user' and 'User'
    $user_of{$ident} = $spec->{user}
                                ? $spec->{user}
                                : $spec->{User};
    # Support the Perforce tags 'client' and 'Client'
    # and the P4::Objects tag 'workspace'
    $workspace_of{$ident} = $spec->{client}
                                ? $spec->{client}
                                : $spec->{Client}
                                    ? $spec->{Client}
                                    : $spec->{workspace};
    # Support both variations on the Perforce tag, 'status' and 'Status'
    $status_of{$ident} = $spec->{status}
                                ? $spec->{status}
                                : $spec->{Status};
    # Support the Perforce tags 'desc' and 'Description'
    # and the P4::Objects tag 'description'
    $description_of{$ident} = $spec->{desc}
                                ? $spec->{desc}
                                : $spec->{Description}
                                    ? $spec->{Description}
                                    : $spec->{description};
    # Support the Perforce tag 'Jobs' (from change)
    # TODO: Support the Perforce tag 'job' (from describe)
    #       and the P4::Objects tag 'jobs' if necessary
    $jobs_of{$ident} =
            $spec->{Jobs}       ?   $spec->{Jobs}
        :   [];

    return;
}

sub _load_changelist : RESTRICTED {
    my ($self, $args ) = @_;

    my $changeno = $args->{changeno};
    my $workspace = $args->{workspace};

    my @args = (
        'change',
        '-o',
    );

    if( defined( $changeno ) ) {
        push @args, $changeno;
    }

    my $conn = $self->get_connection();

    if( defined( $workspace ) ) {
        unshift @args, { workspace => $workspace };
    }

    # Pass errors
    my $result = $conn->run( @args );

    $self->_set_attrs_from_spec( $result );

    return;
}

sub _load_spec : RESTRICTED { ## no critic (RequireFinalReturn)
    my ($self) = @_;

    P4::Objects::Exception::IncompleteClass->throw(
        class       => ref( $self ),
    );
}

sub _as_num : STRINGIFY {
    my ($self) = @_;

    return $self->get_changeno();
}

}

1; # End of P4::Objects::Changelist
__END__

=head1 NAME

P4::Objects::Changelist - a base representation of a Perforce changelist

=head1 SYNOPSIS

P4::Objects::Changelist implements the basic behavior associated with all
changelists. This class is not intended to be instantiated. Instead use the
derived classes L<P4::Objects::SubmittedChangelist> and
L<P4::Objects::PendingChangelist>.

=head1 FUNCTIONS

=head2 get_changeno

Returns the change number for this changelist. For new changelists, this will
be 'new'. Otherwise it will be a number. Default changelists are not
supported.

=head3 Throws

Nothing

=head2 get_date

Returns the creation date for this changelist as a number of epoch seconds.

=head3 Throws

Nothing

=head2 get_description

Returns the description for the changelist.

=head3 Throws

Nothing

=head2 get_files

Returns a reference to the array of L<P4::Objects::Revision> objects listing
the files associated with this changelist. This will incur a connection to the
server if the list of files has not been loaded yet or if there are no files
associated with the changelist.

=head3 Throws

Nothing

=head2 get_jobs

Returns a reference to the list of string names of jobs that this changelist
fixes.

=head3 Throws

Nothing

=head2 get_status

Returns the status of the changelist. Default changelists are not supported.

=head3 Throws

Nothing

=head2 get_user

Returns the name of the user who created the changelist.

=head3 Throws

Nothing

=head2 get_workspace

Returns the name of the L<P4::Objects::Workspace> with which this Changelist
is associated.

=head3 Throws

Nothing

=head2 is_numbered

Returns true if the current state of this object indicates that it represents
a numbered changelist. Returns false otherwise.

=head3 Throws

Nothing

=head2 is_default

Returns true if the current state of this object indicates that it represents
a default changelist. Returns false otherwise.

=head3 Throws

Nothing

=head2 is_existing

Returns whether the form already exists on the server or not.

=head3 Throws

Nothing

=head2 is_new

Returns true if the current state of this object indicates that it represents
a new changelist. Returns false otherwise.

=head3 Throws

Nothing

=head2 is_pending

Returns true if the current state of this object indicates that it represents
a pending changelist. Returns false otherwise.

=head3 Throws

Nothing

=head2 is_submitted

Returns true if the current state of this object indicates that it represents
a submitted changelist. Returns false otherwise.

=head3 Throws

Nothing

=head2 new

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

changeno (Required) - The changelist number. May be passed either directly or
as part of the attrs hash. The allowed values and defaults are defined by the
derived classes. The values seen in Perforce use are 'default', 'new', and an
integer, although 'new' is probably not publicly valid in a programmatic
context.

=item *

workspace (Optional) - Identifies the L<P4::Objects::Workspace> with which
this Changelist is associated.

=item *

attrs (Optional) - A hash of changelist attributes.

=back

=head3 Throws

=over

=item *

Error::Simple - if the changeno parameter is omitted the '-text' key of the
exception starts with 'Missing initializer label' and contains the parameter
name consistent with L<Class::Std>.

=back

=head2 BUILD

Pre-initialization constructor invoked by L<Class::Std>

=head2 START

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-changelist at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Changelist>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Changelist

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Changelist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Changelist>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Changelist>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Changelist>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

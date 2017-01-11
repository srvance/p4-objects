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

package P4::Objects::Repository;

use warnings;
use strict;

use Error qw( :try );
use P4::Objects::ChangelistRevision;
use P4::Objects::Exception;
use P4::Objects::FstatResult;
use P4::Objects::IntegrationRecord;
use P4::Objects::PendingChangelist;
use P4::Objects::SubmittedChangelist;
use P4::Objects::Workspace;

use Class::Std;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.47';

sub START {
    my ($self, $ident, $args_ref) = @_;

    $self->_weaken_session();

    return;
}

sub get_workspaces {
    my ($self) = @_;
    my $ident = ident $self;

    my $conn = $self->get_connection();

    my $workspaces = $conn->run( 'clients' );

    my @results;
    my $session = $self->get_session();
    foreach my $wshash ( @{$workspaces} ) {
        my $wsname = $wshash->{client};
        push @results, P4::Objects::Workspace->new( {
                                session => $session,
                                name => $wsname,
                                attrs => $wshash,
        } );
    }

    return \@results;
}

sub get_changelists {
    my ($self, $filter) = @_;
    my $ident = ident $self;

    my $conn = $self->get_connection();

    my @args = (
        '-l',   # Long descriptions
        '-t',   # Time as well as date
    );
    my $filespec;

    if( defined( $filter ) ) {
        # Take care of and remove filespecs first
        if( defined( $filter->{filespec} ) ) {
            $filespec = ref( $filter->{filespec} ) eq 'ARRAY'
                ? $filter->{filespec}
                : [ $filter->{filespec} ];

            # Remove from the keys we will check
            delete $filter->{filespec};
        }

        my %filter_flags = (
            maxReturned     =>  '-m',
            status          =>  '-s',
            workspace       =>  '-c',
        );

        for my $parm ( keys %$filter ) {
            if( defined( $filter_flags{$parm} ) ) {
                push @args, $filter_flags{$parm}, $filter->{$parm};
            }
            # TODO: Add output modifiers here
            else {
                P4::Objects::Exception::UnsupportedFilter->throw(
                            filter  =>  $parm,
                );
            }
        }
    }

    my $changes = $conn->run( 'changes', @args, @{$filespec} );

    my @results = map {
        $self->_create_appropriate_changelist( $_ )
    } @{$changes};

    return \@results;
}

sub fstat {
    my ($self, @filelist) = @_;
    my $ident = ident $self;

    my $conn = $self->get_connection();

    my $stats = $conn->run( 'fstat', @filelist );

    my @results;
    my $session = $self->get_session();
    for my $stat ( @{$stats} ) {
        my %copy = %{$stat};
        $copy{session} = $session;
        push @results, P4::Objects::FstatResult->new( \%copy );
    }

    return \@results;
}

sub get_fixes {
    my ($self, @filelist) = @_;
    my $options = ();

    if( ref( $filelist[0] ) eq 'HASH' ) {
        $options = shift @filelist;
    }

    my %optionmap = (
        report_integrate_history    => '-i',
    );

    my @args = ();

    for my $opt ( keys %{$options} ) {
        if( $options->{$opt} && $optionmap{$opt} ) {
            push @args, $optionmap{$opt};
        }
    }

    my $conn = $self->get_connection();

    my $fixes = $conn->run( 'fixes', @args, @filelist );

    my @joblist = map { $_->{Job} } @{$fixes};

    return \@joblist;
}

sub get_changelist {
    my ($self, $changeno) = @_;

    my $conn = $self->get_connection();

    my $clhash;
    try {
        $clhash = $conn->run( 'change', '-o', $changeno );
    }
    # Perforce reports an unknown change as an error but we just want to
    # return undef.
    catch P4::Objects::Exception::P4::RunError with { ## no critic 'Dynamic::ValidateAgainstSymbolTable'
        my $e = shift;

        # TODO: I was going to only rethrow if I didn't find the string "Change
        # $changeno unknown.\n" but I don't know how to generate a RunError
        # for another condition to test against, so for now, I'm swallowing
        # the error to get coverage.

        my $unknowns = scalar
            grep { /\AChange $changeno unknown.\n/ } @{$e->errors()};
        if( $unknowns == 0 ) {
            $e->rethrow();
        }
    };

    my $cl;
    if( defined( $clhash ) ) {
        $cl = $self->_create_appropriate_changelist( $clhash );
    }

    return $cl;
}

sub integrated {
    my ($self, @files) = @_;

    my $conn = $self->get_connection();

    my $results = $conn->run( 'integrated', @files );

    my $integrations = [];
    my $session = $self->get_session();
    for my $record ( @{$results} ) {
        $record->{session} = $session;
        push @{$integrations}, P4::Objects::IntegrationRecord->new( $record );
        delete $record->{session};
    }

    return $integrations;
}

sub files {
    my ($self, @args) = @_;

    my $conn = $self->get_connection();

    my $results = $conn->run( 'files', @args );

    my $files = [];
    my $session = $self->get_session();
    for my $rev ( @{$results} ) {
        $rev->{session} = $session;
        push @{$files}, P4::Objects::ChangelistRevision->new( $rev );
        delete $rev->{session};
    }

    return $files;
}

sub get_jobs {
    my ($self, $filter) = @_;

    my $conn = $self->get_connection();

    my $filespec;

    if( defined( $filter ) ) {
        # Take care of and remove filespecs first
        if( defined( $filter->{filespec} ) ) {
            $filespec = ref( $filter->{filespec} ) eq 'ARRAY'
                ? $filter->{filespec}
                : [ $filter->{filespec} ];

            # Remove from the keys we will check
            delete $filter->{filespec};
        }
    }

    my $results = $conn->run( 'jobs', @{$filespec} );

    my @jobs = map { $_->{Job} } @{$results};

    return \@jobs;
}

# PRIVATE METHODS

sub _create_appropriate_changelist : PRIVATE {
    my ($self, $clhash) = @_;

    my $cl;
    my $session = $self->get_session();
    my $status = $self->_get_changelist_hash_status( $clhash );
    my $wsname = $self->_get_changelist_hash_client( $clhash );
    if( $status eq 'submitted' ) {
        $cl = P4::Objects::SubmittedChangelist->new( {
                            session     => $session,
                            workspace   => $wsname,
                            attrs       => $clhash,
        } );
    }
    else { # Numbered changelists can only be submitted or pending
        my $changeno = $self->_get_changelist_hash_change( $clhash );
        $cl = P4::Objects::PendingChangelist->new( {
                            session     => $session,
                            workspace   => $wsname,
                            changeno    => $changeno,
        } );
    }

    return $cl;
}

# TODO: Good candidate for common base class or Changelist class method
sub _get_changelist_hash_status : PRIVATE {
    my ($self, $clhash) = @_;

    my $status = defined( $clhash->{status} )   ? $clhash->{status}
                                                : $clhash->{Status};

    return $status;
}

# TODO: Good candidate for common base class or Changelist class method
sub _get_changelist_hash_client : PRIVATE {
    my ($self, $clhash) = @_;

    my $client = defined( $clhash->{client} )   ? $clhash->{client}
                                                : $clhash->{Client};

    return $client;
}

# TODO: Good candidate for common base class or Changelist class method
sub _get_changelist_hash_change : PRIVATE {
    my ($self, $clhash) = @_;

    my $change = defined( $clhash->{change} )   ? $clhash->{change}
                                                : $clhash->{Change};

    return $change;
}

sub _as_str : STRINGIFY {
    my ($self) = @_;

    my $session = $self->get_session();
    my $port = $session->get_port();

    return defined( $port ) ? $port : '';
}

}

1; # End of P4::Objects::Repository
__END__

=head1 NAME

P4::Objects::Repository - a representation for the SCM repository as a whole

=head1 SYNOPSIS

P4::Objects::Repository contains the general listing functions that are
associated with a Perforce instance but are more global than any single
entity. The primary category of functions are the listing functions, e.g.
most of the plural subcommands from the command line. It stringifies to the
port value from the associated L<P4::Objects::Session>.

    use P4::Objects;

    ...
    my $repo = $session->get_repository();
    my $changelists = $repo->get_changelists();
    ...

=head1 FUNCTIONS

=head2 files

Returns a reference to a list of L<P4::Objects::ChangelistRevision> objects,
each representing a Perforce file, just like 'p4 files'.

=head3 Parameters

=over

=item *

rev (Required) - One or more revision specifiers

=back

=head3 Throws

=over

=item *

Exceptions from L<Connection/run>

=back

=head2 fstat

Returns a reference to a list of L<P4::Objects::FstatResult> objects
describing the file statistics for the specified files, just like 'p4 fstat'.

=head3 Throws

=over

=item *

Exceptions from L<Connection/run>

=back

=head2 get_changelist

Returns either a L<P4::Objects::SubmittedChangelist> or a
L<P4::Objects::PendingChangelist> object representing the specified
changelist, as appropriate. Returns undef if the changelist does not exist on
the server.

=head3 Parameters

=over

=item *

changeno (Required) - The changelist number to return an object for

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 get_changelists

Returns a list of L<P4::Objects::SubmittedChangelist> and
L<P4::Objects::PendingChangelist> objects as appropriate in descending
order for those changelists that match the query. This is the P4::Objects
implementation of the 'p4 changes' command.

=head3 Parameters

=over

=item *

filter (Optional) - reference to a hash containing filter parameters for the
results. Supported values and their corresponding Perforce command line flags
are:

=over

=item *

maxReturned (-m)

=item *

status (-s)

=item *

workspace (-c)

=item *

filespec - the arguments to the changes command. A single filespec can be
passed as a string or an array. Multiple filespecs should be passed as an
array.

=back

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::UnsupportedFilter - if an invalid or unsupport filter
parameter is passed

=item *

Exceptions from L</get_session>

=item *

Exceptions from L<Connection/run>

=back

=head2 get_fixes

Returns a reference to a list of job names that fix the specified files.
Implements the 'fixes' command.

=head3 Parameters

=over

=item *

options (Optional) - reference to a hash containing flags to modify the
behavior of the Perforce call. Supported values and their corresponding
Perforce command line flags are:

=over

=item *

report_integrate_history (-i)

=back

=item *

filelist (Optional) - a list of file specs for which the fix associations are
desired

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 get_jobs

Returns a reference to a list of job names that match the filter. Implements
the 'jobs' command.

=head3 Parameters

=over

=item *

filter (Optional) - An anonymous hash defining a filter corresponding to the
options to the 'jobs' command. Available hash keys are:

=over

=item *

filespec (Optional) - A string or reference to an array of strings that are
Perforce file or revision specifications. The results will only be jobs that
apply to those files or revisions.

=back

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>

=back

=head2 get_workspaces

Returns a list of L<P4::Objects::Workspace> objects from the repository.

=head3 Throws

=over

=item *

Exceptions from L</get_session>

=item *

Exceptions from L<Connection/run>

=back

=head2 integrated

Returns reference to a list of submitted integration records for the specified
files, if any.  Equivalent to the Perforce 'integrated' command.

=head3 Parameters

=over

=item *

files (Optional) - If specified, restricts the list of integration records to
those targeting the specified files.

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/run>.

=back

=head2 new

=head3 Parameters

Only inherited parameters.

=head3 Throws

Nothing

=head2 START

Pre-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-repository at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Repository>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Repository

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Repository>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Repository>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Repository>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Repository>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

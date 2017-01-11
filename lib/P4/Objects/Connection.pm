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

package P4::Objects::Connection;

use warnings;
use strict;

use Class::Std;
use Error qw( :try );
use P4 ();
use P4::Objects::Exception;
use Scalar::Util qw( looks_like_number );

use base qw( P4::Objects::BasicConnection );

{

our $VERSION = '0.52';

sub save_changelist {
    my ($self, $spec) = @_;
    my $p4 = $self->get_p4();

    $self->connect();
    my $result = $p4->SaveChange( $spec );
    if( $p4->ErrorCount() > 0 ) {
        my $errors = $self->_get_errors();
        P4::Objects::Exception::P4::BadSpec->throw(
            errorcount  =>  $p4->ErrorCount(),
            errors      =>  $errors,
        );
    }
    else {
        # This pattern deliberately only matches the final message from a save
        # of a changelist. It's designed to match either of the following two
        # lines:
        #     Change ##### created
        #     Change ##### updated
        # and extract the changelist number from it. If the changelist fixes a
        # job, the above messages may be followed by " fixing X job(s)" which
        # is ignored.
        # TODO: Do I need to test for an empty result? Should only occur on
        #       error.
        # TODO: Need to test the "updated" case.
        $result =~ s/Change (\d+) (created|updated).*/$1/;
        if( ! looks_like_number( $result ) ) {
            P4::Objects::Exception::P4::UnexpectedOutput->throw(
                type        => 'Change submission result',
                output      => $result,
            );
        }
    }

    return $result;
}

sub save_workspace {
    my ($self, $spec) = @_;

    $self->_save_spec( 'Client', $spec );

    return;
}

sub save_label {
    my ($self, $spec) = @_;

    $self->_save_spec( 'Label', $spec );

    return;
}

sub save_job {
    my ($self,$spec) = @_;

    $self->_save_spec( 'Job', $spec );

    return;
}

sub save_branch {
    my ($self, $spec ) = @_;
    $self->_save_spec( 'Branch', $spec );
    return;
}

sub submit_changelist {
    my ($self, $spec) = @_;
    my $p4 = $self->get_p4();

    $self->connect();
    my $result = $p4->SubmitSpec( $spec );
    my $retval;
    if( $p4->ErrorCount() > 0 ) {
        my $errors = $self->_get_errors();
        P4::Objects::Exception::P4::BadSpec->throw(
            errorcount  =>  $p4->ErrorCount(),
            errors      =>  $errors,
        );
    }
    else {
        foreach my $item ( @$result ) {
            if( defined( $item->{submittedChange} ) ) {
                $retval = $item->{submittedChange};
                last;
            }
        }
    }

    return $retval;
}

sub sync_workspace {
    my ($self, $parms) = @_;

    my $workspace = $parms->{workspace};
    if( ! defined( $workspace ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   =>  'workspace',
        )
    }

    my %parm_args = (
        force_sync      => '-f',
        omit_files      => '-k',
        preview         => '-n',
    );

    my %ignore_parm_args = map { $_ => 1 } (
        'workspace',
        'filespec',
    );

    my @args = $self->_convert_parms_to_args(
        $parms,
        \%parm_args,
        \%ignore_parm_args,
    );

    my $p4 = $self->get_p4();

    # TODO: Fix problem with setting values if already connected.
    $self->connect();

    # Override the session setting
    $p4->SetClient( $workspace );
    my $results;
    try {
        $results = $self->run( 'sync', @args );
    }
    catch P4::Objects::Exception::P4::RunError with { ## no critic 'Dynamic::ValidateAgainstSymbolTable'
        my $e = shift;
        P4::Objects::Exception::P4::SyncError->throw(
            results         => $e->results(),
            errorcount      => $e->errorcount(),
            errors          => $e->errors(),
            warningcount    => $e->warningcount(),
            warnings        => $e->warnings(),
        );
    };

    return ( $results, $self->_get_warnings() );
}

sub integrate_workspace {
    my ($self, $parms) = @_;

    my $workspace = $parms->{workspace};
    if( ! defined( $workspace ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   =>  'workspace',
        )
    }

    my %parm_args = (
        ignore_deletes  => '-Di',
        compute_base    => '-o',
        preview         => '-n',
        branch          => { option => '-b',
                             optarg => 1 },
        from_branchrev  => { option => '-s',
                             optarg => 1 },
        reverse         => '-r',
    );

    my %ignore_parm_args = map { $_ => 1 } (
        'workspace',
        'filespec',
    );

    my @args = $self->_convert_parms_to_args(
        $parms,
        \%parm_args,
        \%ignore_parm_args,
    );

    my $p4 = $self->get_p4();

    # TODO: Fix problem with setting values if already connected.
    $self->connect();

    # Override the session setting
    $p4->SetClient( $workspace );
    my $results;
    try {
        $results = $self->run( 'integrate', @args );
    }
    catch P4::Objects::Exception::P4::RunError with { ## no critic 'Dynamic::ValidateAgainstSymbolTable'
        my $e = shift;
        P4::Objects::Exception::P4::IntegrationError->throw(
            results         => $e->results(),
            errorcount      => $e->errorcount(),
            errors          => $e->errors(),
            warningcount    => $e->warningcount(),
            warnings        => $e->warnings(),
        );
    };

    return ( $results, $self->_get_warnings() );
}


sub get_workspace_opened {
    my ($self, $wsname) = @_;

    if( ! defined( $wsname ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   =>  'workspace',
        )
    }

    my @args = (
        '-C'    => $wsname,
    );

    my $results = $self->run( 'opened', @args );

    return $results;
}

sub resolve_files {
    my ($self, $parms) = @_;

    my $workspace = $parms->{workspace};
    if( ! defined( $workspace ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   =>  'workspace',
        )
    }

    # TODO: Remove this when the more general resolve command is supported
    if( ! defined( $parms->{preview} ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   => 'preview',
        );
    }

    # TODO: Remove this when the more general resolve command is supported
    if( ! $parms->{preview} ) {
        P4::Objects::Exception::InvalidParameter->throw(
            parameter   => 'preview',
            reason      => 'Only true values for preview are currently'
                            . ' supported.',
        );
    }

    my %parm_args = (
        preview         => '-n',
    );

    my %ignore_parm_args = map { $_ => 1 } (
        'workspace',
    );

    my @args = $self->_convert_parms_to_args(
        $parms,
        \%parm_args,
        \%ignore_parm_args,
    );

    my $p4 = $self->get_p4();

    $self->connect();

    $p4->SetClient( $workspace );
    my $results;
    $results = $self->run( 'resolve', @args );

    return ( $results, $self->_get_warnings() );
}

sub resolved_files {
    my ($self, $ws) = @_;

    if( ! defined( $ws ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   => 'workspace',
        );
    }

    my $p4 = $self->get_p4();

    $self->connect();

    $p4->SetClient( $ws );
    my $results = $self->run( 'resolved' );

    return $results;
}

sub diff_files {
    my ($self, $parms) = @_;

    my $workspace = $parms->{workspace};
    if( ! defined( $workspace ) ) {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   =>  'workspace',
        )
    }

    my %parm_args = (
        find_edits      => '-se',
        find_deletes    => '-sd',
    );

    my %ignore_parm_args = map { $_ => 1 } (
        'workspace',
    );

    my @args = $self->_convert_parms_to_args(
        $parms,
        \%parm_args,
        \%ignore_parm_args,
    );

    my $p4 = $self->get_p4();

    # TODO: Fix problem with setting values if already connected.
    $self->connect();

    # Override the session setting
    $p4->SetClient( $workspace );
    my $results = $self->run( 'diff', @args );

    return $results;
}

# PRIVATE AND RESTRICTED METHODS

sub _save_spec : PRIVATE {
    my ($self, $type, $spec) = @_;
    my $p4 = $self->get_p4();
    $self->connect();
    # We're not going to check this because it's strictly internal.
    my $method = "Save\u$type";
    $p4->$method( $spec );
    if( $p4->ErrorCount() > 0 ) {
        my $errors = $self->_get_errors();
        P4::Objects::Exception::P4::BadSpec->throw(
            errorcount  =>  $p4->ErrorCount(),
            errors      =>  $errors,
        );
    }

    return;
}

sub _requires_arrayref : RESTRICTED {
    my ($self, $cmd) = @_;

    # These are in alphabetical order. Columns are used for synonyms.
    my %requires_array = map { $_ => 1 } qw/
        clients     workspaces
        changes     changelists
        diff
        dirs
        branches
        files
        fixes
        fstat
        integrated  integed
        integrate   integ
        jobs
        opened
        resolve
        resolved
        sync        get
        where
    /;

    return $requires_array{$cmd};
}

sub _initialize_p4 : RESTRICTED {
    my ($self) = @_;
    my $ident = ident $self;
    my $p4 = $self->get_p4();

    # Get the user's settings from the Session
    my $session = $self->get_session();
    my $port = $session->get_port();
    my $user = $session->get_user();
    my $host = $session->get_host();
    my $client = $session->_get_workspace_name();
    my $charset = $session->get_charset();

    # Apply the environment to the connection in case it's changed from the
    # initially loaded values.
    $p4->SetPort( $port );
    $p4->SetUser( $user );
    $p4->SetHost( $host );
    $p4->SetClient( $client );
    $p4->SetCharset( $charset ) if( defined( $charset ) && length( $charset ) );
    $p4->ParseForms();

    return;
}

#
# If the parm_args values is a reference to a hash, it must contain
# an "option" field that is the option value and may contain an
# optarg field that is true of the option has an optional argument
# like -b <branch>.
#
# for example:
#  {
#     option => '-b',
#     optarg => 1
#  }
#

sub _convert_parms_to_args : PRIVATE {
    my ($self, $parms, $parm_args, $ignore_parm_args) = @_;

    my @args;

    for my $parm ( keys %{$parms} ) {
        # Handle ignored parameters separately and last
        if( defined( $ignore_parm_args->{$parm} ) ) {
            next;
        }

        my $flag = $parm_args->{$parm};
        my $optarg;

        #
        # Supports a hash that has option and optarg fields
        # to allow parameterized option values like -b <branch>
        #
        if (ref $flag eq 'HASH') {
            $optarg = $flag->{optarg};
            $flag = $flag->{option};
        }

        if( ! defined( $flag ) ) {
            P4::Objects::Exception::InvalidParameter->throw(
                parameter       => $parm,
                reason          => 'Unsupported parameter',
            );
        }

        my $value = $parms->{$parm};
        if( $value ) {
            push @args, $flag;
            if ($optarg) {
                push @args, $value;
            }
        }
    }

    my $filespec = $parms->{filespec};
    if( defined( $filespec ) ) {
        if( ref( $filespec ) eq 'ARRAY' ) {
            push @args, @{$filespec};
        }
        else {
            push @args, $filespec;
        }
    }

    return @args;
}

}

1; # End of P4::Objects::Connection
__END__

=head1 NAME

P4::Objects::Connection - a convenience class to encapsulate the L<P4> instance

=head1 SYNOPSIS

P4::Objects::Connection wraps and manages the L<P4> class. It provides for
connection policy and, where required, connection life cycle management. It
inherits from L<P4::Objects::BasicConnection>.

    use P4::Objects::Connection;

    my $conn = P4::Objects::Connection->new();
    ...

=head1 FUNCTIONS

=head2 diff_files

Returns file difference information for a workspace like the Perforce 'diff'
command. The exact data contained in the return depends on the passed
parameters.

=head3 Parameters

=over

=item *

options (Required) - A reference to a hash containing values to define the
behavior of the request. Currently supported values are:

=over

=item *

workspace (Required) - The workspace on which the diff is to operate

=item *

find_deletes (-sd) - If true, returns a reference to an array of local paths
to unopened files that are missing in the workspace.

=item *

find_edits (-se) - Returns a reference to an array of hashes identifying
unopened files that are different from the revision in the depot.

=back

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - If the workspace is omitted

=item *

Exceptions from L</connect>

=item *

Exceptions from L</run>

=back

=head2 get_workspace_opened

Returns the results from the 'p4 opened' command on the specified workspace.

=head3 Parameters

=over

=item *

workspace (Required) - The name of the workspace to check for opened files

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - if a required parameter is omitted

=back

=head2 new

Constructor

=head3 Parameters

See L<P4::Objects::BasicConnection/new>.

=head3 Throws

See L<P4::Objects::BasicConnection/new>.

=head2 resolve_files

Resolves files open for integration. Currently only preview (-n) is supported.

=head3 Parameters

=over

=item *

workspace (Required) - The name of the workspace in which the files to
resolve are open

=item *

preview (Required) - Must be a true value. Equivalent to the -n flag to
resolve. Will become optional once a more generalized form of resolve is
supported.

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - If the 'workspace' parameter was not
supplied

=back

=head2 resolved_files

Returns resolved files open for integration.

=head3 Parameters

=over

=item *

workspace (Required) - The name of the workspace in which to report on the
resolved files

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - If the 'workspace' parameter was not
supplied

=back

=head2 save_changelist

Saves a changelist spec to the server.

=head3 Parameters

=over

=item *

spec (Required) - A hash reference containing the fields for the change spec.
The hash keys correspond to the Perforce change fields and are:

=over

=item *

Change

=item *

Date

=item *

Client

=item *

User

=item *

Status

=item *

Description

=item *

Files - An array of strings containing file names of open files

=back

=back

=head2 save_branch

Saves a branch spec to the server.

=head3 Parameters

=over

=item *

spec (Required) - A hash reference containing the fields for the branch spec.
The hash keys correspond to the Perforce branch fields and are:

=over

=item *

Branch

=item *

Owner

=item *

Description

=item *

Options

=item *

View

=back

=back

=head2 save_job

Saves a job specification to the server.

=head3 Parameters

=over

=item *

spec (Required) - A reference to a hash containing the fields for
the job specification.  The hash keys correspond to the Perforce job fields
and are:

=over

=item *

Job

=item *

Description

=back

=back

=head3 Throws

=over

=item *

Exceptions from L</connect>

=item *

L<P4::Objects::Exception::P4::BadSpec> - if Perforce reports errors from
saving the job spec

=back

=head2 save_label

Saves a label spec to the server.

=head3 Parameters

=over

=item *

spec (Required) - A reference to a hash containing the fields for the
workspace spec. The hash keys correspond to the Perforce workspace fields and
are:

=over

=item *

Label

=item *

Owner

=item *

Description

=item *

Options

=item *

Revision

=item *

View - An array of strings, one for each line of the view spec

=back

=back

=head3 Throws

=over

=item *

Exceptions from L</connect>

=item *

L<P4::Objects::Exception::P4::BadSpec> - if Perforce reports errors from
saving the spec

=back

=head2 save_workspace

Saves a workspace spec to the server.

=head3 Parameters

=over

=item *

spec (Required) - A reference to a hash containing the fields for the
workspace spec. The hash keys correspond to the Perforce workspace fields and
are:

=over

=item *

Client

=item *

Root

=item *

View - An array of strings, one for each line of the view spec

=item *

Owner

=item *

LineEnd

=item *

Host

=item *

Description

=item *

SubmitOptions

=back

=back

=head3 Throws

=over

=item *

Exceptions from L</connect>

=item *

L<P4::Objects::Exception::P4::BadSpec> - if Perforce reports errors from
saving the spec

=back

=head2 submit_changelist

Submit a changelist.

=head3 Parameters

=over

=item *

spec (Required) - A hash reference containing the fields for the change spec.
The hash keys correspond to the Perforce change fields and are:

=over

=item *

Change - Must be provided as a string. Can be the number of an existing
pending changelist, 'default', or 'new'.

=item *

Date

=item *

Client

=item *

User

=item *

Status

=item *

Description

=item *

Files - An array of strings containing file names of open files

=back

=back

=head2 sync_workspace

Syncs the specified workspace. Takes hash arguments:

=head3 Parameters

=over

=item *

workspace (Required) - The name of the workspace to sync

=item *

filespec (Optional) - A single string to be used as the file specifier for the
sync command

=item *

omit_files (Optional) - A boolean argument determining whether files should be
transferred with the sync or not. Equivalent to 'flush' or the '-k' argument
to sync.

=item *

force_sync (Optional) - A boolean argument that forces the sync to ignore the
have list when syncing. Equivalent to the '-f' argument to sync.

=back

=head3 Returns

A two-element list. The first element is a reference to the results as a list
of references to hashes. The second element is a reference to a list of the
warning messages.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - if the workspace parameter is
omitted

=item *

P4::Objects::Exception::P4::SyncError - if an error occurs during the sync

=item *

Exceptions thrown by L</connect>.

=item *

Exceptions thrown by L</run>.

=back

=head2 integrate_workspace

Starts an integration in the specified workspace

=head3 Parameters

=over

=item *

workspace (Required) - The name of the workspace to integrate

=item *

filespec (Optional) - A single string to be used as the file specifier for the
integrate command

=item *

ignore_deletes (Optional) - A boolean argument determining whether the integration
should ignore the fact that a source file has been deleted and re-added when
searching for an integration base.  This causes the -Di option to be thrown to integrate
If omitted, the default value is true.

=item *

compute_base (Optional) - A boolean argument that causes the integrate result to include the
base of the integration.  Equivalent to the -o option to integrate.
If omitted, the default value is true.

=item *

preview (Optional) - A boolean argument that causes the integrate result to be returned
without opening any files for integrate.  Corresponds to the -n option to integrate.

=item *

branch (Optional) - The value is a string corresponding to the name of the branch specification
to use for the integrate.  Corresponds to the -b <branchname> option to integrate

=item *

from_branchrev (Optional) - The value is a string corresponding to the source branch
to use for the integrate.  Corresponds to the -s <fromfile>[<revrange> option to integrate

=back

=head3 Returns

This returns the raw output from running the integrate command in the workspace.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - if the workspace parameter is
omitted

=item *

P4::Objects::Exception::P4::IntegrationError - if an error occurs during the integrate

=item *

Exceptions thrown by L</connect>.

=item *

Exceptions thrown by L</run>.

=back

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-connection at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Connection>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Connection

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Connection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Connection>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Connection>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Connection>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

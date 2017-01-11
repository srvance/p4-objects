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

package P4::Objects::Workspace;

use warnings;
use strict;

use Data::Dumper;
use Error qw( :try );
use File::Path;
use P4::Objects::Common::BinaryOptions;
use P4::Objects::Exception;
use P4::Objects::OpenRevision;
use P4::Objects::PendingChangelist;
use P4::Objects::PendingResolve;
use P4::Objects::IntegrationRecord;
use P4::Objects::SyncResults;
use P4::Objects::IntegrateResults;

use base qw( P4::Objects::Common::AccessUpdateForm );

use Class::Std;

{

our $VERSION = '0.52';

my %name_of : ATTR( init_arg => 'name' get => 'name' );
my %owner_of : ATTR( set => 'owner' get => 'owner' );
my %host_of : ATTR( set => 'host' get => 'host' );
my %description_of : ATTR( set => 'description' get => 'description' );
my %root_of : ATTR( set => 'root' get => 'root' );
my %altroots_of : ATTR( set => 'altroots' get => 'altroots' );
# TODO: Do a better job with Options
my %options_of : ATTR( get => 'options', set => 'options' );
my %submitoptions_of : ATTR( set => 'submitoptions' get => 'submitoptions' );
my %lineend_of : ATTR( set => 'lineend' get => 'lineend' );
# Set explicitly implemented because of representation
my %view_of : ATTR( get => 'view' );

sub START {
    my ($self, $ident, $args_ref) = @_;
    
    if( ! defined( $self->get_name() ) ) {
        P4::Objects::Exception::MissingWorkspaceName->throw();
    }

    return;
}

sub set_view {
    my ($self, $view) = @_;

    if( ref( $view ) ne 'ARRAY' ) {
        P4::Objects::Exception::InvalidView->throw();
    }

    $view_of{ident $self} = $view;

    return;
}

sub set_name {
    my ($self, $name) = @_;
    my $reset_fields = 0;
    
    if( ! defined( $name ) ) {
        P4::Objects::Exception::MissingWorkspaceName->throw();
    }
    
    my $cur_name = $self->get_name();
    
    if( $name ne $cur_name ) {
        $reset_fields = 1;
    }

    $name_of{ident $self} = $name;
    
    # TODO: Should we reload the fields or just blank them?
    if( $reset_fields ) {
        $self->_load_spec();
    }

    return;
}

sub commit {
    my ($self) = @_;
    my $ident = ident $self;

    my %spec = (
        Client => $name_of{$ident},
        Root => $root_of{$ident},
        AltRoots => $altroots_of{$ident},
        View => $view_of{$ident},
        Owner => $owner_of{$ident},
        LineEnd => $lineend_of{$ident},
        Host => $host_of{$ident},
        Description => $description_of{$ident},
        SubmitOptions => $submitoptions_of{$ident},
    );

    my $conn = $self->get_connection();

    # Let exceptions pass
    $conn->save_workspace( \%spec );

    return;
}

sub new_changelist {
    my ($self) = @_;

    return P4::Objects::PendingChangelist->new( {
        session     => $self->get_session(),
        workspace   => $self->get_name(),
    } );
}

sub sync {
    my ($self, @args) = @_;

    my $parms = {};

    if( @args > 0 ) {
        if( ref( $args[0] ) eq 'HASH' ) {
            $parms = $args[0];
            shift @args;
        }
    }

    if( @args > 0 ) {
        $parms->{filespec} = \@args;
    }

    my $conn = $self->get_connection();

    $parms->{workspace} = $self->get_name();

    my ($results, $warnings) = $conn->sync_workspace( $parms );

    my $session = $self->get_session();
    my $sync_results = P4::Objects::SyncResults->new( {
        session     => $session,
        workspace   => $self,
        results     => $results,
        warnings    => $warnings,
    } );

    return $sync_results;
}

sub flush {
    my ($self, @args) = @_;

    #
    # If the first argument to flush is an argument hash
    # use it, otherwise create an empty argument
    # hash
    # In any case add the omit_files argument
    #
    my $parms = { };

    if( @args > 0 ) {
        if( ref( $args[0] ) eq 'HASH' ) {
            $parms = $args[0];
            shift @args;
        }
    }
    $parms->{omit_files} = 1;

    return $self->sync( $parms, @args );
}

sub integrate {
    my ($self, @args) = @_;

    my $parms = {
    };

    if( @args > 0 ) {
        if( ref( $args[0] ) eq 'HASH' ) {
            $parms = $args[0];
            shift @args;
        }
    }

    if( @args > 0 ) {
        $parms->{filespec} = \@args;
    }

    #
    # If this ignore_deletes is not specified, default it to on
    #
    if (!exists( $parms->{ignore_deletes} )) {
        $parms->{ignore_deletes} = 1;
    }
    #
    # If this compute_base is not specified, default it to on
    #
    if (!exists( $parms->{compute_base} )) {
        $parms->{compute_base} = 1;
    }

    my $conn = $self->get_connection();

    $parms->{workspace} = $self->get_name();

    my ($results, $warnings) = $conn->integrate_workspace( $parms );

    my $session = $self->get_session();

    my $integrate_results = P4::Objects::IntegrateResults->new( {
        session     => $session,
        workspace   => $self,
        results     => $results,
        warnings    => $warnings,
    } );

    return $integrate_results;
}

sub delete { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $options) = @_;
    my $ident = ident $self;

    # We wouldn't need to cache this, except we don't know if the spec has
    # been retrieved from the server yet. This forces retrieval before
    # deletion.
    my $root = $self->get_root();
    my $altroots = $self->get_altroots();

    my $conn = $self->get_connection();

    # Pass exceptions
    $conn->run( 'client', '-d', $self->get_name() );

    $self->_set_access_and_update( undef, undef );

    if( defined( $options ) ) {
        if( $options->{remove_all_files} ) {
            for my $dir ( $root, @{$altroots} ) {
                rmtree( $dir );
            }
        }
    }

    return;
}

sub opened {
    my ($self) = @_;

    my $conn = $self->get_connection();

    my $results = $conn->get_workspace_opened( $self->get_name() );

    my @retval;
    my $session = $self->get_session();
    for my $rev ( @{$results} ) {
        # Copy it so the back reference to Session doesn't cause a cycle
        my %parms = %{$rev};
        $parms{session} = $session;
        # Translate Perforce term to ours
        $parms{workspace} = $self;
        push @retval, P4::Objects::OpenRevision->new(
            \%parms,
        );
    }

    return \@retval;
}

sub is_exactly_at_level {
    my ($self, $level) = @_;

    my $wsname = $self->get_name();
    my $srs = $self->sync( { preview => 1 }, "//$wsname/...\@$level" );

    my $results = $srs->get_results();
    return scalar @{$results} == 0;
}

sub resolve {
    my ($self, @args) = @_;

    my $parms = {};

    if( @args > 0 ) {
        if( ref( $args[0] ) eq 'HASH' ) {
            $parms = $args[0];
            shift @args;
        }
        else {
            P4::Objects::Exception::InvalidParameter->throw(
                parameter   => 'options',
                reason      => 'Options parameter must be supplied and no '
                                . 'other parameters are valid at this time.',
            );
        }
    }
    else {
        P4::Objects::Exception::MissingParameter->throw(
            parameter   => 'options',
        );
    }

    $parms->{workspace} = $self->get_name();

    my $conn = $self->get_connection();

    my ($results, $warnings) = $conn->resolve_files( $parms );

    my $ret = [];
    my $session = $self->get_session();
    for my $resolve ( @{$results} ) {
        # Note that we are adding keys into an existing hash that's
        # associated with the Connection, not making a copy. This creates
        # a circular reference unless we delete it like we do below.
        $resolve->{session} = $session;
        push @{$ret}, P4::Objects::PendingResolve->new( $resolve );
        delete $resolve->{session};
    }

    return $ret;
}

# TODO: Support file arguments
sub resolved {
    my ($self) = @_;

    my $conn = $self->get_connection();

    my $results = $conn->resolved_files( $self );

    my $ret = [];
    my $session = $self->get_session();
    for my $resolved ( @{$results} ) {
        # Note that we are adding keys into an existing hash that's
        # associated with the Connection, not making a copy. This creates
        # a circular reference unless we delete it like we do below.
        $resolved->{session} = $session;
        push @{$ret}, P4::Objects::IntegrationRecord->new( $resolved );
        delete $resolved->{session};
    }

    return $ret;
}

sub diff {
    my ($self, $parms) = @_;

    my $conn = $self->get_connection();

    $parms->{workspace} = $self->get_name();

    my $results = $conn->diff_files( $parms );

    my @ret = map { $_->{clientFile} } @{$results};

    return \@ret;
}

sub get_highest_changelist {
    my ($self) = shift;

    my $cls = $self->get_repository()->get_changelists( {
        maxReturned => 1,
        status      => 'submitted',
        filespec    => '@' . $self,
    } );

    # Happens to return undef if none exists
    return $cls->[0];
}

# PRIVATE METHODS

sub _as_str : STRINGIFY {
    my ($self) = @_;

    return $self->get_name();
}

# Throws (see _set_attrs_from_spec)

# TODO: May have to distinguish between an intent to load versus an intent to
# check or may have to have an existance flag. Don't really want to go back
# to the server every time the update is checked on a new spec, right?
sub _load_workspace_spec : PRIVATE {
    my ($self) = @_;
    my $ident = ident $self;

    my $conn = $self->get_connection();
    # TODO: Check errors
    my $spec = $conn->run( 'client', '-o', $name_of{$ident} );
    $self->_set_attrs_from_spec( $spec );

    return;
}

sub _load_spec : RESTRICTED {
    my ($self) = @_;

    $self->_load_workspace_spec();

    return;
}

# Throws P4::Objects::Exception::MissingWorkspaceName

sub _set_attrs_from_spec : RESTRICTED {
    my ($self, $spec) = @_;
    my $ident = ident $self;

    # Address case inconsistency between 'clients' and 'client -o' commands
    my $clname = defined( $spec->{Client} )
                    ? $spec->{Client}
                    : $spec->{client};
    # We don't want to let someone change the identity of the object,
    # but we want to allow use from the constructor. We're requiring that
    # the object's name is set as an invariant prerequisite.
    if( defined( $clname ) && $clname ne $name_of{$ident} ) {
        P4::Objects::Exception::MismatchedWorkspaceName->throw();
    }

    if( ! defined( $clname ) ) {
        P4::Objects::Exception::MissingWorkspaceName->throw();
    }

    $name_of{$ident} = $clname; # Perforce is inconsistent with the
                                        # case for this one
    $root_of{$ident} = $spec->{Root};
    $altroots_of{$ident} = $spec->{AltRoots};
    $options_of{$ident} = P4::Objects::Common::BinaryOptions->new( $spec );
    if( defined( $spec->{View} ) ) {
        if( ref( $spec->{View} ) eq 'ARRAY' ) {
            $view_of{$ident} = $spec->{View};
        }
        else {
            P4::Objects::Exception::InvalidView->throw();
        }
    }
    $owner_of{$ident} = $spec->{Owner};
    $lineend_of{$ident} = $spec->{LineEnd};
    $host_of{$ident} = $spec->{Host};
    $description_of{$ident} = $spec->{Description};
    $submitoptions_of{$ident} = $spec->{SubmitOptions};
    $self->_set_access_and_update(
        $spec->{Access},
        $spec->{Update},
    );

    return;
}

}

1; # End of P4::Objects::Workspace
__END__

=head1 NAME

P4::Objects::Workspace - a Perforce workspace (a.k.a. client)

=head1 SYNOPSIS

P4::Objects::Workspace models the Perforce workspace (a.k.a. client). It
contains all of the attributes of the workspace spec as well as operations
logically associated with the workspace. It can be used to retrieve, create
and modify workspace specs.

    use P4::Objects;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $wsname = $ws->get_name();
    ...

=head1 FUNCTIONS

=head2 commit

Saves the new or updated workspace to the Perforce server.

=head3 Throws

=over

=item *

P4::Objects::Exception::P4::BadSpec - if the spec is ill-formed according to
Perforce

=back

=head2 delete

Deletes the workspace spec from the Perforce server. The workspace object is
still valid, but the access and update fields are set to undef. The rest of
the workspace attributes are preserved to allow re-use.

=head3 Parameters

=over

=item *

options (Optional) - a reference to a hash with options to modify the
behavior. Available options include:

=over

=item *

remove_all_files - Removes the entire tree under and including the workspace
root after deletion of the workspace from the server.

=back

=back

=head3 Throws

Nothing

=head2 diff

Returns file difference information for the workspace like the Perforce 'diff'
command. The exact data contained in the return depends on the passed
parameters.

=head3 Parameters

=over

=item *

options (Required) - A reference to a hash containing values to define the
behavior of the request. Currently supported values are:

=over

=item *

find_deletes (-sd) - If true, returns a reference to an array of local paths
to unopened files that are missing in the workspace.

=item *

find_edits (-se) - If true, returns a reference to an array of local paths to
unopened files that are different from the revision in the depot.

=back

=back

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/diff_files>

=back

=head2 flush

Identical to sync in options and exceptions.  It forces:

omit_files => 1

before calling sync.

See the documentation for sync.

=head2 get_altroots

Returns the altroots for this workspace.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_description

Returns the workspace description for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_highest_changelist

Returns the highest-numbered L<P4::Objects::SubmittedChangelist> that has a
file synced to this workspace. If no such changelist exists (i.e. no files
have been synced), it returns undef.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Repository/get_changelists>

=back

=head2 get_host

Returns the workspace host for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_lineend

Returns the workspace lineend for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_name

Gets the name of the workspace represented by this object.

=head3 Throws

Nothing

=head2 get_options

Returns a L<P4::Objects::Common::BinaryOptions> object containing the
workspace options for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_owner

Returns the workspace owner for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_root

Returns the workspace root for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_submitoptions

Returns the workspace submit options for this object.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 get_view

Returns the workspace view for this object as an array of strings.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - When the attrs parameter is
supplied and it does not have an entry for the client name.

=back

=head2 is_exactly_at_level

Returns true if the workspace is exactly synced to the specified level, and
false otherwise.  This method is a convenience wrapper that executes a
'sync -n //workspacename/...@level' and reports whether there were any results
returned from the sync. No results means the workspace is exactly synced.

=head3 Parameters

=over

=item *

level (Required) - The level against which the workspace is to be checked,
specified as a string that could be placed after the '@' in a Perforce
revision spec.

=back

=head3 Throws

=over

=item *

Exceptions from L</sync>

=back

=head2 new

Constructor

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

name (Required) - The name of the workspace

=item *

attrs (Optional) - A hash of workspace attributes

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - if the 'name' parameter is
omitted

=item *

P4::Objects::Exception::MismatchedWorkspaceName - if the name already in the
Workspace object or supplied in the 'name' parameter does not match the name
supplied in the 'attrs' parameter

=item *

P4::Objects::Exception::InvalidView - if the view passed in through the attrs
hash is not an array.

=item *

Exceptions from L<P4::Objects::Common::BinaryOptions/new>.

=back

=head2 new_changelist

Creates a new pending numbered changelist for the workspace and returns a
L<P4::Objects::PendingChangelist> object.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::PendingChangelist/new>

=back

=head2 opened

Returns the files opened in the workspace as a list of
L<P4::Objects::OpenRevision> objects.

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/get_workspace_opened>

=back

=head2 resolve

Resolves files opened for integrate. Currently only supports preview.

=head3 Parameters

=over

==item *

options (Required) - hash reference to optional settings. This will be
optional when the generalized form of resolve is supported. Must be the first
argument if present. Supported keys are:

=over

=item *

preview - if true, equivalent to 'resolve -n'

=back

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::InvalidParameter - If the 'options' parameter is not
supplied while only preview is supported

=item *

P4::Objects::Exception::MissingParameter - If no parameters are supplied

=item *

Exceptions from L<P4::Objects::Connection/resolve_files>.

=back

=head2 resolved

Returns a list of resolved files open for integration.

=head3 Parameters

None

=head3 Throws

=over

=item *

Exceptions from L<P4::Objects::Connection/resolved_files>.

=back

=head2 set_altroots

Sets the altroots for this workspace.

=head3 Throws

Nothing

=head2 set_description

Sets the workspace description for this object.

=head3 Throws

Nothing

=head2 set_host

Sets the workspace host for this object.

=head3 Throws

Nothing

=head2 set_lineend

Sets the workspace lineend for this object.

=head3 Throws

Nothing

=head2 set_name

Sets the workspace name for this object. If you are redefining an entire
Workspace object, you need to set the name first. If the name is changed, it
will reset all of the other form fields, although the session reference will
be preserved.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingWorkspaceName - if no name is specified

=back

=head2 set_options

Sets the workspace options for this object.

=head3 Throws

Nothing

=head2 set_owner

Sets the workspace owner for this object.

=head3 Throws

Nothing

=head2 set_root

Sets the workspace root for this object.

=head3 Throws

Nothing

=head2 set_submitoptions

Sets the workspace submit options for this object.

=head3 Throws

Nothing

=head2 set_view

Sets the workspace view for this object. The parameter must be an array of
strings.

=head3 Throws

=over

=item *

P4::Objects::Exception::InvalidView - If the parameter is not an array

=back

=head2 sync

Syncs the workspace, returning a L<P4::Objects::SyncResults> object.

=head3 Parameters

=over

=item *

options (Optional) - hash reference to optional settings. Must be the first
argument if present. Supported keys are:

=over

=item *

omit_files - if true, equivalent to 'flush' or 'sync -k'

=back

=item *

filespec (Optional) - the file specification to pass to the sync command.

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::UnexpectedSyncResults - typically when Perforce
returns a sync result key that is unexpected.

=item *

Exceptions from L<P4::Objects::Connection/sync_workspace>

=back

=head3 Usage Notes

=over

=item *

When syncing a file that is open at the revision requested by the sync,
Perforce does not acknowledge in any way that the file might have been synced
if it weren't open, even if the sync is forced. If only open files are synced,
it simply reports "file(s) up-to-date." If some of the files are not open,
then it only reports on the unopen files and gives no indication that it
skipped the open files. Concerned code should use
L<P4::Objects::Repository/opened> to identify potential issues when syncing.

=back

=head2 integrate

Integrates into the workspace, returning a L<P4::Objects::IntegrateResults> object.

=head3 Parameters

=over

=item *

options (Optional) - hash reference to optional settings. Must be the first
argument if present. Supported keys are:

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

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::P4::IntegrationError - typically when Perforce
returns an error from the integrate command.

=item *

P4::Objects::Exception::P4::UnexpectedIntegrateResult - typically when Perforce
returns a integrate result key that is unexpected.

=item *

Exceptions from L<P4::Objects::Connection/integrate_workspace>

=back

=head2 START

Post-initialization constructor invoked by L<Class::Std>

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-workspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Workspace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Workspace

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Workspace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Workspace>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Workspace>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Workspace>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

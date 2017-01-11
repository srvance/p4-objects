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

package P4::Objects::Extensions::MergeResolveTracker;

use warnings;
use strict;

use English                                       qw( -no_match_vars );
use Storable                                      qw();
use File::Spec                                    qw();
use File::Spec::Unix                              qw();
use Class::Std::Storable                          qw(ATTR);
use P4::Objects::Common::Base                     qw();
use P4::Objects::Exception                        qw();
use P4::Objects::IntegrateResult                  qw();
use P4::Objects::Extensions::MergeResolveData     qw();
use Fatal                                         qw(:void open close);
use base qw( P4::Objects::Common::Base );

{
my %integrateresult_of   : ATTR( get => 'integrateresult'  );
my %integrateoptions_of  : ATTR( name => 'integrateoptions');
my %workspace_of         : ATTR( name => 'workspace'       );
my %resolvedata_of       : ATTR( get => 'resolvedata'      );
my %changelist_of        : ATTR( get => 'changelist'       );

our $VERSION = '0.52';

sub START {
    my ($self, $ident, $args_ref) = @_;

    my $ws = $self->get_workspace();
    my $ses = $ws->get_session();
    my $connection = $ses->get_connection();

    my $io = $self->get_integrateoptions();

    my $branch = $io->{branch};

    P4::Objects::Exception::P4::PreconditionViolation->throw(
            reason => 'merging can only be done using a branch specification'
    ) if( ! defined( $branch ) );

    $self->_setup_client_workspace( $ses, $ws, $branch );

    $integrateresult_of{$ident} = $ws->integrate( $io );

    my $results = $self->get_integrateresult()->get_results();

    if (!@{$results}) {
        $resolvedata_of{$ident} = [];
        return;
    }

    my $cl = $ws->new_changelist();
    my $description = 'Integrate using branch specification $branch '
                         . "\n";
# TODO: Add tests for reverse and from_branchrev
#       don't add this code until the tests are ready
#                         . ($io->{reverse} ? '(reverse)' : '')
#                         . ($io->{from_branchrev} ? " at source change level $io->{from_branchrev}" : '')
    $cl->set_description( $description );
    $cl->commit();
    $cl->reopen_files( map { $_->get_depotfile() }
                       grep { $_->get_action() =~ /^cant/ } @{$results} );

    #
    # Try to resolve any trivial merges.  These are files that are only
    # changed on the source branch and not on the target branch
    #
    my $resolveas = $connection->run( 'resolve', '-as' );

    #
    # Any files that are resolved are trivial merges.  These can be new files,
    # the destination of a rename operation or files that only changed
    # on the source branch
    #
    my $resolved = $connection->run( 'resolved' );

    #
    # The resolved output comes back in sandbox syntax, but the integrate
    # output comes back in depot syntax, so call "p4 where" to determine
    # the name of the depotfile for each client file so that we can match
    # them up.
    #

    my $where = $connection->run( 'where', map { $_->{toFile} } @{$resolved} );
    my %resolved_depot_map = map { $_->{clientFile} => $_ } @{$where};

    #
    # Create a map from depot path to all of the files that were resolved
    #
    my %resolved_map = map {
        $_->{depotFile} = $resolved_depot_map{ $_->{toFile} }->{depotFile};
        $_->{depotFile} => $_;
    } @{$resolved};

    #
    # For all of the files in the integrate result, call the files command
    # to get the file type and other information about the version
    #
    my $files_map = _compute_files_map( $ses, $results );

    my @resolve_data = map  {
        my $ir = $_;
        my $trivial = exists $resolved_map{$ir->get_depotfile()};
        my $cant = $ir->get_action =~ /^cant_/;

        my ($typemerge, $typepropagate, $sourcerevision, $targetrevision, $baserevision) = _compute_type_merge( $cl, $ir, $files_map );

        my $rd = P4::Objects::Extensions::MergeResolveData->new( {
            session           => $ses,
            mergeaction       => ($trivial) ? 'trivial' : ($cant ? 'cant' : 'non_trivial'),
            resolved          => $trivial,
            p4resolved        => $trivial,
            typemerge         => $typemerge,
            typepropagate     => $typepropagate,
            integrateresult   => $ir,
            sourcerevision    => $sourcerevision,
            targetrevision    => $targetrevision,
            baserevision      => $baserevision || '',
        });
    } @{$results};

    $resolvedata_of{$ident} = \@resolve_data;

    return;
}

sub get_perforce_opened {
    my ($self) = @_;
    return grep { $_->get_mergeaction() ne 'cant' } @{$self->get_resolvedata()};
}

sub save {
    my ($self) = @_;

    my $filename = _compute_merge_filename( $self->get_workspace() );
    open my $sh, '>', $filename;
    binmode $sh;
    print $sh Storable::freeze( $self );
    close $sh;
    return;
}

sub load {
    my ($ws) = @_;

    #
    # Set the session to use for the load.
    #
    P4::Objects::Common::Base::_set_thaw_session( $ws->get_session() );

    my $filename = _compute_merge_filename( $ws );
    open my $sh, '<', $filename;
    binmode $sh;
    local $INPUT_RECORD_SEPARATOR;

    my $mrt = Storable::thaw( <$sh> );
    close $sh;

    return $mrt;
}

sub STORABLE_freeze_pre : CUMULATIVE(BASE FIRST) {
    my ($self, $cloning) = @_;

    $workspace_of{ident $self} = undef;  # The workspace cannot be serialized

    return;
}

sub STORABLE_thaw_post : CUMULATIVE(BASE FIRST) {
    my ($self, $cloning) = @_;

    $workspace_of{ident $self} = $self->get_session()->get_workspace();

    return;
}

#
# Given a set of paths return the least common view specification for that set
# given client views.
#
sub _least_common_view : RESTRICTED {
    my ($ws_name, @views) = @_;

    my @common_view;

    #
    # Find the least common view
    #
    for my $view (@views) {
        my @this_view = File::Spec->splitdir( $view );

        if (!@common_view) {
            @common_view = @this_view;
        }
        else {
            my @new_view;
            for my $oview (@common_view) {
                my $nv = shift @this_view;
                if ($nv ne $oview) {
                    @common_view = @new_view;
                    last;
                }
                push @new_view, $nv;
            }
        }
    }

    #
    # Produce a map based on the least common view
    #
    my @client_view = map {
        my @local_view = File::Spec->splitdir( $_ );
        for my $view (@common_view) {
            shift @local_view;
            last if @local_view == 1;
        }
        "$_ //" . File::Spec::Unix->catdir( $ws_name, @local_view );
    } @views;

    return @client_view;
}

sub _setup_client_workspace : RESTRICTED {
    my ($self, $ses, $ws, $branch_name) = @_;
    my $connection = $ses->get_connection();

    #
    # Make sure that the workspace has no opened files
    #
    my $o = $ws->opened();

    if (@{$o}) {
        P4::Objects::Exception::P4::PreconditionViolation->throw(
            reason => 'The workspace used for merging may not have any open files' );
    }

    #
    # Clear all file contents from the workspace
    #
    $ws->sync('#0');

    #
    # Edit the client specification to be the same as the destination of the merge
    #
    my $branch = $connection->run( 'branch', '-o', $branch_name );
    my $view = $branch->{View};

    #
    # In order to construct the appropriate branch view, you
    # take the least common prefix from all of the view lines and break there.
    # This may be counter-intuitive but requires no other data points and always works
    #
    my @views = map {
        if (/^-/) {
        P4::Objects::Exception::P4::PreconditionViolation->throw(
            reason => "branch specifications used for merging cannot include exclusionary (-) views: $_" );
        }
        /\S+\s+(\S+)/;
    } @{$view};

    my @client_view = _least_common_view( $ws->get_name(), @views );

    $ws->set_view( \@client_view );
    $ws->commit();
    return;

}

sub _compute_files_map : RESTRICTED {
    my ($ses, $list) = @_;

    my @files = map {
        ($_->get_source_revision(), $_->get_target_revision(),
          $_->get_base_revision() );
    } (@{$list});

    my $files = $ses->get_repository()->files(@files);

    my %files_map;

    for my $file (@{$files}) {
        $files_map{$file->get_depotname()}{$file->get_revision()} = $file;
    }

    return \%files_map;
}

sub _find_file : RESTRICTED {
    my ($files_map, $depotname, $rev) = @_;

    my $files = $files_map->{$depotname};

    #
    # If the revision was not specified, we sent it to files
    # without a revision.  In this case take the largest rev
    # in the hash for this depotfile
    #
    if (!$rev) {
      my @revs = sort keys %{$files};
      $rev = pop @revs;
    }

    return $files->{$rev};
}

sub _compute_type_merge : RESTRICTED {
    my ($cl, $ir, $files_map) = @_;

    my $typemerge = '';
    my $typepropagate = '';

    my $sourcerevision = _find_file( $files_map, $ir->get_source(), $ir->get_endfromrev() );
    my $targetrevision = _find_file( $files_map, $ir->get_depotfile(), $ir->get_workingrev() );
    my $basename = $ir->get_basename();
    my $baserevision = $basename ? _find_file( $files_map, $basename, $ir->get_baserev() ) : undef;

    #
    # Branch actions have no target file
    #
    if ($ir->get_action() ne 'branch') {

        my $sourcetype = $sourcerevision->get_type();
        my $targettype = $targetrevision->get_type();

        if (!$sourcetype->equals($targettype)) {
            #
            # If there is no base version then it is a type merge
            # the only case should be the "cant_integrate" or "cant_delete" action
            #
            if (!$baserevision) {
                $typemerge = 1;
            }
            else {
                my $basetype = $baserevision->get_type();
                my $sourcechange = !$sourcetype->equals($basetype);
                my $targetchange = !$targettype->equals($basetype);

                $typemerge = $sourcechange && $targetchange;
                #
                # if the source changed and not the target then it needs to be propagated to the target
                #
                $typepropagate = $sourcechange && !$targetchange;
                if ($typepropagate) {
                    $cl->reopen_files( '-t', $sourcetype->get_type_string(), $ir->get_depotfile() );
                }
            }
        }
    }

    return ($typemerge, $typepropagate, $sourcerevision, $targetrevision, $baserevision);
}

sub _compute_merge_filename : RESTRICTED {
    my ($ws) = @_;

    my $root = $ws->get_root();

    my $savedir = File::Spec->catfile( $root, '.merge' );
    if (!-e $savedir) {
        mkdir $savedir;
    }
    return File::Spec->catfile( $savedir, 'MergeResolveTracker.dat' );
}

}

1; # End of P4::Objects::Extensions::MergeResolveTracker

__END__

=head1 NAME

P4::Objects::Extensions::MergeResolveTracker - Used to open files for integrate and resolve
file type changes and resolvable deletes not handled by Perforce.

=head1 SYNOPSIS

P4::Objects::Extensions::MergeResolveTracker tracks a single integrate operation from the point of
integrate to the point of submit.  It provides additional logging and handles several cases not handled
by Perforce.  This is the integrate and resolve command that Peforce should have written.

It first checks for appropriate sandbox pre-conditions:

    * No open files
    * Must use a branch specification (to resolve renames properly) - this restriction may be removed in a future version
    * The branch specification must not include any exclusionary mappings (- mappings)

It then performs a sync#0 to eliminate all files from the workspace and resets the
workspace view to be the full target of the branch.

It then performs the integrate operation:

    * By default uses ignore_deletes (-Di) unless ingore_delete is specified as false
    * By default uses compute_base (-o) unless compute base is specified as false
    * Identifies and tracks for resolve all files that perforce cannot open for integrate due
      to any of the following messages:
        * can't branch from
        * can't integrate from
        * can't delete from
   * Identifies and tracks for resolve all files that have file type change conflicts.
     Correctly propagates file type changes from the source to the target (if applicable).

The expected usage is store the object into a file at the completion of the integrate.
Each subsequent resolve step will read the data back in and allow you to work to resolve
all of the files.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    P4::Objects::Extensions::MergeResolveTracker->new( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
            branch => 'branchspec'
        }
    });

=head1 FUNCTIONS

=head2 get_integrateresult

Returns a reference to a P4::Objects::IntegrateResults object that contains the
result of the integrate.

=head3 Throws

Nothing

=head2 get_integrateoptions

Returns a reference to a hash that includes all of the options used on this integrate.

=head3 Throws

Nothing

=head2 get_workspace

Returns a reference to the workspace with which this set of results is
associated.

=head3 Throws

Nothing

=head2 get_resolvedata

Returns an array of P4::Objects::Extensions::MergeResolveData objects that includes
information on whether all merge issues have been resolved successfully.

=head3 Throws

Nothing

=head2 save

Saves the current merge result set into a directory at the root of the current
sandbox called ".merge".  Serializes the data using Storable::Freeze

=head3 Throws

Nothing

=head2 load

Loads the file at the root of the sandbox called .merge/MergeResolveTracker.dat which was
saved using this class.  Returns the constructed object.

=head3 Throws

Nothing

=head2 new

Constructor

=head3 Parameters

Parameters are passed in an anonymous hash.

=over

=item *

workspace (Required) - A reference to a workspace object

=item *

integrateoptions (Required) - A hash of integrate attributes as defined by the
P4::Objects::Workspace::integrate function.

=back

=head3 Throws

=over

=item *

none

=back

=head2 get_perforce_opened

Returns a list of all files opened in Perforce for the integrate

=head3 Throws

Nothing

=head2 START

Post-initialization constructor invoked by Class::Std.

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - If 'results' is not supplied

=back

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-integrateresults at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-IntegrateResults>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::IntegrateResults

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-IntegrateResults>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-IntegrateResults>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-IntegrateResults>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-IntegrateResults>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

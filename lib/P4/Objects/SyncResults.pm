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

package P4::Objects::SyncResults;

use warnings;
use strict;

use Class::Std;
use P4::Objects::Exception;
use P4::Objects::WorkspaceRevision;

use base qw( P4::Objects::Common::Base );

{

our $VERSION = '0.43';

my %workspace_of : ATTR( init_arg => 'workspace' get => 'workspace' );
my %results_of : ATTR( get => 'results' );
my %totalfilecount_of : ATTR( default => 0 get => 'totalfilecount' );
my %totalfilesize_of : ATTR( default => 0 get => 'totalfilesize' );
my %warnings_of : ATTR( init_arg => 'warnings' get => 'warnings' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    my $passed_results = $args_ref->{results};
    P4::Objects::Exception::MissingParameter->throw(
        parameter => 'results',
    ) if( ! defined( $passed_results ) );

    # The first result holds the totals
    if( @{$passed_results} > 0 ) {
        my $first_result = $passed_results->[0];

        if( ref( $first_result ) eq 'HASH' ) {
            if( defined( $first_result->{totalFileCount} ) ) {
                $totalfilecount_of{$ident} = $first_result->{totalFileCount};
            }

            if( defined( $first_result->{totalFileSize} ) ) {
                $totalfilesize_of{$ident} = $first_result->{totalFileSize};
            }
        }
    }

    $results_of{$ident} = [];
    for my $result ( @{$passed_results} ) {
        if( ref( $result ) eq 'HASH' ) {
            # Note that we are adding keys into an existing hash that's
            # associated with the Connection, not making a copy. This creates
            # a circular reference unless we delete it like we do below.
            $result->{session} = $self->get_session();
            $result->{workspace} = $self->get_workspace();
            push @{$results_of{$ident}},
                P4::Objects::WorkspaceRevision->new( $result );
            delete $result->{session};
            delete $result->{workspace};
        }
        else {
            # Assumed to be strings as from syncs requiring resolve
            my $warnings = $warnings_of{$ident};
            push @{$warnings}, $result;
        }
    }

    return;
}

}

1; # End of P4::Objects::SyncResults
__END__

=head1 NAME

P4::Objects::SyncResults - the result of a sync operation

=head1 SYNOPSIS

P4::Objects::SyncResults encapsulates the set of results from a sync operation.
In addition to the expected output of the files synced, the sync operation can
have warnings that are the failure messages and that include the "File(s)
up-to-date" message. Since a sync can have partial success, the results set
can be a mixed bag.

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $sr = $ws->sync();
    analyze_results( $sr->get_results() );
    analyze_warnings( $sr->get_warnings() );
    ...

=head1 FUNCTIONS

=head2 get_results

Returns a reference to an array of L<P4::Objects::WorkspaceRevision> objects.

=head3 Throws

Nothing

=head2 get_totalfilecount

Returns the total number of files synced in the operation.

=head3 Throws

Nothing

=head2 get_totalfilesize

Returns the total size of the files synced in the operation.

=head3 Throws

Nothing

=head2 get_warnings

Returns a reference to an array of strings of the warnings in this set of
results.

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

Parameters are passed in an anonymous hash.

=over

=item *

workspace (Required) - A reference to a workspace object

=item *

results (Required) - A hash of workspace attributes as defined by the Perforce
return from sync. Each entry must contain the keys necessary for
L<P4::Objects::WorkspaceRevision/new>. The first entry optionally may also
contain the keys totalFileSize and totalFileCount.

=item *

warnings (Required) - The warnings from the operation

=back

=head3 Throws

=over

=item *

P4::Objects::Exception::MissingParameter - If 'results' is not supplied

=back

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
C<bug-p4-objects-syncresults at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-SyncResults>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::SyncResults

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-SyncResults>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-SyncResults>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-SyncResults>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-SyncResults>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

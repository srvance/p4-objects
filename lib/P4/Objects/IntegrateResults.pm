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

package P4::Objects::IntegrateResults;

use warnings;
use strict;

use Class::Std::Storable;
use P4::Objects::Exception;
use P4::Objects::WorkspaceRevision;
use P4::Objects::IntegrateResult;

use base qw( P4::Objects::Common::Base );

{


our $VERSION = '0.52';

my %workspace_of : ATTR( init_arg => 'workspace' get => 'workspace' );
my %results_of : ATTR( get => 'results' );
my %warnings_of : ATTR( init_arg => 'warnings' get => 'warnings' );

sub START {
    my ($self, $ident, $args_ref) = @_;

    my $passed_results = $args_ref->{results};
    P4::Objects::Exception::MissingParameter->throw(
        parameter => 'results',
    ) if( ! defined( $passed_results ) );

    my @returned_results = map {
        $self->_compute_integrate_result( $_ );
    } @{$passed_results};

    $results_of{$ident} = \@returned_results;

    return;
}

#
# The goal is to make a branch record that looks like this:
#           {
#             'startFromRev' => '1',
#             'fromFile' => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin',
#             'clientFile' => '/tmp/battest.49c6d9c6.abpromote.2387/tp4merge.pt/Bmi_workspace/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin',
#             'action' => 'integrate',
#             'workRev' => '2',
#             'depotFile' => '//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin',
#             'endFromRev' => '2'
#           }
# from a string that looks like this:
#
#          '//matlab/Bmi/matlab/Amiowned/B1_add/B2_unc_med_scm.txt - can\'t integrate from //matlab/Ami/matlab/Amiowned/B1_add/B2_unc_med_scm.txt#1 without -i flag',
#          '//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_lg.txt - can\'t delete from //matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_lg.txt#1,#2 without -d or -Ds flag',
#          '//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_lg.txt - can\'t branch from //matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_lg.txt#2 without -d or -Dt flag',
#
# NOTE: Since the string does not contain the clientFile and the workRev, this does not return them.
#
sub _make_branch_record_from_merge_error : RESTRICTED {
    my ($str) = @_;

    my ($depotFile, $action, $fromFile, $startFromRev, $endFromRev) = $str =~ /^(\S+).+(branch|delete|integrate)\sfrom\s(\S+?)#(\d+)(?:,#(\d+))?/;
    if (!$depotFile) {
        P4::Objects::Exception::P4::UnexpectedIntegrateResult->throw(
            badresult => $str
        );
    }
    if (!defined($endFromRev)) {
        $endFromRev = $startFromRev;
    }
    return {
        startFromRev => $startFromRev,
        fromFile     => $fromFile,
        action       => "cant_$action",
        depotFile    => $depotFile,
        endFromRev   => $endFromRev
    };
}

sub _compute_integrate_result : RESTRICTED {
    my ($self, $result) = @_;

    if (ref( $result ) ne 'HASH') {
        $result = _make_branch_record_from_merge_error( $result );
    }
    $result->{session} = $self->get_session();
    $result->{workspace} = $self->get_workspace();
    my $val = P4::Objects::IntegrateResult->new( $result );
    delete $result->{session};
    delete $result->{workspace};
    return $val;
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

}

1; # End of P4::Objects::IntegrateResults

__END__

=head1 NAME

P4::Objects::IntegrateResults - the result of an integrate operation

=head1 SYNOPSIS

P4::Objects::IntegrateResults encapsulates the set of results from an integrate operation.
In addition to the expected output of the files integrated,

    use P4::Objects::Session;

    my $session = P4::Objects::Session->new();
    my $ws = $session->get_workspace();
    my $sr = $ws->integrate({ branch => branchname });
    analyze_results( $sr->get_results() );
    analyze_warnings( $sr->get_warnings() );
    ...

=head1 FUNCTIONS

=head2 get_results

Returns a reference to an array of L<P4::Objects::IntegrateResult> objects.

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

results (Required) - A hash of integrate attributes as defined by the Perforce
return from integrate. Each entry must contain the keys necessary for
L<P4::Objects::IntegrateResults/new>.

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

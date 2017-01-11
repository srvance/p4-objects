# Copyright (C) 2008 Stephen Vance
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

package P4::Objects::Extensions::Test::MergeResolveTracker;

use strict;
use warnings;

use Data::Dumper;
use Error                                           qw( :try );
use Storable                                        qw();
use File::Spec                                      qw();
use File::Copy                                      qw();
use P4::Objects::Session                            qw();
use P4::Objects::Extensions::MergeResolveTracker    qw();

use base qw( P4::Objects::Test::Helper::TestCase );

my $user = 'generic_user';
my $workspace = 'Bmi_workspace';
my %expected_result;
my $branch_name = 'Bmi__Ami-to-Bmi';

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {

    return;
}

sub tear_down {

    return;
}

sub test_new {
    my ($self) = @_;

    my $server = $self->_create_p4d( {
        archive => 'SCMTestGenerator.tgz',
        package => 'P4::Objects::Test::Workspace' # Share data with this test - 80Mb!
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $server->get_port,
        user        => $user,
        workspace   => $workspace,
    } );

    $self->assert_not_null( $rootdir );

    my $session = P4::Objects::Session->new();
    $session->set_port( $server->get_port() );
    $session->set_workspace( $workspace );
    $session->set_user( $user );

    my $ws = $session->get_workspace($workspace);

    my $mrt = P4::Objects::Extensions::MergeResolveTracker->new( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
            branch => $branch_name
        }
    } );
    $self->_compare_expected_results( $mrt, $session, $ws );

    my @list = $mrt->get_perforce_opened();
    $self->assert_equals( 137, scalar @list );

    $mrt->save();

    #
    # Save a copy of the file in /tmp for future reference
    #
#    File::Copy::copy( File::Spec->catfile( $ws->get_root(), '.merge', 'MergeResolveTracker.dat' ),
#                      File::Spec->catfile( '/tmp', 'MergeResolveTracker.dat' ) );
    return;
}

sub test_load {
    my ($self) = @_;

    my ($server,$session,$ws) = $self->_make_server();

    my $target_filename = _compute_merge_filename( $ws );

    my ($volume,$dir,$file) = File::Spec->splitpath( $target_filename );

    my $header = Storable::read_magic(Storable::freeze(\1));
    $file .= "_$header->{byteorder}_$header->{intsize}_$header->{longsize}_$header->{ptrsize}";

    my $source_filename = $self->_get_test_data_file_name( __PACKAGE__, $file );

    $self->assert( File::Copy::copy( $source_filename, $target_filename ) );

    my $mrt = P4::Objects::Extensions::MergeResolveTracker::load( $ws );
    $self->_compare_expected_results( $mrt, $session, $ws );

    return;
}

sub _compare_expected_results {
    my ($self, $mrt, $ses, $ws) = @_;

    $self->assert_not_null( $mrt );
    $self->assert_equals( $ses, $mrt->get_session() );
    $self->assert_equals( $ws, $mrt->get_workspace() );

    $self->assert_equals( $ws, $mrt->get_integrateresult()->get_workspace() );

    my $r = $mrt->get_resolvedata();
    my @trivial     = grep { $_->get_mergeaction() eq 'trivial'     } @{$r};
    my @non_trivial = grep { $_->get_mergeaction() eq 'non_trivial' } @{$r};
    my @cant        = grep { $_->get_mergeaction() eq 'cant'        } @{$r};
    $self->assert_equals( 125, scalar @trivial    );
    $self->assert_equals( 12, scalar @non_trivial );
    $self->assert_equals( 135, scalar @cant       );

    $self->assert_equals( scalar @trivial + scalar @non_trivial + scalar @cant, scalar @{$r} );

    for my $res (@{$r}) {
        my $ir = $res->get_integrateresult();
        $self->assert_equals( $ses, $ir->get_session() );

        my $depotfile = $ir->get_depotfile();
        my $p4resolved = $res->get_p4resolved();
        my $resolved = $res->get_resolved();
        my $mergeaction = $res->get_mergeaction();
        my $baserevision = $res->get_baserevision();
        my $basefile_name = '';
        if ($baserevision) {
            $basefile_name = $baserevision->get_depotname();
        }
        my $sourcefile_name = $res->get_sourcerevision()->get_depotname();
        my $typepropagate = $res->get_typepropagate();
        my $typemerge = $res->get_typemerge();

        my $expected = $expected_result{ $depotfile };
        $self->assert_not_null( $expected );
        $self->assert_equals( $expected->{mergeaction} ,    $mergeaction     );
        $self->assert_equals( $expected->{p4resolved},    $p4resolved      );
        $self->assert_equals( $expected->{resolved},      $resolved        );
        $self->assert_equals( $expected->{typemerge},     $typemerge       );
        $self->assert_equals( $expected->{typepropagate}, $typepropagate   );
        $self->assert_equals( $expected->{sourcefile},    $sourcefile_name );
        $self->assert_equals( $expected->{base},          $basefile_name   );

# TODO: Add test for type propagation working on the open file's type

# Use these print statements to re-generate the expected results
#
#         print "'$depotfile' => {\n";
#         print "    mergeaction   => '$mergeaction',\n";
#         print "    p4resolved    => '$p4resolved',\n";
#         print "    resolved      => '$resolved',\n";
#         print "    typemerge     => '$typemerge',\n";
#         print "    typepropagate => '$typepropagate',\n";
#         print "    sourcefile    => '$sourcefile_name',\n";
#         print "    base          => '$basefile_name',\n";
#         print "},\n";
    }
    return;
}
sub _compute_merge_filename {
    my ($ws) = @_;

    my $root = $ws->get_root();

    my $savedir = File::Spec->catfile( $root, '.merge' );
    if (!-e $savedir) {
        mkdir $savedir;
    }
    return File::Spec->catfile( $savedir, 'MergeResolveTracker.dat' );
}

sub _test_new_precondition_exception {
    my ($self, $newarg ) = @_;

    try {
        my $mrt = P4::Objects::Extensions::MergeResolveTracker->new( $newarg );
        $self->assert(0, 'Should not return from constructor' );
    }
    catch P4::Objects::Exception::P4::PreconditionViolation with {
        my $e = shift;
        $self->assert_not_null( $e->reason() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0 , "Unexpected exception " . ref( $e ) );
    };
    return;
}

sub test_new_no_branch {
    my ($self) = @_;

    my ($server,$session,$ws) = $self->_make_server();

    $self->_test_new_precondition_exception( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
        }
    });
    return;
}

sub test_new_open_files {
    my ($self) = @_;

    my ($server,$session,$ws) = $self->_make_server();

    my $file = '//matlab/Bmi/matlab/Amiowned/B1_unc_B2_unc_scm_med.bin';
    $ws->sync($file);
    my $cl = $ws->new_changelist();
    $cl->set_description( 'Force an error from integrate' );
    $cl->commit();
    $cl->edit_files( $file );

    $self->_test_new_precondition_exception( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
            branch => $branch_name
        }
    } );
    $session->get_connection()->run( 'revert', $file );
    return;
}
sub test_new_negative_branch_mapping {
    my ($self) = @_;

    my ($server,$session,$ws) = $self->_make_server();

    my $connection = $session->get_connection();
    my $b = $connection->run( 'branch', '-o', $branch_name );
    $b->{Branch} = 'test_branch';
    $b->{View} = [
                      '//matlab/Ami/... //matlab/Bmi/...',
                      '-//matlab/Ami/matlab/... //matlab/Bmi/matlab/...'
                    ];
    $connection->save_branch( $b );
    $self->_test_new_precondition_exception( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
            branch => 'test_branch'
        }
    } );
    return;
}
sub test_new_least_common_view {
    my ($self) = @_;

    my ($server,$session,$ws) = $self->_make_server();


    $session->set_port( $server->get_port() );
    $session->set_workspace($ws->get_name());
    $session->set_cwd( $ws->get_root() );
    my $connection = $session->get_connection();
    $connection->reload();

    my $b = $connection->run( 'branch', '-o', $branch_name );
    $b->{Branch} = 'test_branch';
    $b->{View} = [
                      '//matlab/Ami/matlab/Amiowned/dir1/... //matlab/Ami/matlab/Amiowned/dir1/...',
                      '//matlab/Ami/matlab/Amiowned/B1_add/... //matlab/Ami/matlab/Amiowned/B1_add/...',
                    ];
    $connection->save_branch( $b );
    my $mrt = P4::Objects::Extensions::MergeResolveTracker->new( {
        session          => $session,
        workspace        => $session->get_workspace,
        integrateoptions => {
            branch => 'test_branch'
        }
    } );
    $ws = $session->get_workspace($workspace);
    my $view = $ws->get_view();
    $self->assert_equals( 2, scalar @{$view} );
    $self->assert_equals( '//matlab/Ami/matlab/Amiowned/dir1/... //Bmi_workspace/dir1/...', $view->[0] );
    $self->assert_equals( '//matlab/Ami/matlab/Amiowned/B1_add/... //Bmi_workspace/B1_add/...', $view->[1] );

    $self->assert_not_null( $mrt );
    my $r = $mrt->get_resolvedata();

    $self->assert_equals( 0, scalar @{$r} );
    return;
}

sub _make_server {
    my ($self) = @_;
    my $server = $self->_create_p4d( {
        archive => 'smallinteg.tgz',
        package => __PACKAGE__
    } );

    my $rootdir = $self->_create_and_replace_client_root( {
        port        => $server->get_port,
        user        => $user,
        workspace   => $workspace,
    } );

    $self->assert_not_null( $rootdir );
    my $session = P4::Objects::Session->new();
    $session->set_port( $server->get_port() );
    $session->set_workspace( $workspace );
    $session->set_user( $user );

    my $ws = $session->get_workspace($workspace);
    return ($server,$session,$ws);
}

%expected_result = (
'//matlab/Bmi/matlab/Amiowned/B1_add/B2_unc_med_scm.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add/B2_unc_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_del_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_ren_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_add_B2_unc_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_add_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del/B2_unc_med_scm.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del/B2_unc_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_del_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_del_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_del_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_lg.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_lg.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_lg.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_lg.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_lg.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_lg.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_med.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_med.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_med.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_med.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_med.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_med.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_z.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_z.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_z.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_edit_scm_z.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_z.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_edit_scm_z.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_ren_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_lg.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_lg.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_lg.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_lg.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_med.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_med.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_med.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_med.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '1',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_z.bin',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_z.bin',
},
'//matlab/Bmi/matlab/Amiowned/B1_edit_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '1',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_z.txt',
    base          => '//matlab/Ami/matlab/Amiowned/B1_edit_B2_unc_scm_z.txt',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren/B2_unc_lg_scm.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren/B2_unc_lg_scm.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren/B2_unc_med_scm.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren/B2_unc_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_ren_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_ren_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname/B2_unc_lg_scm.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname/B2_unc_lg_scm.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname/B2_unc_med_scm.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname/B2_unc_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_add_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_del_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_edit_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_ren_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_renname_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_renname_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B1_unc_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B1_unc_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B2_add/B1_unc_med_scm.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B2_add/B1_unc_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/B2_deladd/B1_add_B2_add_med_scm.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/B2_deladd/B1_add_B2_add_med_scm.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_del_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_ren_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_add_B2_unc_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_add_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_del_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_del_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_del_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_lg.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_med.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.txt' => {
    mergeaction   => 'non_trivial',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_edit_scm_z.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_lg.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_med.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '1',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.bin',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.bin',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '1',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.txt',
    base          => '//matlab/Ami/matlab/Amiowned/dir1/B1_edit_B2_unc_scm_z.txt',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_add_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_z.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_ren_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_add_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_add_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_del_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_del_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_edit_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_ren_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_lg.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_lg.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_med.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_med.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_z.bin' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_z.txt' => {
    mergeaction   => 'trivial',
    p4resolved    => '1',
    resolved      => '1',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_renname_B2_unc_scm_z.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_lg.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_lg.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_lg.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_lg.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_med.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_med.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_med.txt' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_med.txt',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_z.bin' => {
    mergeaction   => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_z.bin',
    base          => '',
},
'//matlab/Bmi/matlab/Amiowned/dir1/B1_unc_B2_add_scm_z.txt' => {
    mergeaction => 'cant',
    p4resolved    => '',
    resolved      => '',
    typemerge     => '1',
    typepropagate => '',
    sourcefile    => '//matlab/Ami/matlab/Amiowned/dir1/B1_unc_B2_add_scm_z.txt',
    base          => '',
},
);

1;


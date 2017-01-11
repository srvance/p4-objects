#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 28;

my $trustme = { trustme => [ qr/open|close|STORABLE_thaw_post|STORABLE_freeze_pre/ ] };
pod_coverage_ok( 'P4::Objects' );
pod_coverage_ok( 'P4::Objects::BasicConnection' );
pod_coverage_ok( 'P4::Objects::Changelist' );
pod_coverage_ok( 'P4::Objects::ChangelistRevision' );
pod_coverage_ok( 'P4::Objects::Connection' );
# We specifically want to avoid P4::Objects::Exception.
pod_coverage_ok( 'P4::Objects::FileType' );
pod_coverage_ok( 'P4::Objects::FstatResult' );
pod_coverage_ok( 'P4::Objects::IntegrationRecord' );
pod_coverage_ok( 'P4::Objects::Label' );
pod_coverage_ok( 'P4::Objects::OpenRevision' );
pod_coverage_ok( 'P4::Objects::PendingChangelist' );
pod_coverage_ok( 'P4::Objects::PendingResolve' );
pod_coverage_ok( 'P4::Objects::IntegrateResults', $trustme );
pod_coverage_ok( 'P4::Objects::IntegrateResult' );
pod_coverage_ok( 'P4::Objects::RawConnection' );
pod_coverage_ok( 'P4::Objects::Repository' );
pod_coverage_ok( 'P4::Objects::Revision' );
pod_coverage_ok( 'P4::Objects::Session' );
pod_coverage_ok( 'P4::Objects::SubmittedChangelist' );
pod_coverage_ok( 'P4::Objects::SyncResults' );
pod_coverage_ok( 'P4::Objects::Workspace' );
pod_coverage_ok( 'P4::Objects::WorkspaceRevision' );
pod_coverage_ok( 'P4::Objects::Common::AccessUpdateForm' );
pod_coverage_ok( 'P4::Objects::Common::Base', $trustme );
pod_coverage_ok( 'P4::Objects::Common::BinaryOptions' );
pod_coverage_ok( 'P4::Objects::Common::Form' );
pod_coverage_ok( 'P4::Objects::Extensions::MergeResolveData' );
#
# NOTE: open and close are falsely reported because this module us using Fatal for them
#
pod_coverage_ok( 'P4::Objects::Extensions::MergeResolveTracker', $trustme );

#!perl -T

use Test::More tests => 29;

BEGIN {
	use_ok( 'P4::Objects' );
	use_ok( 'P4::Objects::BasicConnection' );
	use_ok( 'P4::Objects::Changelist' );
	use_ok( 'P4::Objects::ChangelistRevision' );
	use_ok( 'P4::Objects::Connection' );
	use_ok( 'P4::Objects::Exception' );
	use_ok( 'P4::Objects::IntegrationRecord' );
	use_ok( 'P4::Objects::FileType' );
	use_ok( 'P4::Objects::FstatResult' );
	use_ok( 'P4::Objects::Label' );
	use_ok( 'P4::Objects::OpenRevision' );
	use_ok( 'P4::Objects::PendingChangelist' );
	use_ok( 'P4::Objects::PendingResolve' );
        use_ok( 'P4::Objects::IntegrateResults' );
        use_ok( 'P4::Objects::IntegrateResult' );
	use_ok( 'P4::Objects::RawConnection' );
	use_ok( 'P4::Objects::Repository' );
	use_ok( 'P4::Objects::Revision' );
	use_ok( 'P4::Objects::Session' );
	use_ok( 'P4::Objects::SubmittedChangelist' );
	use_ok( 'P4::Objects::SyncResults' );
	use_ok( 'P4::Objects::Workspace' );
	use_ok( 'P4::Objects::WorkspaceRevision' );
	use_ok( 'P4::Objects::Common::AccessUpdateForm' );
	use_ok( 'P4::Objects::Common::Base' );
	use_ok( 'P4::Objects::Common::BinaryOptions' );
	use_ok( 'P4::Objects::Common::Form' );
	use_ok( 'P4::Objects::Extensions::MergeResolveTracker' );
	use_ok( 'P4::Objects::Extensions::MergeResolveData' );
}

diag( "Testing P4::Objects $P4::Objects::VERSION, Perl $], $^X" );

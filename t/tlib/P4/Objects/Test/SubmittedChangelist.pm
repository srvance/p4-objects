# Copyright (C) 2007 Stephen Vance
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

package P4::Objects::Test::SubmittedChangelist;

use strict;
use warnings;

use Date::Parse;
use P4::Objects::Session;
use P4::Objects::SubmittedChangelist;
use P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec;

use base qw( P4::Objects::Test::Helper::TestCase );

our $session_id = 0xaccede;
our $wsname = 'unusualworkspace';
our $changeno = 17;

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub test_new {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );
    $self->assert_not_null( $cl );
    $self->assert( $cl->isa( 'P4::Objects::Common::Base' ) );

    return;
}

sub test_new_real_server {
    my $self = shift;

    my $user = 'someuser';
    my $workspace = 'thisworkspace';
    my $changeno = 1;
    my $date = 1189630224;
    my $description = "Seed the depot.\n";

    my $checkpoint =<<EOC;
\@pv\@ 0 \@db.counters\@ \@change\@ 1 
\@pv\@ 0 \@db.counters\@ \@journal\@ 1 
\@pv\@ 0 \@db.counters\@ \@upgrade\@ 15 
\@ex\@ 10740 1189630265
\@pv\@ 3 \@db.user\@ \@$user\@ \@$user\@\@$workspace\@ \@\@ 1189629934 1189630265 \@$user\@ \@\@ 0 \@\@ 0 
\@ex\@ 10740 1189630265
\@pv\@ 1 \@db.depot\@ \@depot\@ 0 \@\@ \@depot/...\@ 
\@ex\@ 10740 1189630265
\@pv\@ 4 \@db.domain\@ \@depot\@ 100 \@\@ \@\@ \@\@ \@\@ \@\@ 1189629883 1189629883 0 \@Default depot\@ 
\@pv\@ 4 \@db.domain\@ \@$workspace\@ 99 \@\@ \@CLIENTROOT\@ \@\@ \@\@ \@$user\@ 1189629941 1189629941 0 \@Created by $user.
\@ 
\@ex\@ 10740 1189630265
\@pv\@ 1 \@db.view\@ \@$workspace\@ 0 0 \@//$workspace/...\@ \@//depot/...\@ 
\@ex\@ 10740 1189630265
\@pv\@ 7 \@db.rev\@ \@//depot/binary.bin\@ 1 65539 0 $changeno $date 1189629982 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/binary.bin\@ \@1.1\@ 65539 
\@pv\@ 7 \@db.rev\@ \@//depot/text.txt\@ 1 0 0 $changeno $date 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/text.txt\@ \@1.1\@ 0 
\@ex\@ 10740 1189630265
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/binary.bin\@ 1 0 
\@pv\@ 0 \@db.revcx\@ $changeno \@//depot/text.txt\@ 1 0 
\@ex\@ 10740 1189630265
\@pv\@ 7 \@db.revhx\@ \@//depot/binary.bin\@ 1 65539 0 $changeno $date 1189629982 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/binary.bin\@ \@1.1\@ 65539 
\@pv\@ 7 \@db.revhx\@ \@//depot/text.txt\@ 1 0 0 $changeno $date 1189629978 D41D8CD98F00B204E9800998ECF8427E 0 0 0 \@//depot/text.txt\@ \@1.1\@ 0 
\@ex\@ 10740 1189630265
\@pv\@ 0 \@db.change\@ $changeno $changeno \@$workspace\@ \@$user\@ $date 1 \@$description\@ 
\@ex\@ 10740 1189630265
\@pv\@ 0 \@db.desc\@ $changeno \@$description\@ 
\@ex\@ 10740 1189630265
EOC

    my $server = $self->_create_p4d( {
        journal     => $checkpoint,
    } );
    my $port = $server->get_port();

    my $session = P4::Objects::Session->new();
    $session->set_port( $port );

    my $cl = P4::Objects::SubmittedChangelist->new( {
        session     => $session,
        changeno    => $changeno,
    } );

    $self->assert_not_null( $cl );
    $self->assert_equals( $changeno, $cl->get_changeno() );
    $self->assert( $cl->is_submitted() );
    $self->assert_equals( $workspace, $cl->get_workspace() );
    $self->assert_equals( $user, $cl->get_user() );
    $self->assert_equals( $date, $cl->get_date() );
    $self->assert_equals( $description, $cl->get_description() );
    $self->assert_equals( 2, scalar @{$cl->get_files()} );

    return;
}

sub test_get_session {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );
    $self->assert_equals( $session_id, $cl->get_session() );

    return;
}

sub test_get_workspace {
    my $self = shift;

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );
    $self->assert_equals( $wsname, $cl->get_workspace() );

    return;
}

sub test_set_get_date_number {
    my $self = shift;
    my $expected_date = 1186014538;

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_date() );

    {
        package P4::Objects::Changelist;
        $cl->_set_date( $expected_date );
    }
    my $gotten_date = $cl->get_date();

    $self->assert_equals( $expected_date, $gotten_date );

    return;
}

sub test_set_get_date_formatted {
    my $self = shift;
    my $input_date = '2007/08/02 10:28:58';
    my $expected_date = str2time( $input_date );

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_date() );

    {
        package P4::Objects::Changelist;
        $cl->_set_date( $input_date );
    }
    my $gotten_date = $cl->get_date();

    $self->assert_equals( $expected_date, $gotten_date );

    return;
}

sub test_set_get_user {
    my $self = shift;
    my $expected_user = 'anothernameforme';

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_user() );

    {
        package P4::Objects::Changelist;
        $cl->_set_user( $expected_user );
    }
    my $gotten_user = $cl->get_user();

    $self->assert_equals( $expected_user, $gotten_user );

    return;
}

# TODO: This should be updated to handle the use of Revision objects to
# contain the file information. For now it doesn't matter as the logic is the
# same.
sub test_set_get_files_cache {
    my $self = shift;
    my $expected_files = [ 'file1', 'file2' ];

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    {
        package P4::Objects::Changelist;
        $cl->_set_files_cache( $expected_files );
    }
    my $gotten_files = $cl->get_files();

    $self->assert_equals( $expected_files, $gotten_files );
    $self->assert_deep_equals( $expected_files, $gotten_files );

    return;
}


sub test_set_get_description {
    my $self = shift;
    my $expected_description = 'Is this really likely text for a description?';

    my $cl = P4::Objects::Test::Helper::SubmittedChangelist::NoopLoadSpec->new( {
                        session     => $session_id,
                        workspace   => $wsname,
                        changeno    => $changeno,
    } );

    $self->assert_null( $cl->get_description() );

    {
        package P4::Objects::Changelist;
        $cl->_set_description( $expected_description );
    }
    my $gotten_description = $cl->get_description();

    $self->assert_equals( $expected_description, $gotten_description );

    return;
}

1;

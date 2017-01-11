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

package P4::Objects::Common::Test::Base;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Common::Base;
use P4::Objects::Exception;

use base qw( P4::Objects::Test::Helper::TestCase );

use P4::Objects::Common::Test::Helper::EnsureArray;

my $sessionid = 0x0badf00d;

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

sub test_new_get_session {
    my $self = shift;

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    $self->assert_equals( $sessionid, $base->get_session() );

    return;
}

sub test_get_session_bad_session {
    my $self = shift;

    my $base = P4::Objects::Common::Base->new( {
        session => undef,
    } );

    try {
        $base->get_session();
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch P4::Objects::Exception::InvalidSession with {
        # Expected behavior
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

# Coverage motivated. This will throw a system exception if it tries to weaken
# an undefined value.
sub test_weaken_session_bad_session {
    my $self = shift;

    my $base = P4::Objects::Common::Base->new( {
        session => undef,
    } );

    {
        package P4::Objects::Common::Base;

        $base->_weaken_session();
    }

    return;
}

sub test_get_connection {
    my $self = shift;

    my $conn = 0xdeadbeef;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_connection( $conn );

    my $base = P4::Objects::Common::Base->new( {
        session => $session,
    } );

    $self->assert_equals( $conn, $base->get_connection() );

    return;
}

sub test_get_repository {
    my $self = shift;

    my $repo = 0xdeadbeef;

    my $session = P4::Objects::Test::Helper::Session::Mock->new();
    $session->set_repository( $repo );

    my $base = P4::Objects::Common::Base->new( {
        session => $session,
    } );

    $self->assert_equals( $repo, $base->get_repository() );

    return;
}

sub test_translate_special_chars_to_codes_percent {
    my $self = shift;

    my $chars = '%';
    my $expected_codes = '%25';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_special_chars_to_codes_at {
    my $self = shift;

    my $chars = '@';
    my $expected_codes = '%40';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_special_chars_to_codes_hash {
    my $self = shift;

    my $chars = '#';
    my $expected_codes = '%23';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_special_chars_to_codes_asterisk {
    my $self = shift;

    my $chars = '*';
    my $expected_codes = '%2A';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_special_chars_to_codes_multiple_hash_first {
    my $self = shift;

    my $chars = '%@#*';
    my $expected_codes = '%25%40%23%2A';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_special_chars_to_codes_multiple_hash_last {
    my $self = shift;

    my $chars = '@#*%';
    my $expected_codes = '%40%23%2A%25';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_special_chars_to_codes( $chars );

    $self->assert_equals( $expected_codes, $result );

    return;
}

sub test_translate_codes_to_special_chars_percent {
    my $self = shift;

    my $codes = '%25';
    my $expected_chars = '%';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_translate_codes_to_special_chars_asterisk {
    my $self = shift;

    my $codes = '%2A';
    my $expected_chars = '*';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_translate_codes_to_special_chars_hash {
    my $self = shift;

    my $codes = '%23';
    my $expected_chars = '#';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_translate_codes_to_special_chars_at {
    my $self = shift;

    my $codes = '%40';
    my $expected_chars = '@';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_translate_codes_to_special_chars_multiple_hash_first {
    my $self = shift;

    my $codes = '%25%40%23%2A';
    my $expected_chars = '%@#*';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_translate_codes_to_special_chars_multiple_hash_last {
    my $self = shift;

    my $codes = '%40%23%2A%25';
    my $expected_chars = '@#*%';

    my $base = P4::Objects::Common::Base->new( {
        session => $sessionid,
    } );

    my $result = $base->translate_codes_to_special_chars( $codes );

    $self->assert_equals( $expected_chars, $result );

    return;
}

sub test_ensure_arrayref {
    my ($self) = @_;

    my $ensure_arrayref = P4::Objects::Common::Test::Helper::EnsureArray->new( {
        session => $sessionid,
    } );

    my $expected_result = [];
    my $result = $ensure_arrayref->test_ensure_arrayref( );
    $self->assert_deep_equals( $expected_result, $result );

    #
    # Special case of a single undef should return [] and not [ undef ]
    #
    $result = $ensure_arrayref->test_ensure_arrayref( undef );
    $self->assert_deep_equals( $expected_result, $result );

    $expected_result = [ 'a' ];
    $result = $ensure_arrayref->test_ensure_arrayref( 'a' );
    $self->assert_deep_equals( $expected_result, $result );

    $expected_result = ['a', 'b'];
    $result = $ensure_arrayref->test_ensure_arrayref( 'a', 'b' );
    $self->assert_deep_equals( $expected_result, $result );

    $expected_result = [ 'a', 'b' ];
    $result = $ensure_arrayref->test_ensure_arrayref( $expected_result );
    $self->assert_equals( $expected_result, $result );
}

1;

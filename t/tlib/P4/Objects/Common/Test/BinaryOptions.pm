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

package P4::Objects::Common::Test::BinaryOptions;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Common::BinaryOptions;

use base qw( P4::Objects::Test::Helper::TestCase );

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

sub test_new_none {
    my $self = shift;

    try {
        P4::Objects::Common::BinaryOptions->new();
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch Error::Simple with {
        # Expected behavior
        my $e = shift;

        $self->assert_matches(
            qr/\AMissing initializer label for P4::Objects::Common::BinaryOptions: 'Options'./,
            $e->{-text},
            'Unexpected derivative of Error::Simple: ' . Dumper( $e )
        );
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_new_single_general_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );

    return;
}

sub test_new_single_general_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'nofirst',
    } );

    my $first = $opts->get_first();
    $self->assert( ! $first );

    return;
}

sub test_new_single_locked_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'locked',
    } );

    my $locked = $opts->get_locked();
    $self->assert( $locked );

    return;
}

sub test_new_single_locked_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'unlocked',
    } );

    my $locked = $opts->get_locked();
    $self->assert( ! $locked );

    return;
}

sub test_new_multiple_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first second third',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );
    my $second = $opts->get_second();
    $self->assert( $second );
    my $third = $opts->get_third();
    $self->assert( $third );

    return;
}

sub test_new_multiple_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'nofirst nosecond nothird',
    } );

    my $first = $opts->get_first();
    $self->assert( ! $first );
    my $second = $opts->get_second();
    $self->assert( ! $second );
    my $third = $opts->get_third();
    $self->assert( ! $third );

    return;
}

sub test_new_multiple_locked_first_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'locked second third',
    } );

    my $locked = $opts->get_locked();
    $self->assert( $locked );
    my $second = $opts->get_second();
    $self->assert( $second );
    my $third = $opts->get_third();
    $self->assert( $third );

    return;
}

sub test_new_multiple_locked_first_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'unlocked second third',
    } );

    my $locked = $opts->get_locked();
    $self->assert( ! $locked );
    my $second = $opts->get_second();
    $self->assert( $second );
    my $third = $opts->get_third();
    $self->assert( $third );

    return;
}

sub test_new_multiple_locked_second_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first locked third',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );
    my $locked = $opts->get_locked();
    $self->assert( $locked );
    my $third = $opts->get_third();
    $self->assert( $third );

    return;
}

sub test_new_multiple_locked_second_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first unlocked third',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );
    my $locked = $opts->get_locked();
    $self->assert( ! $locked );
    my $third = $opts->get_third();
    $self->assert( $third );

    return;
}

sub test_new_multiple_locked_last_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first second locked',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );
    my $second = $opts->get_second();
    $self->assert( $second );
    my $locked = $opts->get_locked();
    $self->assert( $locked );

    return;
}

sub test_new_multiple_locked_last_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first second unlocked',
    } );

    my $first = $opts->get_first();
    $self->assert( $first );
    my $second = $opts->get_second();
    $self->assert( $second );
    my $locked = $opts->get_locked();
    $self->assert( ! $locked );

    return;
}

sub test_set_general_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'noopt',
    } );

    $self->assert_equals( 0, $opts->get_opt() );

    my $expected_value = 1;

    $opts->set_opt( $expected_value );

    $self->assert_equals( $expected_value, $opts->get_opt() );

    return;
}

sub test_set_general_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'opt',
    } );

    $self->assert_equals( 1, $opts->get_opt() );

    my $expected_value = 0;

    $opts->set_opt( $expected_value );

    $self->assert_equals( $expected_value, $opts->get_opt() );

    return;
}

sub test_set_locked_true {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'unlocked',
    } );

    $self->assert_equals( 0, $opts->get_locked() );

    my $expected_value = 1;

    $opts->set_locked( $expected_value );

    $self->assert_equals( $expected_value, $opts->get_locked() );

    return;
}

sub test_set_locked_false {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'locked',
    } );

    $self->assert_equals( 1, $opts->get_locked() );

    my $expected_value = 0;

    $opts->set_locked( $expected_value );

    $self->assert_equals( $expected_value, $opts->get_locked() );

    return;
}

sub test_stringify_true {
    my $self = shift;

    # Let's start with the wrong string just to ensure that the initial string
    # is not what is being parroted back.
    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'nofirst unlocked nosecond nothird',
    } );

    $opts->set_first( 1 );
    $opts->set_locked( 1 );
    $opts->set_second( 1 );
    $opts->set_third( 1 );

    my $expected_string = 'first locked second third';
    $self->assert_equals( $expected_string, $opts );

    return;
}

sub test_stringify_false {
    my $self = shift;

    # Let's start with the wrong string just to ensure that the initial string
    # is not what is being parroted back.
    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first locked second third',
    } );

    $opts->set_first( 0 );
    $opts->set_locked( 0 );
    $opts->set_second( 0 );
    $opts->set_third( 0 );

    my $expected_string = 'nofirst unlocked nosecond nothird';
    $self->assert_equals( $expected_string, $opts );

    return;
}

sub test_nonexistent_method {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first',
    } );

    my $method = 'get_nonoption';
    try {
        $opts->$method();
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch Error::Simple with {
        my $e = shift;

        $self->assert_matches(
            qr/\ACan't locate object method "$method" via package/,
            $e->{-text}
        )
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_bad_prefix_valid_option {
    my $self = shift;

    my $opts = P4::Objects::Common::BinaryOptions->new( {
        Options => 'first',
    } );

    my $method = 'corrupt_first';
    try {
        $opts->$method();
        $self->assert( 0, 'Did not catch exception as expected' );
    }
    catch Error::Simple with {
        my $e = shift;

        $self->assert_matches(
            qr/\ACan't locate object method "$method" via package/,
            $e->{-text}
        )
    }
    otherwise {
        my $e = shift;

        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

1;

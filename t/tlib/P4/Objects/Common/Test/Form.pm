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

package P4::Objects::Common::Test::Form;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Common::Form;
use P4::Objects::Common::Test::Helper::Form::NoopLoadSpec;
use P4::Objects::Common::Test::Helper::Form::InspectInit;
use P4::Objects::Exception;

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

sub test_new_no_attrs_incomplete {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::Form->new( {
            session => $sessionid,
        } );
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'P4::Objects::Common::Form', $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_new_no_attrs_validated {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::Test::Helper::Form::InspectInit->new( {
            session => $sessionid,
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    $self->assert_not_null( $form );
    $self->assert( ! $form->get_used_attrs() );
    $self->assert( $form->get_loaded_spec() );

    return;
}

sub test_new_with_attrs {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::Form->new( {
            session => $sessionid,
            attrs   => {},
        } );
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( 'P4::Objects::Common::Form', $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_new_with_attrs_validated {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::Test::Helper::Form::InspectInit->new( {
            session => $sessionid,
            attrs   => {},
        } );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    $self->assert_not_null( $form );
    $self->assert( $form->get_used_attrs() );
    $self->assert( ! $form->get_loaded_spec() );

    return;
}

sub test_is_new_failure {
    my $self = shift;

    my $class = 'P4::Objects::Common::Test::Helper::Form::NoopLoadSpec';
    my $form = $class->new( {
        session => $sessionid,
    } );

    try {
        $form->is_new( {
            session => $sessionid,
        } );
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $class, $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_is_existing_failure {
    my $self = shift;

    my $class = 'P4::Objects::Common::Test::Helper::Form::NoopLoadSpec';
    my $form = $class->new( {
        session => $sessionid,
    } );

    try {
        $form->is_existing();
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals( $class, $e->class() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

1;

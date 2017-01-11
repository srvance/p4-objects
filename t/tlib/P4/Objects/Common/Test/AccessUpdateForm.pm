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

package P4::Objects::Common::Test::AccessUpdateForm;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Common::AccessUpdateForm;
use P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec;
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

sub test_new_no_attrs {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::AccessUpdateForm->new( {
            session => $sessionid,
        } );
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals(
            'P4::Objects::Common::AccessUpdateForm',
            $e->class(),
        );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_new_with_attrs {
    my $self = shift;

    my $form;
    try {
        $form = P4::Objects::Common::AccessUpdateForm->new( {
            session => $sessionid,
            attrs   => {},
        } );
        $self->assert( 0, 'Did not get exception as expected' );
    }
    catch P4::Objects::Exception::IncompleteClass with {
        # Expected behavior
        my $e = shift;
        $self->assert_equals(
            'P4::Objects::Common::AccessUpdateForm',
            $e->class(),
        );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, 'Caught unexpected exception: ' . Dumper( $e ) );
    };

    return;
}

sub test_new_access {
    my $self = shift;
    my $access = 235711;
    my $update = 13171923;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session     => $sessionid,
        access      => $access,
        update      => $update,
    } );

    $self->assert_not_null( $form );
    $self->assert_not_null( $form->get_access() );
    $self->assert_equals( $access, $form->get_access() );

    return;
}

sub test_new_update {
    my $self = shift;
    my $access = 235711;
    my $update = 13171923;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session     => $sessionid,
        access      => $access,
        update      => $update,
    } );

    $self->assert_not_null( $form->get_update() );
    $self->assert_equals( $update, $form->get_update() );

    return;
}

sub test_new_inconsistent_no_access {
    my $self = shift;
    my $update = 13171923;

    try {
        my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
            session     => $sessionid,
            access      => undef,
            update      => $update,
        } );
        $self->assert( 0, 'Did not catch the expected exception' );
    }
    catch P4::Objects::Exception::InconsistentFormState with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'access', $e->missing() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Caught unexpected exception:\n" . Dumper( $e ) );
    };

    return;
}

sub test_new_inconsistent_no_update {
    my $self = shift;
    my $access = 235711;

    try {
        my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
            access      => $access,
            update      => undef,
        } );
        $self->assert( 0, 'Did not catch the expected exception' );
    }
    catch P4::Objects::Exception::InconsistentFormState with {
        # Expected behavior
        my $e = shift;

        $self->assert_equals( 'update', $e->missing() );
    }
    otherwise {
        my $e = shift;
        $self->assert( 0, "Caught unexpected exception:\n" . Dumper( $e ) );
    };

    return;
}

sub test_is_new_true {
    my $self = shift;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session => $sessionid,
    } );

    $self->assert( $form->is_new() );

    return;
}

sub test_is_new_false {
    my $self = shift;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session     => $sessionid,
        access      => 235711,
        update      => 13171923,
    } );

    $self->assert( ! $form->is_new() );

    return;
}

sub test_is_new_dysfunctional_for_coverage {
    my $self = shift;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session     => $sessionid,
        access      => 235711,
        update      => 13171923,
    } );

    {
        package P4::Objects::Common::AccessUpdateForm;

        $form->_set_access_only( undef );
    }

    $self->assert( ! $form->is_new() );

    return;
}

sub test_is_existing_true {
    my $self = shift;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session     => $sessionid,
        access      => 235711,
        update      => 13171923,
    } );

    $self->assert( $form->is_existing() );

    return;
}

sub test_is_existing_false {
    my $self = shift;

    my $form = P4::Objects::Common::Test::Helper::AccessUpdateForm::NoopLoadSpec->new( {
        session => $sessionid,
    } );

    $self->assert( ! $form->is_existing() );

    return;
}

1;

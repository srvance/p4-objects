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

package P4::Objects::Test::FileType;

use strict;
use warnings;

use P4::Objects::FileType;

use base qw( P4::Objects::Test::Helper::TestCase );

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

# We're testing stringify for each variation rather than repeating the
# permutations specifically for that purpose.
sub test_new_no_init_val {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    my $expected_type = 'text';
    $self->assert_not_null( $ft );
    $self->assert_equals( $expected_type, $ft->get_basetype() );

    for my $mod ( $ft->get_modifiers() ) {
        my $method = "get_$mod";
        $self->assert_equals( 0, $ft->$method(),
            "Processing $mod: Got " . $ft->$method()
        );
    }

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_basetype_only {
    my $self = shift;

    my $ft = P4::Objects::FileType->new( { type => 'binary' } );

    $self->assert_equals( 'binary', $ft->get_basetype() );

    $self->assert_equals( 'binary', $ft );

    return;
}

sub test_new_with_keyword {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+k';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_keyword_expansion() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_old_keyword {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+ko';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_old_keyword_expansion() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_store_compressed {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+C';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_store_compressed() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_store_deltas {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+D';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_store_deltas() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_store_full_file {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+F';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_store_full_file() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_stored_revisions_no_number {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+S';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_stored_revisions() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_stored_revisions_one {
    my $self = shift;

    my $expected_basetype = 'binary';
    my $expected_type = $expected_basetype . '+S';
    my $ft = P4::Objects::FileType->new( { type => $expected_type . '1' } );

    $self->assert_equals( $expected_basetype, $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_stored_revisions() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_stored_revisions_multiple {
    my $self = shift;

    my @valid_counts = (
        2, 3, 4, 5, 6, 7, 8, 9, 10, # 2-10
        16, 32, 64, 128, 256, 512,  # powers of 2
    );

    for my $count ( @valid_counts ) {
        my $expected_basetype = 'binary';
        my $expected_type = $expected_basetype . '+S' . $count;
        my $ft = P4::Objects::FileType->new( { type => $expected_type } );

        $self->assert_equals( $expected_basetype, $ft->get_basetype() );
        $self->assert_equals( $count, $ft->get_stored_revisions() );

        $self->assert_equals( $expected_type, $ft );
    }

    return;
}

sub test_new_with_non_exclusive_modifiers {
    my $self = shift;

    my $expected_type = 'binary+lmwx';
    my $ft = P4::Objects::FileType->new( { type => $expected_type } );

    $self->assert_equals( 'binary', $ft->get_basetype() );
    $self->assert_equals( 1, $ft->get_exclusive_open() );
    $self->assert_equals( 1, $ft->get_use_modtime() );
    $self->assert_equals( 1, $ft->get_sync_writable() );
    $self->assert_equals( 1, $ft->get_executable() );

    $self->assert_equals( $expected_type, $ft );

    return;
}

sub test_new_with_aliases {
    my $self = shift;

    # Taken from the Perforce documentation
    my %type_aliases = (
        'ctext'      => 'text+C',
        'cxtext'     => 'text+Cx',
        'ktext'      => 'text+k',
        'kxtext'     => 'text+kx',
        'ltext'      => 'text+F',
        'tempobj'    => 'binary+Sw',
        'ubinary'    => 'binary+F',
        'uresource'  => 'resource+F',
        'uxbinary'   => 'binary+Fx',
        'xbinary'    => 'binary+x',
        'xltext'     => 'text+Fx',
        'xtempobj'   => 'binary+Swx',
        'xtext'      => 'text+x',
        'xunicode'   => 'unicode+x',
        'xutf16'     => 'utf16+x',
    );

    for my $alias ( keys %type_aliases ) {
        my $ft = P4::Objects::FileType->new( { type => $alias } );

        $self->assert_equals( $type_aliases{$alias}, $ft );
    }

    return;
}

sub test_get_set_modifiers {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    for my $mod ( $ft->get_modifiers() ) {
        my $get_method = "get_$mod";
        my $set_method = "set_$mod";

        # Assert precondition
        $self->assert_equals( 0, $ft->$get_method(), "Processing $mod" );

        my $expected_value = 1;
        # Set modifier
        $ft->$set_method( $expected_value );

        # Verify change
        $self->assert_equals( $expected_value, $ft->$get_method(),
            "Processing $mod: Got " .  $ft->$get_method()
        );

        $expected_value = 0;
        # Set modifier
        $ft->$set_method( $expected_value );

        # Verify change
        $self->assert_equals( $expected_value, $ft->$get_method(),
            "Processing $mod: Got " .  $ft->$get_method()
        );
    }

    return;
}

sub test_get_set_stored_revisions_explicit {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    my @valid_counts = (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        16, 32, 64, 128, 256, 512,
    );

    for my $expected_count ( @valid_counts ) {
        $ft->set_stored_revisions( 0 );

        $self->assert_equals( 0, $ft->get_stored_revisions() );

        $ft->set_stored_revisions( $expected_count );

        $self->assert_equals( $expected_count, $ft->get_stored_revisions() );
    }

    return;
}

sub test_set_keywords_exclusive {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    # Assert preconditions
    $self->assert_equals( 0, $ft->get_keyword_expansion() );
    $self->assert_equals( 0, $ft->get_old_keyword_expansion() );

    $ft->set_keyword_expansion( 1 );

    $self->assert_equals( 1, $ft->get_keyword_expansion() );
    $self->assert_equals( 0, $ft->get_old_keyword_expansion() );

    $ft->set_old_keyword_expansion( 1 );
    $self->assert_equals( 0, $ft->get_keyword_expansion() );
    $self->assert_equals( 1, $ft->get_old_keyword_expansion() );

    $ft->set_keyword_expansion( 1 );
    $self->assert_equals( 1, $ft->get_keyword_expansion() );
    $self->assert_equals( 0, $ft->get_old_keyword_expansion() );

    return;
}

sub test_set_storage_exclusive {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    # Assert preconditions
    $self->assert_equals( 0, $ft->get_store_compressed() );
    $self->assert_equals( 0, $ft->get_store_deltas() );
    $self->assert_equals( 0, $ft->get_store_full_file() );

    $ft->set_store_compressed( 1 );

    $self->assert_equals( 1, $ft->get_store_compressed() );
    $self->assert_equals( 0, $ft->get_store_deltas() );
    $self->assert_equals( 0, $ft->get_store_full_file() );

    $ft->set_store_deltas( 1 );

    $self->assert_equals( 0, $ft->get_store_compressed() );
    $self->assert_equals( 1, $ft->get_store_deltas() );
    $self->assert_equals( 0, $ft->get_store_full_file() );

    $ft->set_store_full_file( 1 );

    $self->assert_equals( 0, $ft->get_store_compressed() );
    $self->assert_equals( 0, $ft->get_store_deltas() );
    $self->assert_equals( 1, $ft->get_store_full_file() );

    return;
}

sub test_stringify_keywords {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $ft->set_keyword_expansion( 1 );

    $self->assert_equals( 'text+k', $ft );

    return;
}

sub test_stringify_old_keywords {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $ft->set_old_keyword_expansion( 1 );

    # Make sure we have at least one use of get_type_string() directly
    $self->assert_equals( 'text+ko', $ft->get_type_string() );

    return;
}

sub test_stringify_store_compressed {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $ft->set_store_compressed( 1 );

    $self->assert_equals( 'text+C', $ft );

    return;
}

sub test_stringify_store_deltas {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $ft->set_store_deltas( 1 );

    $self->assert_equals( 'text+D', $ft );

    return;
}

sub test_stringify_store_full_file {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $ft->set_store_full_file( 1 );

    $self->assert_equals( 'text+F', $ft );

    return;
}

sub test_stringify_non_exclusive_modifiers {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    for my $mod ( $ft->get_modifiers() ) {
        # Skip keywords. They're tested separately
        if( $mod =~ /(keyword|store)/ ) {
            next;
        }

        my $method = "set_$mod";
        $ft->$method( 1 );
    }

    $self->assert_equals( 'text+lmwx', $ft );

    return;
}

sub test_get_modifiers {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    my @mods = $ft->get_modifiers();

    $self->assert_not_equals( 0, scalar @mods );
    $self->assert_equals( sort @mods, @mods );

    return;
}

sub test_get_invalid_modifier {
    my $self = shift;

    my $modifier = 'notavalidmodifier';

    my $ft = P4::Objects::FileType->new();

    # Assert pre-conditions that we're using an invalid modifier
    my @mods = $ft->get_modifiers();
    $self->assert_equals( 0, scalar grep { /$modifier/ } @mods );

    $self->assert( ! $ft->can( "get_$modifier" ) );

    return;
}

sub test_unsupported_method_no_underscore {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $self->assert( ! $ft->can( 'invalidmethod' ) );

    return;
}

sub test_unsupported_method_with_underscore {
    my $self = shift;

    my $ft = P4::Objects::FileType->new();

    $self->assert( ! $ft->can( 'invalid_method' ) );

    return;
}

sub test_equal_same {
    my $self = shift;

    # Note: Modifiers are deliberately out of alpha order
    my $type = 'text+lkw';
    my $ft = P4::Objects::FileType->new( { type => $type } );

    $self->assert( $ft->equals( $type ) );

    return;
}

sub test_equal_same_mods_different_order {
    my $self = shift;

    # Note: Modifiers are deliberately out of alpha order
    my $lhs_type = 'text+lkw';
    my $rhs_type = 'text+kwl';

    my $ft = P4::Objects::FileType->new( { type => $lhs_type } );

    $self->assert( $ft->equals( $rhs_type ) );

    return;
}

sub test_equal_different_basetype {
    my $self = shift;

    # Note: Modifiers are deliberately out of alpha order
    my $mods = 'lkw';
    my $lhs_base = 'text';
    my $rhs_base = 'binary';

    my $ft = P4::Objects::FileType->new( { type => "$lhs_base+$mods" } );

    $self->assert( ! $ft->equals( "$rhs_base+$mods" ) );

    return;
}

sub test_equal_different_mods {
    my $self = shift;

    # Note: Modifiers are deliberately out of alpha order
    my $base = 'text';
    my $lhs_mods = 'lkw';
    my $rhs_mods = 'xko';

    my $ft = P4::Objects::FileType->new( { type => "$base+$lhs_mods" } );

    $self->assert( ! $ft->equals( "$base+$rhs_mods" ) );

    return;
}

sub test_equal_object {
    my $self = shift;

    my $type = 'text+lkw';
    my $lhs_ft = P4::Objects::FileType->new( { type => $type } );
    my $rhs_ft = P4::Objects::FileType->new( { type => $type } );

    $self->assert( $lhs_ft->equals( $rhs_ft ) );

    return;
}

1;

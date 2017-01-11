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

package P4::Objects::Extensions::Test::MergeResolveData;

use strict;
use warnings;

use Data::Dumper;
use Error qw( :try );
use P4::Objects::Extensions::MergeResolveData;

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

sub test_new_get_all {
    my ($self) = @_;
    my $expected = {
        session           => 'fakesession',
        mergeaction       => 'trivial',
        resolved          => 1,
        p4resolved        => 1,
        integrateresult   => 'ir',
        typemerge         => '',
        typepropagate     => 1,
        sourcerevision    => 'sourcerevision',
        targetrevision    => 'targetrevision',
        baserevision      => 'baserevision',
    };
    my $mrd = P4::Objects::Extensions::MergeResolveData->new( $expected );

    $self->assert_equals( $expected->{session},         $mrd->get_session() );
    $self->assert_equals( $expected->{mergeaction},     $mrd->get_mergeaction() );
    $self->assert_equals( $expected->{resolved},        $mrd->get_resolved() );
    $self->assert_equals( $expected->{p4resolved},      $mrd->get_p4resolved() );
    $self->assert_equals( $expected->{integrateresult}, $mrd->get_integrateresult() );
    $self->assert_equals( $expected->{typemerge},       $mrd->get_typemerge() );
    $self->assert_equals( $expected->{typepropagate},   $mrd->get_typepropagate() );
    $self->assert_equals( $expected->{sourcerevision},  $mrd->get_sourcerevision() );
    $self->assert_equals( $expected->{targetrevision},  $mrd->get_targetrevision() );
    $self->assert_equals( $expected->{baserevision},    $mrd->get_baserevision() );
}
1;


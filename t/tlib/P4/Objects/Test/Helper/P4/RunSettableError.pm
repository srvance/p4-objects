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

package P4::Objects::Test::Helper::P4::RunSettableError;

use strict;
use warnings;

use base qw( P4 );

my $errors_of = [];

sub set_errors {
    my ($self, $errors) = @_;

    $errors_of = $errors;

    return;
}

sub ErrorCount {
    my $self = @_;

    return scalar @{$errors_of};
}

sub Errors {
    my $self = @_;

    return $errors_of;
}

sub Run {
    my ($self, @args) = @_;

    return [];
}

1;

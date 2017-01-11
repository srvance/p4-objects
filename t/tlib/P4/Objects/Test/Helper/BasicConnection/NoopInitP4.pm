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

package P4::Objects::Test::Helper::BasicConnection::NoopInitP4;

use strict;
use warnings;

use base qw( P4::Objects::BasicConnection );

# Do nothing so that coverage can get to later code.
sub _initialize_p4 : RESTRICTED {
    my ($self) = @_;

    # Not really a no-op anymore, but not worth renaming the class.
    my $session = $self->get_session();
    my $port = $session->get_port();
    my $p4 = $self->get_p4();
    $p4->SetPort( $port );

    return;
}

1;

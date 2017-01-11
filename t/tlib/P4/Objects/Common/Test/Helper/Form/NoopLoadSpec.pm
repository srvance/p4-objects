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

package P4::Objects::Common::Test::Helper::Form::NoopLoadSpec;

use strict;
use warnings;

use base qw( P4::Objects::Common::Form );

use Class::Std;

{

sub _set_attrs_from_spec : RESTRICTED {
    return;
}

sub _load_spec : RESTRICTED {
    return;
}

}

1;

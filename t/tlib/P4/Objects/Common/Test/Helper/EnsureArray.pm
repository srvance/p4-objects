
package P4::Objects::Common::Test::Helper::EnsureArray;
use strict;
use warnings;

use Class::Std;
use P4::Objects::Common::Base;
use base qw( P4::Objects::Common::Base );

#
# Since _ensure_arrayref is a RESTRICTED method
# need a helper class to call the method.  Make it a straight
# pass-through for testing purposes
#
sub test_ensure_arrayref {
    my ($self, @args) = @_;
    return $self->_ensure_arrayref( @args );
}

1;

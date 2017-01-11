# Example code implementing Story 33: Sync PWD to current directory on
# Session::new()
use strict;
use warnings;

use P4::Objects::Session;

my $session = P4::Objects::Session->new();

# In order for this to be true, the path needs to be converted to it's true
# path in case of symlinks. Should this be the case? Should I also do that for
# set_cwd()?
if( $ENV{PWD} eq getcwd() ) {
    # Should always be true
}
else {
    # Something's wrong
}

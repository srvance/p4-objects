package P4::Objects::Test::Helper::Session::Mock;

use strict;
use warnings;

use Class::Std;

{
    my %p4_of : ATTR( init_arg => 'p4' default => 'P4' get => 'p4' set => 'p4' );
    my %port_of : ATTR( get => 'port' set => 'port' );
    my %user_of : ATTR( get => 'user' set => 'user' );
    my %host_of : ATTR( default => 'mockhost' get => 'host' set => 'host' );
    my %workspace_of : ATTR( default => 'mockws' get => 'workspace' set => 'workspace' );
    my %charset_of : ATTR( get => 'charset' set => 'charset' );

    my %connection_of : ATTR( get => 'connection' set => 'connection' );
    my %repository_of : ATTR( get => 'repository' set => 'repository' );

sub _get_workspace_name {
    my ($self) = @_;

    return $workspace_of{ident $self};
}

}

1;

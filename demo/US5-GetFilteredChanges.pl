#!/usr/local/bin/perl

use strict;
use warnings;

use Data::Dumper;
use P4::Objects::Session;

my %parms = @ARGV;

# Work with the default settings
my $session = P4::Objects::Session->new();

print "     Port: ", $session->get_port(), "\n";
print "     User: ", $session->get_user(), "\n";
print "Workspace: ", $session->get_workspace(), "\n";
print "*****************\n";

my $repo = $session->get_repository();

my $changes = $repo->get_changelists( \%parms );

my @keys = sort keys %$changes;
print "Number of results: ", scalar @keys, "\n";

if( ! scalar @keys ) {
    print "No changes found\n";
    exit;
}

print "Changelists: ", join( ',', @keys ), "\n";
print "*****************\n";
my $changeno = $keys[-1];
my $change = $changes->{$changeno};
print "Change detail for change $changeno\n";
print "Date: ", $change->get_date(), "\n";
print "Workspace: ", $change->get_workspace(), "\n";
print "User: ", $change->get_user(), "\n";
print "Status: ", $change->get_status(), "\n";
print "Description: ", $change->get_description(), "\n";
#print "Files: \n", join( "\n", @{$change->get_files()} ), "\n";

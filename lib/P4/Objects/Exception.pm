# Copyright (C) 2007-8 Stephen Vance
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

package P4::Objects::Exception;

use warnings;
use strict;

use Error::Exception;

our $VERSION = '0.52';

use Exception::Class (
    'P4::Objects::Exception' => {
        isa         =>  'Error::Exception',
        description =>  'Base class for P4-related exceptions',
    },

    'P4::Objects::Exception::BadAlloc' => {
        isa         =>  'P4::Objects::Exception',
        fields      =>  [ 'class' ],
        description =>  'Class to throw for memory allocation problems',
    },

    'P4::Objects::Exception::BadAutoMethod'  =>  {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'class', 'method' ],
        description => 'Class to throw for an unsupported automatic method',
    },

    'P4::Objects::Exception::BadPackage'    =>  {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'class' ],
        description => 'Class to throw for a bad package reference',
    },

    'P4::Objects::Exception::InvalidDirectory'  =>  {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'directory' ],
        description => 'Class to throw when a name is not a valid directory',
    },

    'P4::Objects::Exception::MissingParameter'  => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'parameter' ],
        description => 'Class to throw when a method parameter is missing',
    },

    'P4::Objects::Exception::InvalidParameter'  => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'parameter', 'reason' ],
        description => 'Class to throw when a method parameter is invalid',
    },

    'P4::Objects::Exception::MissingWorkspaceName' => {
        isa         => 'P4::Objects::Exception',
        description => 'Class to throw when a Workspace object'
                        . ' is missing its name',
    },

    'P4::Objects::Exception::MismatchedWorkspaceName' => {
        isa         => 'P4::Objects::Exception',
        description => 'Class to throw when a Workspace object\'s'
                        . ' name does not match the name supplied'
                        . ' in the attrs parameter',
    },

    'P4::Objects::Exception::InvalidView' => {
        isa         => 'P4::Objects::Exception',
        description => 'Class to throw when a view is improperly formed,'
                        . ' for example when it is not passed as an array',
    },

    'P4::Objects::Exception::UnsupportedFilter' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'filter' ],
        description => 'Class to throw when an illegal or unsupported filter'
                        . ' parameter is passed in a filter context',
    },

    'P4::Objects::Exception::InvalidSession' => {
        isa         => 'P4::Objects::Exception',
        description => 'Class to throw when a weak reference to a session is'
                        . ' no longer valid',
    },

    'P4::Objects::Exception::UnexpectedSyncResults' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'cause' ],
        description => 'Class to throw when sync returns unexpected keys',
    },

    'P4::Objects::Exception::InconsistentFormState' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'missing' ],
        description => 'Class to throw when access or update is set '
                        . 'but not both',
    },

    'P4::Objects::Exception::IncompleteClass' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'class' ],
        description => 'Class to throw when invoking an "abstract" method',
    },

    'P4::Objects::Exception::InappropriateChangelist' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'changeno' ],
        description => 'Class to throw when initializing a PendingChanglist '
                        . 'with the number for a non-PendingChangelist',
    },

    # P4-specific exceptions

    'P4::Objects::Exception::P4' => {
        isa         => 'P4::Objects::Exception',
        fields      => [ 'errorcount', 'errors' ],
        description => 'Class to throw when there are errors in a P4 command',
    },

    'P4::Objects::Exception::P4::CantConnect' => {
        isa         => 'P4::Objects::Exception::P4',
        fields      => [ 'port' ],
        description => 'Class to throw when you cannot connect'
                        . ' to the P4 server',
    },

    'P4::Objects::Exception::P4::BadSpec' => {
        isa         => 'P4::Objects::Exception::P4',
        description => 'Class to throw when there are errors when committing '
                        . 'a spec',
    },

    'P4::Objects::Exception::P4::UnexpectedOutput' => {
        isa         => 'P4::Objects::Exception::P4',
        fields      => [ 'type', 'output' ],
        description => 'Class to throw when parsed output does not produce '
                        . 'the expected results',
    },

    'P4::Objects::Exception::P4::RunError' => {
        isa         => 'P4::Objects::Exception::P4',
        fields      => [
            'results',
            'warningcount',
            'warnings'
        ],
        description => 'Class to throw when there are errors when running '
                        . 'a Perforce command',
    },

    'P4::Objects::Exception::P4::SyncError' => {
        isa         => 'P4::Objects::Exception::P4::RunError',
        description => 'Class to throw when there are errors during '
                        . 'a sync operation',
    },

    'P4::Objects::Exception::P4::IntegrationError' => {
        isa         => 'P4::Objects::Exception::P4::RunError',
        description => 'Class to throw when there are errors during '
                        . 'an integrate operation',
    },

    'P4::Objects::Exception::P4::UnexpectedIntegrateResult' => {
        isa         => 'P4::Objects::Exception::P4::RunError',
        fields      => [ 'badresult' ],
        description => 'Class to throw when there are unexpected results during '
                        . 'an integrate operation',
    },

    'P4::Objects::Exception::P4::PreconditionViolation' => {
        isa         => 'P4::Objects::Exception::P4::RunError',
        fields      => [ 'reason' ],
        description => 'Class to throw when a pre-condition of the branch merge process is not met.'
    },

);

1;
__END__

=head1 NAME

P4::Objects::Exception - Exceptions for use in the P4::Objects package.

=head1 SYNOPSIS

This package supplies all exceptions used as error condition in the
P4::Objects package. Exceptions are true OO exceptions defined using
L<Exception::Class> and L<Error>. See that documentation for more details.

    use Error qw( :try );
    use P4::Object::Exception;

    try {
        SomeClass->new();
    }
    catch P4::Objects::Exception::SomeClassError with {
        # Do something
    }
    otherwise {
        P4::Objects::BadAlloc->throw( class => __PACKAGE__ );
    };

=head1 EXCEPTIONS

=head2 P4::Objects::Exception

=head3 Attributes

None

=head2 P4::Objects::Exception::BadAlloc

=head3 Attributes

=over

=item *

class - This has been the package in which the allocation problem occurs so
far. Should it be the package that originally had the allocation problem?

=back

=head2 P4::Objects::Exception::BadAutoMethod

=head3 Attributes

=over

=item *

class - Class on which automethod was invoked

=item *

method - Name of method that was attempted to invoke

=back

=head2 P4::Objects::Exception::BadPackage

=head3 Attributes

=over

=item *

class - Name of package referenced badly

=back

=head2 P4::Objects::Exception::InvalidDirectory

=head3 Attributes

None

=head1 AUTHOR

Stephen Vance, C<< <steve at vance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-p4-objects-exception at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=P4-Objects-Exception>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc P4::Objects::Exception

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/P4-Objects-Exception>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/P4-Objects-Exception>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=P4-Objects-Exception>

=item * Search CPAN

L<http://search.cpan.org/dist/P4-Objects-Exception>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to The MathWorks, Inc. for sponsoring this work and to the BaT Team
for their valuable input, review, and contributions.

=head1 COPYRIGHT & LICENSE

Copyright 2007-8 Stephen Vance, all rights reserved.

This program is released under the following license: Artistic

=cut

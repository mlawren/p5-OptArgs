package OptArgs2::OptArgBase;
use strict;
use warnings;

use Class::Inline
  abstract => 1,
  FIELDS   => {
    comment      => { required => 1, },
    default      => {},
    getopt       => {},
    name         => { required => 1, },
    required     => {},
    show_default => {},
  },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

1;

=head1 NAME

OptArgs2::OptArgBase - Internal Base class for Arg and Opt

=head1 SYNOPSIS

    package OptArgs2::Opt;
    use parent 'OptArgs2::OptArgBase';

=head1 DESCRIPTION

B<OptArgs2::OptArgBase> is an internal abstract class providing
attributes common to L<OptArgs2::Arg> and L<OptArgs2::Opt>.

=head1 ATTRIBUTES

=over

=item comment

Required. A brief description of the argument or option. This is used
to generate usage/help messages.

=item default

The default value to be used if the argument or option is not supplied.
Can be any value or a code reference to be called when arguments are
parsed.

=item getopt

A hash reference for configuring specific Getopt::Long parameters. This
could include type, validation, etc.

=item name

Required. The name of the argument or option. This corresponds to the
key used when defining it in the optargs list.

=item required

A boolean flag indicating whether this argument or option is mandatory.
If true, it must be provided by the user.

=item show_default

A boolean flag indicating whether the default value should be shown in
usage messages. If true, the default value is included in the
usage/help text.

=back

=head1 SEE ALSO

L<OptArgs2>

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


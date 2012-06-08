package App::optargs;
use strict;
use warnings;
use OptArgs;
use lib 'lib';
our $VERSION = '0.0.1';

arg class => (
    isa      => 'Str',
    required => 1,
    comment  => 'OptArgs-based module to map',
);

arg command => (
    isa     => 'Str',
    comment => 'Name of the command',
    default => sub { return shift->{class}; }
);

opt indent => (
    isa     => 'Int',
    comment => 'Number of spaces to indent sub-commands',
    alias   => 'i',
    default => 4,
);

opt spacer => (
    isa     => 'Str',
    comment => 'Character to use for indent spaces',
    default => ' ',
    alias   => 's',
);

opt full => (
    isa     => 'Bool',
    comment => 'Print the full usage messages',
    alias   => 'f',
);

sub run {
    my $opts  = shift;
    my $class = $opts->{class};

    die $@ unless eval "require $class;";
    binmode( STDOUT, ':encoding(utf8)' );

    my $initial = scalar split( /::/, $class );
    my $indent = $opts->{spacer} x $opts->{indent};

    foreach my $cmd ( OptArgs::_cmdlist($class) ) {
        my $length = scalar split( /::/, $cmd ) - $initial;
        my $space = $indent x $length;

        my $usage = OptArgs::_usage($cmd);
        $usage =~ s/^usage: optargs/usage: $opts->{command}/;
        $usage =~ s/^/$space/gm;

        unless ( $opts->{full} ) {
            $usage =~ s/usage: //;
            $usage =~ m/(.*?)$/sm;
            print "$1\n";
            next;
        }

        my $n = 79 - length $space;
        print $space, '#' x $n, "\n";
        print $space, "# $cmd\n";
        print $space, '#' x $n, "\n";
        print $usage;
        print $space . "\n";
    }
}

1;

__END__

=head1 NAME

App::optargs - print an OptArgs program command summary

=head1 VERSION

0.0.1 Development release.

=head1 SYNOPSIS

    use OptArgs;
    dispatch(qw/run App::optargs/);

=head1 DESCRIPTION

This is the implementation of the L<optargs> command which has the
following usage:

    usage: optargs CLASS [COMMAND]

        CLASS             OptArgs-based module to map
        COMMAND           Name of the command

        --indent, -i      Number of spaces to indent sub-commands
        --spacer, -s      Character to use for indent spaces
        --full,   -f      Print the full usage messages

It has a single function which expects to be called by L<OptArgs>
C<dispatch()>:

=over

=item run(\%opts)

Run with options as defined by \%opts.

=back

=head1 SEE ALSO

L<optargs>, L<OptArgs>

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2012 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


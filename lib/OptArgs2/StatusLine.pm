use strict;
use warnings;

package OptArgs2::StatusLine;

our $VERSION = 'v0.0.0';

sub RS { chr(30) }
my $RS = RS;

sub WARN { chr(5) }
my $WARN = WARN;

sub TIESCALAR {
    my $class = shift;
    bless( ( \my $str ), $class );
}

sub FETCH { ${ $_[0] } }

sub STORE {
    my $self = shift;
    my $arg  = shift;
    my $warn = 0;

    if ( not defined $arg ) {
        $$self = undef;
        return;
    }

    #TODO arg = undef?

    ( $$self // '' ) =~ m/
        (?:(?<prefix>.*)(?:$RS))?
        (?<msg>.+?)?
        (?<NL>\n)?
        \z
        /x;

    my %items = %+;

    if ( 'SCALAR' eq ref $arg ) {
        $items{prefix} = $$arg;
    }
    else {
        $arg =~ m/
            (?:(?<prefix>.+?)?(?:$RS))?
            (?<WARN>$WARN)?
            (?<msg>.+?)?
            (?<NL>\n)?
            \z
            /x;

        if ( defined $+{prefix} ) {
            $items{prefix} = $+{prefix};
        }
        elsif ( not defined $items{prefix} ) {
            require File::Basename;
            $items{prefix} = File::Basename::basename($0) . ': ';
        }

        $items{msg}  = $+{msg} if defined $+{msg};
        $items{NL}   = $+{NL}  if defined $+{msg};
        $items{WARN} = $+{WARN};
    }

    $items{msg} //= '';
    $items{NL}  //= '';

    my $fh = select;
    if ( $items{WARN} ) {
        warn $items{prefix}, $items{msg}, -t STDERR ? "\e[K" : '', "\n";
        $fh->print( $items{prefix}, $items{msg}, "\n" ) if not -t $fh;
    }
    elsif ( -t $fh ) {
        $fh->printflush( "\e[?25l", $items{prefix}, $items{msg}, "\e[K",
            ( $items{NL} || "\r" ) );
    }
    else {
        $fh->print( $items{prefix}, $items{msg}, "\n" );
    }

    $$self = $items{prefix} . RS . $items{msg} . ( $items{NL} // '' );
}

DESTROY {
    my $fh = select;
    $fh->printflush("\e[?25h") if -t $fh;
}

sub import {
    my $class  = shift;
    my $caller = scalar caller;

    no strict 'refs';
    foreach my $arg (@_) {
        if ( $arg =~ m/^\$(.*)/ ) {
            my $name = $1;
            tie my $x, 'OptArgs2::StatusLine';
            *{ $caller . '::' . $name } = \$x;
        }
        elsif ( $arg eq 'RS' ) {
            *{ $caller . '::RS' } = \&RS;
        }
        elsif ( $arg eq 'WARN' ) {
            *{ $caller . '::WARN' } = \&WARN;
        }
        else {
            require Carp;
            Carp::croak('expected "RS", "WARN" or "$scalar"');
        }

    }
}

1;

__END__

=head1 NAME

OptArgs2::StatusLine - terminal status line

=head1 VERSION

v0.0.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    use OptArgs2::StatusLine '$status', 'RS', 'WARN';
    use Time::HiRes 'sleep';    # just for simulating work

    $status = 'starting ... '; sleep .7;
    $status = WARN. 'Warning!';

    $status = 'working: ';
    foreach my $i ( 1 .. 10 ) {
        $status .= " $i"; sleep .15;
    }

    # You can localize $status for temporary changes
    {
        local $status = \'temporary: ';
        foreach my $i ( 1 .. 10 ) {
            $status = $i; sleep .15;
        }
        sleep 1;
    }
    $status .= ' (previous)';
    sleep 1;

    # Right back where you started
    $status = "Done.\n";

=head1 DESCRIPTION

B<OptArgs2::StatusLine> provides a simple terminal status line
implementation, using the L<perltie> mechanism. Simply assigning to a
C<$scalar> prints the string to the terminal. The terminal line will be
overwritten by the next assignment unless it ends with a newline.

You can create a status C<$scalar> at import time as shown in the
SYNOPSIS, or you can C<tie> your own variable manually, even in a HASH:

    my $self = bless {}, 'My::Class';
    tie $self->{status}, 'OptArgs2::StatusLine';
    $self->{status} = 'my status line';

=head2 Prefix

Status variables have a default prefix of "program-name: ". You can
change that two ways:

=over

=item * Assign a scalar reference:

    $status = \'New Prefix: ';
    $status = 'fine';             # "New Prefix: fine"

=item * Use an ASCII record separator (i.e. chr(30)) which you can
import as C<RS> if you prefer:

    use OptArgs2::StatusLine '$status', 'RS';

    $status = 'Other: ' . RS . 'my status'; # "Other: my status"
    $status = 'something else';             # "Other: something else"

=back

You can import multiple status variables in one statement:

    use OptArgs2::StatusLine '$status', '$d_status';

    if ($DEBUG) {
        $d_status = \'debug: ';
    } else {
        untie $d_status;
    }

    $status   = 'frobnicating';     # program: frobnicating
    $d_status = 'details matter!';  # debug: details matter!

=head2 Status as Warnings

A status line can be output via C<warn> by prefixing it with the ASCII
enquiry character (i.e. chr(5)) which you can import as C<WARN> if you
prefer:

    use OptArgs2::StatusLine '$status', 'WARN';

    $status = 'Things are normal';                  # STDOUT
    $status = WARN . 'Warning! Something is wrong'; # STDERR

A newline is automatically added to the end of a WARN status. A
C<$status> can of course be passed to C<warn> directly, but that either
results in a potientially unwanted "... at Module.pm line 6170, <$fh>
line 1573" or the status line printed twice when it ends with a "\n".

=head1 SEE ALSO

L<OptArgs2>

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs2

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2022-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


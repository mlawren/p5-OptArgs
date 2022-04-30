use strict;
use warnings;

package OptArgs2::StatusLine {

    our @CARP_NOT;

    sub _croak {
        @CARP_NOT = (__PACKAGE__);
        require Carp;
        Carp::croak(@_);
    }

    sub import {
        no strict 'refs';
        my $class  = shift;
        my $caller = scalar caller;

        while (@_) {
            my ( $l, $p ) = ( shift, shift );

            if ( $l =~ s/^\$(.*)// ) {
                $l = $caller . '::' . $1;
            }
            else {
                die 'first argument must be like "$scalar"';
            }

            my $x;
            if ( defined $p && $p =~ s/^\$(.*)// ) {
                my $o = make_line_prefix( $x, my $y );
                $p = $caller . '::' . $1;
                *{$p} = \$y;
            }
            else {
                make_line( $x, $p );
            }

            *{$l} = \$x;
        }
    }

    sub make_line {
        my $o = tie $_[0], 'OptArgs2::StatusLine::Line';
        $o->{prefix} = $_[1] // '';
        $o;
    }

    sub make_line_prefix {
        my $o = tie $_[0], 'OptArgs2::StatusLine::Line';
        tie $_[1], 'OptArgs2::StatusLine::Prefix', $o;
        $o;
    }
}

package OptArgs2::StatusLine::Line {

    sub TIESCALAR {
        my $class = shift;
        no strict 'refs';
        bless {
            prefix => '',
            val    => undef,
        }, $class;
    }

    sub FETCH {
        my $self = shift;
        $self->{val};
    }

    sub STORE {
        my $self = shift;
        $self->{val} = shift // return;
        return if not defined $self->{val};

        my $NL = $self->{val} =~ s/\n\z// ? 1 : 0;
        my $fh = select;

        if ( -t $fh ) {
            $fh->printflush( $self->{prefix}
                  . $self->{val} . "\e[K"
                  . ( $NL ? "\n" : "\r" ) );
        }
        else {
            $fh->print( $self->{prefix} . $self->{val} . "\n" );
        }

        $self->{val} = '' if $NL;
    }
}

package OptArgs2::StatusLine::Prefix {

    sub TIESCALAR {
        my ( $class, $line ) = @_;
        bless \$line, $class;
    }

    sub FETCH {
        my $self = shift;
        $$self->{prefix};
    }

    sub STORE {
        my $self        = shift;
        my $o           = $$self;
        my $was_defined = defined $o->{prefix};
        $o->{prefix} = shift;
        $o->STORE( $o->{val} ) if defined $o->{prefix} and $was_defined;
    }
}

1;

__END__

=head1 NAME

OptArgs2::StatusLine - terminal status line

=head1 VERSION

2.0.0_3 (2022-04-30)

=head1 SYNOPSIS

    use OptArgs2::StatusLine '$line', '$prefix';
    use Time::HiRes 'sleep'; # just for simulating work

    $prefix = '[prog] ';
    $line   = 'working ... '; sleep .7;

    foreach my $i ( 1 .. 10 ) {
        $line .= " $i"; sleep .2;
    }

    # You can localize both $line and $prefix
    # If referencing the outer scope $prefix you must
    # stringify it with ""
    {
        local $prefix = "$prefix" . '[debug] ';
        local $line   = "temporary info"; sleep .8;
    }

    sleep .7;    # back to old value for a while
    $line = "Done.\n";

=head1 DESCRIPTION

B<OptArgs2::StatusLine> provides a simple terminal status line
implementation, using Perl's C<tie()> mechanism on scalars.

The first argument must be a variable name starting with '$' which is
imported into your namespace.  Updates or concatenations to that
variable get printed immediately.

    use OptArgs2::StatusLine '$line';

If the optional second argument is provided it get prefixed to every
line of output, which you might like to use with your script's name:

    use File::Basename;
    use OptArgs2::StatusLine '$line', '['.basename($0).'] ';

If the second argument starts with '$' then it gets imported like
$line, allowing you to update the prefix dynamically as shown in the
synopsis.

If you would like multiple status lines you can import them all at
once:

    use OptArgs2::StatusLine
      '$line'  => '[myprog] ',
      '$debug' => '[myprog] (debug) ';

=head1 SEE ALSO

L<OptArgs2>

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs2/tree/devel

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2022 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


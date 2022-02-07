package OptArgs2::StatusLine;
use strict;
use warnings;

sub TIESCALAR {
    my ( $class, $prefix, $fh ) = @_;
    no strict 'refs';
    bless {
        fh     => \*{ $fh // select() },
        prefix => $prefix,
        line   => undef,
    }, $class;
}

sub prefix {
    my $self = shift;
    $self->{prefix} = $_[0] if @_;
    $self->{prefix};
}

sub FETCH {
    my $self = shift;
    $self->{line};
}

sub STORE {
    my $self = shift;
    my $val  = shift;
    my $NL   = $val =~ s/\n\z// ? 1 : 0;

    $self->{fh}
      ->printflush( $self->{prefix} . $val . "\e[K" . ( $NL ? "\n" : "\r" ) );
    $self->{line} = $NL ? '' : $val;
}

1;

__END__

=head1 NAME

OptArgs2::StatusLine - terminal status line

=head1 VERSION

2.0.0_2 (yyyy-mm-dd)

=head1 SYNOPSIS

    use OptArgs2::StatusLine;
    my $o = tie my ($line), 'OptArgs2::StatusLine', 'prefix: ';

    # assignment to $line prints to the terminal:
    $line = 'status';         # prefix: status
    $line .= ' update...';    # prefix: status update...
    $line .= "done\n";        # prefix: status update... done\n

    # a newline clears the internal buffer
    $line eq '';              # (true, and no prefix printed yet)
    $line .= "new line";      # prefix: new line

    $o->prefix('different: ');
    $line .= " done\n";        # different: new line done\n

=head1 DESCRIPTION

B<OptArgs2::StatusLine> provides a simple tied SCALAR class for
printing status lines to the terminal.  Usage is as follows:

    tie $var, 'OptArgs2::StatusLine', $PREFIX, $HANDLE;

C<$PREFIX> if provided will be prefixed is optional. C<$HANDLE> is
optional, defaulting to C<STDOUT>.

=head1 SEE ALSO

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


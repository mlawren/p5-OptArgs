package OptArgs2::Pager;
use strict;
use warnings;
use OptArgs2::Mo;
use Carp ();
use File::Which;
use IO::Handle;

our @CARP_NOT = (__PACKAGE__);

has auto => (
    is      => 'ro',
    default => 1,
);

has encoding => (
    is      => 'ro',
    default => ':utf8',
);

has pager => (
    is      => 'ro',
    default => \&_build_pager,
);

has fh => (
    is      => 'rw',
    default => sub { IO::Handle->new },
);

has pid => ( is => 'rw' );

has orig_fh => (
    is      => 'ro',
    default => sub { select },
);

sub _build_pager {
    my $self = shift;

    if ( exists $ENV{PAGER} ) {
        return unless length( $ENV{PAGER} );

        # Explicit pager defined
        my ( $pager, @options ) = split ' ', $ENV{PAGER};
        my $path = File::Which::which($pager);
        Carp::croak("pager not found: $pager") unless $path;
        return join( ' ', $path, @options );
    }

    # Otherwise take the first from our own list
    foreach my $pager (qw/pager less most w3m lv pg more/) {
        my $path = File::Which::which($pager);
        return $path if $path;
    }

    Carp::croak("no suitable pager found");
}

sub BUILD {
    my $self = shift;
    $self->open if $self->auto;
}

sub open {
    my $self = shift;
    return unless -t $self->orig_fh and !$self->fh->opened;

    my $pager = $self->pager || return;

    local $ENV{LESS} = $ENV{LESS} // '-FXeR';
    local $ENV{MORE} = $ENV{MORE} // '-FXer' unless $^O eq 'MSWin32';

    $self->pid( CORE::open( $self->fh, '|-', $pager ) )
      or Carp::croak "Could not pipe to PAGER ('$pager'): $!\n";

    binmode( $self->fh, $self->encoding ? $self->encoding : () )
      or Carp::cluck "Could not set bindmode: $!";

    $self->fh->autoflush(1);

    select $self->fh;
}

sub close {
    my $self = shift;
    return unless $self->fh && $self->fh->opened;

    select $self->orig_fh;
    $self->fh->close;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

1;

__END__

=head1 NAME

=for bif-doc #perl

OptArgs2::Pager - pipe output to a system (text) pager

=head1 VERSION

0.1.5_8 (yyyy-mm-dd)

=head1 SYNOPSIS

    use OptArgs2::Pager;

    my $pager = OptArgs2::Pager->new;
    print "This text goes to a pager\n";

    undef $pager;
    print "This text goes to STDOUT\n";

=head1 DESCRIPTION

B<OptArgs2::Pager> opens a connection to a system pager and makes it
the default filehandle so that by default any print statements are sent
there.

When the pager object goes out of scope the previous default filehandle
is selected again.

=head1 CONSTRUCTOR

The C<new()> constuctor takes the following arguments.

=over

=item C<< auto => 1 >>

By default the pager is opened when the object is created. Set C<auto>
to a false value to inhibit this behaviour.

=item C<< encoding => ':utf8' >>

The Perl IO layer encoding to set after the pager has been opened. This
defaults to ':utf8'. Set it to 'undef' to get binary mode.

=item C<< pager => undef >>

The pager executable to run. The default is to check the PAGER
environment variable, and if that is not set then the following
programs will be searched for using L<File::Which>: pager, less, most,
w3m, lv, pg, more.

You can set PAGER to nothing to temporarily disable B<OptArgs2::Pager>:

    $ PAGER= your_cmd --your --options

=back

=head1 ATTRIBUTES

=over

=item C<fh>

The underlying filehandle of the pager.

=item C<pid>

The process ID of the pager program (only set on UNIX systems)

=item C<orig_fh>

The original filehandle that was selected before the pager was started.

=back

=head1 METHODS

=over

=item C<close>

Explicitly close the pager. This is useful if you want to keep the
object around to start and stop the pager multiple times. Can be called
safely when no pager is running.

=item C<open>

Open the pager if it is not running. Can be called safely when the
pager is already running.

=back

=head1 SEE ALSO

L<IO::Pager> - does something similar by mucking directly with STDOUT
in a way that breaks fork/exec, and I couldn't for the life of me
decipher the code style enough to fix it.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2022 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


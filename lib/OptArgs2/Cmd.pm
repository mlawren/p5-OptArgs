package OptArgs2::Cmd;
use strict;
use warnings;
use parent 'OptArgs2::CmdBase';

### START Class::Inline ### v0.0.1 Wed Dec  3 10:44:51 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my ( %seen, @new, @build );
        my @possible = ($CLASS);
        while (@possible) {
            my $c = shift @possible;
            no strict 'refs';
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            $seen{$c}++;
            if ( exists &{ $c . '::DOES' } ) {
                push @possible, grep { not $seen{$_}++ } $c->DOES('*');
            }
            push @possible, grep { not $seen{$_}++ } @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("OptArgs2::Cmd: unexpected argument '$_'") for keys %$attrs
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    map { delete $_[1]->{$_} } 'name', 'no_help';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub name {
    __RO() if @_ > 1;
    $_[0]{'name'} //= $_FIELDS->{'name'}->{'default'}->( $_[0] );
}

sub no_help {
    __RO() if @_ > 1;
    $_[0]{'no_help'} //= $_FIELDS->{'no_help'}->{'default'};
}
@_CLASS = grep 1,    ### END Class::Inline ###
  name => {
    default => sub {
        my $x = $_[0]->class;

        # once legacy code goes move this into optargs()
        if ( $x eq 'main' ) {
            require File::Basename;
            File::Basename::basename($0),;
        }
        else {
            $x =~ s/.*://;
            $x =~ s/_/-/g;
            $x;
        }
    },
  },
  no_help => { default => 0 },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

sub BUILD {
    my $self = shift;

    $self->add_opt(
        isa          => OptArgs2::USAGE_HELP(),
        show_default => 0,
      )
      unless $self->no_help
      or 'CODE' eq ref $self->optargs;    # legacy interface
}

1;

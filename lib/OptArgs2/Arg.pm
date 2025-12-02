package OptArgs2::Arg;
use strict;
use warnings;
use parent 'OptArgs2::OptArgBase';

my %isa2name = (
    'ArrayRef' => 'Str',
    'HashRef'  => 'Str',
    'Int'      => 'Int',
    'Num'      => 'Num',
    'Str'      => 'Str',
    'SubCmd'   => 'Str',
);

my %arg2getopt = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

use Class::Inline
  cmd      => { is => 'rw', weaken => 1, },
  fallthru => {},
  greedy   => {},
  isa      => {
    required => 1,
    isa      => sub {
        $isa2name{ $_[0] } // OptArgs2->throw_error( 'InvalidIsa',
            'invalid isa type: ' . $_[0] );
        $_[0];
    },
  },
  isa_name => {
    default => sub {
        '(' . $isa2name{ $_[0]->isa } . ')';
    },
  },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

sub BUILD {
    my $self = shift;

    OptArgs2->throw_error( 'Conflict', q{'default' and 'required' conflict} )
      if $self->required and defined $self->default;

    OptArgs2->throw_error( 'Conflict', q{'isa SubCmd' and 'greedy' conflict} )
      if $self->greedy and $self->isa eq 'SubCmd';
}

sub name_alias_type_comment {
    my $self  = shift;
    my $value = shift;

    my $deftype = ( defined $value ) ? '[' . $value . ']' : $self->isa_name;
    my $comment = $self->comment;

    if ( $self->required ) {
        $comment .= ' ' if length $comment;
        $comment .= '*required*';
    }

    return $self->name, '', $deftype, $comment;
}

1;

package OptArgs2::Opt;
use strict;
use warnings;
use parent 'OptArgs2::OptArgBase';

my %isa2name = (
    'ArrayRef' => 'Str',
    'Bool'     => '',
    'Counter'  => '',
    'Flag'     => '',
    'HashRef'  => 'Str',
    'Int'      => 'Int',
    'Num'      => 'Num',
    'Str'      => 'Str',
);

my %isa2getopt = (
    'ArrayRef' => '=s@',
    'Bool'     => '!',
    'Counter'  => '+',
    'Flag'     => '!',
    'HashRef'  => '=s%',
    'Int'      => '=i',
    'Num'      => '=f',
    'Str'      => '=s',
);

use Class::Inline
  alias   => {},
  hidden  => {},
  trigger => {},
  isa     => {
    required => 1,
    isa      => sub {
        $isa2name{ $_[0] }
          // OptArgs2::croak( 'InvalidIsa', 'invalid isa type: ' . $_[0] );
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

sub new_from {
    my $proto = shift;
    my $ref   = {@_};

    # legacy interface
    if ( exists $ref->{ishelp} ) {
        delete $ref->{ishelp};
        $ref->{isa} //= OptArgs2::USAGE_HELP();
    }

    if ( $ref->{isa} =~ m/^Help/ ) {    # one of the USAGE_HELPs
        my $style = $ref->{isa};
        my $name  = $style;
        $name =~ s/([a-z])([A-Z])/$1-$2/g;
        $ref->{isa} = 'Counter';
        $ref->{name}    //= lc $name;
        $ref->{alias}   //= lc substr $ref->{name}, 0, 1;
        $ref->{comment} //= "print a $style message and exit";
        $ref->{trigger} //= sub {
            my $cmd = shift;
            my $val = shift;

            if ( $val == 1 ) {
                $cmd->throw( OptArgs2::USAGE_HELP() );
            }
            elsif ( $val == 2 ) {
                $cmd->throw( OptArgs2::USAGE_HELPTREE() );
            }
            else {
                $cmd->throw( OptArgs2::USAGE_USAGE(), 'UnexpectedOptArg',
                    qq{"--$ref->{name}" used too many times} );
            }
        };
    }

    if ( !exists $isa2getopt{ $ref->{isa} } ) {
        return OptArgs2::croak( 'InvalidIsa', 'invalid isa "%s" for opt "%s"',
            $ref->{isa}, $ref->{name} );
    }

    $ref->{getopt} = $ref->{name};
    if ( $ref->{name} =~ m/_/ ) {
        ( my $x = $ref->{name} ) =~ s/_/-/g;
        $ref->{getopt} .= '|' . $x;
    }
    $ref->{getopt} .= '|' . $ref->{alias} if $ref->{alias};
    $ref->{getopt} .= $isa2getopt{ $ref->{isa} };

    return $proto->new(%$ref);
}

sub name_alias_type_comment {
    my $self  = shift;
    my $value = shift;

    ( my $opt = $self->name ) =~ s/_/-/g;
    if ( $self->isa eq 'Bool' ) {
        if ($value) {
            $opt = 'no-' . $opt;
        }
        elsif ( not defined $value ) {
            $opt = '[no-]' . $opt;
        }
    }
    $opt = '--' . $opt;

    my $alias = $self->alias // '';
    if ( length $alias ) {
        $opt .= ',';
        $alias = '-' . $alias;
    }

    my $isa     = $self->isa;
    my $deftype = '';
    if ( $isa ne 'Flag' and $isa ne 'Bool' and $isa ne 'Counter' ) {
        $deftype = defined $value ? '[' . $value . ']' : $self->isa_name;
    }

    my $comment = $self->comment;
    if ( $self->required ) {
        $comment .= ' ' if length $comment;
        $comment .= '*required*';
    }

    return $opt, $alias, $deftype, $comment;
}

1;

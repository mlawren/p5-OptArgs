package OptArgs2::Cmd;
use strict;
use warnings;
use parent 'OptArgs2::CmdBase';

use Class::Inline name => {
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

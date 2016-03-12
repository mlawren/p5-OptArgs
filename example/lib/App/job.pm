package App::job;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub cmd {
    my $self = shift;
    return OptArgs2::get_cmd( ref $self );
}

sub run {
    my $self = shift;
    my $opts = shift;

    if ( $opts->{usage} ) {
        return print $self->cmd->usage_tree;
    }

    return print "job status is SOMETHING...\n";
}

1;

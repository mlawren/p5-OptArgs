use strict;
use warnings;
use Test::More;
use OptArgs;

opt count => (
    isa     => 'Counter',
    alias   => 'c',
    comment => 'comment',
    default => 4,
);

is opts->{count}, 4, 'default 4';

@ARGV = (qw/-c/);
is opts->{count}, 1, 'count 1';

@ARGV = (qw/-c -c/);
is opts->{count}, 2, 'count 2';

done_testing();

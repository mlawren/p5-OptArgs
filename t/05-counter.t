use strict;
use warnings;
use Test::More;
use optargs;

opt count => (
    isa     => 'Counter',
    alias   => 'c',
    comment => 'comment',
);

TODO: {
    local $TODO = 'need default parameter to work';
    is opts->count, 0, 'default 0';
}

@ARGV = (qw/-c/);
is opts->count, 1, 'count 1';

@ARGV = (qw/-c -c/);
is opts->count, 2, 'count 2';

done_testing();

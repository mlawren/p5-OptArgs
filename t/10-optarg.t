use strict;
use warnings;
use Test::More;
use Test::Fatal;
use optargs;

opt long_str => (
    isa   => 'Str',
    alias => 's|t',
);

is_deeply optargs, opts, 'optarg is opt';

@ARGV = (qw/--long_str x/);
is_deeply optargs, { long_str => 'x' }, 'fullname';
is_deeply opts,    { long_str => 'x' }, 'fullname';

is opts->long_str,    'x', 'fullname method';
is optargs->long_str, 'x', 'fullname method';

done_testing;

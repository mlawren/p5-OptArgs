use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt long_str => (
    isa     => 'Str',
    alias   => 's|t',
    comment => 'comment',
);

is_deeply opts, { long_str => undef }, 'nothing';

@ARGV = (qw/--long_str x/);
is_deeply opts, { long_str => 'x' }, 'fullname';

@ARGV = (qw/-s x/);
is_deeply opts, { long_str => 'x' }, 'alias';

@ARGV = (qw/-t x/);
is_deeply opts, { long_str => 'x' }, 'alias2';

done_testing;

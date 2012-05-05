use strict;
use warnings;
use Test::More;
use Test::Fatal;
use optargs;

opt long_str => (
    isa     => 'Str',
    alias   => 's|t',
    comment => 'comment',
);

is_deeply opts, { long_str => undef }, 'nothing';

@ARGV = (qw/--long_str x/);
is_deeply opts, { long_str => 'x' }, 'fullname';
is opts->long_str, 'x', 'fullname method';

@ARGV = (qw/--long-str x/);
is opts->long_str, 'x', 'dash method';

@ARGV = (qw/-s x/);
is_deeply opts, { long_str => 'x' }, 'alias';
is opts->long_str, 'x', 'fullname method';

@ARGV = (qw/-t x/);
is_deeply opts, { long_str => 'x' }, 'alias2';
is opts->long_str, 'x', 'fullname method';

done_testing;

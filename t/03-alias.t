use strict;
use warnings;
use Test::More;
use Test::Fatal;
use optargs;

opt str => (
    isa   => 'Str',
    alias => 's',
);

is_deeply opts, { str => undef }, 'nothing';

@ARGV = (qw/--str x/);
is_deeply opts, { str => 'x' }, 'fullname';
is opts->str, 'x', 'fullname method';

@ARGV = (qw/-s x/);
is_deeply opts, { str => 'x' }, 'alias';
is opts->str, 'x', 'fullname method';

opt two => (
    isa   => 'Str',
    alias => 't|u',
);

@ARGV = (qw/-t x/);
is_deeply opts, { str => undef, two => 'x' }, 'two alias deeply';

@ARGV = (qw/-u x/);
is_deeply opts, { str => undef, two => 'x' }, 'two alias deeply';

done_testing;

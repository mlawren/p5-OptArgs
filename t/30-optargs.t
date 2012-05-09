use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt quiet => (
    isa     => 'Str',
    alias   => 'q',
    comment => 'comment',
);

arg door => (
    isa     => 'Str',
    comment => 'comment',
);

@ARGV = (qw/bedroom/);
is_deeply optargs, { quiet => undef, door => 'bedroom' }, 'optargs structure';

is_deeply optargs(qw/kitchen/), { quiet => undef, door => 'kitchen' },
  'optargs structure';

done_testing;

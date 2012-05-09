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
is optargs->quiet, undef,     'fullname method';
is optargs->door,  'bedroom', 'fullname method';

is_deeply optargs(qw/kitchen/), { quiet => undef, door => 'kitchen' },
  'optargs structure';
is optargs->quiet, undef,     'fullname method';
is optargs->door,  'kitchen', 'fullname method';

optargs->{quiet} = 1;
optargs->{door}  = 'bathroom';
is optargs->quiet, 1,          'method match';
is optargs->door,  'bathroom', 'method match';

done_testing;

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use optargs;

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

done_testing;

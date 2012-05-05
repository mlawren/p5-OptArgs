use strict;
use warnings;

package x;
use Test::More;
use optargs;

opt quiet => (
    isa     => 'Bool',
    default => 1,
    comment => 'do nothing',
);

arg subref => (
    isa     => 'Str',
    default => sub {
        my $ref = shift;
        pass 'default subref called';
        return 2;
    },
    comment => 'do nothing',
);

is_deeply optargs, { quiet => 1, subref => 2 }, 'subref and normal default';

@ARGV = (qw/1/);
is_deeply optargs, { quiet => 1, subref => 1 }, 'subref and not default';

@ARGV = (qw/--no-quiet 1/);
is_deeply optargs, { quiet => 0, subref => 1 }, 'subref and not default';

@ARGV = (qw/--no-quiet/);
is_deeply optargs, { quiet => 0, subref => 2 }, 'subref and not default';

done_testing();

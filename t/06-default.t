use strict;
use warnings;

package x;
use Test::More;
use optargs;

my $str = 1;
opt subref => (
    isa     => 'Str',
    default => sub {
        my $ref = shift;
        is $ref->{str}, $str, 'default sub after normal values';
        return 2;
    },
    comment => 'do nothing',
);

opt str => (
    isa     => 'Str',
    default => $str,
    comment => 'do nothing',
);

is_deeply opts, { subref => 2, str => $str }, 'subref and normal default';

@ARGV = (qw/--str 4/);
$str  = 4;
is_deeply opts, { subref => 2, str => 4 }, 'normal not default';

@ARGV = (qw/--subref 3/);
$str  = 1;
is_deeply opts, { subref => 3, str => 1 }, 'subref not def';

done_testing();

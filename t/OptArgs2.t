#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

my $o;

isa_ok dies {
    subcmd not_found => ();
},
  'OptArgs2::Error::ParentCmdNotFound';

@ARGV = ('the arg');
$o    = optargs2(
    comment => 'test',
    optargs => [
        arg => {
            isa      => 'Str',
            comment  => 'do soemthing',
            required => 1,
        },
        opt => {
            isa     => '--Flag',
            comment => 'do soemthing',
        },
        three => {
            isa     => '--Int',
            comment => 'do soemthing',
            default => 3,
        },
    ],
);

is $o, { arg => 'the arg', three => 3 }, 'optargs as ARRAY ref';

done_testing;

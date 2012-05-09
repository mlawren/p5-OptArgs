use strict;
use warnings;
use Test::More;
use Test::Output;
use Test::Fatal;
use lib 't/lib';
use app::multi;

is exception { app::multi->run }, 'usage: 41-subcommand.t [options] COMMAND

    --dry-run    do nothing
    --verbose    do it loudly

    COMMAND      (required) valid values include:
        init         do the y thing
        new          do the z thing

', 'no arguments';

stdout_is(
    sub { app::multi->run('init') },
    'you are in init, thanks
', 'init'
);

is exception { app::multi->run(qw/init -q/) },
  'unexpected option or argument: -q

usage: 41-subcommand.t [options] init [options]

    --dry-run    do nothing
    --verbose    do it loudly

    --opty       do nothing

', 'unexpected option';

done_testing();

use strict;
use warnings;
use Test::More;
use Test::Output;
use Test::Fatal;
use lib 't/lib';
use OptArgs qw/dispatch/;

$OptArgs::COLOUR = 0;

is exception { dispatch(qw/run app::multi/) }, 'usage:
    41-subcommand.t init   do the y thing
    41-subcommand.t new    do the z thing

  options:
    --help,    -h          print a help message and exit
    --dry-run, -n          do nothing
    --verbose, -v          do it loudly

', 'no arguments';

stdout_is(
    sub { dispatch(qw/run app::multi init/) },
    'you are in init, thanks
', 'init'
);

is exception { dispatch(qw/run app::multi init -q/) },
  'error: unexpected option or argument: -q

usage: 41-subcommand.t init

  options:
    --help,    -h   print a help message and exit
    --dry-run, -n   do nothing
    --verbose, -v   do it loudly
    --opty          do nothing

', 'unexpected option';

# abbreviations

like exception { dispatch(qw/run app::multi in/) }, qr/error/,
  'No abbreviation';

$OptArgs::ABBREV++;

stdout_is(
    sub { dispatch(qw/run app::multi i/) },
    'you are in init, thanks
', 'abbrev i'
);

stdout_is(
    sub { dispatch(qw/run app::multi ini/) },
    'you are in init, thanks
', 'abbrev ini'
);

stdout_is(
    sub { dispatch(qw/run app::multi ne p/) },
    'you are in new project, thanks
', 'abbrev ne p'
);

# sorting

$OptArgs::SORT = 0;

is exception { dispatch(qw/run app::multi new -h/) }, '[help requested]

usage:
    41-subcommand.t new project   do the new project thing
    41-subcommand.t new issue     create a new issue
    41-subcommand.t new task      create a new task thread

  options:
    --help,    -h                 print a help message and exit
    --dry-run, -n                 do nothing
    --verbose, -v                 do it loudly

', 'ordered';

$OptArgs::SORT = 1;

is exception { dispatch(qw/run app::multi new -h/) }, '[help requested]

usage:
    41-subcommand.t new issue     create a new issue
    41-subcommand.t new project   do the new project thing
    41-subcommand.t new task      create a new task thread

  options:
    --help,    -h                 print a help message and exit
    --dry-run, -n                 do nothing
    --verbose, -v                 do it loudly

', 'sorted';

done_testing();

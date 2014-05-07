use strict;
use warnings;
use lib 't/lib';
use OptArgs qw/dispatch/;
use Test::More;
use Test::Output;
use Test::Fatal;

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi/) },
    'multi COMMAND
    multi init
    multi new THREAD
        multi new project
        multi new issue
        multi new task TARG
            multi new task pretty
            multi new task noopts
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2/) },
    'multi COMMAND
  multi init
  multi new THREAD
    multi new project
    multi new issue
    multi new task TARG
      multi new task pretty
      multi new task noopts
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x/) },
    'multi COMMAND
xxmulti init
xxmulti new THREAD
xxxxmulti new project
xxxxmulti new issue
xxxxmulti new task TARG
xxxxxxmulti new task pretty
xxxxxxmulti new task noopts
'
    , 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x yy/) },
    'yy COMMAND
xxyy init
xxyy new THREAD
xxxxyy new project
xxxxyy new issue
xxxxyy new task TARG
xxxxxxyy new task pretty
xxxxxxyy new task noopts
', 'App::optargs on app::multi'
);

done_testing();

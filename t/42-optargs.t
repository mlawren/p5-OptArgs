use strict;
use warnings;
use Test::More;
use Test::Output;
use Test::Fatal;
use lib 't/lib';
use OptArgs qw/dispatch/;

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi/) },
    'app::multi COMMAND
    app::multi init
    app::multi new THREAD
        app::multi new project
        app::multi new issue
        app::multi new task TARG
            app::multi new task pretty
            app::multi new task noopts
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2/) },
    'app::multi COMMAND
  app::multi init
  app::multi new THREAD
    app::multi new project
    app::multi new issue
    app::multi new task TARG
      app::multi new task pretty
      app::multi new task noopts
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x/) },
    'app::multi COMMAND
xxapp::multi init
xxapp::multi new THREAD
xxxxapp::multi new project
xxxxapp::multi new issue
xxxxapp::multi new task TARG
xxxxxxapp::multi new task pretty
xxxxxxapp::multi new task noopts
'
    , 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x multi/) },
    'multi COMMAND
xxmulti init
xxmulti new THREAD
xxxxmulti new project
xxxxmulti new issue
xxxxmulti new task TARG
xxxxxxmulti new task pretty
xxxxxxmulti new task noopts
', 'App::optargs on app::multi'
);

done_testing();

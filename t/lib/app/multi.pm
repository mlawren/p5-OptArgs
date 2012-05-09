use strict;
use warnings;

package app::multi;
use optargs;

opt dry_run => (
    isa     => 'Bool',
    comment => 'do nothing',
    alias   => 'n',
);

opt verbose => (
    isa     => 'Bool',
    comment => 'do it loudly',
    alias   => 'v',
);

arg command => (
    isa      => 'Str',
    comment  => '(required) valid values include:',
    required => 1,
    dispatch => 1,
);

sub run {
    shift if $_[0] eq __PACKAGE__;
    optargs(@_);
}

package app::multi::init;
use optargs qw/subcommand opt arg/;

subcommand('do the y thing');

opt opty => (
    isa     => 'Bool',
    comment => 'do nothing',
);

package app::multi::new;
use optargs qw/subcommand opt arg/;

subcommand('do the z thing');

arg thread => (
    isa      => 'Str',
    comment  => '',
    required => 1,
    dispatch => 1,
);

package app::multi::new::project;
use optargs qw/subcommand opt/;

subcommand('do the new project thing');

opt popt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

package app::multi::new::issue;
use optargs qw/subcommand opt/;

subcommand('create a new issue');

opt iopt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

package app::multi::new::task;
use optargs qw/subcommand opt arg/;

subcommand('create a new task thread');

opt topt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

arg targ => (
    isa      => 'Str',
    comment  => '',
    required => 1,
    dispatch => 1,
);

package app::multi::new::task::pretty;
use optargs qw/subcommand opt/;

subcommand('create a new task thread prettier than before');

opt optz => (
    isa     => 'Bool',
    comment => 'do nothing',
);

1;

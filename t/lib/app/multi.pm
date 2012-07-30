package app::multi;
use strict;
use warnings;
use OptArgs;

$OptArgs::COLOUR = 1;

arg command => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '(required) valid values include:',
);

opt dry_run => (
    isa     => 'Bool',
    alias   => 'n',
    comment => 'do nothing',
);

opt verbose => (
    isa     => 'Bool',
    alias   => 'v',
    comment => 'do it loudly',
);

subcmd( 'init', 'do the y thing' );

opt opty => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd( 'new', 'do the z thing' );

arg thread => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

subcmd( qw/new project/, 'do the new project thing' );

opt popt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd( qw/new issue/, 'create a new issue' );

opt iopt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd( qw/new task/, 'create a new task thread' );

opt topt => (
    isa     => 'Bool',
    comment => 'do nothing',
);

arg targ => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

subcmd( qw/new task pretty/, 'create a new task prettier than before' );

opt optz => (
    isa     => 'Bool',
    comment => 'do nothing',
);

subcmd( qw/new task noopts/, 'create a new task with no opts or args' );

1;

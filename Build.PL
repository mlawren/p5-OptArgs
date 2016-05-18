#!perl
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;
use Module::Build::Pluggable 'CPANfile';

my $builder = Module::Build::Pluggable->new(
    module_name        => 'OptArgs2',
    create_license     => 1,
    create_makefile_pl => 'small',
    create_readme      => 1,
    license            => 'GPL_3',
    dist_author        => 'Mark Lawrence <nomad@null.net>',
    dist_version       => '0.0.2',
    no_index           => {
        package => [ 'OptArgs2::Result', 'Getopt::Args2::Result' ],
    },
    recursive_test_files => 1,
    add_to_cleanup =>
      [ 'OptArgs2-*', '*.bak', 'blib', 'Makefile', 'lib*Getopt*Args2.pm' ],
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/mlawren/p5-OptArgs2/issues',
            repository => 'git://github.com/mlawren/p5-OptArgs2.git',
            homepage   => 'https://github.com/mlawren/p5-OptArgs2',
        },
        keywords => [],
    },
);

$builder->create_build_script();

# I prefer to use make when developing so lets built the Makefile here
# as well
Module::Build::Compat->write_makefile( build_class => 'Module::Build' );

#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME       => 'OptArgs2',
    ABSTRACT   => 'CLI argument and option processing',
    AUTHOR     => 'Mark Lawrence <nomad@null.net>',
    VERSION    => '2.0.1_1',
    LICENSE    => 'gpl_3',
    test       => { RECURSIVE_TEST_FILES => 1, },
    dist       => { PREOP => 'class-inline-filter $(DISTVNAME)', },   #CIFILTER#
    PM_FILTER  => 'class-inline-filter',                              #CIFILTER#
    META_MERGE => {
        dynamic_config => 1,
        'meta-spec'    => { version => 2 },
        no_index       => {
            package => [
                qw/
                  OptArgs2::Arg
                  OptArgs2::Arg_CI
                  OptArgs2::CODEREF
                  OptArgs2::Cmd
                  OptArgs2::CmdBase
                  OptArgs2::CmdBase_CI
                  OptArgs2::Cmd_CI
                  OptArgs2::Opt
                  OptArgs2::OptArgBase
                  OptArgs2::OptArgBase_CI
                  OptArgs2::Opt_CI
                  OptArgs2::Pager_CI
                  OptArgs2::Status
                  OptArgs2::SubCmd
                  OptArgs2::SubCmd_CI
                  /
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https//github.com/mlawren/p5-OptArgs/issues', },
            homepage   => 'https//github.com/mlawren/p5-OptArgs',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-OptArgs.git',
                web  => 'https//github.com/mlawren/p5-OptArgs',
            }
        },
    },
);


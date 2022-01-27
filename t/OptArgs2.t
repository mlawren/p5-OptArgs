#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

skip_all 'no tests at the moment';

my $e;

$e = dies {
    opt one => (
        isa     => 'Flag',
        ishelp  => 1,
        trigger => sub { },
        comment => 'comment',
    );
};

isa_ok $e, 'OptArgs2::Error::IshelpTriggerConflict';

done_testing;

#!perl
use strict;
use warnings;
use Test2::V0;
use OptArgs2;

@ARGV = ();    # just in case this script got called with some

my ( $e, $class, $opts );

cmd 'c1' => (
    comment => 'the base command',
    optargs => sub {
        arg command => (
            isa     => 'SubCmd',
            comment => 'command to run',
        );
    },
);

subcmd 'c1::s1' => (
    comment => 'sub command',
    optargs => sub { },
);

$e = dies { ( $class, $opts ) = class_optargs( 'c1', 's' ) };
like ref $e, qr/SubCmdUnknown/, 'unknown SubCmd without abbrev';

cmd 'c2' => (
    comment => 'the base command',
    abbrev  => 1,
    optargs => sub {
        arg command => (
            isa     => 'SubCmd',
            comment => 'command to run',
        );
    },
);

subcmd 'c2::s1' => (
    comment => 'sub command',
    optargs => sub { },
);

( $class, $opts ) = class_optargs( 'c2', 's' );
is $class, 'c2::s1', 'correct SubCmd abbrev';

( $class, $opts ) = class_optargs( 'c2', 's1' );
is $class, 'c2::s1', 'correct SubCmd full';

done_testing;

#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

@ARGV = ( '--range', 'a' );

like(
    dies {
        optargs(
            comment => 'script to paint things',
            optargs => [
                range => {
                    isa     => '--HashRef',
                    comment => 'the item to paint',
                },
            ],
        );
    },
    qr/requires a value/,
    'catch warning'
);

done_testing;

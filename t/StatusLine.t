#!perl
use strict;
use warnings;
use OptArgs2::StatusLine '$line';
use OptArgs2::StatusLine '$line2', 'prefix:';
use OptArgs2::StatusLine '$line3', '$prefix';
use Test2::V0;
use Test::Output;

my ( $i, $old ) = ( 0, undef );

is $line, undef, 'initially undefined';
stdout_is { $line = $i; } "$i\n", 'assignment';
$i++;
stdout_is { $line = $i; } "$i\n", 'reassignment';
$old = $line;
$i++;
stdout_is { $line .= $i; } "${line}${i}\n", 'concatenation';

is $line2, undef, 'initially undefined';
$i = 0;
stdout_is { $line2 = $i; } "prefix:$i\n", 'assignment';
$i++;
stdout_is { $line2 = $i; } "prefix:$i\n", 'reassignment';
$old = $line2;
$i++;
stdout_is { $line2 .= $i; } "prefix:${line2}${i}\n", 'concatenation';

is $line3, undef, 'initially undefined';
$i = 0;
stdout_is { $line3 = $i; } "$i\n", 'assignment';
stdout_is { $prefix = 'junk:' } "junk:$i\n", 'change of prefix';
$i++;
stdout_is { $line3 = $i; } "${prefix}$i\n", 'reassignment';
$old = $line3;
$i++;
stdout_is { $line3 .= $i; } "${prefix}${line3}${i}\n", 'concatenation';

done_testing();

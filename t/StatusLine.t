#!perl
use strict;
use warnings;
use OptArgs2::StatusLine;
use Test2::V0;

my $string;
open( my $fh, ">", \$string );
my $o = tie my ($l), 'OptArgs2::StatusLine', 'prefix:', $fh;

is $o, tied($l), $o;
isa_ok( $o, 'OptArgs2::StatusLine' );
is $l,      undef, 'var is undef';
is $string, undef, 'output is undef';

my $KILL = '\e\[K';
my $RET  = '\r';

$l = 1;
like $string, qr/prefix:1$KILL$RET\z/, 'assign ' . $l;

$l .= 2;
like $string, qr/prefix:12$KILL$RET\z/, 'concatenate ' . $l;

$l .= "\n";
like $string, qr/prefix:12$KILL\n\z/s, 'newline output';
is $l,        '',                      'newline reset';

$o->prefix('new:');
$l .= 2;
like $string, qr/new:2$KILL$RET\z/s, 'change of prefix';

done_testing();

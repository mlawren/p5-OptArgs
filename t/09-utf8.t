use strict;
use warnings;
use utf8;
use FindBin qw/$Bin/;
use Encode qw/is_utf8 decode_utf8/;
use Test::More;
use OptArgs ':all';

my $utf8   = '¥';
my $output = qx/$^X $Bin\/single $utf8/;

like $output, qr/\$VAR1/, 't/single ran ok';

my $VAR1;
my $result = eval $output;

is_deeply $result, { arg1 => $utf8, arg2 => 'optional', },
  'external argument encoding';
done_testing;

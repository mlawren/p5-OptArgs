use strict;
use warnings;
use utf8;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use FindBin qw/$Bin/;
use OptArgs ':all';
use Test::More;

my $builder = Test::More->builder;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

my $utf8  = '¥';
my $bytes = encode_utf8($utf8);

open( my $fh, '-|', $^X, "$Bin\/single", $bytes ) || die "open: $!";
my $result = join( '', <$fh> );

is $result, Dumper( { arg1 => $utf8, arg2 => 'optional', } ),
  'external argument encoding';

done_testing;

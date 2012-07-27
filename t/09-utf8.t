use strict;
use warnings;
use utf8;
use utf8::all;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use FindBin qw/$Bin/;
use OptArgs ':all';
use Test::More;

$ENV{LANG}   = 'en_US.UTF-8';
$ENV{LC_ALL} = 'en_US.UTF-8';

my $builder = Test::More->builder;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

my $utf8  = '¥';
my $bytes = encode_utf8($utf8);

open( my $fh, '-|', $^X, "$Bin\/single", $utf8 ) || die "open: $!";
my $result = join( '', <$fh> );
close $fh;

is $result, Dumper( { arg1 => $utf8, arg2 => 'optional', } ),
  'external argument encoding given utf8';

open( $fh, '-|', $^X, "$Bin\/single", $bytes ) || die "open: $!";
$result = join( '', <$fh> );
close $fh;

is $result, Dumper( { arg1 => $utf8, arg2 => 'optional', } ),
  'external argument encoding given bytes';

done_testing;

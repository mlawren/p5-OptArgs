use strict;
use warnings;
use utf8;

# Make our test output utf8 pretty
BEGIN {
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
}

use Data::Dumper;
use FindBin qw/$Bin/;
use Encode qw/is_utf8 decode_utf8/;
use Test::More;
use OptArgs ':all';

my $builder = Test::More->builder;
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

my $utf8   = '¥';
my $result = qx/$^X $Bin\/single $utf8/;

use Encode qw/encode_utf8 decode_utf8/;
my $opts = { arg1 => $utf8, arg2 => 'optional', };
$opts->{osname}          = $^O;
$opts->{plain}           = $opts->{arg1};
$opts->{is_utf8}         = utf8::is_utf8( $opts->{arg1} );
$opts->{encode}          = encode_utf8( $opts->{arg1} );
$opts->{decode}          = decode_utf8( $opts->{arg1} );
$opts->{'decode.encode'} = decode_utf8( encode_utf8( $opts->{arg1} ) );

is $result, Dumper($opts), 'external argument encoding';
done_testing;

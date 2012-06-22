use strict;
use warnings;
use Data::Dumper;

BEGIN {
    if (@ARGV) {
        require Test::More;
        Test::More::diag( "\npre utf8::all: "
              . Dumper( { utf8 => $ARGV[0], bytes => $ARGV[1] } ) );
    }
}

use utf8;
use utf8::all;

BEGIN {
    if (@ARGV) {
        Test::More::diag( "\npost utf8::all: "
              . Dumper( { utf8 => $ARGV[0], bytes => $ARGV[1] } ) );
        exit;
    }
}

use Encode;
use Test::More;

my $builder = Test::More->builder;
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

my $utf8  = '¥';
my $bytes = encode_utf8($utf8);

diag( "\nPassing: " . Dumper( { utf8 => $utf8, bytes => $bytes, } ) );

open( my $fh, '-|', $^X, $0, $utf8, $bytes ) || die "open: $!";
my $result = join( '', <$fh> );
close $fh;

ok(1);
done_testing();

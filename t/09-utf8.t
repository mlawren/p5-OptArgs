use strict;
use warnings;
use utf8;
use FindBin qw/$Bin/;
use Encode qw/is_utf8 decode_utf8/;
use Test::More;
use OptArgs ':all';

my $utf8 = '¥';
binmode( STDERR, ':encoding(UTF-8)' );
binmode( STDOUT, ':encoding(UTF-8)' );

arg one => (
    isa     => 'Str',
    comment => 'unicode string',
);

opt opt => (
    isa     => 'Str',
    comment => 'unicode opt',
);

@ARGV = ( $utf8, '--opt', $utf8 );
is_deeply optargs,
  { one => $utf8, opt => $utf8 },
  'decoded bytes to utf8 using environment encoding';

my $output = qx/$^X $Bin\/single $utf8/;

my $VAR1;
if ( $output =~ m/\$VAR1/ ) {
    my $result = eval $output;

    is_deeply $result, { arg1 => $utf8, arg2 => 'optional', },
      'external argument encoding';
}

done_testing;

use strict;
use warnings;

# do not "use utf8"
#use utf8;
use FindBin qw/$Bin/;
use Encode qw/is_utf8 decode_utf8/;
use Test::More;
use Test::Fatal;
use OptArgs ':all';

my $complex = '¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/';
my $utf8    = decode_utf8($complex);

arg one => (
    isa      => 'Str',
    required => 1,
    comment  => 'unicode string',
);

arg two => (
    isa     => 'Str',
    comment => 'unicode string',
);

opt opt => (
    isa     => 'Str',
    comment => 'unicode opt',
);

@ARGV = ( $utf8, $complex, '--opt', $complex );
is_deeply optargs,
  { one => $utf8, two => $utf8, opt => $utf8 },
  'decoded bytes to utf8 using environment encoding';

my $output = qx/$^X $Bin\/single $complex/;

my $VAR1;
if ( $output =~ m/\$VAR1/ ) {
    my $result = eval $output;

    is_deeply $result, { arg1 => $utf8, arg2 => 'optional', },
      'external argument encoding';
}

$output = qx/$^X $Bin\/single $utf8/;

if ( $output =~ m/\$VAR1/ ) {
    my $result = eval $output;

    is_deeply $result, { arg1 => $utf8, arg2 => 'optional', },
      'external argument encoding';
}

done_testing;

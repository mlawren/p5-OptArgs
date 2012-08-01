use strict;
use warnings;
use utf8;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use FindBin qw/$Bin/;
use OptArgs ':all';
use POSIX qw/setlocale LC_ALL/;
use Test::More;

my $en_US = 'en_US.UTF-8';
my $loc = setlocale( LC_ALL, $en_US );

diag "POSIX::setlocale claims locale is set to $loc";

$loc = setlocale( LC_ALL, $en_US );

diag "POSIX::setlocale now claims locale is set to $loc";

unless ( $loc =~ m/$en_US/ ) {
    plan skip_all => "Cannot set locale $en_US";
    exit;
}

$ENV{LANG}   = $en_US;
$ENV{LC_ALL} = $en_US;

my $utf8 = '¥';

open( my $fh, '-|', $^X, "$Bin\/single", $utf8 ) || die "open: $!";
my $result = join( '', <$fh> );
close $fh;

is $result, Dumper( { arg1 => $utf8, arg2 => 'optional', } ),
  'external argument encoding given utf8';

done_testing;

use strict;
use warnings;
use Encode qw/is_utf8 decode_utf8/;
use Test::More;
use Test::Fatal;
use OptArgs ':all';

# Do not "use utf8;"
# We need @ARGV to contain bytes, not UTF8 strings
# But we also need to check that optargs works when given UTF-8 strings
# in @ARGV, which could occur if -C or -A is given to Perl

my $bytes;
my $utf8;

sub reset_args {
    $bytes = '¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/';
    $utf8  = decode_utf8($bytes);

    ok !is_utf8($bytes), 'bytes are bytes';
    ok is_utf8($utf8),   'utf8 is utf8';
}

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

reset_args();
@ARGV = ( $bytes, $utf8, '--opt', $bytes );
is_deeply optargs,
  { one => $utf8, two => $utf8, opt => $utf8 },
  'decoded bytes to utf8 using environment encoding';

reset_args();
@ARGV = ( $utf8, $bytes, '--opt', $utf8 );
is_deeply optargs,
  { one => $utf8, two => $utf8, opt => $utf8 },
  'decoded bytes to utf8 using environment encoding';

# Check for a missing I18N::Langinfo::CODESET
sub I18N::Langinfo::CODESET { die "missing" }

reset_args();
@ARGV = ( $bytes, $utf8, '--opt', $bytes );
is_deeply optargs,
  { one => $utf8, two => $utf8, opt => $utf8 },
  'decoded utf8 when I18N::Langinfo::CODESET is invalid';

reset_args();
@ARGV = ( '--opt', $bytes, $utf8, $bytes );
is_deeply optargs,
  { one => $utf8, two => $utf8, opt => $utf8 },
  'decoded utf8 when I18N::Langinfo::CODESET is invalid';

done_testing;

use strict;
use warnings;
use Encode qw/decode_utf8/;
use Test::More;
use Test::Fatal;
use OptArgs ':all';

# Do not "use utf8;"
# We need @ARGV to contain bytes, not UTF8 strings

arg utf8 => (
    isa     => 'Str',
    comment => 'unicode string',
);

@ARGV = ('¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/');
is_deeply optargs,
  { utf8 => decode_utf8('¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/')
  }, 'decoded utf8';

# But we also need to check that optargs works when given UTF-8 strings
# in @ARGV, which could occur if -C or -A is given to Perl
@ARGV =
  ( decode_utf8('¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/') );
is_deeply optargs,
  { utf8 => decode_utf8('¥£€$¢₡₢₣₤₥₦₧₨₩₪₫₭₮₯/')
  }, 'decoded utf8';

done_testing;

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

like exception {
    OptArgs::Error->new( undef, 'an error' );
},
  qr/OptArgs::Error->new/,
  'OptArgs::Error caller';

like exception {
    OptArgs::Error->new( 'Err', undef );
}, qr/OptArgs::Error->new/, 'OptArgs::Error caller';

my $e;

$e = OptArgs::Error->new( '', 'an error' );
isa_ok $e, 'OptArgs::Error';
is $e, 'an error', 'stringification';

$e = OptArgs::Error->new( 'Sub', 'an error' );
isa_ok $e, 'OptArgs::Error::Sub';
is $e, 'an error', 'sub class stringification';

$e = OptArgs::Usage->new( '', 'a usage msg' );
isa_ok $e, 'OptArgs::Usage';
is $e, 'a usage msg', 'usage stringification';

$e = OptArgs::Usage->new( 'Sub', 'a usage msg' );
isa_ok $e, 'OptArgs::Usage::Sub';
is $e, 'a usage msg', 'sub usage stringification';

done_testing();

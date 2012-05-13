use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

like exception {
    opt;
},
  qr/usage: opt/,
  'missing name';

like exception {
    opt undef;
}, qr/usage: opt/, 'missing name';

like exception {
    opt 0 => ();
}, qr/usage: opt/, 'missing name';

like exception {
    opt '' => ();
}, qr/usage: opt/, 'missing name';

like exception {
    opt no_isa => ();
}, qr/missing required parameter/, 'required isa';

like exception {
    opt str => ( isa => 'Str' );
}, qr/missing required parameter/, 'dont have all';

like exception {
    opt str => ( isa => 'Str', comment => 'comment', dummy => 1 );
}, qr/invalid parameter/, 'invalid parameter';

like exception {
    opt no_isa => ( isa => 'NoType', comment => 'comment' );
}, qr/unknown type/, 'unknown type';

like exception {
    opts;
}, qr/no defined/, 'no defined';

opt str => ( isa => 'Str', comment => 'comment' );

like exception {
    opt str => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

@ARGV = (qw/--str x --bool/);

like exception {
    opts;
}, qr/unexpected option or argument/, 'unexpected option or argument';

opt int => ( isa => 'Int', comment => 'comment' );
@ARGV = qw(--int=3.14);

like exception {
    opts;
}, qr/unexpected option or argument/, 'Gave real to an int';

done_testing;

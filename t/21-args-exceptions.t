use strict;
use warnings;
use Test::More;
use Test::Fatal;
use optargs;

like exception {
    arg;
},
  qr/usage: arg/,
  'missing name';

like exception {
    arg undef;
}, qr/usage: arg/, 'missing name';

like exception {
    arg 0 => ();
}, qr/usage: arg/, 'missing name';

like exception {
    arg '' => ();
}, qr/usage: arg/, 'missing name';

like exception {
    arg no_isa => ();
}, qr/missing required parameter/, 'required isa';

like exception {
    arg no_isa => ( isa => 'Str' );
}, qr/missing required parameter/, 'required both';

like exception {
    arg str => ( isa => 'Str', comment => 'comment', dummy => 1 );
}, qr/invalid parameter/, 'invalid parameter';

like exception {
    arg bad_type => ( isa => 'NoType', comment => 'comment', );
}, qr/unknown type/, 'unknown type';

like exception {
    arg clash => (
        isa      => 'Str',
        comment  => 'comment',
        required => 1,
        default  => 1
    );
}, qr/cannot be used together/, 'clash';

like exception {
    args;
}, qr/no defined/, 'no defined';

arg str => ( isa => 'Str', comment => 'comment', required => 1 );

like exception {
    arg str => ();
}, qr/already defined/, 'already defined';

@ARGV = ();

like exception {
    args;
}, qr/missing argument/, 'missing argument';

@ARGV = (qw/x x2/);

like exception {
    args;
}, qr/unexpected option or argument/, 'unexpected option or argument';

arg int => ( isa => 'Int', comment => 'comment', );
@ARGV = qw(x 3.14);

like exception {
    args;
}, qr/unexpected option or argument/, 'Gave real to an int';

opt bool => ( isa => 'Bool', comment => 'comment', );

like exception {
    arg bool => ();
}, qr/already defined/, 'already defined';

done_testing;

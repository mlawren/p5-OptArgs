use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

#------------------------------------------------------------------------
# optargs()
#------------------------------------------------------------------------

@ARGV = ();

like exception {
    optargs;
},
  qr/no option or argument defined/,
  'no defined';

#------------------------------------------------------------------------
# opt()
#------------------------------------------------------------------------

like exception {
    opt;
}, qr/usage: opt/, 'missing name';

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

opt str => ( isa => 'Str', comment => 'comment' );

like exception {
    opt str => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

#------------------------------------------------------------------------
# arg()
#------------------------------------------------------------------------

like exception {
    arg;
}, qr/usage: arg/, 'missing name';

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
    arg str => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

like exception {
    arg invalid_param => ( isa => 'Str', comment => 'comment', dummy => 1 );
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

arg astr => ( isa => 'Str', comment => 'comment', required => 1 );

#------------------------------------------------------------------------
# opt()
#------------------------------------------------------------------------

# check the opt/arg clash from the other side
like exception {
    opt astr => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

#------------------------------------------------------------------------
# optargs()
#------------------------------------------------------------------------

@ARGV = ();

like exception {
    optargs;
}, qr/^usage:/, 'missing argument';

@ARGV = (qw/x x2/);

like exception {
    optargs;
}, qr/unexpected option or argument/, 'unexpected option or argument';

arg int => (
    isa     => 'Int',
    comment => 'comment',
);

@ARGV = qw(x 3.14);

TODO: {
    local $TODO = 'arg types not implemented yet';
    like exception {
        optargs;
    }, qr/not an Int: 3.14/, 'not an Int';
}

opt bool => ( isa => 'Bool', comment => 'comment', );

like exception {
    arg bool => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

done_testing;

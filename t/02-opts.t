use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

opt bool => ( isa => 'Bool', comment => 'comment' );
is_deeply opts, { bool => undef }, 'nothing';

@ARGV = (qw/--bool/);
is_deeply opts, { bool => 1 }, 'got a bool';

is_deeply opts(qw/--no-bool/), { bool => 0 }, 'manual argv got no bool';
is_deeply opts,                { bool => 0 }, 'still got no bool';

opt str => ( isa => 'Str', comment => 'comment' );
is_deeply opts, { bool => undef, str => undef }, 'bool reset on new opt';

opt int      => ( isa => 'Int',      comment => 'comment' );
opt num      => ( isa => 'Num',      comment => 'comment' );
opt arrayref => ( isa => 'ArrayRef', comment => 'comment' );
opt hashref  => ( isa => 'HashRef',  comment => 'comment' );

is_deeply opts,
  {
    bool     => undef,
    str      => undef,
    int      => undef,
    num      => undef,
    arrayref => undef,
    hashref  => undef,
  },
  'deep match';

is opts->bool,     undef, 'opt->bool';
is opts->str,      undef, 'opt->str';
is opts->int,      undef, 'opt->int';
is opts->num,      undef, 'opt->num';
is opts->arrayref, undef, 'opt->arrayref';
is opts->hashref,  undef, 'opt->hashref';

@ARGV = qw(--int=3);
is opts->int, 3,     'int val';
is opts->str, undef, 'undef Str still';

@ARGV = qw(--num=3.14);
is opts->num, 3.14, 'num val';

@ARGV = qw(--num=14 --bool --str something);
is opts->num, 14, 'num val';
ok opts->bool, 'bool ok';
is opts->str, 'something', 'str something';

is_deeply opts,
  {
    bool     => 1,
    str      => 'something',
    int      => undef,
    num      => 14,
    arrayref => undef,
    hashref  => undef,
  },
  'deep match';

opts->{bool} = 0;
is opts->bool, 0, 'method match';

@ARGV = qw(--arrayref=14);
is_deeply opts->arrayref, [14], 'arrayref single';

@ARGV = qw(--arrayref=14 --arrayref=15);
is_deeply opts->arrayref, [ 14, 15 ], 'arrayref multi';

@ARGV = qw(--arrayref=15 --arrayref=14);
is_deeply opts->arrayref, [ 15, 14 ], 'arrayref multi order';

@ARGV = qw(--hashref one=1 --hashref two=2);
is_deeply opts->hashref, { one => 1, two => 2 }, 'hashref multi';

done_testing;

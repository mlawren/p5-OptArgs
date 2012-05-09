use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs;

arg str => ( isa => 'Str', comment => 'comment', );

@ARGV = (qw/x/);
is_deeply args, { str => 'x' }, 'got a str';

is_deeply args(qw/y/), { str => 'y' }, 'manual argv got str';
is_deeply args,        { str => 'y' }, 'still got str';

arg int => ( isa => 'Int', comment => 'comment', );

@ARGV = (qw/k 1/);
is_deeply args, { int => 1, str => 'k' }, 'str reset on new arg';

arg num      => ( isa => 'Num',      comment => 'comment', );
arg arrayref => ( isa => 'ArrayRef', comment => 'comment', );
arg hashref  => ( isa => 'HashRef',  comment => 'comment', );

@ARGV = (qw/k 1 3.14 1 one=1/);
is_deeply args,
  {
    str      => 'k',
    int      => 1,
    num      => 3.14,
    arrayref => [1],
    hashref  => { one => 1 },
  },
  'deep match';

is args->str, 'k',  'arg->str';
is args->int, 1,    'arg->int';
is args->num, 3.14, 'arg->num';
is_deeply args->arrayref, [1], 'arg->arrayref';
is_deeply args->hashref, { one => 1 }, 'arg->hashref';

done_testing;

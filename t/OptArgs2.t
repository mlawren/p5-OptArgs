#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::V0;

like dies {
    opt one => (
        isa     => 'Flag',
        ishelp  => 1,
        trigger => sub { },
        comment => 'comment',
    );
},
  qr/IshelpTriggerConflict/,
  'ishelp and trigger conflict';

done_testing;

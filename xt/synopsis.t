use Test::More;
eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis required for testing SYNOPSIS" if $@;
all_synopsis_ok();

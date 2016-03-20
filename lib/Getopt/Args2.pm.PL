#!perl
use strict;
use warnings;
use File::Spec;

# Duplicate OptArgs2 as Getopt::Args2 for easy discoverability

open my $fh, '<', File::Spec->catfile(qw/lib OptArgs2.pm/) or die "open: $!";
my $src = do { local $/ = undef; <$fh> };
close $fh;

$src =~ s/Getopt::Args2/GETOPT::ARGS2/g;
$src =~ s/OptArgs2/Getopt::Args2/g;
$src =~ s/p5-Getopt::Args2/p5-OptArgs2/g;
$src =~ s/GETOPT::ARGS2/OptArgs2/g;

mkdir File::Spec->catdir(qw/lib Getopt/);
open $fh, '>', File::Spec->catfile(qw/lib Getopt Args2.pm/);
print $fh $src;
close $fh;

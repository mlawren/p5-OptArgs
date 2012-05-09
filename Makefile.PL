use inc::Module::Install;

name 'optargs';
version '0.0.1_1';
all_from 'lib/optargs.pm';
readme_from 'lib/optargs.pod';

requires 'Exporter'     => 0;
requires 'Carp'         => 0;
requires 'Getopt::Long' => 2.37;
requires 'Module::Load' => 0;
requires 'Scalar::Util' => 0;

test_requires 'Test::More';
test_requires 'Test::Fatal';

author_tests 'xt';

repository 'https://github.com/mlawren/optargs';

WriteAll;

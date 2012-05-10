use inc::Module::Install;

name 'OptArgs';
version '0.0.1_1';
all_from 'lib/OptArgs.pm';
readme_from 'lib/OptArgs.pod';

requires 'Exporter::Tidy' => 0;
requires 'Carp'           => 0;
requires 'Getopt::Long'   => 2.37;
requires 'Scalar::Util'   => 0;

test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Output';

author_tests 'xt';

repository 'https://github.com/mlawren/optargs';

WriteAll;

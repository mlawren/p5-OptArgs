use inc::Module::Install;

name 'OptArgs';
version '0.0.2';
all_from 'lib/OptArgs.pm';
readme_from 'lib/OptArgs.pod';

requires 'Carp'           => 0;
requires 'Encode'         => 0;
requires 'Exporter::Tidy' => 0;
requires 'Getopt::Long'   => 2.37;
requires 'I18N::Langinfo' => 0;
requires 'List::Util'     => 0;

test_requires 'POSIX';
test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Output';

author_tests 'xt';

install_script 'bin/optargs';

repository 'https://github.com/mlawren/optargs';

WriteAll;

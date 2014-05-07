use inc::Module::Install;

name 'OptArgs';
version '0.1.10';
all_from 'lib/OptArgs.pm';
readme_from 'lib/OptArgs.pod';

requires 'Carp'           => 0;
requires 'Encode'         => 0;
requires 'Exporter::Tidy' => 0;
requires 'Getopt::Long'   => 2.37;
requires 'I18N::Langinfo' => 0 if $^O ne 'MSWin32';
requires 'List::Util'     => 0;
requires 'Text::Abbrev'   => 0;

test_requires 'IO::Capture::Stdout';
test_requires 'POSIX';
test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::Output';

author_tests 'xt';

install_script 'bin/optargs';

no_index package => 'OptArgs::Usage';
no_index package => 'Getopt::Args::Usage';

repository 'https://github.com/mlawren/p5-OptArgs';

WriteAll;

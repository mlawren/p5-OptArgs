package OptArgs2::SubCmd;
use strict;
use warnings;
use parent 'OptArgs2::CmdBase';
use Class::Inline name => {    # once legacy code goes move this into CmdBase
    init_arg => undef,
    default  => sub {
        my $x = $_[0]->class;
        $x =~ s/.*://;
        $x =~ s/_/-/g;
        $x;
    },
  },
  parent => { required => 1, },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

v0.0.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

    # For simple scripts use optargs()

    my $args = optargs(
        comment => 'script to paint things',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    print "Painting $args->{item}\n" unless $args->{quiet};

    # For complex multi-command applications
    # use cmd(), subcmd() and class_optargs()

    cmd 'My::app' => (
        comment => 'handy work app',
        optargs => [
            command => {
                isa      => 'SubCmd',
                required => 1,
                comment  => 'the action to take',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    subcmd 'My::app::prepare' => (
        comment => 'prepare something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to prepare',
            },
        ],
    );

    subcmd 'My::app::paint' => (
        comment => 'paint something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            color => {
                isa     => '--Str',
                alias   => 'c',
                comment => 'your faviourite',
                default => 'blue',
            },
        ],
    );

    my ( $class, $opts, $file ) = class_optargs('My::app');
    require $file;
    $class->new($opts);

=head1 DESCRIPTION

B<OptArgs2> processes command line arguments, options, and subcommands
according to the following definitions:

=over

=item Command

A program run from the command line to perform a task.

=item Arguments

Arguments are positional parameters that pass information to a command.
Arguments can be optional, but they should not be confused with Options
below.

=item Options

Options are non-positional parameters that pass information to a
command.  They are generally not required to be present (hence the name
Option) but that is configurable. All options have a long form prefixed
by '--', and may have a single letter alias prefixed by '-'.

=item Subcommands

From the users point of view a subcommand is a special argument with
its own set of arguments and options.  However from a code authoring
perspective subcommands are often implemented as stand-alone programs,
called from the main script when the appropriate command arguments are
given.

=back

=head2 Differences with Earlier Releases

B<OptArgs2> version 2.0.0 was a large re-write to improve the API and
code.  Users upgrading from version 0.0.11 or B<OptArgs> need to be
aware of the following:

=over

=item API changes: optargs(), cmd(), subcmd()

Commands and subcommands are now explicitly defined using C<optargs()>,
C<cmd()> and C<subcmd()>. The arguments to C<optargs()> have changed to
match C<cmd()>.

=item Deprecated: arg(), opt(), fallback arguments

Optargs definitions must now be defined in an array reference
containing key/value pairs as shown in the synopsis. Fallback arguments
have been replaced with a new C<fallthru> option.

=item class_optargs() no longer loads the class

Users must specifically require the class if they want to use it
afterwards.

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now displayed with the "[no-]"
prefix. What this means in practise is that many of your existing Bool
options most likely would become Flag options instead.

=back

=head2 Simple Commands

To demonstrate the simple use case (i.e. with no subcommands) lets put
the code from the synopsis in a file called C<paint> and observe the
following interactions from the shell:

    $ ./paint
    usage: paint ITEM [OPTIONS...]

      arguments:
        ITEM          the item to paint *required*

      options:
        --help,  -h   print a usage message and exit
        --quiet, -q   output nothing while working

The C<optargs()> function parses the command line (C<@ARGV>) according
to the included declarations and returns a single HASH reference.  If
the command is not called correctly then an exception is thrown
containing an automatically generated usage message as shown above.
Because B<OptArgs2> fully knows the valid arguments and options it can
detect a wide range of errors:

    $ ./paint wall Perl is great
    error: unexpected option or argument: Perl

So let's add that missing argument definition inside the optargs ref

    optargs => [
        ...
        message => {
            isa      => 'Str',
            comment  => 'the message to paint on the item',
            greedy   => 1,
        },
    ],

And then check the usage again:

    $ ./paint
    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM          the item to paint, *required*
        MESSAGE       the message to paint on the item

      options:
        --help,  -h   print a usage message and exit
        --quiet, -q   output nothing while working

Note that optional arguments are surrounded by square brackets, and
that three dots (...) are postfixed to greedy arguments. A greedy
argument will swallow whatever is left on the comand line:

    $ ./paint wall Perl is great
    Painting on wall: "Perl is great".

Note that it probably doesn't make sense to define any more arguments
once you have a greedy argument. Let's imagine you now want the user to
be able to choose the colour if they don't like the default. An option
might make sense here, specified by a leading '--' type:

    optargs => [
        ...
        colour => {
            isa           => '--Str',
            default       => 'blue',
            comment       => 'the colour to use',
        },
    ],

This now produces the following usage output:

    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM               the item to paint
        MESSAGE            the message to paint on the item

      options:
        --colour=STR, -c   the colour to use [blue]
        --help,       -h   print a usage message and exit
        --quiet,      -q   output nothing while working

=head2 Multi-Level Commands

Commands with subcommands require a different coding model and syntax
which we will describe over three phases:

=over

=item Definitions

Your command structure is defined using calls to the C<cmd()> and
C<subcmd()> functions. The first argument to both functions is the name
of the Perl class that implements the (sub-)command.

    cmd 'App::demo' => (
        comment => 'the demo command',
        optargs => [
            command => {
                isa      => 'SubCmd',
                required => 1,
                comment  => 'command to run',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'run quietly',
            },
        ],
    );

    subcmd 'App::demo::foo' => (
        comment => 'demo foo',
        optargs => [
            action => {
                isa      => 'Str',
                required => 1,
                comment  => 'command to run',
            },
        ],
    );

    subcmd 'App::demo::bar' => (
        comment => 'demo bar',
        optargs => [
            baz => {
                isa => '--Counter',
                comment => '+1',
            },
        ],
    );

    # Command hierarchy for the above code,
    # printed by using '-h' twice:
    #
    #     demo COMMAND [OPTIONS...]
    #         demo foo ACTION [OPTIONS...]
    #         demo bar [OPTIONS...]

An argument of type 'SubCmd' is an explicit indication that subcommands
can occur in that position. The command hierarchy is based upon the
natural parent/child structure of the class names.  This definition can

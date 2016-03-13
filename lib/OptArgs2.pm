package OptArgs2::Mo;

BEGIN {
#<<< do not perltidy
# use Mo qw/required build default is import/;
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.39
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];if(!exists$a{$n}){require Carp;Carp::croak($n." required")}$s}}$m}};*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=&{$M.Object::new}($c,@_);my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};*{$M.'is::e'}=sub{my($P,$e,$o)=@_;$o->{is}=sub{my($m,$n,%a)=@_;$a{is}or return$m;sub{$#_&&$a{is}eq'ro'&&caller ne'Mo::coerce'?die$n.' is ro':$m->(@_)}}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};@f=qw[required build default is import];use strict;use warnings;
#>>>
    $INC{'OptArgs2/Mo.pm'} = __FILE__;
}
1;

package OptArgs2::Result;
use overload
  bool     => sub { 1 },
  '""'     => 'as_string',
  fallback => 1;

1;

sub new {
    my $proto = shift;
    my $type  = shift || Carp::croak( $proto . '->new($TYPE,[@args])' );
    my $class = $proto . '::' . $type;

    {
        no strict 'refs';
        *{ $class . '::ISA' } = [$proto];
    }
    return bless [@_], $class;
}

sub as_string {
    my $type = ref( $_[0] ) =~ s/^OptArgs2::Result::(.*)/$1/r;
    my @x    = @{ $_[0] };
    if ( my $str = shift @x ) {
        return sprintf( "$str (%s)\n", @x, $type )
          unless $str =~ m/\n/;
        return sprintf( $str, @x );
    }
    return ref $_[0];
}

sub OptArgs2::STYLE_SUMMARY { 1 }
sub OptArgs2::STYLE_NORMAL  { 2 }
sub OptArgs2::STYLE_FULL    { 3 }

package OptArgs2::Arg;
use strict;
use warnings;
use OptArgs2::Mo;

has cmd => (
    is       => 'rw',
    weak_ref => 1,
);

has comment => (
    is       => 'ro',
    required => 1,
);

has default => ( is => 'ro', );

has fallback => ( is => 'rw', );

has greedy => ( is => 'ro', );

has isa => ( required => 1, );

has getopt => ( is => 'rw', );

has greedy => ( is => 'ro', );

#has isa2name => ( is => 'rw', );

has name => (
    is       => 'ro',
    required => 1,
);

has required => ( is => 'ro', );

my %arg2getopt = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

sub BUILD {
    my $self = shift;
    $self->fallback( OptArgs2::Fallback->new( %{ $self->fallback } ) )
      if $self->fallback;
}

sub name_comment {
    my $self  = shift;
    my $style = shift;

    return [ uc( $self->name ), $self->comment ]
      unless $self->isa eq 'SubCmd';

    return (
        [ uc( $self->name ), $self->comment ],

        map {
            [
                '  '
                  . (
                    ref $_ eq 'OptArgs2::Fallback'
                    ? uc( $_->name )
                    : $_->name
                  ),
                '  ' . $_->comment
            ]
          }
          sort { $a->name cmp $b->name }
          grep { $style == OptArgs2::STYLE_FULL or !$_->hidden }
          @{ $self->cmd->subcmds },
        $self->fallback ? $self->fallback : ()
    );
}

package OptArgs2::Fallback;
use strict;
use warnings;
use OptArgs2::Mo;

extends 'OptArgs2::Arg';

has hidden => ( is => 'ro', );

package OptArgs2::Opt;
use strict;
use warnings;
use Carp qw/croak/;
use OptArgs2::Mo;

has alias => ( is => 'ro', );

has comment => (
    is       => 'ro',
    required => 1,
);

has default => ( is => 'ro', );

has ishelp => ( is => 'ro', );

has isa => (
    is       => 'ro',
    required => 1,
);

has isa_name => ( is => 'rw', );

has name => (
    is       => 'ro',
    required => 1,
);

has hidden => ( is => 'ro', );

my %isa2getopt = (
    'Bool'     => '!',
    'Counter'  => '+',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

sub BUILD {
    my $self = shift;

    exists $isa2getopt{ $self->isa } || croak(
        OptArgs2::Result->new(
            'Error::IsaInvalid', 'invalid isa "%s" for opt "%s"',
            $self->isa,          $self->name
        )
    );
}

sub getopt {
    my $self = shift;
    my $expr = $self->name;
    $expr .= '|' . $self->alias if $self->alias;
    return $expr .= $isa2getopt{ $self->isa };
}

my %isa2name = (
    'Bool'     => '',
    'Counter'  => '',
    'Str'      => 'STR',
    'Int'      => 'INT',
    'Num'      => 'NUM',
    'ArrayRef' => 'STR',
    'HashRef'  => 'STR',
);

sub name_alias_comment {
    my $self          = shift;
    my $PRINT_DEFAULT = 1;
    my $PRINT_ISA     = 1;

    my $opt = $self->name =~ s/_/-/gr;

    if ( $self->isa eq 'Bool' ) {
        if ( $self->isa eq 'Bool' and $self->default ) {
            $opt = 'no-' . $opt;
        }
        elsif ( $self->isa eq 'Bool' and not defined $self->default ) {
            $opt = '[no-]' . $opt;
        }
    }
    elsif ($PRINT_ISA) {
        $opt .= '=' . ( $self->isa_name || $isa2name{ $self->isa } );
    }

    $opt = '--' . $opt;

    my $alias = $self->alias;
    if ( length $alias ) {
        $alias = '-' . $alias;
        $opt .= ',';
    }
    else {
        $alias = '';
    }

    my $comment = $self->comment;
    if ( $PRINT_DEFAULT && ( my $default = $self->default ) and !$self->ishelp )
    {
        my $value =
          ref $default eq 'CODE'
          ? $default->( {%$opt} )
          : $default;

        if ( $self->isa eq 'Bool' ) {
            $value = $value ? 'true' : 'false';
        }

        $comment .= " [default: $value]";
    }

    return [ $opt, $alias, $comment ];
}

package OptArgs2::Cmd;
use strict;
use warnings;
use OptArgs2::Mo;
use List::Util qw/max/;
use Scalar::Util qw/weaken/;

sub BUILD {
    my $self = shift;
    $self->name( $self->class =~ s/.*://r ) unless $self->name;
}

has abbrev => ( is => 'ro', );

has args => (
    is      => 'ro',
    default => sub { [] },
);

has class => (
    is       => 'ro',
    required => 1,
);

has comment => (
    is       => 'ro',
    required => 1,
);

has hidden => ( is => 'ro', );

has name => ( is => 'rw', );

has optargs => ( is => 'rw', );

has opts => (
    is      => 'ro',
    default => sub { [] },
);

has parent => (
    is       => 'rw',
    weak_ref => 1,
);

has subcmds => (
    is      => 'ro',
    default => sub { [] },
);

has usage_style => (
    is      => 'rw',
    default => OptArgs2::STYLE_NORMAL,
);

sub build_args_opts {
    my $self = shift;
    return unless ref $self->optargs eq 'CODE';
    local $OptArgs2::COMMAND = $self;
    $self->optargs->();
    $self->optargs(undef);
}

sub add_arg {
    my $self = shift;
    my $arg  = shift;

    push( @{ $self->args }, $arg );
    $arg->cmd($self);

    # A hack until Mo gets weaken support
    weaken $arg->{cmd};
    return $arg;
}

sub add_opt {
    push( @{ $_[0]->opts }, $_[1] );
    $_[1];
}

sub add_cmd {
    my $self   = shift;
    my $subcmd = shift;

    push( @{ $self->subcmds }, $subcmd );
    $subcmd->parent($self);

    # A hack until Mo gets weaken support
    weaken $subcmd->{parent};
    return $subcmd;
}

sub parents {
    my $self = shift;
    return unless $self->parent;
    return ( $self->parent, $self->parent->parents );
}

sub result {
    my $self = shift;
    return OptArgs2::Result->new(@_);
}

sub usage {
    my $self = shift;
    my $style = shift || $self->usage_style;

    my @parents = $self->parents;
    my @usage;
    my @uargs;
    my @uopts;

    my $usage = '';
    $usage .= join( ' ', map { $_->name } @parents ) . ' ' if @parents;
    $usage .= $self->name;

    $self->build_args_opts;

    my @args = @{ $self->args };
    foreach my $arg (@args) {
        $usage .= ' ';
        $usage .= '[' unless $arg->required;
        $usage .= uc $arg->name;
        $usage .= '...' if $arg->greedy;
        $usage .= ']' unless $arg->required;
        push( @uargs, $arg->name_comment($style) );
    }

    my @opts = map { @{ $_->opts } } @parents, $self;
    $usage .= ' [OPTIONS...]' if @opts;
    $usage .= "\n";

    return $usage if $style == OptArgs2::STYLE_SUMMARY;

    $usage .= "\n  Synopsis:\n    " . $self->comment . "\n"
      if $style == OptArgs2::STYLE_FULL;

    # Calulate the widths of the columns
    my @sorted_opts = sort { $a->name cmp $b->name } @opts;
    foreach my $opt (@sorted_opts) {
        next if $style != OptArgs2::STYLE_FULL and $opt->hidden;
        push( @uopts, $opt->name_alias_comment );
    }

    if (@uopts) {
        my $w1 = max( map { length $_->[0] } @uopts );
        my $fmt = '%-' . $w1 . "s %s";

        @uopts = map { [ sprintf( $fmt, $_->[0], $_->[1] ), $_->[2] ] } @uopts;
    }

    my $w1 = max( map { length $_->[0] } @usage, @uargs, @uopts );
    my $format = '    %-' . $w1 . "s   %s\n";

    # Lengths are now known so create the text
    if (@usage) {
        foreach my $row (@usage) {
            $usage .= sprintf( $format, @$row );
        }
    }

    #    if ( @uargs and $last->{isa} ne 'SubCmd' ) {
    if (@uargs) {
        if ( $style == OptArgs2::STYLE_FULL ) {
            $usage .= "\n  Arguments:\n";
        }
        else {
            $usage .= "\n";
        }
        foreach my $row (@uargs) {
            $usage .= sprintf( $format, @$row );
        }
    }

    if (@uopts) {
        if ( $style == OptArgs2::STYLE_FULL ) {
            $usage .= "\n  Options:\n";
        }
        else {
            $usage .= "\n";
        }
        foreach my $row (@uopts) {
            $usage .= sprintf( $format, @$row );
        }
    }

    return 'usage: ' . $usage . "\n";
}

sub usage_tree {
    my $self = shift;
    my $depth = shift || '';

    my $str = $depth . $self->usage(OptArgs2::STYLE_SUMMARY);

    foreach my $subcmd ( sort { $a->name cmp $b->name } @{ $self->subcmds } ) {
        $str .= $subcmd->usage_tree( $depth . '    ' );
    }

    return $str;
}

package OptArgs2;
use strict;
use warnings;
use Carp qw/croak/;
use Encode qw/decode/;
use Getopt::Long qw/GetOptionsFromArray/;
use Exporter qw/import/;
use OptArgs2::Mo;

our $VERSION = '0.0.1_1';
our @EXPORT  = (qw/arg cmd class_optargs opt subcmd/);
our $COMMAND;

my %command;

sub cmd {
    my $class = shift || Carp::confess('cmd($CLASS,@args)');

    croak "command already defined: $class"
      if exists $command{$class};

    my $cmd = OptArgs2::Cmd->new( class => $class, @_ );
    $command{$class} = $cmd;

    if ( $class =~ m/:/ ) {
        my $parent_class = $class =~ s/(.*)::/$1/r;
        if ( exists $command{$parent_class} ) {
            $command{$parent_class}->add_cmd($cmd);
        }
    }

    return $cmd;
}

sub get_cmd {
    my $class = shift;
    return exists $command{$class}
      ? $command{$class}
      : croak( 'command not found: ' . $class );
}

sub subcmd {
    my $class = shift || Carp::confess('cmd($CLASS,@args)');

    croak "sub-command already defined: $class"
      if exists $command{$class};

    croak "no '::' in class '$class' - must have a parent"
      unless $class =~ m/::/;

    my $parent_class = $class =~ s/(.*)::.*/$1/r;
    croak "parent class not found" unless exists $command{$parent_class};

    my $subcmd = OptArgs2::Cmd->new(
        class => $class,
        @_
    );

    return $command{$class} = $command{$parent_class}
      ->add_cmd( OptArgs2::Cmd->new( class => $class, @_ ) );
}

sub arg {
    my $name = shift;
    $OptArgs2::COMMAND->add_arg( OptArgs2::Arg->new( name => $name, @_ ) );
}

sub opt {
    my $name = shift;
    $OptArgs2::COMMAND->add_opt( OptArgs2::Opt->new( name => $name, @_ ) );
}

# ------------------------------------------------------------------------
# Option/Argument processing
# ------------------------------------------------------------------------
sub class_optargs {
    my $class = shift || croak('class_optargs($CLASS, [@argv])');
    my $cmd = $command{$class} || croak( 'command class not found: ' . $class );

    my $source      = \@_;
    my $source_hash = {};

    if ( !@_ and @ARGV ) {
        my $CODESET =
          eval { require I18N::Langinfo; I18N::Langinfo::CODESET() };

        if ($CODESET) {
            my $codeset = I18N::Langinfo::langinfo($CODESET);
            $_ = decode( $codeset, $_ ) for @ARGV;
        }

        $source = \@ARGV;
    }
    else {
        $source_hash = { map { %$_ } grep { ref $_ eq 'HASH' } @$source };
        $source = [ grep { ref $_ ne 'HASH' } @$source ];
    }

    map { Carp::croak('_optargs argument undefined!') if !defined $_ } @$source;

    Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

    $cmd->build_args_opts;

    my @config = ( @{ $cmd->opts }, @{ $cmd->args } );

    my $ishelp;
    my $missing_required;
    my $optargs = {};
    my @coderef_default_keys;

    while ( my $try = shift @config ) {
        my $result;

        if ( $try->SUPER::isa('OptArgs2::Opt') ) {
            if ( exists $source_hash->{ $try->name } ) {
                $result = delete $source_hash->{ $try->name };
            }
            else {
                GetOptionsFromArray( $source, $try->getopt => \$result );
            }

        }
        if ( $try->SUPER::isa('OptArgs2::Arg') ) {

            if (@$source) {

                die $cmd->result( 'Error::UnknownOption',
                    qq{error: unknown option "$source->[0]"\n\n} . $cmd->usage )
                  if $source->[0] =~ m/^--\S/;

                die $cmd->result( 'Error::UnknownOption',
                    qq{error: unknown option "$source->[0]"\n\n} . $cmd->usage )
                  if $source->[0] =~ m/^-\S/
                  and !(
                    $source->[0] =~ m/^-\d/ and ( $try->isa ne 'Num'
                        or $try->isa ne 'Int' )
                  );

                if ( $try->greedy ) {
                    my @later;
                    if ( @config and @$source > @config ) {
                        push( @later, pop @$source ) for @config;
                    }

                    if ( $try->isa eq 'ArrayRef' ) {
                        $result = [@$source];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result = { map { split /=/, $_ } @$source };
                    }
                    else {
                        $result = "@$source";
                    }

                    shift @$source while @$source;
                    push( @$source, @later );
                }
                else {
                    if ( $try->isa eq 'ArrayRef' ) {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result = { split /=/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }
                }

                # TODO: type check using Param::Utils?
            }
            elsif ( exists $source_hash->{ $try->name } ) {
                $result = delete $source_hash->{ $try->name };
            }
            elsif ( $try->required and !$ishelp ) {
                $missing_required++;
                next;
            }

            if ( $result and $try->isa eq 'SubCmd' ) {

                # look up abbreviated words
                if ( $cmd->abbrev ) {
                    require Text::Abbrev;
                    my %abbrev =
                      Text::Abbrev::abbrev( map { $_->name }
                          @{ $cmd->subcmds } );
                    $result = $abbrev{$result} if defined $abbrev{$result};
                }

                my $new_class = $class . '::' . $result;
                $new_class =~ s/-/_/g;

                if ( exists $command{$new_class} ) {
                    $cmd = $command{$new_class};
                    $cmd->build_args_opts;

                    # Ignoring any remaining arguments
                    @config =
                      grep { ref($_)->SUPER::isa('OptArgs2::Opt') } @config;
                    push( @config, @{ $cmd->opts }, @{ $cmd->args } );
                }
                elsif ( !$ishelp ) {
                    if ( $try->fallback ) {
                        unshift @$source, $result;

                      #                        $try->{fallback}->{type} = 'arg';
                        unshift( @config, $try->fallback );
                        next;
                    }
                    else {
                        die $cmd->result(
                            'Error::Unknown' . uc( $try->name ),
                            'unknown '
                              . uc( $try->name )
                              . qq{ "$result"\n\n}
                              . $cmd->usage
                        );
                    }
                }

                $result = undef;
            }

        }

        if ( defined $result ) {
            $optargs->{ $try->name } = $result;
        }
        elsif ( defined $try->default ) {
            push( @coderef_default_keys, $try->name )
              if ref $try->default eq 'CODE';
            $optargs->{ $try->name } = $result = $try->default;
        }

        $ishelp = 1
          if $result and ( $try->SUPER::isa('OptArgs2::Opt') && $try->ishelp );

    }

    if ($ishelp) {
        die $cmd->result( 'Help', $cmd->usage(OptArgs2::STYLE_FULL) );
    }
    elsif ($missing_required) {
        die $cmd->result( 'Error::MissingRequired', $cmd->usage );
    }
    elsif (@$source) {
        die $cmd->result( 'Error::UnexpectedOptArgs',
            "error: unexpected option(s) or argument(s): @$source\n\n"
              . $cmd->usage );
    }
    elsif ( my @unexpected = keys %$source_hash ) {
        die $cmd->result( 'Error::UnexpectedHashOptArgs',
            "error: unexpected HASH options or arguments: @unexpected\n\n"
              . $cmd->usage );
    }

    # Re-calculate the default if it was a subref
    foreach my $key (@coderef_default_keys) {
        $optargs->{$key} = $optargs->{$key}->( {%$optargs} );
    }

    return ( $cmd->class, $optargs );
}

1;

__END__

=head1 NAME

OptArgs2 - argument and option processor for scripts

=head1 VERSION

0.1.19_2 (yyyy-mm-dd)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

    opt quiet => (
        isa     => 'Bool',
        alias   => 'q',
        comment => 'output nothing while working',
    );

    arg item => (
        isa      => 'Str',
        required => 1,
        comment  => 'the item to paint',
    );

    my $ref = optargs;

    print "Painting $ref->{item}\n" unless $ref->{quiet};

=head1 DESCRIPTION

B<OptArgs2> processes Perl script I<options> and I<arguments>.  This is
in contrast with most modules in the Getopt::* namespace, which deal
with options only. This module is duplicated as L<Getopt::Args>, to
cover both its original name and yet still be found in the mess that is
Getopt::*.

The following model is assumed by B<OptArgs2> for command-line
applications:

=over

=item Command

The program name - i.e. the filename be executed by the shell.

=item Options

Options are parameters that affect the way a command runs. They are
generally not required to be present, but that is configurable. All
options have a long form prefixed by '--', and may have a single letter
alias prefixed by '-'.

=item Arguments

Arguments are positional parameters that that a command needs know in
order to do its work. Confusingly, arguments can be optional.

=item Sub-commands

From a users point of view a sub-command is simply one or more
arguments given to a Command that result in a particular action.
However from a code perspective they are implemented as separate,
stand-alone programs which are called by a dispatcher when the
appropriate arguments are given.

=back

=head2 Simple Scripts

To demonstrate lets put the code from the synopsis in a file called
C<paint> and observe the following interactions from the shell:

    $ ./paint
    usage: paint ITEM

      arguments:
        ITEM          the item to paint

      options:
        --quiet, -q   output nothing while working

The C<optargs()> function parses the commands arguments according to
the C<opt> and C<arg> declarations and returns a single HASH reference.
If the command is not called correctly then an exception is thrown (an
C<OptArgs2::Usage> object) with an automatically generated usage
message as shown above.

Because B<OptArgs2> knows about arguments it can detect errors relating
to them:

    $ ./paint house red
    error: unexpected option or argument: red

So let's add that missing argument definition:

    arg colour => (
        isa     => 'Str',
        default => 'blue',
        comment => 'the colour to use',
    );

And then check the usage again:

    $ ./paint
    usage: paint ITEM [COLOUR]

      arguments:
        ITEM          the item to paint
        COLOUR        the colour to use

      options:
        --quiet, -q   output nothing while working

It can be seen that the non-required argument C<colour> appears inside
square brackets indicating its optional nature.

Let's add another argument with a positive value for the C<greedy>
parameter:

    arg message => (
        isa     => 'Str',
        comment => 'the message to paint on the item',
        greedy  => 1,
    );

And check the new usage output:

    usage: paint ITEM [COLOUR] [MESSAGE...]

      arguments:
        ITEM          the item to paint
        COLOUR        the colour to use
        MESSAGE       the message to paint on the item

      options:
        --quiet, -q   output nothing while working

Three dots (...) are postfixed to usage message for greedy arguments.
By being greedy, the C<message> argument will swallow whatever is left
on the comand line:

    $ ./paint house blue Perl is great
    Painting in blue on house: "Perl is great".

Note that it doesn't make sense to define any more arguments once you
have a greedy argument.

The order in which options and arguments (and sub-commands - see below)
are defined is the order in which they appear in usage messsages, and
is also the order in which the command line is parsed for them.

=head2 Sub-Command Scripts

Sub-commands are useful when your script performs different actions
based on the value of a particular argument. To use sub-commands you
build your application with the following structure:

=over

=item Command Class

The Command Class defines the options and arguments for your I<entire>
application. The module is written the same way as a simple script but
additionally specifies an argument of type 'SubCmd':

    package My::Cmd;
    use OptArgs2;

    arg command => (
        isa     => 'SubCmd',
        comment => 'sub command to run',
    );

    opt help => (
        isa     => 'Bool',
        comment => 'print a help message and exit',
        ishelp  => 1,
    );

    opt dry_run => (
        isa     => 'Bool',
        comment => 'do nothing',
    );

The C<subcmd> function call is then used to define sub-command names
and descriptions, and separate each sub-commands arguments and options:

    subcmd(
        cmd     => 'start',
        comment => 'start a machine'
    );

    arg machine => (
        isa     => 'Str',
        comment => 'the machine to start',
    );

    opt quickly => (
        isa     => 'Bool',
        comment => 'start the machine quickly',
    );

    subcmd(
        cmd     => 'stop',
        comment => 'start the machine'
    );

    arg machine => (
        isa     => 'Str',
        comment => 'the machine to stop',
    );

    opt plug => (
        isa     => 'Bool',
        comment => 'stop the machine by pulling the plug',
    );

One nice thing about B<OptArgs2> is that options are I<inherited>. You
only need to specify something like a C<dry-run> option once at the top
level, and all sub-commands will see it if it has been set.

Additionally, and this is the main reason why I wrote B<OptArgs2>, you
do not have to load a whole bunch of slow-to-start modules ( I'm
looking at you, L<Moose>) just to get a help message.

=item Sub-Command Classes

These classes do the actual work. The usual entry point would be a
method or a function, typically called something like C<run>, which
takes a HASHref argument:

    package My::Cmd::start;

    sub run {
        my $self = shift;
        my $opts = shift;
        print "Starting $opts->{machine}\n";
    }


    package My::Cmd::stop;

    sub run {
        my $self = shift;
        my $opts = shift;
        print "Stoping $opts->{machine}\n";
    }

=item Command Script

The command script is what the user runs, and does nothing more than
dispatch to your Command Class, and eventually a Sub-Command Class.

    #!/usr/bin/perl
    use OptArgs2 qw/class_optargs/;
    my ($class, $opts) = class_optargs('My::Cmd');

    # Run object based sub-command classes
    $class->new->run($opts);

    # Or function based sub-command classes
    $class->can('run')->($opts);

One advantage to having a separate Command Class (and not defining
everything inside a Command script) is that it is easy to run tests
against your various Sub-Command Classes as follows:

    use Test::More;
    use Test::Output;
    use OptArgs2 qw/class_optargs/;

    stdout_is(
        sub {
            my ($class,$opts) = class_optargs('My::Cmd','start','A');
            $class->new->run($opts);
        },
        "Starting A\n", 'start'
    );

    eval { class_optargs('My::Cmd', '--invalid-option') };
    isa_ok $@, 'OptArgs2::Usage';

    done_testing();

It is much easier to catch and measure exceptions when the code is
running inside your test script, instead of having to fork and parse
stderr strings.

=back

=head1 FUNCTIONS

The following functions are exported (by default except for
C<dispatch>) using L<Exporter::Tidy>.

=over

=item arg( $name, %parameters )

Define a Command Argument with the following parameters:

=over

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

     optargs         Getopt::Long
    ------------------------------
     'Str'           '=s'
     'Int'           '=i'
     'Num'           '=f'
     'ArrayRef'      's@'
     'HashRef'       's%'
     'SubCmd'        '=s'

=item comment

Required. Used to generate the usage/help message.

=item required

Set to a true value when the caller must specify this argument.  Can
not be used if a 'default' is given.

=item default

The value set when the argument is not given. Can not be used if
'required' is set.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item greedy

If true the argument swallows the rest of the command line. It doesn't
make sense to define any more arguments once you have used this as they
will never be seen.

=item fallback

A hashref containing an argument definition for the event that a
sub-command match is not found. This parameter is only valid when
C<isa> is a C<SubCmd>. The hashref must contain "isa", "name" and
"comment" key/value pairs, and may contain a "greedy" key/value pair.
The Command Class "run" function will be called with the fallback
argument integrated into the first argument like a regular sub-command.

This is generally useful when you want to calculate a command alias
from a configuration file at runtime, or otherwise run commands which
don't easily fall into the OptArgs2 sub-command model.

=back

=item class_optargs( $rootclass, [ @argv ] ) -> ($class, $opts)

This is a more general version of the C<optargs> function described in
detail below.  It parses C<@ARGV> (or C<@argv> if given) according to
the options and arguments as defined in C<$rootclass>, and returns two
values:

=over

=item $class

The class name of the matching sub-command.

=item $opts

The matching argument and options for the sub-command.

=back

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item dispatch( $function, $rootclass, [ @argv ] )

[ NOTE: This function is badly designed and is depreciated. It will be
removed at some point before version 1.0.0]

Parse C<@ARGV> (or C<@argv> if given) and dispatch to C<$function> in
the appropriate package name constructed from C<$rootclass>.

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item opt( $name, %parameters )

Define a Command Option. If C<$name> contains underscores then aliases
with the underscores replaced by dashes (-) will be created. The
following parameters are accepted:

=over

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

     optargs         Getopt::Long
    ------------------------------
     'Bool'          '!'
     'Counter'       '+'
     'Str'           '=s'
     'Int'           '=i'
     'Num'           '=f'
     'ArrayRef'      's@'
     'HashRef'       's%'

=item isa2name

When C<$OptArgs2::PRINT_ISA> is set to a true value, this value will be
printed instead of the generic value from C<isa>.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not used.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

For "Bool" options setting "default" to a true has a special effect:
the the usage message formats it as "--no-option" instead of
"--option". If you do use a true default value for Bool options you
probably want to reverse the normal meaning of your "comment" value as
well.

=item alias

A single character alias.

=item ishelp

When true flags this option as a help option, which when given on the
command line results in a usage message exception.  This flag is
basically a cleaner way of doing the following in each (sub) command:

    my $opts = optargs;
    if ( $opts->{help} ) {
        die usage('help requested');
    }

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item arg_name

When C<$OptArgs2::PRINT_OPT_ARG> is set to a true value, this value
will be printed instead of the generic value from C<isa>.

=back

=item optargs( [ @argv ] ) -> HashRef

Parse @ARGV by default (or @argv when given) for the arguments and
options defined in the I<current package>, and returns a hashref
containing key/value pairs for options and arguments I<combined>.  An
error / usage exception object (C<OptArgs2::Usage>) is thrown if an
invalid combination of options and arguments is given.

Note that C<@ARGV> will be decoded into UTF-8 (if necessary) from
whatever L<I18N::Langinfo> says your current locale codeset is.

=item subcmd( %parameters )

Create a sub-command. After this function is called further calls to
C<opt> and C<arg> define options and arguments respectively for the
sub-command.  The following parameters are accepted:

=over

=item cmd

Required. Either a scalar or an ARRAY reference containing the sub
command name.

=item comment

Required. Used to generate the usage/help message.

=item hidden

When true this sub command will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only or rarely-used commands that
you don't want cluttering up your normal usage message.

=back

=item usage( [$message] ) -> Str

Returns a usage string prefixed with $message if given.

=back

=head1 OPTIONAL BEHAVIOUR

Certain B<OptArgs2> behaviour and/or output can be changed by setting
the following package-level variables:

=over

=item $OptArgs2::ABBREV

If C<$OptArgs2::ABBREV> is a true value then sub-commands can be
abbreviated, up to their shortest, unique values.

=item $OptArgs2::COLOUR

If C<$OptArgs2::COLOUR> is a true value and C<STDOUT> is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=item $OptArgs2::SORT

If C<$OptArgs2::SORT> is a true value then sub-commands will be listed
in usage messages alphabetically instead of in the order they were
defined.

=item $OptArgs2::PRINT_DEFAULT

If C<$OptArgs2::PRINT_DEFAULT> is a true value then usage will print
the default value of all options.

=item $OptArgs2::PRINT_ISA

If C<$OptArgs2::PRINT_ISA> is a true value then usage will print the
type of argument a options expects.

=back

=head1 SEE ALSO

L<Getopt::Long>, L<Exporter::Tidy>

=head1 SUPPORT & DEVELOPMENT


This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs2/tree/devel

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2012-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


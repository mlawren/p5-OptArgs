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

has trigger => ( is => 'ro', );

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
    'Boo'      => '!',
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
    'Boo'      => '',
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
    elsif ( !$self->isa eq 'Boo' and $PRINT_ISA ) {
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
    if ( $PRINT_DEFAULT && defined( my $default = $self->default ) ) {
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
use overload
  bool     => sub { 1 },
  '""'     => 'class',
  fallback => 1;
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

our $CURRENT;

sub build_args_opts {
    my $self = shift;
    return unless ref $self->optargs eq 'CODE';
    local $CURRENT = $self;
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

    return $self->result( 'UsageSummary', $usage )
      if $style == OptArgs2::STYLE_SUMMARY;

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

    return $self->result( 'UsageFull', 'usage: ' . $usage . "\n" );
}

sub _usage_tree {
    my $self = shift;
    my $depth = shift || '';

    my $str = $depth . $self->usage(OptArgs2::STYLE_SUMMARY);

    foreach my $subcmd ( sort { $a->name cmp $b->name } @{ $self->subcmds } ) {
        $str .= $subcmd->_usage_tree( $depth . '    ' );
    }

    return $str;
}

sub usage_tree {
    my $self = shift;
    return $self->result( 'UsageTree', $self->_usage_tree );
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
our @EXPORT  = (qw/arg cmd cmd_optargs opt subcmd/);

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

    croak "subcommand already defined: $class"
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
    $OptArgs2::Cmd::CURRENT->add_arg( OptArgs2::Arg->new( name => $name, @_ ) );
}

sub opt {
    my $name = shift;
    $OptArgs2::Cmd::CURRENT->add_opt( OptArgs2::Opt->new( name => $name, @_ ) );
}

# ------------------------------------------------------------------------
# Option/Argument processing
# ------------------------------------------------------------------------
sub cmd_optargs {
    my $class = shift || croak('cmd_optargs($CLASS, [@argv])');
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

            if ( my $ref = $try->trigger and defined $result ) {
                $ref->( $cmd, $result );
            }
        }
        elsif ( $try->SUPER::isa('OptArgs2::Arg') ) {

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
            elsif ( $try->required ) {
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
                elsif ( $try->fallback ) {
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

    }

    if ($missing_required) {
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

    return ( $cmd, $optargs );
}

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

0.0.1_1 (yyyy-mm-dd)

=head1 SYNOPSIS

    use OptArgs2;

    cmd 'App::foo' => (
        comment => 'the thing that goes foo',
        optargs => sub {
            arg item => (
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            );

            opt quiet => (
                isa     => 'Bool',
                alias   => 'q',
                comment => 'output nothing while working',
            );
        },
    );

    subcmd 'App::foo::bar' => (
        comment => 'go bar',
        optargs => sub {
            arg maybe => (
                isa     => 'Bool',
                alias   => 'm',
                comment => 'output nothing while working',
            );
        },
    );

    my ($cmd, $opts) = cmd_optargs('App::foo');

    # Load your $cmd and run it with $opts, perhaps
    # eval "require $cmd" or die $@;
    $cmd->new($opts);
    print "Running $cmd\n" unless $opts->{quiet};

=head1 DESCRIPTION

B<OptArgs2> processes command line options I<and arguments>, with
support for subcommands. It helps you build applications with a
hierarchical command structure like so:

    demo COMMAND [OPTIONS...]
        demo args STRING [STRING] [GREEDY...] [OPTIONS...]
        demo opts [OPTIONS...]

B<OptArgs2> automatically generates usage messages like the following
when arguments are missing or options are invalid:

    error: unknown option "--not-exist"

    usage: demo COMMAND [OPTIONS...]

        COMMAND
          args            demo for arguments
          opts            demo for options

        --dry-run, -n   a global option
        --help,    -h   print full help and exit
        --quiet,   -q   a quiet global option


This module is duplicated on CPAN as L<Getopt::Args2>, to cover both
its original name and yet still be found in the mess that is Getopt::*.

=head2 Differences Between OptArgs and OptArgs2

B<OptArgs2> is a re-write of the original L<OptArgs> module with a
cleaner code base and improved API. It should be preferred over
L<OptArgs> for new projects however both distributions will continue to
be maintained in parallel.

Users converting to B<OptArgs2> from L<OptArgs> need to be aware of the
following:

=over

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now shown with the "[no-]" prefix
unless a default has been provided, in which case either "--bool" (for
default = false) or "--no-bool" (for default = true) is shown.

=item A new 'Boo' option type

The Boo option type is like a Bool that can only be set to true or left
undefined. This makes sense for things such as C<--help> or
C<--version> for which you never need to see a "--no" prefix.

It also makes sense for "negative" options which will only ever turn
things off:

    opt no_foo => (
        isa     => 'Boo',
        comment => 'disable the foo feature',
    );

    # do { } unless $opts->{no_foo}

=item The "ishelp" option parameter is no longer supported.

Support for C<--help> style actions is now provided via the 'trigger'
parameter as follows:

    opt help => (
        isa     => 'Boo',
        comment => 'print a help message and exit',
        trigger => { sub die shift->usage(OptArgs2::STYLE_FULL) },
    );

=back

=head2 Terminology

The following terminology is assumed by B<OptArgs2> for command-line
applications:

=over

=item Command

A program run from the command line to perform a task.

=item Arguments

Arguments are positional parameters that pass information to the
command. Arguments can be optional, but they should not be confused
with Options below.

=item Options

Options are parameters that also pass information to a command.  They
are generally not required to be present (hence the name Option) but
that is configurable. All options have a long form prefixed by '--',
and may have a single letter alias prefixed by '-'.

=item Subcommands

From the users point of view a subcommand is seen as a specific
argument to a command.  However from a code authoring perspective
subcommands are often implemented as separate, stand-alone programs
which are called by a dispatcher when the appropriate command arguments
are given.

=back

=head2 Authoring Commands

Applications using B<OptArgs2> work like this:

=over

=item Definition

You define your command structure using calls to C<cmd()> and
C<subcmd()>.  This can be done in your main script, or in one or more
separate packages, as you like.

=item Parsing

The C<cmd_optargs()> function uses this command structure to parse the
C<@ARGV> array and calls your C<arg()> and C<opt()> definitions as
needed. A usage exception is raised if required elements of C<@ARGV>
are missing or invalid.

=item Dispatch/Execution

The matching (sub)command name plus a HASHref of combined argument and
option values is returned, which you can use to execute the action or
dispatch to the appropriate class/package as you like.

=back

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item cmd( $name, %parameters ) -> OptArgs2::Cmd

Define a top-level command identified by C<$name> which is typically a
Perl package name. The following parameters are accepted:

=for comment
=item name
A display name of the command. Optional - if it is not provided then the
last part of the command name is used is usage messages.

=over

=item comment

A description of the command. Required.

=item optargs

A subref containing calls to C<arg()> and C<opt>. Note that options are
inherited by subcommands so you don't need to define them again in
child subcommands.

By default this subref is only called on demand when the
C<cmd_optargs()> function sees arguments for that particular
subcommand. However for testing it is useful to know immediately if you
have an error. For this purpose the OPTARGS2_IMMEDIATE environment
variable can be set to trigger it at definition time.

=item abbrev

If $OptArgs::ABBREV is a true value then subcommands can be
abbreviated, up to their shortest, unique values.

=item colour

If $OptArgs::COLOUR is a true value and "STDOUT" is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=item sort

If $OptArgs::SORT is a true value then subcommands will be listed in
usage messages alphabetically instead of in the order they were
defined.

=item print_default

If $OptArgs::PRINT_DEFAULT is a true value then usage will print the
default value of all options.

=item print_isa

If $OptArgs::PRINT_ISA is a true value then usage will print the type
of argument a options expects.

=for comment
=item usage
Valid for C<cmd()> only. A subref for generating a custom usage
message. See XXX befow for the structure this subref receives.

=back

=item subcmd( $name, %parameters ) -> OptArgs2::Cmd

Defines a subcommand identified by C<$name> which must include the name
of a previously defined (sub)command + '::'.

Accepts the same parameters as C<cmd()> in addition to the following:

=over

=item hidden

Hide the existence of this subcommand in usage messages created with
OptArgs::STYLE_NORMAL.  This is handy if you have developer-only or
rarely-used commands that you don't want cluttering up your normal
usage message.

=back

=item arg( $name, %parameters )

    arg name => (
        isa      => 'Str',
        isa_name => 'FILE',
        comment  => 'the file to parse',
        required => 1,
        default  => '-',
        greedy   => 0,
    );

Define a command argument with the following parameters:

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
subcommand match is not found. This parameter is only valid when C<isa>
is a C<SubCmd>. The hashref must contain "isa", "name" and "comment"
key/value pairs, and may contain a "greedy" key/value pair. The Command
Class "run" function will be called with the fallback argument
integrated into the first argument like a regular subcommand.

This is generally useful when you want to calculate a command alias
from a configuration file at runtime, or otherwise run commands which
don't easily fall into the OptArgs2 subcommand model.

=back

=item opt( $name, %parameters )

Define a Command Option. If C<$name> contains underscores then aliases
with the underscores replaced by dashes (-) will be created. The
following parameters are accepted:

=over

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

    isa              Getopt::Long
    ---              ------------
     'ArrayRef'      's@'
     'Boo'           '!'
     'Bool'          '!'
     'Counter'       '+'
     'HashRef'       's%'
     'Int'           '=i'
     'Num'           '=f'
     'Str'           '=s'

The presentation of Boo and Bool types in usage messages is as follows:

    $name       Type        Default         Presentation
    ----        ----        -------         ------------
    option      Boo         always undef    --option
    no_option   Boo         always undef    --no-option
    option      Bool        undef           --[no-]option
    option      Bool        true            --no-option
    option      Bool        false           --option
    option      Counter     *               --option

The presentation of the remaining types is as follows:

    $name       Type        isa_name        Presentation
    ----        ----        --------        ------------
    option      ArrayRef    -               --option=STR
    option      HashRef     -               --option=STR
    option      Int         -               --option=INT
    option      Num         -               --option=NUM
    option      Str         -               --option=STR
    option      *           XX              --option=XX

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

=item trigger => sub { }

The trigger parameter lets you define a subroutine that is called
I<immediately> as soon as the option presence is detected. This is
primarily to support --help or --version options which typically don't
need the full command line to be processed before generating a
response.

    opt help => (
        isa     => 'Boo',
        alias   => 'h',
        comment => 'print full help message and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die $cmd->usage(OptArg2::STYLE_FULL);
        }
    );

The trigger subref is pass two parameters: an OptArgs2::Cmd object on
which you can call the C<usage()> method and the value (if any) of the
option.

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

=item cmd_optargs( $cmd, [ @argv ] ) -> ($subcmd, $opts)

Parse @ARGV by default (or @argv when given) for the arguments and
options defined in the command C<$cmd>.  C<@ARGV> will first be decoded
into UTF-8 (if necessary) from whatever L<I18N::Langinfo> says your
current locale codeset is.

Throws an error / usage exception object (typically C<OptArgs2::Usage>)
if @ARGV is missing or contains invalid options or arguments.

Returns the following two values:

=over

=item $subcmd

The C<$subcmd> that was matched by parsing the arguments. This may be
the same as C<$cmd>.

=item $opts

a hashref containing key/value pairs for options and arguments
I<combined>.

=back

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item usage( [$message] ) -> Str

Returns a usage string prefixed with $message if given.

=back

=head1 SEE ALSO

L<Getopt::Long>

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

Copyright 2016 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


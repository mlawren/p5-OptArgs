use strict;
use warnings;

package OptArgs2 {
    use overload
      bool     => sub { 1 },
      '""'     => sub { ${ $_[0] } },
      fallback => 1;
    use Encode qw/decode/;
    use Getopt::Long qw/GetOptionsFromArray/;
    use Exporter::Tidy
      default => [qw/arg class_optargs cmd opt optargs subcmd/],
      other   => [qw/usage/];

    our $VERSION = '2.0.0_3';
    our @CARP_NOT;

    # constants
    sub STYLE_USAGE()       { 'Usage' }         # default
    sub STYLE_HELP()        { 'Help' }
    sub STYLE_HELPTREE()    { 'HelpTree' }
    sub STYLE_HELPSUMMARY() { 'HelpSummary' }

    # Backwards compatibility
    sub STYLE_FULL()    { STYLE_HELP }
    sub STYLE_TREE()    { STYLE_HELPTREE }
    sub STYLE_SUMMARY() { STYLE_HELPSUMMARY }

    our $CURRENT;
    our %isa2name = (
        'ArrayRef' => 'Str',
        'Bool'     => '',
        'Counter'  => '',
        'Flag'     => '',
        'HashRef'  => 'Str',
        'Int'      => 'Int',
        'Num'      => 'Num',
        'Str'      => 'Str',
        'SubCmd'   => 'Str',
    );

    my %COMMAND;

    my @chars;

    sub _chars {
        if ( $^O eq 'MSWin32' ) {
            require Win32::Console;
            @chars = Win32::Console->new()->Size();
        }
        else {
            require Term::Size::Perl;
            @chars = Term::Size::Perl::chars();
        }
        $chars[shift];
    }

    sub cols {
        $chars[0] // _chars(0);
    }

    sub rows {
        if (@_) {
            my $r = scalar( split /\n/, $_[0] );
            $r++ if $_[0] =~ m/\n\z/;
        }
        else {
            $chars[1] // _chars(1);
        }
    }

    sub maybe_page {
        return unless -t select;

        my $lines = scalar( split /\n/, $_[0] );
        $lines++ if $_[0] =~ m/\n\z/;

        if ( $lines >= ( $chars[1] // _chars(1) ) ) {
            require OptArgs2::Pager;
            OptArgs2::Pager::page( $_[0] );    # returns true on success
        }
    }

    sub _usage {
        my $reason = shift
          // _croak( 'Usage', 'usage: _usage($REASON, [$msg])' );
        my $usage = shift // '';

        my %reasons = (
            ArgRequired      => undef,
            Help             => undef,
            HelpSummary      => undef,
            HelpTree         => undef,
            OptRequired      => undef,
            OptUnknown       => undef,
            SubCmdRequired   => undef,
            SubCmdUnknown    => undef,
            UnexpectedOptArg => undef,
        );

        _croak( 'Usage', "unknown usage reason: $reason" )
          unless exists $reasons{$reason};

        my $pkg = 'OptArgs2::Usage::' . $reason;

        {
            no strict 'refs';
            *{ $pkg . '::ISA' } = [__PACKAGE__];
        }

        $usage .= "\n\n" if length $usage;
        $usage .= $OptArgs2::CURRENT->usage($reason);

        die bless \$usage, $pkg unless maybe_page($usage) && exit 1;
    }

    # Carp::croak can't deal with blessed references so a straight croak in
    # the rest of the code doesn't do what we want, hence this.
    sub _croak {
        my $type  = shift // _croak( 'Usage', 'usage: _croak($TYPE, [$msg])' );
        my %types = (
            CmdExists          => undef,
            CmdNotFound        => undef,
            Conflict           => undef,
            FallbackNotHashref => undef,
            InvalidIsa         => undef,
            ParentCmdNotFound  => undef,
            SubCmdExists       => undef,
            UndefOptArg        => undef,
            Usage              => undef,
        );

        _croak( 'Usage', "unknown croak type: $type" )
          unless exists $types{$type};

        my $pkg = 'OptArgs2::Error::' . $type;

        {
            no strict 'refs';
            *{ $pkg . '::ISA' } = [__PACKAGE__];
        }

        local @CARP_NOT = (
            qw/
              OptArgs2
              OptArgs2::Arg
              OptArgs2::Cmd
              OptArgs2::Fallback
              OptArgs2::Opt
              OptArgs2::Mo
              OptArgs2::Mo::Object
              /
        );

        my $msg =
          ( shift // $types{$type} // "($pkg)" ) . ' ' . Carp::longmess('');

        die bless \$msg, $pkg;
    }

    sub arg {
        my $name = shift;

        $OptArgs2::CURRENT //= cmd( ( scalar caller ), comment => '' );
        $OptArgs2::CURRENT->add_arg(
            OptArgs2::Arg->new(
                name         => $name,
                show_default => $OptArgs2::CURRENT->show_default,
                @_,
            )
        );
    }

    sub class_optargs {
        my $class = shift
          || _croak( 'Usage', 'class_optargs($CMD,[@argv])' );

        my $cmd = $COMMAND{$class}
          || _croak( 'CmdNotFound', 'command class not found: ' . $class );

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
            $source      = [ grep { ref $_ ne 'HASH' } @$source ];
        }

        map {
            _croak( 'UndefOptArg', '_optargs argument undefined!' )
              if !defined $_
        } @$source;

        Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

        my $error;
        my $optargs = {};
        my @trigger;

        $cmd->run_optargs;

        # Start with the parents options
        my @opts = map { @{ $_->opts } } $cmd->parents, $cmd;
        my @args = @{ $cmd->args };

      OPTARGS: while ( @opts or @args ) {
            while ( my $try = shift @opts ) {
                my $result;
                my $name = $try->name;

                if ( exists $source_hash->{$name} ) {
                    $result = delete $source_hash->{$name};
                }
                else {
                    GetOptionsFromArray( $source, $try->getopt => \$result );
                }

                if ( defined($result) and my $t = $try->trigger ) {
                    push @trigger, [ $t, $name ];
                }

                if ( defined( $result //= $try->default ) ) {

                    if ( 'CODE' eq ref $result ) {
                        tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                          $name,
                          $result;
                    }
                    else {
                        $optargs->{$name} = $result;
                    }
                }
                elsif ( $try->required ) {
                    $name =~ s/_/-/g;
                    $error //= [
                        'OptRequired',
                        qq{error: missing required option "--$name"}
                    ];
                }
            }

            # Sub command check
            if ( @$source and my @subcmds = @{ $cmd->subcmds } ) {
                my $result = $source->[0];
                if ( $cmd->abbrev ) {
                    require Text::Abbrev;
                    my %abbrev =
                      Text::Abbrev::abbrev( map { $_->name } @subcmds );
                    $result = $abbrev{$result} // $result;
                }

                ( my $new_class = $class . '::' . $result ) =~ s/-/_/g;

                if ( exists $COMMAND{$new_class} ) {
                    shift @$source;
                    $class = $new_class;
                    $cmd   = $COMMAND{$new_class};
                    $cmd->run_optargs;
                    push( @opts, @{ $cmd->opts } );

                    # Ignoring any remaining arguments
                    @args = @{ $cmd->args };

                    next OPTARGS;
                }
            }

            while ( my $try = shift @args ) {
                my $result;

                if ( $try->isa eq 'SubCmd' ) {
                    if ( my $new_arg = $try->fallback ) {
                        $try = $new_arg;
                    }
                    elsif ( $try->required ) {
                        $error //= ['SubCmdRequired'];
                        last OPTARGS;
                    }
                    elsif (@$source) {
                        $error //= ['SubCmdUnknown'];
                        last OPTARGS;
                    }
                }

                my $name = $try->name;

                if (@$source) {
                    if (
                        $try->isa ne 'OptArgRef'
                        and (
                            ( $source->[0] =~ m/^--\S/ )
                            or (
                                $source->[0] =~ m/^-\S/
                                and !(
                                    $source->[0] =~ m/^-\d/
                                    and (  $try->isa ne 'Num'
                                        or $try->isa ne 'Int' )
                                )
                            )
                        )
                      )
                    {
                        my $o = shift @$source;
                        $error //=
                          [ 'OptUnknown', qq{error: unknown option "$o"} ];
                    }

                    if ( $try->greedy ) {
                        my @later;
                        if ( @args and @$source > @args ) {
                            push( @later, pop @$source ) for @args;
                        }

                        if (   $try->isa eq 'ArrayRef'
                            or $try->isa eq 'OptArgRef' )
                        {
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
                    elsif ($try->isa eq 'ArrayRef'
                        or $try->isa eq 'OptArgRef' )
                    {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result = { split /=/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }

                    # TODO: type check using Param::Utils?
                }
                elsif ( exists $source_hash->{$name} ) {
                    $result = delete $source_hash->{$name};
                }

                if ( defined( $result //= $try->default ) ) {
                    if ( 'CODE' eq ref $result ) {
                        tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                          $name,
                          $result;
                    }
                    else {
                        $optargs->{$name} = $result;
                    }
                }
                elsif ( $try->required ) {
                    $error //= ['ArgRequired'];
                }
            }
        }

        if (@$source) {
            $error //= [
                'UnexpectedOptArg',
                "error: unexpected option(s) or argument(s): @$source"
            ];
        }
        elsif ( my @unexpected = keys %$source_hash ) {
            $error //= [
                'UnexpectedHashOptArg',
                "error: unexpected HASH option(s) or argument(s): @unexpected"
            ];
        }

        $cmd->_values($optargs);

        local $OptArgs2::CURRENT = $cmd;
        map { $_->[0]->( $cmd, $optargs->{ $_->[1] } ) } @trigger;

        OptArgs2::_usage(@$error) if $error;

        return ( $cmd->class, $optargs );
    }

    sub cmd {
        my $class = shift || _croak('cmd($CLASS,@args)');

        _croak( 'CmdExists', "command already defined: $class" )
          if exists $COMMAND{$class};

        my $cmd = OptArgs2::Cmd->new( class => $class, @_ );
        $OptArgs2::CURRENT = $COMMAND{$class} = $cmd;

        # If this check is not performed we end up adding ourselves
        if ( $class =~ m/:/ ) {
            ( my $parent_class = $class ) =~ s/(.*)::/$1/;
            if ( exists $COMMAND{$parent_class} ) {
                $COMMAND{$parent_class}->add_cmd($cmd);
            }
        }

        return $cmd;
    }

    sub opt {
        my $name = shift;

        $OptArgs2::CURRENT //= cmd( ( scalar caller ), comment => '' );
        $OptArgs2::CURRENT->add_opt(
            OptArgs2::Opt->new_from(
                name         => $name,
                show_default => $OptArgs2::CURRENT->show_default,
                @_,
            )
        );
    }

    sub optargs {
        my ( undef, $opts ) = class_optargs( scalar(caller), @_ );
        return $opts;
    }

    sub subcmd {
        my $class = shift || _croak( 'Usage', 'subcmd($CLASS,%%args)' );

        _croak( 'SubCmdExists', "subcommand already defined: $class" )
          if exists $COMMAND{$class};

        _croak( 'ParentCmdNotFound',
            "no '::' in class '$class' - must have a parent" )
          unless $class =~ m/::/;

        ( my $parent_class = $class ) =~ s/(.*)::.*/$1/;

        _croak( 'ParentCmdNotFound',
            "parent class not found: " . $parent_class )
          unless exists $COMMAND{$parent_class};

        return $COMMAND{$parent_class}->add_cmd(
            $COMMAND{$class} = OptArgs2::Cmd->new(
                class        => $class,
                show_default => $COMMAND{$parent_class}->show_default,
                @_
            )
        );
    }

    sub usage {
        my $class = shift || _croak( 'Usage', 'usage($CLASS,[$style])' );
        my $style = shift;

        _croak( 'CmdNotFound', "command not found: $class" )
          unless exists $COMMAND{$class};

        return $COMMAND{$class}->usage($style);
    }
}

package OptArgs2::CODEREF {

    sub TIESCALAR {
        my $class = shift;
        ( 3 == @_ ) or Optargs2::_croak( 'Usage', 'args: optargs,name,sub' );
        return bless [@_], $class;
    }

    sub FETCH {
        my $self = shift;
        my ( $optargs, $name, $sub ) = @$self;
        untie $optargs->{$name};
        $optargs->{$name} = $sub->($optargs);
    }
}

package OptArgs2::Arg {
    use OptArgs2::Mo;

    has cmd => (
        is       => 'rw',
        weak_ref => 1,
    );

    has comment => (
        is       => 'ro',
        required => 1,
    );

    # Can be re-set by CODEref defaults
    has default => ( is => 'ro', );

    has fallback => ( is => 'rw', );

    has isa => ( required => 1, );

    has isa_name => ( is => 'rw', );

    has getopt => ( is => 'rw', );

    has greedy => ( is => 'ro', );

    has name => (
        is       => 'ro',
        required => 1,
    );

    has required => ( is => 'ro', );

    has show_default => ( is => 'ro', );

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

        OptArgs2::_croak( 'Conflict', q{'default' and 'required' conflict} )
          if $self->required and defined $self->default;

        if ( my $fb = $self->fallback ) {
            OptArgs2::_croak( 'FallbackNotHashref',
                'fallback must be a HASH ref' )
              unless 'HASH' eq ref $fb;

            $self->fallback(
                OptArgs2::Fallback->new(
                    %$fb, required => $self->required,
                )
            );
        }
    }

    sub name_alias_type_comment {
        my $self  = shift;
        my $value = shift;

        my $deftype = '';
        if ( $self->show_default and defined $value ) {
            $deftype = '[' . $value . ']';
        }
        else {
            $deftype = $self->isa_name // $OptArgs2::isa2name{ $self->isa }
              // OptArgs2::_croak( 'InvalidIsa',
                'invalid isa type: ' . $self->isa );
        }

        my $comment = $self->comment;
        if ( $self->required ) {
            $comment .= ' ' if length $comment;
            $comment .= '[required]';
        }

        return $self->name, '', $deftype, $comment;
    }

}

package OptArgs2::Fallback {
    use OptArgs2::Mo;

    extends 'OptArgs2::Arg';

    has hidden => ( is => 'ro', );

}

package OptArgs2::Opt {
    use OptArgs2::Mo;

    has alias => ( is => 'ro', );

    has comment => (
        is       => 'ro',
        required => 1,
    );

    # Can be re-set by CODEref defaults
    has default => ( is => 'ro', );

    has getopt => ( is => 'ro', );

    has required => ( is => 'ro', );

    has hidden => ( is => 'ro', );

    has isa => (
        is       => 'ro',
        required => 1,
    );

    has isa_name => ( is => 'rw', );

    has name => (
        is       => 'ro',
        required => 1,
    );

    has trigger => ( is => 'ro', );

    has show_default => ( is => 'ro', );

    my %isa2getopt = (
        'ArrayRef' => '=s@',
        'Bool'     => '!',
        'Counter'  => '+',
        'Flag'     => '!',
        'HashRef'  => '=s%',
        'Int'      => '=i',
        'Num'      => '=f',
        'Str'      => '=s',
    );

    sub new_from {
        my $proto = shift;
        my $ref   = {@_};
        use feature 'state';

        if ( my $type = delete $ref->{ishelp} ) {
            state $styles = {
                OptArgs2::STYLE_USAGE       => undef,
                OptArgs2::STYLE_HELP        => undef,
                OptArgs2::STYLE_HELPSUMMARY => undef,
                OptArgs2::STYLE_HELPTREE    => undef,
            };
            $type = OptArgs2::STYLE_HELP if $type eq 1;
            OptArgs2::_croak( 'InvalidIshelp',
                'invalid ishelp "%s" for opt "%s"',
                $type, $ref->{name} )
              unless exists $styles->{$type};

            $ref->{isa}     //= 'Flag';
            $ref->{alias}   //= substr $ref->{name}, 0, 1;
            $ref->{comment} //= 'print a full help message and exit';
            $ref->{trigger} //= sub {
                OptArgs2::_usage($type);
            };
        }

        if ( !exists $isa2getopt{ $ref->{isa} } ) {
            return OptArgs2::_croak( 'InvalidIsa',
                'invalid isa "%s" for opt "%s"',
                $ref->{isa}, $ref->{name} );
        }

        $ref->{getopt} = $ref->{name};
        if ( $ref->{name} =~ m/_/ ) {
            ( my $x = $ref->{name} ) =~ s/_/-/g;
            $ref->{getopt} .= '|' . $x;
        }
        $ref->{getopt} .= '|' . $ref->{alias} if $ref->{alias};
        $ref->{getopt} .= $isa2getopt{ $ref->{isa} };

        return $proto->new(%$ref);
    }

    sub name_alias_type_comment {
        my $self  = shift;
        my $value = shift;

        ( my $opt = $self->name ) =~ s/_/-/g;
        if ( $self->isa eq 'Bool' ) {
            if ($value) {
                $opt = 'no-' . $opt;
            }
            elsif ( not defined $value ) {
                $opt = '[no-]' . $opt;
            }
        }
        $opt = '--' . $opt;

        my $alias = $self->alias // '';
        if ( length $alias ) {
            $opt .= ',';
            $alias = '-' . $alias;
        }

        my $deftype = '';
        if ( defined $value and $self->show_default ) {
            if ( $self->isa eq 'Flag' ) {
                $deftype = '(set)';
            }
            elsif ( $self->isa eq 'Bool' ) {
                $deftype = '(' . ( $value ? 'true' : 'false' ) . ')';
            }
            elsif ( $self->isa eq 'Counter' ) {
                $deftype = '(' . $value . ')';
            }
            else {
                $deftype = '[' . $value . ']';
            }
        }
        else {
            $deftype = $self->isa_name // $OptArgs2::isa2name{ $self->isa }
              // OptArgs2::_croak( 'InvalidIsa',
                'invalid isa type: ' . $self->isa );
        }

        my $comment = $self->comment;
        if ( $self->required ) {
            $comment .= ' ' if length $comment;
            $comment .= '[required]';
        }

        return $opt, $alias, $deftype, $comment;
    }

}

package OptArgs2::Cmd {
    use overload
      bool     => sub { 1 },
      '""'     => sub { shift->class },
      fallback => 1;
    use List::Util qw/max/;
    use OptArgs2::Mo;
    use Scalar::Util qw/weaken/;

    has abbrev => ( is => 'rw', );

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

    has name => (
        is      => 'rw',
        default => sub {
            my $x = $_[0]->class;
            if ( $x eq 'main' ) {
                require File::Basename;
                File::Basename::basename($0),;
            }
            else {
                $x =~ s/.*://;
                $x =~ s/_/-/g;
                $x;
            }
        },
    );

    has optargs => ( is => 'rw', );

    has opts => (
        is      => 'ro',
        default => sub { [] },
    );

    has parent => (
        is       => 'rw',
        weak_ref => 1,
    );

    has show_default => (
        is      => 'ro',
        default => 0,
    );

    has subcmds => (
        is      => 'ro',
        default => sub { [] },
    );

    has _values => ( is => 'rw' );

    sub add_arg {
        my $self = shift;
        my $arg  = shift;

        push( @{ $self->args }, $arg );
        $arg->cmd($self);

        # A hack until Mo gets weaken support
        weaken $arg->{cmd};
        return $arg;
    }

    sub add_cmd {
        my $self   = shift;
        my $subcmd = shift;

        push( @{ $self->subcmds }, $subcmd );
        $subcmd->parent($self);
        $subcmd->abbrev( $self->abbrev );

        # A hack until Mo gets weaken support
        weaken $subcmd->{parent};
        return $subcmd;
    }

    sub add_opt {
        push( @{ $_[0]->opts }, $_[1] );
        $_[1];
    }

    sub parents {
        my $self = shift;
        return unless $self->parent;
        return ( $self->parent->parents, $self->parent );
    }

    sub run_optargs {
        my $self = shift;
        map { $_->run_optargs } $self->parents;
        return unless ref $self->optargs eq 'CODE';
        local $OptArgs2::CURRENT = $self;
        $self->optargs->();
        $self->optargs(undef);
    }

    sub _usage_tree {
        my $self  = shift;
        my $depth = shift || 0;

        return [
            $depth, $self->usage(OptArgs2::STYLE_HELPSUMMARY),
            $self->comment
          ],
          map { $_->_usage_tree( $depth + 1 ) }
          sort { $a->name cmp $b->name } @{ $self->subcmds };
    }

    sub usage {
        my $self  = shift;
        my $style = shift || OptArgs2::STYLE_USAGE;
        my $usage = '';

        if ( $style eq OptArgs2::STYLE_HELPTREE ) {
            my ( @w1, @w2 );
            my @items = map {
                $_->[0] = ' ' x ( $_->[0] * 3 );
                push @w1, length( $_->[1] ) + length( $_->[0] );
                push @w2, length $_->[2];
                $_
            } $self->_usage_tree;
            my ( $w1, $w2 ) = ( max(@w1), max(@w2) );
            my $paged  = OptArgs2::rows() < scalar @items;
            my $cols   = OptArgs2::cols();
            my $usage  = '';
            my $spacew = 3;
            my $space  = ' ' x $spacew;
            foreach my $i ( 0 .. $#items ) {
                my $overlap = $w1 + $spacew + $w2[$i] - $cols;
                if ( $overlap > 0 and not $paged ) {
                    $items[$i]->[2] =
                      sprintf '%-.' . ( $w2[$i] - $overlap - 3 ) . 's%s',
                      $items[$i]->[2], '.' x 3;
                }
                $usage .= sprintf "%-${w1}s${space}%-s\n",
                  $items[$i]->[0] . $items[$i]->[1],
                  $items[$i]->[2];
            }
            @OptArgs2::HelpTree::ISA = ('OptArgs2');
            return bless \$usage, 'OptArgs2::HelpTree';
        }

        $self->run_optargs;

        my @parents = $self->parents;
        my @args    = @{ $self->args };
        my @opts =
          sort { $a->name cmp $b->name } map { @{ $_->opts } } @parents,
          $self;

        my $optargs = $self->_values;

        # Summary line
        $usage .= join( ' ', map { $_->name } @parents ) . ' '
          if @parents and $style ne OptArgs2::STYLE_HELPSUMMARY;
        $usage .= $self->name;

        foreach my $arg (@args) {
            $usage .= ' ';
            $usage .= '[' unless $arg->required;
            $usage .= uc $arg->name;
            $usage .= '...' if $arg->greedy;
            $usage .= ']' unless $arg->required;
        }

        if ( $style eq OptArgs2::STYLE_HELPSUMMARY ) {
            return $usage if __PACKAGE__ eq caller;
            no strict 'refs';
            @OptArgs2::HelpSummary::ISA = ('OptArgs2');
            return bless \$usage, 'OptArgs2::HelpSummary';
        }

        $usage .= ' [OPTIONS...]' if @opts;
        $usage .= "\n";

        # Synopsis
        $usage .= "\n  Synopsis:\n    " . $self->comment . "\n"
          if $style eq OptArgs2::STYLE_HELP and length $self->comment;

        # Build arguments
        my @sargs;
        my @uargs;
        my $have_subcmd;

        if (@args) {
            my $i = 0;
            foreach my $arg (@args) {
                if ( $arg->isa eq 'SubCmd' ) {
                    my ( $n, undef, undef, $c ) =
                      $arg->name_alias_type_comment( $optargs->{ $arg->name }
                          // undef );
                    push( @sargs, [ '  ' . ucfirst($n) . ':', $c ] );
                    my @sorted_subs =
                      map  { $_->[1] }
                      sort { $a->[0] cmp $b->[0] }
                      map  { [ $_->name, $_ ] }
                      grep { $style eq OptArgs2::STYLE_HELP or !$_->hidden }
                      @{ $arg->cmd->subcmds },
                      $arg->fallback ? $arg->fallback : ();

                    foreach my $subcmd (@sorted_subs) {
                        push(
                            @sargs,
                            [
                                '    '
                                  . (
                                    ref $subcmd eq 'OptArgs2::Fallback'
                                    ? uc( $subcmd->name )
                                    : $subcmd->usage(
                                        OptArgs2::STYLE_HELPSUMMARY)
                                  ),
                                $subcmd->comment
                            ]
                        );
                    }

                    $have_subcmd++;
                }
                elsif ( 'OptArgRef' ne $arg->isa ) {
                    push( @uargs, [ '  Arguments:', '', '', '' ] ) if !$i;
                    my ( $n, $a, $t, $c ) =
                      $arg->name_alias_type_comment( $optargs->{ $arg->name }
                          // undef );
                    push( @uargs, [ '    ' . uc($n), $a, $t, $c ] );
                }
                $i++;
            }
        }

        # Build options
        my @uopts;
        if (@opts) {
            push( @uopts, [ "  Options:", '', '', '' ] );
            foreach my $opt (@opts) {
                next if $style ne OptArgs2::STYLE_HELP and $opt->hidden;
                my ( $n, $a, $t, $c ) =
                  $opt->name_alias_type_comment( $optargs->{ $opt->name }
                      // undef );
                push( @uopts, [ '    ' . $n, $a, $t, $c ] );
            }
        }

        # Width calculation for args and opts combined
        my $w1 = max( 0,               map { length $_->[0] } @uargs, @uopts );
        my $w2 = max( 0,               map { length $_->[1] } @uargs, @uopts );
        my $w3 = max( 0,               map { length $_->[2] } @uargs, @uopts );
        my $w4 = max( 0,               map { length $_->[0] } @sargs );
        my $w5 = max( $w1 + $w2 + $w3, $w4 );

        my $format1 = "%-${w5}s  %s\n";
        my $format2 = "%-${w1}s %-${w2}s %-${w3}s";

        # Output Arguments
        if (@sargs) {
            $usage .= "\n";
            foreach my $row (@sargs) {
                $usage .= sprintf( $format1, @$row );
            }
        }

        if (@uargs) {
            $usage .= "\n";
            foreach my $row (@uargs) {
                my $l = pop @$row;
                $usage .= sprintf( $format1, sprintf( $format2, @$row ), $l );
            }
        }

        # Output Options
        if (@uopts) {
            $usage .= "\n";
            foreach my $row (@uopts) {
                my $l = pop @$row;
                $usage .= sprintf( $format1, sprintf( $format2, @$row ), $l );
            }
        }

        $usage = 'usage: ' . $usage . "\n";

        if ( $style eq OptArgs2::STYLE_HELP ) {
            no strict 'refs';
            @OptArgs2::Help::ISA = ('OptArgs2');
            return bless \$usage, 'OptArgs2::Help';
        }
        else {
            no strict 'refs';
            @OptArgs2::Usage::ISA = ('OptArgs2');
            return bless \$usage, 'OptArgs2::Usage';
        }
    }

}

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

2.0.0_3 (yyyy-mm-dd)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

    arg item => (
        isa      => 'Str',
        required => 1,
        comment  => 'the item to paint',
    );

    opt help => ( ishelp => 1 );

    opt quiet => (
        isa     => 'Flag',
        alias   => 'q',
        comment => 'output nothing while working',
    );

    my $ref = optargs;

    print "Painting $ref->{item}\n" unless $ref->{quiet};


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

B<OptArgs2> is a re-write of the original L<OptArgs> module with a
cleaner code base and improved API. It should be preferred over
L<OptArgs> for new projects however L<OptArgs> is not likely to
disappear from CPAN anytime soon.  Users converting to B<OptArgs2> from
L<OptArgs> need to be aware of the following:

=over

=item Obvious API changes: cmd(), subcmd()

Commands and subcommands must now be explicitly defined using C<cmd()>
and C<subcmd()>.

=item class_optargs() no longer loads the class

Users must specifically require the class if they want to use it
afterwards:

    my ($class, $opts) = class_optargs('App::demo');
    eval "require $class" or die $@; # new requirement

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now displayed with the "[no-]"
prefix. What this means in practise is that many of your existing Bool
options should likely become Flag options instead.

=back

=head2 Simple Commands

To demonstrate the simple use case (i.e. with no subcommands) lets put
the code from the synopsis in a file called C<paint> and observe the
following interactions from the shell:

    $ ./paint
    usage: paint ITEM [OPTIONS...]

      arguments:
        ITEM          the item to paint [required]

      options:
        --help,  -h   print a usage message and exit
        --quiet, -q   output nothing while working

The C<optargs()> function parses the command line according to the
previous C<opt()> and C<arg()> declarations and returns a single HASH
reference.  If the command is not called correctly then an exception is
thrown containing an automatically generated usage message as shown
above.  Because B<OptArgs2> fully knows the valid arguments and options
it can detect a wide range of errors:

    $ ./paint wall Perl is great
    error: unexpected option or argument: Perl

So let's add that missing argument definition:

    arg message => (
        isa      => 'Str',
        comment  => 'the message to paint on the item',
        greedy   => 1,
    );

And then check the usage again:

    $ ./paint
    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM          the item to paint [required]
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
might make sense here:

    opt colour => (
        isa           => 'Str',
        default       => 'blue',
        comment       => 'the colour to use',
    );

This now produces the following usage output:

    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM               the item to paint
        MESSAGE            the message to paint on the item

      options:
        --colour=STR, -c   the colour to use [blue]
        --quiet,      -q   output nothing while working

The command line is parsed first for arguments, then for options, in
the same order in which they are defined. This probably only of
interest if you are using trigger actions on your options (see
FUNCTIONS below for details).

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
        optargs => sub {
            arg command => (
                isa      => 'SubCmd',
                required => 1,
                comment  => 'command to run',
            );

            opt quiet => (
                isa     => 'Flag',
                alias   => 'q',
                comment => 'run quietly',
            );
        },
    );

    subcmd 'App::demo::foo' => (
        comment => 'demo foo',
        optargs => sub {
            arg action => (
                isa      => 'Str',
                required => 1,
                comment  => 'command to run',
            );
        },
    );

    subcmd 'App::demo::bar' => (
        comment => 'demo bar',
        optargs => sub {
            opt baz => (
                isa => 'Counter',
                comment => '+1',
            );
        },
    );

    # Command hierarchy for the above code:
    # demo COMMAND [OPTIONS...]
    #     demo foo ACTION [OPTIONS...]
    #     demo bar [OPTIONS...]

An argument of type 'SubCmd' is an explicit indication that subcommands
can occur in that position. The command hierarchy is based upon the
natural parent/child structure of the class names.  This definition can
be done in your main script, or in one or more separate packages or
plugins, as you like.

=item Parsing

The C<class_optargs()> function is called instead of C<optargs()> to
parse the C<@ARGV> array and call the appropriate C<arg()> and C<opt()>
definitions as needed. It's first argument is generally the top-level
command name you used in your first C<cmd()> call.

    my ($class, $opts) = class_optargs('App::demo');

    printf "Running %s with %s\n", $class, Dumper($opts)
      unless $opts->{quiet};

The additional return value C<$class> is the name of the actual
(sub-)command to which the C<$opts> HASHref applies. Usage exceptions
are raised just the same as with the C<optargs()> function.

    error: unknown option "--invalid"

    usage: demo COMMAND [OPTIONS...]

        COMMAND       command to run
          bar           demo bar
          foo           demo foo

        --quiet, -q   run quietly

Note that options are inherited by subcommands.

=item Dispatch/Execution

Once you have the subcommand name and the option/argument hashref you
can either execute the action or dispatch to the appropriate
class/package as you like.

There are probably several ways to layout command classes when you have
lots of subcommands. Here is one way that seems to work for this
module's author.

=over

=item lib/App/demo.pm, lib/App/demo/subcmd.pm

I typically put the actual (sub-)command implementations in
F<lib/App/demo.pm> and F<lib/App/demo/subcmd.pm>. App::demo itself only
needs to exists if the root command does something. However I tend to
also make App::demo the base class for all subcommands so it is often a
non-trivial piece of code.

=item lib/App/demo/OptArgs.pm

App::demo::OptArgs is where I put all of my command definitions with
names that match the actual implementation modules.

    package App::demo::OptArgs;
    use OptArgs2;

    cmd 'App::demo' => (
        comment => 'the demo app',
        optargs => sub {
            #...
        },
    )

The reason for keeping this separate from lib/App/demo.pm is speed of
loading. I don't want to have to load all of the modules that App::demo
itself uses just to find out that I called the command incorrectly.

=item bin/demo

The command script itself is then usually fairly short:

    #!/usr/bin/env perl
    use OptArgs2 'class_optargs';
    use App::demo::OptArgs;

    my ($class, $opts) = class_optargs('App::demo');
    eval "require $class" or die $@;
    $class->new->run($opts);

The above does nothing more than load the definitions from
App::demo::OptArgs, obtain the command name and options hashref, and
then loads the appropriate package to run the command.

=back

=back

=head2 Formatting of Usage Messages

Usage messages attempt to present as much information as possible to
the caller. Here is a brief overview of how the various types look
and/or change depending on things like defaults.

The presentation of Bool options in usage messages is as follows:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Bool        undef           --[no-]option
    option      Bool        true            --no-option
    option      Bool        false           --option
    option      Counter     *               --option

The Flag option type is like a Bool that can only be set to true or
left undefined. This makes sense for things such as C<--help> or
C<--version> for which you never need to see a "--no" prefix.

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Flag        always undef    --option

Note that Flags also makes sense for "negative" options which will only
ever turn things off:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    no_option   Flag        always undef    --no-option

    # In Perl
    opt no_foo => (
        isa     => 'Flag',
        comment => 'disable the foo feature',
    );

    # Then later do { } unless $opts->{no_foo}

The remaining types are presented as follows:

    Name        Type        isa_name        Presentation
    ----        ----        --------        ------------
    option      ArrayRef    -               --option Str
    option      HashRef     -               --option Str
    option      Int         -               --option Int
    option      Num         -               --option Num
    option      Str         -               --option Str
    option      *           XX              --option XX

Defaults TO BE COMPLETED.

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item arg( $name, %parameters )

Define a command argument, for example:

    arg name => (
        comment  => 'the file to parse',
        default  => '-',
        greedy   => 0,
        isa      => 'Str',
        # required => 1,
    );

The C<arg()> function accepts the following parameters:

=over

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the argument is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item greedy

If true the argument swallows the rest of the command line.

=item fallback

A hashref containing an argument definition for the event that a
subcommand match is not found. This parameter is only valid when C<isa>
is a C<SubCmd>. The hashref must contain "isa", "name" and "comment"
key/value pairs, and may contain a "greedy" key/value pair.

This is generally useful when you want to calculate a command alias
from a configuration file at runtime, or otherwise run commands which
don't easily fall into the OptArgs2 subcommand model.

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
     'OptArgRef'     's@'

An I<OptArgRef> isa is an I<ArrayRef> that doesn't undergo checks for
unexpected options. It exists to capture options and arguments which
get passed back into I<class_optargs> again.

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item required

Set to a true value when the caller must specify this argument.
Conflicts with the 'default' parameter.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=back

=item class_optargs( $class, [ @argv ] ) -> ($subclass, $opts)

Parse @ARGV by default (or @argv when given) for the arguments and
options defined for command C<$class>.  C<@ARGV> will first be decoded
into UTF-8 (if necessary) from whatever L<I18N::Langinfo> says your
current locale codeset is.

Throws an error / usage exception object (typically C<OptArgs2::Usage>)
for missing or invalid arguments/options. Uses L<OptArgs2::Pager> for
'ishelp' output.

Returns the following two values:

=over

=item $subclass

The actual subcommand name that was matched by parsing the arguments.
This may be the same as C<$class>.

=item $opts

a hashref containing key/value pairs for options and arguments
I<combined>.

=back

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item cmd( $class, %parameters ) -> OptArgs2::Cmd

Define a top-level command identified by C<$class> which is typically a
Perl package name. The following parameters are accepted:

=for comment
=item name
A display name of the command. Optional - if it is not provided then the
last part of the command name is used is usage messages.

=over

=item abbrev

When set to true then subcommands can be abbreviated, up to their
shortest, unique values.

=item comment

A description of the command. Required.

=item optargs

A subref containing calls to C<arg()> and C<opt>. Note that options are
inherited by subcommands so you don't need to define them again in
child subcommands.

=item show_default

Boolean indicating if default values for options and arguments should
be shown in usage messages. Can be overriden by sub-commands, args and
opts. Off by default.

=for comment
By default this subref is only called on demand when the
C<class_optargs()> function sees arguments for that particular
subcommand. However for testing it is useful to know immediately if you
have an error. For this purpose the OPTARGS2_IMMEDIATE environment
variable can be set to trigger it at definition time.

=for comment
=item colour
If $OptArgs::COLOUR is a true value and "STDOUT" is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=for comment
=item sort
If $OptArgs::SORT is a true value then subcommands will be listed in
usage messages alphabetically instead of in the order they were
defined.

=for comment
=item usage
Valid for C<cmd()> only. A subref for generating a custom usage
message. See XXX befow for the structure this subref receives.

=back

=item opt( $name, %parameters )

Define a command option, for example:

    opt colour => (
        alias        => 'c',
        comment      => 'the colour to paint',
        default      => 'blue',
        show_default => 1,
        isa          => 'Str',
    );

Any underscores in C<$name> are be replaced by dashes (-) for
presentation and command-line parsing.  The C<arg()> function accepts
the following parameters:

=over

=item alias

A single character alias.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containing all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item required

Set to a true value when the caller must specify this option. Conflicts
with the 'default' parameter.

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

    isa              Getopt::Long
    ---              ------------
     'ArrayRef'      's@'
     'Flag'          '!'
     'Bool'          '!'
     'Counter'       '+'
     'HashRef'       's%'
     'Int'           '=i'
     'Num'           '=f'
     'Str'           '=s'

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item ishelp

Makes the option behave like a typical C<--help>, that displays a usage
message and exits before errors are generated.  Typically used alone as
follows:

    opt help => (
        ishelp => OptArgs2::STYLE_HELP,
    );

    opt help_tree => (
        ishelp => OptArgs2::STYLE_HELPTREE,
        alias  => 'T', # or 'undef' if you don't want an alias
    );

The first option above is similar to this longhand version:

    opt help => (
        isa     => 'Flag',
        alias   => 'h',   # first character of the opt name
        comment => 'print a usage message and exit',
        trigger => sub {
            # Start a pager for long messages
            print OptArgs2::usage(undef, OptArgs2::STYLE_HELP);
            # Stop the pager
            exit;
        }
    );

You can override any of the above with your own parameters.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=item trigger

The trigger parameter lets you define a subroutine that is called after
processing before usage exceptions are raised.  This is primarily to
support --help or --version options which would typically override
usage errors.

    opt version => (
        isa     => 'Flag',
        alias   => 'V',
        comment => 'print version string and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die "$cmd version $VERSION\n";
        }
    );

The trigger subref is passed two parameters: a OptArgs2::Cmd object and
the value (if any) of the option. The OptArgs2::Cmd object is an
internal one, but one public interface is has (in addition to the
usage() method described in 'ishelp' above) is the usage_tree() method
which gives a usage overview of all subcommands in the command
hierarchy.

    opt usage_tree => (
        isa     => 'Flag',
        alias   => 'U',
        comment => 'print usage tree and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die $cmd->usage_tree;
        }
    );

    # demo COMMAND [OPTIONS...]
    #     demo foo ACTION [OPTIONS...]
    #     demo bar [OPTIONS...]

=back

=item optargs( [@argv] ) -> HASHref

Parse @ARGV by default (or @argv when given) for the arguments and
options defined for the I<default global> command. Argument decoding
and exceptions are the same as for C<class_optargs>, but this function
returns only the combined argument/option values HASHref.

=item subcmd( $class, %parameters ) -> OptArgs2::Cmd

Defines a subcommand identified by C<$class> which must include the
name of a previously defined (sub)command + '::'.

Accepts the same parameters as C<cmd()> in addition to the following:

=over

=item hidden

Hide the existence of this subcommand in non-help usage messages.  This
is handy if you have developer-only or rarely-used commands that you
don't want cluttering up your normal usage message.

=back

=item usage( $class, [STYLE] ) -> Str

Only exported on request, this function returns the usage string for
the command C<$class>.

=back

=head1 SEE ALSO

L<OptArgs2::Pager>, L<OptArgs2::StatusLine>, L<Getopt::Long>

This module is duplicated on CPAN as L<Getopt::Args2>, to cover both
its original name and yet still be found in the mess that is Getopt::*.

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

Copyright 2016-2022 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


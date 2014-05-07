package OptArgs;
use strict;
use warnings;
use Carp qw/croak carp/;
use Encode qw/decode/;
use Exporter::Tidy
  default => [qw/opt arg optargs usage subcmd/],
  other   => [qw/dispatch/];
use Getopt::Long qw/GetOptionsFromArray/;
use List::Util qw/max/;

our $VERSION = '0.1.10';
our $COLOUR  = 0;
our $ABBREV  = 0;
our $SORT    = 0;

my %seen;           # hash of hashes keyed by 'caller', then opt/arg name
my %opts;           # option configuration keyed by 'caller'
my %args;           # argument configuration keyed by 'caller'
my %caller;         # current 'caller' keyed by real caller
my %desc;           # sub-command descriptions
my %dispatching;    # track optargs() calls from dispatch classes
my %hidden;         # subcmd hiding by default

# internal method for App::optargs
sub _cmdlist {
    my $package = shift || croak '_cmdlist($package)';
    $package =~ s/-/_/g;
    my @list = ($package);

    if ( exists $args{$package} ) {
        my @subcmd =
          map { exists $_->{subcommands} ? $_->{subcommands} : () }
          @{ $args{$package} };

        push( @subcmd,
            map { exists $_->{fallback} ? [ uc $_->{fallback}->{name} ] : () }
              @{ $args{$package} } );

        if ($SORT) {
            foreach my $subcmd ( sort map { @$_ } @subcmd ) {
                push( @list, _cmdlist( $package . '::' . $subcmd ) );
            }
        }
        else {
            foreach my $subcmd ( map { @$_ } @subcmd ) {
                push( @list, _cmdlist( $package . '::' . $subcmd ) );
            }
        }
    }
    return @list;
}

# ------------------------------------------------------------------------
# Sub-command definition
#
# This works by faking caller context in opt() and arg()
# ------------------------------------------------------------------------
my %subcmd_params = (
    cmd     => undef,
    comment => undef,
    hidden  => undef,

    #    alias   => '',
    #    ishelp  => undef,
);

my @subcmd_required = (qw/cmd comment/);

sub subcmd {
    my $params = {@_};
    my $caller = caller;

    if ( my @missing = grep { !exists $params->{$_} } @subcmd_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $subcmd_params{$_} } keys %$params ) {
        my @valid = keys %subcmd_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    #    croak "'ishelp' can only be applied to Bool opts"
    #      if $params->{ishelp} and $params->{isa} ne 'Bool';

    my @cmd =
      ref $params->{cmd} eq 'ARRAY'
      ? @{ $params->{cmd} }
      : ( $params->{cmd} );
    croak 'missing cmd elements' unless @cmd;

    my $name = pop @cmd;
    my $parent = join( '::', $caller, @cmd );
    $parent =~ s/-/_/g;

    croak "parent command not found: @cmd" unless $seen{$parent};

    my $package = $parent . '::' . $name;
    $package =~ s/-/_/g;

    croak "sub command already defined: @cmd $name" if $seen{$package};

    $caller{$caller}  = $package;
    $desc{$package}   = $params->{comment};
    $seen{$package}   = {};
    $opts{$package}   = [];
    $args{$package}   = [];
    $hidden{$package} = $params->{hidden};

    my $parent_arg = ( grep { $_->{isa} eq 'SubCmd' } @{ $args{$parent} } )[0];
    push( @{ $parent_arg->{subcommands} }, $name );

    return;
}

# ------------------------------------------------------------------------
# Option definition
# ------------------------------------------------------------------------
my %opt_params = (
    isa     => undef,
    comment => undef,
    default => undef,
    alias   => '',
    ishelp  => undef,
    hidden  => undef,
);

my @opt_required = (qw/isa comment/);

my %opt_isa = (
    'Bool'     => '!',
    'Counter'  => '+',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

sub opt {
    my $name    = shift;
    my $params  = {@_};
    my $caller  = caller;
    my $package = $caller{$caller} || $caller;

    croak 'usage: opt $name => (%parameters)' unless $name;
    croak "'$name' already defined" if $seen{$package}->{$name};

    if ( my @missing = grep { !exists $params->{$_} } @opt_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $opt_params{$_} } keys %$params ) {
        my @valid = keys %opt_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    croak "'ishelp' can only be applied to Bool opts"
      if $params->{ishelp} and $params->{isa} ne 'Bool';

    croak "unknown type: $params->{isa}"
      unless exists $opt_isa{ $params->{isa} };

    $params = { %opt_params, %$params };
    $params->{package} = $package;
    $params->{name}    = $name;
    $params->{length}  = length $name;
    $params->{acount}  = do { my @tmp = split( '|', $params->{alias} ) };
    $params->{type}    = 'opt';
    $params->{ISA}     = $params->{name};

    if ( ( my $dashed = $params->{name} ) =~ s/_/-/g ) {
        $params->{dashed} = $dashed;
        $params->{ISA} .= '|' . $dashed;
    }

    $params->{ISA} .= '|' . $params->{alias} if $params->{alias};
    $params->{ISA} .= $opt_isa{ $params->{isa} };

    push( @{ $opts{$package} }, $params );
    $args{$package} ||= [];
    $seen{$package}->{$name}++;

    return;
}

# ------------------------------------------------------------------------
# Argument definition
# ------------------------------------------------------------------------
my %arg_params = (
    isa      => undef,
    comment  => undef,
    required => undef,
    default  => undef,
    greedy   => undef,
    fallback => undef,
);

my @arg_required = (qw/isa comment/);

my %arg_isa = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

sub arg {
    my $name    = shift;
    my $params  = {@_};
    my $caller  = caller;
    my $package = $caller{$caller} || $caller;

    croak 'usage: arg $name => (%parameters)' unless $name;
    croak "'$name' already defined" if $seen{$package}->{$name};

    if ( my @missing = grep { !exists $params->{$_} } @arg_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $arg_params{$_} } keys %$params ) {
        my @valid = keys %arg_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    croak "unknown type: $params->{isa}"
      unless exists $arg_isa{ $params->{isa} };

    croak "'default' and 'required' cannot be used together"
      if defined $params->{default} and defined $params->{required};

    croak "'fallback' only valid with isa 'SubCmd'"
      if $params->{fallback} and $params->{isa} ne 'SubCmd';

    croak "fallback must be a hashref"
      if defined $params->{fallback} && ref $params->{fallback} ne 'HASH';

    $params->{package} = $package;
    $params->{name}    = $name;
    $params->{length}  = length $name;
    $params->{acount}  = 0;
    $params->{type}    = 'arg';
    $params->{ISA}     = $params->{name} . $arg_isa{ $params->{isa} };

    push( @{ $args{$package} }, $params );
    $opts{$package} ||= [];
    $seen{$package}->{$name}++;

    if ( $params->{fallback} ) {
        my $p = $package . '::' . uc $params->{fallback}->{name};
        $p =~ s/-/_/g;
        $opts{$p} = [];
        $args{$p} = [];
        $desc{$p} = $params->{fallback}->{comment};
    }

    return;
}

# ------------------------------------------------------------------------
# Usage message generation
# ------------------------------------------------------------------------

sub _usage {
    my $caller   = shift;
    my $error    = shift;
    my $ishelp   = shift;
    my $terminal = -t STDOUT;
    my $red      = ( $COLOUR && $terminal ) ? "\e[0;31m" : '';
    my $yellow = '';    #( $COLOUR && $terminal ) ? "\e[0;33m" : '';
    my $grey   = '';    #( $COLOUR && $terminal ) ? "\e[1;30m" : '';
    my $reset  = ( $COLOUR && $terminal ) ? "\e[0m" : '';
    my $parent = $caller;
    my @args   = @{ $args{$caller} };
    my @opts   = @{ $opts{$caller} };
    my @parents;
    my @usage;
    my @uargs;
    my @uopts;
    my $usage;

    require File::Basename;
    my $me = File::Basename::basename( defined &static::list ? $^X : $0 );

    if ($error) {
        $usage .= "${red}error:$reset $error\n\n";
    }

    $usage .= $yellow . ( $ishelp ? 'help:' : 'usage:' ) . $reset . ' ' . $me;

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        ( my $name = $2 ) =~ s/_/-/g;
        unshift( @parents, $name );
        unshift( @opts,    @{ $opts{$parent} } );
    }

    $usage .= ' ' . join( ' ', @parents ) if @parents;

    my $last = $args[$#args];

    if ($last) {
        foreach my $def (@args) {
            $usage .= ' ';
            $usage .= '[' unless $def->{required};
            $usage .= uc $def->{name};
            $usage .= '...' if $def->{greedy};
            $usage .= ']' unless $def->{required};
            push( @uargs, [ uc $def->{name}, $def->{comment} ] );
        }
    }

    $usage .= ' [OPTIONS...]' if @opts;

    $usage .= "\n";

    $usage .= "\n  ${grey}Synopsis:$reset\n    $desc{$caller}\n"
      if $ishelp and $desc{$caller};

    if ( $ishelp and my $version = $caller->VERSION ) {
        $usage .= "\n  ${grey}Version:$reset\n    $version\n";
    }

    if ( $last && $last->{isa} eq 'SubCmd' ) {
        $usage .= "\n  ${grey}" . ucfirst( $last->{name} ) . ":$reset\n";

        my @subcommands = @{ $last->{subcommands} };

        push( @subcommands, uc $last->{fallback}->{name} )
          if (
            exists $last->{fallback}
            && ( $ishelp
                or !$last->{fallback}->{hidden} )
          );

        @subcommands = sort @subcommands if $SORT;

        foreach my $subcommand (@subcommands) {
            my $pkg = $last->{package} . '::' . $subcommand;
            $pkg =~ s/-/_/g;
            next if $hidden{$pkg} and !$ishelp;
            push( @usage, [ $subcommand, $desc{$pkg} ] );
        }

    }

    @opts = sort { $a->{name} cmp $b->{name} } @opts if $SORT;

    foreach my $opt (@opts) {
        next if $opt->{hidden} and !$ishelp;

        ( my $name = $opt->{name} ) =~ s/_/-/g;
        $name .= ',' if $opt->{alias};
        push(
            @uopts,
            [
                '--' . $name,
                $opt->{alias}
                ? '-' . $opt->{alias}
                : '',
                $opt->{comment}
            ]
        );
    }

    if (@uopts) {
        my $w1 = max( map { length $_->[0] } @uopts );
        my $fmt = '%-' . $w1 . "s %s";

        @uopts = map { [ sprintf( $fmt, $_->[0], $_->[1] ), $_->[2] ] } @uopts;
    }

    my $w1 = max( map { length $_->[0] } @usage, @uargs, @uopts );
    my $format = '    %-' . $w1 . "s   %s\n";

    if (@usage) {
        foreach my $row (@usage) {
            $usage .= sprintf( $format, @$row );
        }
    }
    if ( @uargs and $last->{isa} ne 'SubCmd' ) {
        $usage .= "\n  ${grey}Arguments:$reset\n";
        foreach my $row (@uargs) {
            $usage .= sprintf( $format, @$row );
        }
    }
    if (@uopts) {
        $usage .= "\n  ${grey}Options:$reset\n";
        foreach my $row (@uopts) {
            $usage .= sprintf( $format, @$row );
        }
    }

    $usage .= "\n";
    return bless( \$usage, 'OptArgs::Usage' );
}

sub _synopsis {
    my $caller = shift;
    my $parent = $caller;
    my @args   = @{ $args{$caller} };
    my @parents;

    require File::Basename;
    my $usage = File::Basename::basename($0);

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        ( my $name = $2 ) =~ s/_/-/g;
        unshift( @parents, $name );
    }

    $usage .= ' ' . join( ' ', @parents ) if @parents;

    if ( my $last = $args[$#args] ) {
        foreach my $def (@args) {
            $usage .= ' ';
            $usage .= '[' unless $def->{required};
            $usage .= uc $def->{name};
            $usage .= '...' if $def->{greedy};
            $usage .= ']' unless $def->{required};
        }
    }

    return 'usage: ' . $usage . "\n";
}

sub usage {
    my $caller = caller;
    return _usage( $caller, @_ );
}

# ------------------------------------------------------------------------
# Option/Argument processing
# ------------------------------------------------------------------------
sub _optargs {
    my $caller  = shift;
    my $source  = \@_;
    my $package = $caller;

    if ( !@_ and @ARGV ) {
        my $CODESET =
          eval { require I18N::Langinfo; I18N::Langinfo::CODESET() };

        if ($CODESET) {
            my $codeset = I18N::Langinfo::langinfo($CODESET);
            $_ = decode( $codeset, $_ ) for @ARGV;
        }

        $source = \@ARGV;
    }

    croak "no option or argument defined for $caller"
      unless exists $opts{$package}
      or exists $args{$package};

    Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

    my @config = ( @{ $opts{$package} }, @{ $args{$package} } );

    my $ishelp;
    my $missing_required;
    my $optargs = {};
    my @coderef_default_keys;

    while ( my $try = shift @config ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {
            GetOptionsFromArray( $source, $try->{ISA} => \$result );
        }
        elsif ( $try->{type} eq 'arg' ) {
            if (@$source) {
                die _usage( $package, qq{Unknown option "$source->[0]"} )
                  if $source->[0] =~ m/^--\S/;

                die _usage( $package, qq{Unknown option "$source->[0]"} )
                  if $source->[0] =~ m/^-\S/
                  and !(
                    $source->[0] =~ m/^-\d/ and ( $try->{isa} ne 'Num'
                        or $try->{isa} ne 'Int' )
                  );

                if ( $try->{greedy} ) {
                    my @later;
                    if ( @config and @$source > @config ) {
                        push( @later, pop @$source ) for @config;
                    }

                    if ( $try->{isa} eq 'ArrayRef' ) {
                        $result = [@$source];
                    }
                    elsif ( $try->{isa} eq 'HashRef' ) {
                        $result = { map { split /=/, $_ } @$source };
                    }
                    else {
                        $result = "@$source";
                    }

                    shift @$source while @$source;
                    push( @$source, @later );
                }
                else {
                    if ( $try->{isa} eq 'ArrayRef' ) {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->{isa} eq 'HashRef' ) {
                        $result = { split /=/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }
                }

                # TODO: type check using Param::Utils?
            }
            elsif ( $try->{required} and !$ishelp ) {
                $missing_required++;
                next;
            }

            if ( $try->{isa} eq 'SubCmd' and $result ) {

                # look up abbreviated words
                if ($ABBREV) {
                    require Text::Abbrev;
                    my %words =
                      map { m/^$package\:\:(\w+)$/; $1 => 1 }
                      grep { m/^$package\:\:(\w+)$/ }
                      keys %seen;
                    my %abbrev = Text::Abbrev::abbrev( keys %words );
                    $result = $abbrev{$result} if defined $abbrev{$result};
                }

                my $newpackage = $package . '::' . $result;
                $newpackage =~ s/-/_/g;

                if ( exists $seen{$newpackage} ) {
                    $package = $newpackage;
                    push( @config, @{ $opts{$package} }, @{ $args{$package} } );
                }
                elsif ( !$ishelp ) {
                    if ( $try->{fallback} ) {
                        unshift @$source, $result;
                        $try->{fallback}->{type} = 'arg';
                        push( @config, $try->{fallback} );
                        next;
                    }
                    else {
                        die _usage( $package,
                            "Unknown " . uc( $try->{name} ) . qq{ "$result"} );
                    }
                }

                $result = undef;
            }

        }

        if ( defined $result ) {
            $optargs->{ $try->{name} } = $result;
        }
        elsif ( defined $try->{default} ) {
            push( @coderef_default_keys, $try->{name} )
              if ref $try->{default} eq 'CODE';
            $optargs->{ $try->{name} } = $result = $try->{default};
        }

        $ishelp = 1 if $result and $try->{ishelp};

    }

    if ($ishelp) {
        die _usage( $package, undef, 1 );
    }
    elsif ($missing_required) {
        die _usage($package);
    }
    elsif (@$source) {
        die _usage( $package,
            qq{Unexpected option or argument "} . ( shift @$source ) . '"' );
    }

    # Re-calculate the default if it was a subref
    foreach my $key (@coderef_default_keys) {
        $optargs->{$key} = $optargs->{$key}->( {%$optargs} );
    }

    return ( $package, $optargs );
}

sub optargs {
    my $caller = caller;

    carp "optargs() called from dispatch handler"
      if $dispatching{$caller};

    my ( $package, $optargs ) = _optargs( $caller, @_ );
    return $optargs;
}

sub dispatch {
    my $method = shift;
    my $class  = shift;

    croak 'dispatch($method, $class, [@argv])' unless $method and $class;
    croak $@ unless eval "require $class;1;";

    my ( $package, $optargs );

    if (@_) {
        my @args;

        foreach my $element (@_) {
            if ( ref $element eq 'HASH' ) {
                push( @args,
                    '--' . $_, defined $element->{$_} ? $element->{$_} : () )
                  for keys %$element;
            }
            else {
                push( @args, $element );
            }
        }

        ( $package, $optargs ) = _optargs( $class, @args );
    }
    else {
        ( $package, $optargs ) = _optargs($class);
    }

    my $sub = $package->can($method);
    if ( !$sub ) {
        croak $@ unless eval "require $package;";
        $sub = $package->can($method);
    }

    die "Can't find method $method via package $package" unless $sub;

    $dispatching{$class}++;
    my @results = $sub->($optargs);
    $dispatching{$class}--;
    return @results if wantarray;
    return $results[0];
}

package OptArgs::Usage;
use overload
  bool     => sub { 1 },
  '""'     => sub { ${ $_[0] } },
  fallback => 1;

1;

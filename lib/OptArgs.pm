package OptArgs;
use strict;
use warnings;
use Carp qw/croak carp/;
use Encode qw/decode decode_utf8/;
use Exporter::Tidy
  default => [qw/opt arg optargs usage subcmd/],
  other   => [qw/dispatch/];
use Getopt::Long qw/GetOptionsFromArray/;
use I18N::Langinfo qw/langinfo/;
use List::Util qw/max/;

our $VERSION = '0.0.2';
our $COLOUR  = 0;

my %seen;           # hash of hashes keyed by 'caller', then opt/arg name
my %opts;           # option configuration keyed by 'caller'
my %args;           # argument configuration keyed by 'caller'
my %caller;         # current 'caller' keyed by real caller
my %desc;           # sub-command descriptions
my %dispatching;    # track optargs() calls from dispatch classes

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

        foreach my $subcmd ( map { @$_ } @subcmd ) {
            push( @list, _cmdlist( $package . '::' . $subcmd ) );
        }
    }
    return @list;
}

# ------------------------------------------------------------------------
# Sub-commands work by faking caller context in opt() and arg()
# ------------------------------------------------------------------------
sub subcmd {
    my $caller = caller;
    croak 'subcmd(@cmd,$description)' unless @_ >= 2;

    my $desc = pop;
    my $name = pop;

    my $parent = join( '::', $caller, @_ );
    $parent =~ s/-/_/g;

    croak "parent command not found: @_" unless $seen{$parent};

    my $package = $parent . '::' . $name;
    $package =~ s/-/_/g;

    croak "sub command already defined: @_ $name" if $seen{$package};

    $caller{$caller} = $package;
    $desc{$package}  = $desc;
    $seen{$package}  = {};
    $opts{$package}  = [];
    $args{$package}  = [];

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
    $params->{acount}  = scalar split( '|', $params->{alias} );
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
        $p =~ s/-/_/;
        $opts{$p} = [];
        $args{$p} = [];
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
    my $yellow   = ( $COLOUR && $terminal ) ? "\e[0;33m" : '';
    my $grey     = ( $COLOUR && $terminal ) ? "\e[1;30m" : '';
    my $reset    = ( $COLOUR && $terminal ) ? "\e[0m" : '';
    my $parent   = $caller;
    my @args     = @{ $args{$caller} };
    my @opts     = @{ $opts{$caller} };
    my @parents;
    my @usage;
    my @uargs;
    my @uopts;
    my $usage;

    require File::Basename;
    my $me = File::Basename::basename($0);

    $usage .= $yellow . 'usage:' . $reset;

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        ( my $name = $2 ) =~ s/_/-/g;
        unshift( @parents, $name );
        unshift( @opts,    @{ $opts{$parent} } );
    }

    $me .= ' ' . join( ' ', @parents ) if @parents;

    if ( my $last = $args[$#args] ) {
        if ( $last->{isa} eq 'SubCmd' ) {
            foreach my $subcommand ( @{ $last->{subcommands} } ) {
                my $pkg = $last->{package} . '::' . $subcommand;
                $pkg =~ s/-/_/g;
                push( @usage, [ $me . ' ' . $subcommand, $desc{$pkg} ] );
            }

            if ( $last->{fallback} ) {
                push(
                    @usage,
                    [
                        $me . ' ' . uc $last->{fallback}->{name},
                        $last->{fallback}->{comment}
                    ]
                );
            }
            $usage .= "\n";
        }
        else {
            $usage .= ' ' . $me;
            foreach my $def (@args) {
                $usage .= ' ';
                $usage .= '[' unless $def->{required};
                $usage .= uc $def->{name};
                $usage .= '...' if $def->{greedy};
                $usage .= ']' unless $def->{required};
                push( @uargs, [ uc $def->{name}, $def->{comment} ] );
            }
            $usage .= "\n";
        }
    }
    else {
        $usage .= ' ' . $me . "\n";
    }

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
    if (@uargs) {
        $usage .= "\n  ${grey}arguments:$reset\n";
        foreach my $row (@uargs) {
            $usage .= sprintf( $format, @$row );
        }
    }
    if (@uopts) {
        $usage .= "\n  ${grey}options:$reset\n";
        foreach my $row (@uopts) {
            $usage .= sprintf( $format, @$row );
        }
    }

    if ($error) {
        my $tmp = $red . "error:" . $reset;
        $tmp .= "\n   " if @usage;
        return $tmp . ' ' . $error . "\n\n" . $usage . "\n";
    }
    elsif ($ishelp) {
        return "[help requested]\n\n" . $usage . "\n";
    }

    return $usage . "\n";
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
        my $CODESET = eval { I18N::Langinfo::CODESET() };

        if ($CODESET) {
            my $codeset = langinfo($CODESET);
            $_ = decode( $codeset, $_ ) for @ARGV;
        }
        else {
            $_ = decode( 'UTF-8', $_ ) for @ARGV;
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

    while ( my $try = shift @config ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {
            GetOptionsFromArray( $source, $try->{ISA} => \$result );
        }
        elsif ( $try->{type} eq 'arg' ) {
            if (@$source) {
                die _usage( $package, "unknown option: " . $source->[0] )
                  if ( $source->[0] =~ m/^(-\S)|(--\S+)$/ );

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
                my $newpackage = $package . '::' . $result;
                $newpackage =~ s/-/_/;

                if ( exists $seen{$newpackage} ) {
                    $package = $newpackage;
                    push( @config, @{ $opts{$package} }, @{ $args{$package} } );
                }
                elsif ( !$try->{fallback} and !$ishelp ) {
                    die _usage( $package,
                        "invalid " . $try->{name} . ': ' . $result );
                }
            }

        }

        if ( defined $result ) {
            $optargs->{ $try->{name} } = $result;
        }
        elsif ( defined $try->{default} ) {
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
            "unexpected option or argument: " . shift @$source );
    }

    # Re-calculate the default if it was a subref
    while ( my ( $key, $val ) = each %$optargs ) {
        $optargs->{$key} = $val->( {%$optargs} ) if ref $val eq 'CODE';
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

    my ( $package, $optargs ) = _optargs( $class, @_ );

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

1;

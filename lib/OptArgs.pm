package OptArgs;
use strict;
use warnings;
use Carp qw/croak carp/;
use Exporter::Tidy
  default => [qw/opt arg opts args optargs usage subcmd/],
  other   => [qw/dispatch/];
use Getopt::Long qw/GetOptionsFromArray/;
use List::Util qw/max/;

our $VERSION = '0.0.1';

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

    my $parent_arg = ( grep { $_->{type} eq 'subcmd' } @{ $args{$parent} } )[0];
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
    $params->{type}    = 'subcmd' if $params->{isa} eq 'SubCmd';
    $params->{ISA}     = $params->{name} . $arg_isa{ $params->{isa} };

    push( @{ $args{$package} }, $params );
    $opts{$package} ||= [];
    $seen{$package}->{$name}++;

    return;
}

# ------------------------------------------------------------------------
# Usage message generation
# ------------------------------------------------------------------------

sub _usage {
    my $caller = shift;
    my $error  = shift;

    my @config;
    my $parent   = $caller;
    my $length_a = 0;
    my $length_b = 0;
    my $usage    = '';

    foreach my $def ( @{ $args{$caller} } ) {
        $usage .= ' ' if $usage;
        $usage .= '[' unless $def->{required};
        $usage .= uc $def->{name};
        $usage .= '...' if $def->{greedy};
        $usage .= ']' unless $def->{required};

        $length_a = max( $length_a, map { length $_ } @{ $def->{subcommands} } )
          if $def->{type} eq 'subcmd';
    }

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        $usage = $2 . ' ' . $usage;
        unshift( @config, @{ $opts{$parent} } );
    }

    $usage .= "\n";
    unshift( @config, @{ $args{$caller} } );
    push( @config, @{ $opts{$caller} } );

    $length_b =
      max( map { $_->{length} + 4 } grep { $_->{type} eq 'opt' } @config ) || 0;
    $length_a = max( $length_a + 4, $length_b + 5 ) || 0;

    my $format_a  = '    %-' . $length_a . "s   %-s\n";
    my $format_b  = '%-' . $length_b . 's%-2s';
    my $prev_type = '';

    foreach my $def (@config) {
        $usage .= "\n" if $def->{type} ne $prev_type;
        $prev_type = $def->{type};

        if ( $def->{type} eq 'arg' ) {
            $usage .= sprintf( $format_a, uc $def->{name}, $def->{comment} );
        }
        elsif ( $def->{type} eq 'opt' ) {
            my $opt = '--' . $def->{name};
            $opt =~ s/_/-/g;
            $opt .= ',' if $def->{alias};
            my $tmp = sprintf( $format_b,
                $opt, $def->{alias} ? '-' . $def->{alias} : '' );

            $usage .= sprintf( $format_a, $tmp, $def->{comment} );
        }
        elsif ( $def->{type} eq 'subcmd' ) {
            $usage .= sprintf( $format_a, uc $def->{name}, $def->{comment} );
            foreach my $subcommand ( @{ $def->{subcommands} } ) {
                my $pkg = $def->{package} . '::' . $subcommand;
                $pkg =~ s/-/_/g;
                my $desc = $desc{$pkg};
                $usage .= sprintf( $format_a, '    ' . $subcommand, $desc );
            }

            if ( $def->{fallback} ) {
                $usage .= sprintf( $format_a,
                    '    ' . uc $def->{fallback}->{name},
                    $def->{fallback}->{comment} );
            }
        }
    }

    require File::Basename;
    $usage = 'usage: ' . File::Basename::basename($0) . ' ' . $usage . "\n";
    $usage = $error . "\n\n" . $usage if $error;
    return $usage;
}

sub usage {
    my $caller = caller;
    return _usage($caller);
}

# ------------------------------------------------------------------------
# Option/Argument processing
# ------------------------------------------------------------------------
sub _optargs {
    my $caller  = shift;
    my $source  = @_ ? \@_ : \@ARGV;
    my $package = $caller;

    croak "no option or argument defined for $caller"
      unless exists $opts{$package}
          or exists $args{$package};

    Getopt::Long::Configure(qw/pass_through no_auto_abbrev/);

    my @config = ( @{ $opts{$package} }, @{ $args{$package} } );

    my $ishelp;
    my $missing_required;
    my $optargs = {};

    while ( my $try = shift @config ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {
            GetOptionsFromArray( $source, $try->{ISA} => \$result );
        }
        elsif ( $try->{type} eq 'arg' or $try->{type} eq 'subcmd' ) {
            if (@$source) {
                if ( $try->{greedy} ) {
                    $result = "@$source";
                    shift @$source while @$source;
                }
                else {
                    $result = shift @$source;
                }

                # TODO: type check using Param::Utils?
            }
            elsif ( $try->{required} and !$ishelp ) {
                $missing_required++;
                next;
            }

            if ( $try->{isa} eq 'SubCmd' and $result ) {
                die _usage( $package, "unknown option: " . $result )
                  if ( $result =~ m/^-/ );

                my $newpackage = $package . '::' . $result;
                $newpackage =~ s/-/_/;

                if ( exists $seen{$newpackage} ) {
                    $package = $newpackage;
                    push( @config, @{ $opts{$package} }, @{ $args{$package} } );
                }
                elsif ( !$try->{fallback} ) {
                    die _usage( $package,
                        "unknown " . uc( $try->{name} ) . ': ' . $result );
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
        die _usage( $package, "[help request]" );
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

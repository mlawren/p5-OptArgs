package OptArgs;
use strict;
use warnings;
use Carp qw/croak/;
use Exporter::Tidy
  default => [qw/opt arg opts args optargs usage subcmd/],
  other   => [qw/dispatch/];
use Getopt::Long qw/GetOptionsFromArray/;
use Data::Show;

our $VERSION = '0.0.1';

Getopt::Long::Configure(qw/pass_through no_auto_abbrev/);

my %config;
my %desc;
my %seen;

my @subcmd;
my %sub;

my %opts;
my %args;
my %optargs;

my %opt_types = (
    'Bool'     => '!',
    'Counter'  => '+',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

my @opt_required = (qw/isa comment/);

my %opt_defaults = (
    isa     => undef,
    comment => undef,
    default => undef,
    alias   => undef,
    package => undef,
    ishelp  => undef,
);

my %arg_types = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

my @arg_required = (qw/isa comment/);

my %arg_defaults = (
    isa      => undef,
    comment  => undef,
    required => undef,
    default  => undef,
    package  => undef,
);

sub _reset {
    my $caller = shift;

    delete $optargs{$caller};
    delete $opts{$caller};
    delete $args{$caller};

    return;
}

sub opt {
    my $caller = caller;
    $caller = $sub{$caller} if $sub{$caller};

    my $name = shift;
    croak 'usage: opt $name => (%parameters)' unless $name;

    my $params = {@_};
    if ( my @missing = grep { !exists $params->{$_} } @opt_required ) {
        croak "missing required parameter(s): @missing";
    }

    $params = { %opt_defaults, %$params };
    if ( my @invalid = grep { !exists $opt_defaults{$_} } keys %$params ) {
        my @valid = keys %opt_defaults;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    $caller = delete $params->{package} if defined $params->{package};
    croak "opt '$name' already defined" if $seen{$caller}->{$name}++;
    _reset($caller);

    croak "'ishelp' can only be applied to Bool opts"
      if $params->{ishelp} and $params->{isa} ne 'Bool';

    $params->{name} = $name;
    $params->{type} = 'opt';
    $params->{ISA}  = $params->{name};

    if ( ( my $dashed = $params->{name} ) =~ s/_/-/g ) {
        $params->{dashed} = $dashed;
        $params->{ISA} .= '|' . $dashed;
    }

    $params->{ISA} .= '|' . $params->{alias} if $params->{alias};

    $params->{ISA} .=
      exists $opt_types{ $params->{isa} }
      ? $opt_types{ $params->{isa} }
      : croak "unknown type: $params->{isa}";

    push( @{ $config{$caller} }, $params );

    return;
}

sub arg {
    my $caller = caller;
    $caller = $sub{$caller} if $sub{$caller};

    _reset($caller);

    my $name = shift;
    croak 'usage: arg $name => (%parameters)' unless $name;

    my $params = {@_};
    if ( my @missing = grep { !exists $params->{$_} } @arg_required ) {
        croak "missing required parameter(s): @missing";
    }

    $params = { %arg_defaults, %$params };
    if ( my @invalid = grep { !exists $arg_defaults{$_} } keys %$params ) {
        my @valid = keys %arg_defaults;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    if ( defined $params->{default} and defined $params->{required} ) {
        croak "'default' and 'required' cannot be used together";
    }

    $caller = delete $params->{package} if defined $params->{package};
    croak "arg '$name' already defined" if $seen{$caller}->{$name}++;
    _reset($caller);

    $params->{name} = $name;
    $params->{type} = 'arg';
    $params->{type} = 'subcmd' if $params->{isa} eq 'SubCmd';
    $params->{ISA}  = $params->{name};

    $params->{ISA} .=
      exists $arg_types{ $params->{isa} }
      ? $arg_types{ $params->{isa} }
      : croak "unknown type: $params->{isa}";

    push( @{ $config{$caller} }, $params );

    return;
}

sub _usage {
    my $caller = shift;
    my $error  = shift;

    croak 'missing $caller' unless $seen{$caller};

    my $usage = $error ? $error . "\n\n" : '';

    require File::Basename;
    $usage .= 'usage: ' . File::Basename::basename($0);

    my @config = @{ $config{$caller} };

    if ( ( my $parent = $caller ) =~ s/^(.*)::(.*)$/$1/ ) {
        my $name = $2;

        while ( $seen{$parent} ) {

            my @parent = @{ $config{$parent} };
            $parent[$#parent] = {
                type   => 'subcmd',
                name   => $name,
                parent => 1,
            };

            unshift( @config, @parent );
            last unless $parent =~ s/(.*)::(.*)/$1/;
            $name = $2;
        }
    }

    my $have_opt  = 0;
    my $maxlength = 0;

    foreach my $def (@config) {
        my $length = length $def->{name};
        $maxlength = $length if $length > $maxlength;

        if ( $def->{type} eq 'opt' ) {
            next if $have_opt;
            $usage .= ' [options]';
            $have_opt++;
        }
        elsif ( $def->{type} eq 'arg' or $def->{type} eq 'subcmd' ) {
            my $tmp = $usage .= ' ';
            $usage .= '[' unless $def->{required} or $def->{parent};
            $usage .= $def->{parent} ? $def->{name} : uc $def->{name};
            $usage .= ']' unless $def->{required} or $def->{parent};
            $have_opt = 0;
        }
    }

    $usage .= "\n";

    my $prev = '';
    my $format = '    %-' . ( $maxlength + 2 ) . "s    %-s\n";

    foreach my $def (@config) {
        if ( $def->{type} eq 'opt' ) {
            $usage .= "\n" unless ( $prev eq 'opt' or $prev eq 'subcmd' );

            my $alias =
              join( ', ', map { '-' . $_ } split( /|/, $def->{alias} || '' ) );
            $alias = ', ' . $alias if $alias;

            if ( exists $def->{dashed} ) {
                $usage .= sprintf( $format,
                    '--' . $def->{dashed} . $alias,
                    $def->{comment} );
            }
            else {
                $usage .= sprintf( $format,
                    '--' . $def->{name} . $alias,
                    $def->{comment} );
            }
        }
        elsif ( $def->{type} eq 'arg' or $def->{type} eq 'subcmd' ) {
            next if $def->{parent};
            $usage .= "\n" unless ( $prev eq 'arg' or $prev eq 'subcmd' );

            $usage .= sprintf( $format, uc( $def->{name} ), $def->{comment} );

            if ( $def->{type} eq 'subcmd' ) {
                my @list = grep { $_ =~ /^${caller}::[^:]+$/ } @subcmd;

                my $max = 0;
                map { $max = $_ > $max ? $_ : $max } map { length $_ } @list;
                my $format =
                    '        %-'
                  . ( $max - length( $caller . '::' ) )
                  . "s       %-s\n";

                if (@list) {

                    foreach my $subc (@list) {
                        my $desc = $desc{$subc};
                        ( my $name = $subc ) =~ s/.*::(.*)/$1/;
                        $name =~ s/_/-/;
                        $usage .= sprintf( $format, $name, $desc );
                    }
                }

            }
        }
        $prev = $def->{type};
    }

    $usage .= "\n";
    return $usage;
}

sub usage {
    my $caller = caller;
    return _usage($caller);
}

sub _optargs {
    my $caller = shift;

    return $caller if exists $optargs{$caller} and !@_ and !@ARGV;

    croak "no defined option/argument for $caller"
      unless exists $config{$caller};

    $config{$caller} ||= [];

    my $source = @_ ? \@_ : \@ARGV;
    my $package = $caller;

    my $optargs = {};
    my $opts    = {};
    my $args    = {};

    my @config  = @{ $config{$caller} };
    my @current = @config;

    my $ishelp;

    while ( my $try = shift @current ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {

            if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
                $optargs->{ $try->{name} } =
                  defined $result
                  ? $result
                  : $try->{default};

                $ishelp = 1 if $optargs->{ $try->{name} } and $try->{ishelp};
            }
            else {
                return;
            }
        }
        elsif ( $try->{type} eq 'arg' or $try->{type} eq 'subcmd' ) {
            if (@$source) {
                unshift( @$source, '--' . $try->{name} );

                if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
                    if ( defined $result && $result =~ m/^-/ ) {
                        require Scalar::Util;
                        die _usage( $package, "unknown option: " . $result )
                          unless Scalar::Util::looks_like_number($result);
                    }

                    $optargs->{ $try->{name} } =
                      defined $result
                      ? $result
                      : $try->{default};
                }
                else {
                    return;
                }
            }
            elsif ( $try->{default} ) {
                $optargs->{ $try->{name} } = $try->{default};
            }
            elsif ( $try->{required} and !$ishelp ) {
                die _usage($package);
            }

            if ( $try->{isa} eq 'SubCmd'
                and my $subcmd = $optargs->{ $try->{name} } )
            {
                die _usage( $package, "unknown option: " . $subcmd )
                  if ( $subcmd =~ m/^-/ );

                my $oldpackage = $package;
                $package = $package . '::' . $optargs->{ $try->{name} };
                $package =~ s/-/_/;

                die _usage( $oldpackage,
                    "unknown " . uc( $try->{name} ) . ': ' . $subcmd )
                  unless exists $seen{$package};

                push( @current, @{ $config{$package} } );
                push( @config,  @{ $config{$package} } );

            }

        }
    }

    if ($ishelp) {
        die _usage( $package, "[help request]" );
    }

    if (@$source) {
        die _usage( $package,
            "unexpected option or argument: " . shift @$source );
    }

    foreach my $try (@config) {
        if ( $try->{type} eq 'subcmd' ) {
            delete $optargs->{ $try->{name} };
            next;
        }

        # Re-calculate the default if it was a subref
        my $result = $optargs->{ $try->{name} };
        if ( ref $result eq 'CODE' ) {
            $result = $result->( {%$optargs} );
            $optargs->{ $try->{name} } = $result;
        }

        if ( $try->{type} eq 'opt' ) {
            $opts->{ $try->{name} } = $result;
        }
        elsif ( $try->{type} eq 'arg' ) {
            $args->{ $try->{name} } = $result;
        }

    }

    $optargs{$caller} = $optargs;
    $opts{$caller}    = $opts;
    $args{$caller}    = $args;

    if ( $package ne $caller ) {
        $optargs{$package} = $optargs;
        $opts{$package}    = $opts;
        $args{$package}    = $args;

        return $package;
    }

    return $caller;
}

sub opts {
    my $caller = caller;

    _optargs( $caller, @_ );
    return $opts{$caller};
}

sub args {
    my $caller = caller;

    _optargs( $caller, @_ );
    return $args{$caller};
}

sub optargs {
    my $caller = caller;

    _optargs( $caller, @_ );
    return $optargs{$caller};
}

sub subcmd {
    my $caller = caller;
    croak 'subcmd(@cmd,$description)' unless @_ >= 2;

    my $desc = pop;
    my @cmd  = @_;
    my $pkg  = $caller . '::' . join( '::', map { s/-/_/g; $_ } @cmd );

    croak "sub command already defined in $caller: @cmd" if $seen{$pkg};

    $config{$pkg} = [];
    $desc{$pkg}   = $desc;
    $seen{$pkg}   = {};
    $sub{$caller} = $pkg;
    push( @subcmd, $pkg );

}

sub dispatch {
    my $method = shift;
    my $class  = shift;

    croak 'dispatch($method, $class, [@argv])' unless $method and $class;
    croak $@ unless eval "require $class;1;";
    _reset($class);

    my $package = _optargs( $class, @_ );
    croak $@ unless ( $package->can($method) || eval "require $package;1;" );
    return $package->$method;
}

1;

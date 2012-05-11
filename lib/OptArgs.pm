package OptArgs;
use strict;
use warnings;
use Carp qw/croak/;
use Exporter::Tidy
  default => [qw/opt arg opts args optargs usage comment/],
  other   => [qw/dispatch/];
use Getopt::Long qw/GetOptionsFromArray/;

our $VERSION = '0.0.1';

Getopt::Long::Configure(qw/pass_through no_auto_abbrev/);

my %definition;
my %definition_list;

my %comments;
my @comments;

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
);

my %arg_types = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

my @arg_required = (qw/isa comment/);

my %arg_defaults = (
    isa      => undef,
    comment  => undef,
    required => undef,
    default  => undef,
    dispatch => undef,
);

sub _reset {
    my $caller = shift;

    delete $opts{$caller};
    delete $args{$caller};
    delete $optargs{$caller};

    return;
}

sub opt {
    my $caller = caller;

    _reset($caller);

    my $name = shift;
    croak 'usage: opt $name => (%parameters)' unless $name;
    croak "opt '$name' already defined" if exists $definition{$caller}->{$name};

    my $params = {@_};
    if ( my @missing = grep { !exists $params->{$_} } @opt_required ) {
        croak "missing required parameter(s): @missing";
    }

    $params = { %opt_defaults, %$params };
    if ( my @invalid = grep { !exists $opt_defaults{$_} } keys %$params ) {
        my @valid = keys %opt_defaults;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

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

    $definition{$caller}->{$name} = $params;
    push( @{ $definition_list{$caller} }, $params );

    return;
}

sub arg {
    my $caller = caller;

    _reset($caller);

    my $name = shift;
    croak 'usage: arg $name => (%parameters)' unless $name;
    croak "arg '$name' already defined" if exists $definition{$caller}->{$name};

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

    $params->{name} = $name;
    $params->{type} = 'arg';
    $params->{ISA}  = $params->{name};

    $params->{ISA} .=
      exists $arg_types{ $params->{isa} }
      ? $arg_types{ $params->{isa} }
      : croak "unknown type: $params->{isa}";

    $definition{$caller}->{$name} = $params;
    push( @{ $definition_list{$caller} }, $params );

    return;
}

sub _usage {
    my $caller = shift;
    my $error  = shift;

    croak 'missing $caller' unless exists $definition_list{$caller};

    require File::Basename;
    my $usage = $error ? $error . "\n\n" : '';
    $usage .= 'usage: ' . File::Basename::basename($0);

    my @defines = @{ $definition_list{$caller} };

    if ( ( my $parent = $caller ) =~ s/^(.*)::(.*)$/$1/ ) {
        my $name = $2;

        while ( exists $definition_list{$parent} ) {

            my @parent = @{ $definition_list{$parent} };
            $parent[$#parent] = {
                type => 'comment',
                name => $name,
            };

            unshift( @defines, @parent );
            last unless $parent =~ s/(.*)::(.*)/$1/;
            $name = $2;
        }
    }

    my $have_opt;
    my $maxlength = 0;

    foreach my $def (@defines) {
        my $length = length $def->{name};
        $maxlength = $length if $length > $maxlength;

        if ( $def->{type} eq 'opt' ) {
            next if $have_opt;
            $usage .= ' [options]';
            $have_opt++;
        }
        elsif ( $def->{type} eq 'arg' ) {
            $usage .= uc ' ' . $def->{name} if $def->{required};
            $usage .= uc ' [' . $def->{name} . ']' unless $def->{required};
            $have_opt = 0;
        }
        elsif ( $def->{type} eq 'comment' ) {
            $usage .= ' ' . $def->{name};
            $have_opt = 0;
        }
    }

    $usage .= "\n";

    my $prev = '';
    my $format = '    %-' . ( $maxlength + 2 ) . "s    %-s\n";

    foreach my $def (@defines) {
        if ( $def->{type} eq 'opt' ) {
            $usage .= "\n" unless ( $prev eq 'opt' or $prev eq 'comment' );

            if ( exists $def->{dashed} ) {
                $usage .=
                  sprintf( $format, '--' . $def->{dashed}, $def->{comment} );
            }
            else {
                $usage .=
                  sprintf( $format, '--' . $def->{name}, $def->{comment} );
            }

            $prev = 'opt';
        }
        elsif ( $def->{type} eq 'arg' ) {
            $usage .= "\n" unless ( $prev eq 'arg' or $prev eq 'comment' );

            $usage .= sprintf( $format, uc( $def->{name} ), $def->{comment} );

            if ( $def->{dispatch} ) {
                my @list = grep { $_ =~ /^${caller}::[^:]+$/ } @comments;

                my $max = 0;
                map { $max = $_ > $max ? $_ : $max } map { length $_ } @list;
                my $format =
                    '        %-'
                  . ( $max + 2 - length( $caller . '::' ) )
                  . "s       %-s\n";

                if (@list) {

                    foreach my $subc (@list) {
                        my $desc = $comments{$subc};
                        ( my $name = $subc ) =~ s/.*::(.*)/$1/;
                        $usage .= sprintf( $format, $name, $desc );
                    }
                }
            }

            $prev = 'arg';
        }
        elsif ( $def->{type} eq 'comment' ) {
            $usage .= "\n" unless $prev eq 'comment';
            $prev = 'comment';
        }
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
      unless exists $definition_list{$caller};

    $definition_list{$caller} ||= [];

    my $source = @_ ? \@_ : \@ARGV;
    my $package = $caller;

    my $optargs = {};
    my $opts    = {};
    my $args    = {};

    my @definitions = @{ $definition_list{$caller} };
    my @current     = @definitions;

    while ( my $try = shift @current ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {

            if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
                $optargs->{ $try->{name} } =
                  defined $result
                  ? $result
                  : $try->{default};
            }
            else {
                return;
            }
        }
        elsif ( $try->{type} eq 'arg' ) {
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
            elsif ( $try->{required} ) {
                die _usage($package);
            }

            if ( $try->{dispatch} and my $subcmd = $optargs->{ $try->{name} } )
            {
                my $oldpackage = $package;
                $package = $package . '::' . $optargs->{ $try->{name} };

                die _usage( $oldpackage, "unknown option: " . $subcmd )
                  if ( $subcmd =~ m/^-/ );

                die _usage( $oldpackage,
                    "unknown " . uc( $try->{name} ) . ': ' . $subcmd )
                  unless exists $definition{$package};

                push( @current,     @{ $definition_list{$package} } );
                push( @definitions, @{ $definition_list{$package} } );

            }

        }
    }

    if (@$source) {
        die _usage( $package,
            "unexpected option or argument: " . shift @$source );
    }

    foreach my $try (@definitions) {
        if ( $try->{dispatch} ) {
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

        unless ( eval "require $package;1;" ) {
            require Carp;
            Carp::confess $@;
        }
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

sub dispatch {
    my $method = shift;
    my $class  = shift;

    croak 'dispatch($method, $class, [@argv])' unless $method and $class;

    die $@ unless eval "require $class;1;";

    _reset($class);

    my $package = _optargs( $class, @_ );
    return $package->$method;
}

sub comment {
    my $caller = caller;
    my $desc = shift || croak 'subcomand($description)';

    croak "comment already defined: $caller"
      if $comments{$caller};

    $comments{$caller} = $desc;
    push( @comments, $caller );
}

1;

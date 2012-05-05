package optargs;
use strict;
use warnings;
use Exporter 'import';
use Getopt::Long qw/GetOptionsFromArray/;
use Carp qw/croak/;

our $VERSION = '0.0.1_1';
our @EXPORT  = (qw/opt opts arg args optargs/);

Getopt::Long::Configure(qw/pass_through/);

my %definition;
my %definition_list;

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
);

sub _reset {
    my $caller = shift;

    no strict 'refs';
    undef *{ $caller . '::_opts::' . $_ }    for keys %{ $opts{$caller} };
    undef *{ $caller . '::_args::' . $_ }    for keys %{ $args{$caller} };
    undef *{ $caller . '::_optargs::' . $_ } for keys %{ $optargs{$caller} };

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

    my $have_opt;
    my $maxlength = 0;
    foreach my $def ( @{ $definition_list{$caller} } ) {
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
    }

    $usage .= "\n";

    my $format = '    %-' . ( $maxlength + 2 ) . 's    %-s';
    foreach my $def ( @{ $definition_list{$caller} } ) {
        if ( $def->{type} eq 'opt' ) {
            if ( exists $def->{dashed} ) {
                $usage .=
                  sprintf( $format, '--' . $def->{dashed}, $def->{comment} );
            }
            else {
                $usage .=
                  sprintf( $format, '--' . $def->{name}, $def->{comment} );
            }
        }
        elsif ( $def->{type} eq 'arg' ) {
            $usage .=
              sprintf( $format, '  ' . uc( $def->{name} ), $def->{comment} );
            $usage .= ' (required)' if $def->{required};
            $usage .= ' (optional)' unless $def->{required};
        }
        $usage .= "\n";
    }

    return $usage;
}

sub _optargs {
    my $caller = shift;

    return if exists $optargs{$caller} and !@_ and !@ARGV;
    croak "no defined option/argument" unless exists $definition_list{$caller};

    my $source = @_ ? \@_ : \@ARGV;
    my $refoptargs = {};

    foreach my $try ( @{ $definition_list{$caller} } ) {
        my $result;

        if ( $try->{type} eq 'arg' ) {
            if (@$source) {
                unshift( @$source, '--' . $try->{name} );
                if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
                    $refoptargs->{ $try->{name} } =
                      defined $result
                      ? $result
                      : $try->{default};
                }
                else {
                    return;
                }
            }
            elsif ( $try->{default} ) {
                $refoptargs->{ $try->{name} } = $try->{default};
            }
            elsif ( $try->{required} ) {
                die _usage( $caller, "missing argument: " . uc $try->{name} );
            }

        }
        elsif ( $try->{type} eq 'opt' ) {

            if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
                $refoptargs->{ $try->{name} } =
                  defined $result
                  ? $result
                  : $try->{default};
            }
            else {
                return;
            }
        }
    }

    if (@$source) {
        die _usage( $caller, "unexpected option or argument: @$source" );
    }

    my $refopts = {};
    my $refargs = {};

    foreach my $try ( @{ $definition_list{$caller} } ) {

        # Re-calculate the default if it was a subref
        my $result = $refoptargs->{ $try->{name} };
        if ( ref $result eq 'CODE' ) {
            $result = $result->( {%$refoptargs} );
            $refoptargs->{ $try->{name} } = $result;
        }

        no strict 'refs';
        no warnings 'redefine';

        my $subref = sub { $result };
        *{ $caller . '::_optargs::' . $try->{name} } = $subref;

        if ( $try->{type} eq 'opt' ) {
            $refopts->{ $try->{name} } = $result;
            *{ $caller . '::_opts::' . $try->{name} } = $subref;
        }
        elsif ( $try->{type} eq 'arg' ) {
            $refargs->{ $try->{name} } = $result;
            *{ $caller . '::_args::' . $try->{name} } = $subref;
        }
    }

    $optargs{$caller} = bless $refoptargs, $caller . '::_optargs';
    $opts{$caller}    = bless $refopts,    $caller . '::_opts';
    $args{$caller}    = bless $refargs,    $caller . '::_args';

    return;
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

1;

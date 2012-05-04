package optargs;
use strict;
use warnings;
use Exporter 'import';
use Getopt::Long qw/GetOptionsFromArray/;
use Carp qw/croak/;

our $VERSION = '0.0.1_1';
our @EXPORT  = (qw/opt opts optargs/);

Getopt::Long::Configure(qw/pass_through/);

my %definition;
my %definition_list;

my %opts;
my %args;
my %optargs;

my @opt_required = (qw/isa/);

my %opt_defaults = (
    isa      => undef,
    required => undef,
    alias    => undef,
    comment  => undef,
);

my %TYPE_MAP = (
    'Bool'     => '!',
    'Counter'  => '+',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
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
      exists $TYPE_MAP{ $params->{isa} }
      ? $TYPE_MAP{ $params->{isa} }
      : croak "unknown type: $params->{isa}";

    $definition{$caller}->{$name} = $params;
    push( @{ $definition_list{$caller} }, $params );

    return;
}

sub _optargs {
    my $caller = shift;

    return if exists $optargs{$caller} and !@_ and !@ARGV;
    croak "no defined option/argument" unless exists $definition_list{$caller};

    my $source     = @_ ? \@_ : \@ARGV;
    my $refopts    = {};
    my $refargs    = {};
    my $refoptargs = {};

    foreach my $try ( @{ $definition_list{$caller} } ) {
        my $result;

        if ( GetOptionsFromArray( $source, $try->{ISA} => \$result ) ) {
            $refoptargs->{ $try->{name} } = $result;

            no strict 'refs';
            no warnings 'redefine';

            *{ $caller . '::_optargs::' . $try->{name} } = sub { $result };

            if ( $try->{type} eq 'opt' ) {
                $refopts->{ $try->{name} } = $result;
                *{ $caller . '::_opts::' . $try->{name} } = sub { $result };
            }
            else {
                $refargs->{ $try->{name} } = $result;
                *{ $caller . '::_args::' . $try->{name} } = sub { $result };
            }
        }
        else {
            return;
        }
    }

    if (@$source) {
        croak "unexpected option or argument: @$source";
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

sub optargs {
    my $caller = caller;

    _optargs( $caller, @_ );
    return $optargs{$caller};
}

1;

# Generated by Class::Inline version 0.0.1
# Date: Sun Sep 25 20:21:57 2022
use strict;
use warnings;

package OptArgs2::CmdBase_CI;                                 ## CI_PM_FILTER
use Class::Inline::Check                                      ## CI_PM_FILTER
  file        => '/home/mark/src/optargs/lib/OptArgs2.pm',    ## CI_PM_FILTER
  line        => 564,                                         ## CI_PM_FILTER
  strip       => 1,                                           ## CI_PM_FILTER
  tidy        => 0,                                           ## CI_PM_FILTER
  wrap        => 0,                                           ## CI_PM_FILTER
  wrap_indent => 0,                                           ## CI_PM_FILTER
  wrap_maxlen => 78,                                          ## CI_PM_FILTER
  code        => <<'CI_PM_FILTER';                            ## CI_PM_FILTER

package OptArgs2::CmdBase;require Scalar::Util;our$_HAS;sub OptArgs2::CmdBase_CI::import {shift;my$ref={@_ > 1 ? @_ : %{$_[0]}};$_HAS=exists$ref->{'has'}? $ref->{'has'}: $ref}our%_ATTRS;my%_BUILD_CHECK;sub new {my$class=shift;my$self={@_ ? @_ > 1 ? @_ : %{$_[0]}: ()};%_ATTRS=map {($_=>1)}keys %$self;bless$self,ref$class || $class;$_BUILD_CHECK{$class}//= do {my@possible=($class);my@BUILD;my@CHECK;while (@possible){no strict 'refs';my$c=shift@possible;push@BUILD,$c .'::BUILD' if exists &{$c .'::BUILD'};push@CHECK,$c .'::__CHECK' if exists &{$c .'::__CHECK'};push@possible,@{$c .'::ISA'}}[reverse(@CHECK),reverse(@BUILD)]};map {$self->$_}@{$_BUILD_CHECK{$class}};Carp::carp("OptArgs2::CmdBase attribute '$_' unexpected")for keys%_ATTRS;$self}sub __RO {my (undef,undef,undef,$sub)=caller(1);Carp::croak("attribute $sub is read-only")}sub __CHECK {if (my@missing=grep {not exists $_[0]->{$_}}'comment'){Carp::croak('OptArgs2::CmdBase attribute(s) required: ' .join(', ',@missing))}no strict 'refs';my$_attrs=*{ref($_[0]).'::_ATTRS'};map {delete$_attrs->{$_}}keys %$_HAS;Scalar::Util::weaken($_[0]{'parent'})if exists $_[0]{'parent'}&& defined $_[0]{'parent'}}sub _args {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'_args'}//= $_HAS->{'_args'}->{'default'}->($_[0])}sub _opts {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'_opts'}//= $_HAS->{'_opts'}->{'default'}->($_[0])}sub _subcmds {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'_subcmds'}//= $_HAS->{'_subcmds'}->{'default'}->($_[0])}sub _values {if (@_ > 1){$_[0]{'_values'}=$_[1];return $_[0]}$_[0]{'_values'}}sub abbrev {if (@_ > 1){$_[0]{'abbrev'}=$_[1];return $_[0]}$_[0]{'abbrev'}}sub args {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'args'}//= $_HAS->{'args'}->{'default'}->($_[0])}sub comment {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'comment'}}sub hidden {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'hidden'}}sub no_help {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'no_help'}//= $_HAS->{'no_help'}->{'default'}}sub optargs {if (@_ > 1){$_[0]{'optargs'}=$_[1];return $_[0]}$_[0]{'optargs'}}sub opts {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'opts'}//= $_HAS->{'opts'}->{'default'}->($_[0])}sub parent {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'parent'}}sub show_color {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'show_color'}//= $_HAS->{'show_color'}->{'default'}->($_[0])}sub show_default {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'show_default'}//= $_HAS->{'show_default'}->{'default'}}sub subcmds {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'subcmds'}//= $_HAS->{'subcmds'}->{'default'}->($_[0])}BEGIN {$INC{'OptArgs2/CmdBase.pm'}=__FILE__}
sub _dump { ## CI_PM_FILTER
    my $self = shift; ## CI_PM_FILTER
    my $d = shift // 1; ## CI_PM_FILTER
    require Data::Dumper; ## CI_PM_FILTER
    no warnings 'once'; ## CI_PM_FILTER
    local $Data::Dumper::Indent = 1; ## CI_PM_FILTER
    local $Data::Dumper::Maxdepth = $d; ## CI_PM_FILTER
    local $Data::Dumper::Sortkeys = 1; ## CI_PM_FILTER
    my $x = Data::Dumper::Dumper($self); ## CI_PM_FILTER
    $x =~ s/.*?{/{/; ## CI_PM_FILTER
    $x =~ s/}.*?\n$/}/; ## CI_PM_FILTER
    my $i = 0; ## CI_PM_FILTER
    my @list; ## CI_PM_FILTER
    do { ## CI_PM_FILTER
        @list = caller( $i++ ); ## CI_PM_FILTER
    } until $list[3] eq __PACKAGE__ . '::_dump'; ## CI_PM_FILTER
    warn "$self $x at $list[1]:$list[2]\n"; ## CI_PM_FILTER
} ## CI_PM_FILTER
CI_PM_FILTER
1;

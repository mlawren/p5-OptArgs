# Generated by Class::Inline version 0.0.1
# Date: Sun Sep 25 16:12:36 2022
use strict;
use warnings;

package OptArgs2::Cmd_CI;                                     ## CI_PM_FILTER
use Class::Inline::Check                                      ## CI_PM_FILTER
  file        => '/home/mark/src/optargs/lib/OptArgs2.pm',    ## CI_PM_FILTER
  line        => 1063,                                        ## CI_PM_FILTER
  strip       => 1,                                           ## CI_PM_FILTER
  tidy        => 0,                                           ## CI_PM_FILTER
  wrap        => 0,                                           ## CI_PM_FILTER
  wrap_indent => 0,                                           ## CI_PM_FILTER
  wrap_maxlen => 78,                                          ## CI_PM_FILTER
  code        => <<'CI_PM_FILTER';                            ## CI_PM_FILTER

package OptArgs2::Cmd;BEGIN {require OptArgs2::CmdBase;our@ISA=('OptArgs2::CmdBase')};our$_HAS;sub OptArgs2::Cmd_CI::import {shift;my$ref={@_ > 1 ? @_ : %{$_[0]}};$_HAS=exists$ref->{'has'}? $ref->{'has'}: $ref}our%_ATTRS;my%_BUILD_CHECK;sub new {my$class=shift;my$self={@_ ? @_ > 1 ? @_ : %{$_[0]}: ()};%_ATTRS=map {($_=>1)}keys %$self;bless$self,ref$class || $class;$_BUILD_CHECK{$class}//= do {my@possible=($class);my@BUILD;my@CHECK;while (@possible){no strict 'refs';my$c=shift@possible;push@BUILD,$c .'::BUILD' if exists &{$c .'::BUILD'};push@CHECK,$c .'::__CHECK' if exists &{$c .'::__CHECK'};push@possible,@{$c .'::ISA'}}[reverse(@CHECK),reverse(@BUILD)]};map {$self->$_}@{$_BUILD_CHECK{$class}};Carp::carp("OptArgs2::Cmd attribute '$_' unexpected")for keys%_ATTRS;$self}sub __RO {my (undef,undef,undef,$sub)=caller(1);Carp::croak("attribute $sub is read-only")}sub __CHECK {if (my@missing=grep {not exists $_[0]->{$_}}'class'){Carp::croak('OptArgs2::Cmd attribute(s) required: ' .join(', ',@missing))}no strict 'refs';my$_attrs=*{ref($_[0]).'::_ATTRS'};map {delete$_attrs->{$_}}keys %$_HAS}sub class {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'class'}}sub name {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'name'}//= $_HAS->{'name'}->{'default'}->($_[0])}BEGIN {$INC{'OptArgs2/Cmd.pm'}=__FILE__}
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

# Generated by Class::Inline version 0.0.1
# Date: Mon Oct  3 17:29:09 2022
use strict;
use warnings;

package OptArgs2::Pager_CI;                                         #CIFILTER#
use Class::Inline::Check                                            #CIFILTER#
  file        => '/home/mark/src/optargs/lib/OptArgs2/Pager.pm',    #CIFILTER#
  strip       => 1,                                                 #CIFILTER#
  tidy        => 0,                                                 #CIFILTER#
  wrap        => 0,                                                 #CIFILTER#
  wrap_indent => 0,                                                 #CIFILTER#
  wrap_maxlen => 78,                                                #CIFILTER#
  code        => <<'CIFILTER';                                      #CIFILTER#

package OptArgs2::Pager;our$_HAS;sub OptArgs2::Pager_CI::import {shift;$_HAS={@_ > 1 ? @_ : %{$_[0]}};$_HAS=$_HAS->{'has'}if exists$_HAS->{'has'}}our%_ATTRS;my%_BUILD_CHECK;sub new {my$class=shift;my$self={@_ ? @_ > 1 ? @_ : %{$_[0]}: ()};%_ATTRS=map {($_=>1)}keys %$self;bless$self,ref$class || $class;$_BUILD_CHECK{$class}//= do {my@possible=($class);my@BUILD;my@CHECK;while (@possible){no strict 'refs';my$c=shift@possible;push@BUILD,$c .'::BUILD' if exists &{$c .'::BUILD'};push@CHECK,$c .'::__CHECK' if exists &{$c .'::__CHECK'};push@possible,@{$c .'::ISA'}}[reverse(@CHECK),reverse(@BUILD)]};map {$self->$_}@{$_BUILD_CHECK{$class}};Carp::carp("OptArgs2::Pager attribute '$_' unexpected")for keys%_ATTRS;$self}sub __RO {my (undef,undef,undef,$sub)=caller(1);Carp::croak("attribute $sub is read-only")}sub __CHECK {map {delete $_[0]->{$_}}'fh','orig_fh','pid';no strict 'refs';my$_attrs=*{ref($_[0]).'::_ATTRS'};map {delete$_attrs->{$_}}keys %$_HAS}sub auto {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'auto'}//= $_HAS->{'auto'}->{'default'}}sub encoding {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'encoding'}//= $_HAS->{'encoding'}->{'default'}}sub fh {if (@_ > 1){$_[0]{'fh'}=$_[1];return $_[0]}elsif (!exists $_[0]{'fh'}){$_[0]->fh($_HAS->{'fh'}->{'default'}->($_[0]))}$_[0]{'fh'}//= $_HAS->{'fh'}->{'default'}->($_[0])}sub orig_fh {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'orig_fh'}//= $_HAS->{'orig_fh'}->{'default'}->($_[0])}sub pager {$_[0]->__RO($_[1])if @_ > 1;$_[0]{'pager'}//= $_HAS->{'pager'}->{'default'}->($_[0])}sub pid {if (@_ > 1){$_[0]{'pid'}=$_[1];return $_[0]}$_[0]{'pid'}}BEGIN {$INC{'OptArgs2/Pager.pm'}=__FILE__}
sub _dump { #CIFILTER#
    my $self = shift; #CIFILTER#
    my $d = shift // 1; #CIFILTER#
    require Data::Dumper; #CIFILTER#
    no warnings 'once'; #CIFILTER#
    local $Data::Dumper::Indent = 1; #CIFILTER#
    local $Data::Dumper::Maxdepth = $d; #CIFILTER#
    local $Data::Dumper::Sortkeys = 1; #CIFILTER#
    my $x = Data::Dumper::Dumper($self); #CIFILTER#
    $x =~ s/.*?{/{/; #CIFILTER#
    $x =~ s/}.*?\n$/}/; #CIFILTER#
    my $i = 0; #CIFILTER#
    my @list; #CIFILTER#
    do { #CIFILTER#
        @list = caller( $i++ ); #CIFILTER#
    } until $list[3] eq __PACKAGE__ . '::_dump'; #CIFILTER#
    warn "$self $x at $list[1]:$list[2]\n"; #CIFILTER#
} #CIFILTER#
CIFILTER
1;

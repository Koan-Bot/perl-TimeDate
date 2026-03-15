##
## Portuguese tables
##

package Date::Language::Portuguese;

use strict;
use warnings;
use utf8;

use Date::Language ();

use base 'Date::Language';

# VERSION: generated
# ABSTRACT: Portuguese localization for Date::Format

our @DoW  = qw(domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado);
our @MoY  = qw(janeiro fevereiro março abril maio junho
               julho agosto setembro outubro novembro dezembro);
our @DoWs = map { substr($_,0,3) } @DoW;
our @MoYs = map { substr($_,0,3) } @MoY;
our @AMPM = qw(AM PM);

our @Dsuf = ('º') x 32;

our ( %MoY, %DoW );
Date::Language::_build_lookups();

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[$_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[$_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_o { sprintf("%2d%s",$_[0]->[3],$Dsuf[$_[0]->[3]]) }
sub format_p { $_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0] }

1;

##
## Portuguese tables (European Portuguese)
##

package Date::Language::Portuguese;

use strict;
use warnings;
use utf8;
use Date::Language ();

use base 'Date::Language';

# VERSION: generated
# ABSTRACT: Portuguese localization for Date::Format

our @DoW = qw(domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado);
our @MoY = qw(janeiro fevereiro março abril maio junho
      julho agosto setembro outubro novembro dezembro);
our @DoWs = qw(dom seg ter qua qui sex sáb);
our @MoYs = qw(jan fev mar abr mai jun jul ago set out nov dez);
our @AMPM = qw(AM PM);

our @Dsuf = ('º') x 31;

our ( %MoY, %DoW );
Date::Language::_build_lookups();

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[$_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[$_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_p { $_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0] }

1;

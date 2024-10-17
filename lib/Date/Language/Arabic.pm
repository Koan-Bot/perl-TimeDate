package Date::Language::Arabic;

use Date::Language ();
our @ISA = qw(Date::Language);
our $VERSION = "1.00";
our (@DoW, @DoWs, @MoY, @MoYs, @AMPM, @Dsuf, %MoY, %DoW);
use utf8;

@DoW = qw(الأحد الاثنين الثلاثاء الأربعاء الخميس الجمعة السبت);
@MoY = qw(يناير فبراير مسيرة أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر);
@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = map { substr($_,0,3) } @MoY;
$MoYs[6] = 'يوليو';
@AMPM = qw(صباحا مساءا);

@Dsuf = ((qw(er e e e e e e e e e)) x 3, 'er'); #To be amended

@MoY{@MoY}  = (0 .. scalar(@MoY));
@MoY{@MoYs} = (0 .. scalar(@MoYs));
@DoW{@DoW}  = (0 .. scalar(@DoW));
@DoW{@DoWs} = (0 .. scalar(@DoWs));

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[$_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[$_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_p { $_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0] }

1;

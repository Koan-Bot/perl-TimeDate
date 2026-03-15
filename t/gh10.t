use strict;
use warnings;

# GH#10 / RT#80649: Wrong timezone abbreviation during DST fall-back
#
# format_Z was calling timelocal() to reconstruct the original epoch from
# broken-down time.  During the "fall-back" hour, the broken-down time is
# ambiguous (1:xx AM occurs twice: once in PDT and once in PST).  timelocal()
# resolves the ambiguity to the first occurrence (PDT), returning the PDT
# epoch (offset -25200).  tz_name(-25200, dst=0) then finds -25200 in %zoneOff
# as "mst" (Mountain Standard), yielding MST instead of PST.
#
# Fix: use the original epoch stored in $_[0]->[9] instead of timelocal().
#
# This test file sets TZ at the very top so that Time::Zone's tz_local_offset
# cache is populated with the correct America/Los_Angeles offsets from the
# first call onward.

use POSIX qw();
use Test::More;

# Skip the whole file if the platform does not support IANA timezone names
my $has_la_tz = eval {
    local $ENV{TZ} = "America/Los_Angeles";
    POSIX::tzset();
    my @lt = localtime(1352021105);    # 2012-11-04 01:25:05 PST (after fall-back)
    $lt[8] == 0;                       # Expect DST flag = 0
};
plan( skip_all => "system does not support America/Los_Angeles timezone" )
    unless $has_la_tz;

plan tests => 3;

# Must be set before loading Date::Format so the tz_local_offset cache is
# primed with the right offsets throughout the test.
$ENV{TZ} = "America/Los_Angeles";
POSIX::tzset();

use Date::Format qw(time2str);

# 2012-11-04 01:25:05 PST — the second occurrence of 01:xx AM after fall-back
# This is the timestamp from the original bug report that returned MST.
is( time2str("%Z", 1352021105), "PST",
    "GH#10/RT#80649: repeated hour after fall-back formats as PST, not MST" );

# 2012-11-04 01:54:22 PDT — before the fall-back (first occurrence of 01:xx AM)
is( time2str("%Z", 1352019262), "PDT",
    "GH#10/RT#80649: pre-fall-back timestamp formats as PDT" );

# 2012-11-04 02:25:05 PST — after the repeated hour, clearly PST
is( time2str("%Z", 1352024705), "PST",
    "GH#10/RT#80649: post-repeated-hour timestamp formats as PST" );

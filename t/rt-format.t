use strict;
use warnings;
use Test::More tests => 7;
use Date::Format qw(time2str strftime);

# RT#45067: Date::Format with %z gives wrong results for half-hour timezones
{
    for my $zone (qw(-0430 -0745)) {
        my $zone_str = time2str("%Z %z", time, $zone);
        is($zone_str, "$zone $zone", "RT#45067: half-hour timezone $zone");
    }
}

# RT#52387: seconds since the Epoch, UCT
{
    my $time = time;
    my @lt = localtime($time);
    is(strftime("%s", @lt), $time, "RT#52387: strftime %s returns epoch");
    is(time2str("%s", $time), $time, "RT#52387: time2str %s returns epoch");

    # strftime %s with explicit timezone must still return the same epoch —
    # %s is timezone-agnostic (Unix timestamp is always UTC-based).
    is(strftime("%s", @lt, "UTC"),   $time, "RT#52387: strftime %s with UTC tz returns epoch");
    is(strftime("%s", @lt, "+0000"), $time, "RT#52387: strftime %s with +0000 tz returns epoch");
    is(strftime("%s", @lt, "+0100"), $time, "RT#52387: strftime %s with +0100 tz returns epoch");
}

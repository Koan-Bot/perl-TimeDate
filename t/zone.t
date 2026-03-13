use strict;
use warnings;
use Test::More;
use Time::Zone;

# tz_offset: standard timezone abbreviations
is(tz_offset("GMT"),  0,      "tz_offset GMT = 0");
is(tz_offset("UTC"),  0,      "tz_offset UTC = 0");
is(tz_offset("EST"),  -18000, "tz_offset EST = -18000");
is(tz_offset("CST"),  -21600, "tz_offset CST = -21600");
is(tz_offset("MST"),  -25200, "tz_offset MST = -25200");
is(tz_offset("PST"),  -28800, "tz_offset PST = -28800");
is(tz_offset("CET"),  3600,   "tz_offset CET = 3600");
is(tz_offset("JST"),  32400,  "tz_offset JST = 32400");
is(tz_offset("IST"),  19800,  "tz_offset IST = 19800");

# tz_offset: DST timezone abbreviations
is(tz_offset("EDT"),  -14400, "tz_offset EDT = -14400");
is(tz_offset("CDT"),  -18000, "tz_offset CDT = -18000");
is(tz_offset("MDT"),  -21600, "tz_offset MDT = -21600");
is(tz_offset("PDT"),  -25200, "tz_offset PDT = -25200");
is(tz_offset("BST"),  3600,   "tz_offset BST = 3600");
is(tz_offset("CEST"), 7200,   "tz_offset CEST = 7200");

# tz_offset: numeric offsets
is(tz_offset("+0000"), 0,      "tz_offset +0000 = 0");
is(tz_offset("-0500"), -18000, "tz_offset -0500 = -18000");
is(tz_offset("+0530"), 19800,  "tz_offset +0530 = 19800");
is(tz_offset("+0900"), 32400,  "tz_offset +0900 = 32400");
is(tz_offset("-0800"), -28800, "tz_offset -0800 = -28800");

# tz_offset: unknown zone returns undef
is(tz_offset("BOGUS"), undef, "tz_offset unknown zone returns undef");

# tz_offset: case insensitivity
is(tz_offset("gmt"), 0,      "tz_offset case insensitive: gmt");
is(tz_offset("est"), -18000, "tz_offset case insensitive: est");

# tz_name: with explicit $dst parameter (deterministic, no system-time dependency)
# When $dst=0, offset -18000 (-5h) should resolve to a standard timezone (EST)
# When $dst=1, offset -18000 (-5h) should resolve to a DST timezone (CDT)
is(tz_name(-18000, 0), "est", "tz_name(-18000, dst=0) is est");
is(tz_name(-18000, 1), "cdt", "tz_name(-18000, dst=1) is cdt");

# tz_name: offset 0 is always GMT/UTC regardless of DST flag
like(tz_name(0, 0), qr/^(?:gmt|utc)$/i, "tz_name(0, dst=0) is GMT or UTC");
like(tz_name(0, 1), qr/^(?:gmt|utc)$/i, "tz_name(0, dst=1) is GMT or UTC");

# tz_name: offsets with only standard or only DST entries
is(tz_name(32400, 0),  "jst",  "tz_name(32400, dst=0) is jst (Japan Standard)");
is(tz_name(-25200, 1), "pdt",  "tz_name(-25200, dst=1) is pdt (Pacific Daylight)");
is(tz_name(-28800, 0), "pst",  "tz_name(-28800, dst=0) is pst (Pacific Standard)");

# tz_name: unknown offset returns numeric string
like(tz_name(5400, 0), qr/^\+\d{4}$/, "tz_name for unknown offset returns numeric");

# tz_local_offset: returns a sane value
{
    my $offset = tz_local_offset();
    ok(defined $offset, "tz_local_offset returns defined value");
    cmp_ok($offset, '>=', -12 * 3600, "tz_local_offset >= -12 hours");
    cmp_ok($offset, '<=', 14 * 3600,  "tz_local_offset <= 14 hours");
}

done_testing;

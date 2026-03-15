use strict;
use warnings;
use Test::More tests => 10;
use Date::Parse qw(strptime str2time);

# RT#48164: Date::Parse unable to set seconds correctly
{
    for my $str ("2008.11.30 22:35 CET", "2008-11-30 22:35 CET") {
        my @t = strptime($str);
        my $t = join ":", map { defined($_) ? $_ : "-" } @t;
        is($t, "-:35:22:30:10:108:3600:20", "RT#48164: seconds parsing for '$str'");
    }
}

# RT#51664: Change in str2time behaviour between 1.16 and 1.19
{
    ok(str2time('16 Oct 09') >= 0, "RT#51664: '16 Oct 09' parses to non-negative time");
}

# RT#84075: Date::Parse::str2time maps date in 1963 to 2063
{
    my $this_year = 1900 + (gmtime(time))[5];
    my $target_year = $this_year - 50;
    my $date = "$target_year-01-01 00:00:00 UTC";
    my $time = str2time($date);
    my $year_parsed_as = 1900 + (gmtime($time))[5];
    is($year_parsed_as, $target_year, "RT#84075: year $target_year not mapped to future");
}

# RT#53413: Date::Parse mangling 4-digit year dates
# str2time() must not map 4-digit pre-1970 years to future dates.
# The root cause: strptime() extracts a 2-digit year (subtracting 1900 from
# the 4-digit value) and stores the century separately. str2time() must
# reconstruct the full 4-digit year before calling Time::Local, whose
# 2-digit-year windowing would otherwise map e.g. year 24 (from 1924) to 2024.
{
    my @cases = (
        [ "1924-01-15 00:00:00 UTC", 1924, "year 1924 does not map to 2024" ],
        [ "1963-06-16 00:00:00 UTC", 1963, "year 1963 does not map to 2063" ],
        [ "1966-01-01 00:00:00 UTC", 1966, "year 1966 does not map to future" ],
        [ "1901-12-17 00:00:00 UTC", 1901, "year 1901 parses correctly" ],
        [ "1935-01-24 00:00:00 UTC", 1935, "year 1935 does not map to future" ],
    );

    for my $c (@cases) {
        my ($date, $expected_year, $desc) = @$c;
        my $t = str2time($date);
        if (!defined $t) {
            fail("RT#53413: str2time('$date') returned undef");
            next;
        }
        my $parsed_year = 1900 + (gmtime($t))[5];
        is($parsed_year, $expected_year, "RT#53413: $desc");
    }

    # strptime() must return year as offset from 1900 with century captured separately
    my @t = strptime("1924-01-15 00:00:00 UTC");
    is($t[5], 24,  "RT#53413: strptime year field is 24 for 1924 (offset from 1900)");
    is($t[7], 19,  "RT#53413: strptime century field is 19 for 1924");
}

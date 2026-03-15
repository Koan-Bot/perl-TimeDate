use strict;
use warnings;
use Test::More tests => 50;
use Date::Format qw(time2str strftime);
use Date::Parse qw(strptime str2time);

# RT#45067: Date::Format with %z gives wrong results for half-hour timezones
{
    for my $zone (qw(-0430 -0445)) {
        my $zone_str = time2str("%Z %z", time, $zone);
        is($zone_str, "$zone $zone", "RT#45067: half-hour timezone $zone");
    }
}

# RT#48164: Date::Parse unable to set seconds correctly
{
    for my $str ("2008.11.30 22:35 CET", "2008-11-30 22:35 CET") {
        my @t = strptime($str);
        my $t = join ":", map { defined($_) ? $_ : "-" } @t;
        is($t, "-:35:22:30:10:108:3600:20", "RT#48164: seconds parsing for '$str'");
    }
}

# RT#17396: Parse error for french date with 'mars' (march) as month
{
    use Date::Language;
    my $dateP     = Date::Language->new('French');
    my $timestamp = $dateP->str2time('4 mars 2005');
    my ($ss, $mm, $hh, $day, $month, $year, $zone) = localtime $timestamp;
    $month++;
    $year += 1900;
    my $date = "$day/$month/$year";
    is($date, "4/3/2005", "RT#17396: French 'mars' parsed correctly");
}

# RT#52387: seconds since the Epoch, UCT
{
    my $time = time;
    my @lt = localtime($time);
    is(strftime("%s", @lt), $time, "RT#52387: strftime %s returns epoch");
    is(time2str("%s", $time), $time, "RT#52387: time2str %s returns epoch");
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

# RT#70650: Date::Parse should not parse ludicrous strings like bare numbers
{
    ok(!defined str2time('1'),      "RT#70650: str2time('1') returns undef");
    ok(!defined str2time('+01'),    "RT#70650: str2time('+01') returns undef");
    ok(!defined str2time('+0500'),  "RT#70650: str2time('+0500') returns undef");
}

# IST (Indian Standard Time) should resolve to UTC+5:30
{
    use Time::Zone;

    my $offset = tz_offset("ist");
    is($offset, 19800, "tz_offset('ist') returns 19800 (UTC+5:30)");

    my $time = str2time("2024-01-15 12:00:00 IST");
    my $time_utc = str2time("2024-01-15 06:30:00 UTC");
    is($time, $time_utc, "IST date parses to correct UTC equivalent");
}

# RT#76968: tz2zone("America/Chicago") doesn't work
# IANA timezone names like "America/Chicago" should be usable with tz_offset
{
    use Time::Zone;
    use POSIX qw();

  SKIP: {
        # Verify that the system supports IANA timezone names
        my $has_iana = eval {
            local $ENV{TZ} = "Etc/UTC";
            POSIX::tzset();
            my ($std) = POSIX::tzname();
            defined $std && $std =~ /UTC|GMT/i;
        };
        skip "system does not support IANA timezone names", 6 unless $has_iana;

        # tz_offset with IANA name "Etc/UTC" must return 0 (deterministic)
        my $utc_offset = tz_offset("Etc/UTC");
        is($utc_offset, 0, "RT#76968: tz_offset('Etc/UTC') returns 0");

        # tz2zone with IANA name "Etc/UTC" must return a valid abbreviation
        my $utc_name = tz2zone("Etc/UTC", undef, 0);
        ok(defined $utc_name && length($utc_name) > 0,
            "RT#76968: tz2zone('Etc/UTC') returns a defined non-empty name");

        # tz_offset(tz2zone(IANA_name)) must return defined — the key failure in the bug
        my $chicago_abbr = tz2zone("America/New_York", undef, 0);
        ok(defined $chicago_abbr,
            "RT#76968: tz2zone('America/New_York', dst=0) returns defined");

        my $chicago_offset = tz_offset($chicago_abbr);
        ok(defined $chicago_offset,
            "RT#76968: tz_offset(tz2zone('America/New_York')) returns defined");

        # tz_offset of IANA name directly must return defined
        my $ny_offset = tz_offset("America/New_York");
        ok(defined $ny_offset,
            "RT#76968: tz_offset('America/New_York') returns defined");

        # tz_offset("Etc/UTC") via tz2zone round-trip
        my $utc_abbr = tz2zone("Etc/UTC", undef, 0);
        my $utc_offset2 = tz_offset($utc_abbr);
        is($utc_offset2, 0,
            "RT#76968: tz_offset(tz2zone('Etc/UTC')) returns 0");
    }
}

# RT#53413 / RT#105031 (GH#17): Date::Parse mangling 4-digit year dates
# str2time() must not map 4-digit pre-1970 years to future dates.
# The root cause: strptime() extracts a 2-digit year (subtracting 1900 from
# the 4-digit value) and stores the century separately. str2time() must
# reconstruct the full 4-digit year before calling Time::Local, whose
# 2-digit-year windowing would otherwise map e.g. year 24 (from 1924) to 2024,
# or year 65 (from 1965) to 2065.
{
    my @cases = (
        [ "1924-01-15 00:00:00 UTC", 1924, "year 1924 does not map to 2024" ],
        [ "1963-06-16 00:00:00 UTC", 1963, "year 1963 does not map to 2063" ],
        [ "1965-12-31 00:00:00 UTC", 1965, "year 1965 does not map to 2065" ],
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

# RT#59298: tz_name() reports incorrect offset for unknown timezone names
# The offset passed is in seconds, but the old code treated it as minutes,
# producing e.g. "+33000" for IST (+5:30) instead of "+0530".
# Also: negative fractional-hour offsets must format correctly.
{
    use Time::Zone;
    # UTC+5:30 = 19800s — not in the Zone table when the bug was filed
    is(tz_name(19800, 0), "ist",   "RT#59298: tz_name(19800) returns ist (UTC+5:30 is now in table)");
    # An offset not in the table: UTC+1:30 = 5400s → "+0130" (was "+9000" before fix)
    is(tz_name(5400, 0),  "+0130", "RT#59298: tz_name(5400) returns +0130, not +9000");
    # Negative fractional offset: UTC-2:30 = -9000s → "-0230"
    is(tz_name(-9000, 0), "-0230", "RT#59298: tz_name(-9000) returns -0230 (UTC-2:30)");
}

# RT#82271: tz_name should return CEST (not MEST) for Central European Summer Time
# CEST (Central European Summer Time) is the standard/preferred abbreviation;
# MEST (Middle European Summer Time) is a German-influenced variant.
{
    use Time::Zone;
    is(tz_name(7200, 1),  "cest", "RT#82271: tz_name(+2h, dst=1) returns cest not mest");
    is(tz_offset("MEST"), 7200,   "RT#82271: tz_offset(MEST) still works for backward compat");
}

# RT#92611: str2time wrong year when no year specified for a future month
# Parsing "1 Feb" in January should give the current year, not last year.
{
    my @lt = localtime(time);
    my $cur_month = $lt[4];            # 0-11
    my $cur_year  = 1900 + $lt[5];
    my @months    = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

  SKIP: {
        # December → January crosses a year boundary; the heuristic is ambiguous there.
        skip "RT#92611: skipping in December (year-boundary edge case)", 1
            if $cur_month == 11;

        my $future_month = $cur_month + 1;    # guaranteed valid (0-10 → 1-11)
        my $future_name  = $months[$future_month];
        my $t = str2time("15 $future_name");
        my $got_year = 1900 + (localtime($t))[5];
        is($got_year, $cur_year,
            "RT#92611: '15 $future_name' with no year resolves to current year $cur_year");
    }
}

# RT#53267 / GH#2: strptime('MONTH YEAR') puts year into $day
# 'December 2009' should give month=11, year=109 (2009-1900), day=undef
# not month=11, day=2009, year=undef
{
    my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('December 2009');
    is($month, 11,  "RT#53267: 'December 2009' gives month=11 (December)");
    ok(!defined($day), "RT#53267: 'December 2009' gives day=undef (not 2009)");
    is($year,  109, "RT#53267: 'December 2009' gives year=109 (2009-1900)");

    # 4-digit year in same position
    ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('Jan 1995');
    is($month, 0,   "RT#53267: 'Jan 1995' gives month=0 (January)");
    ok(!defined($day), "RT#53267: 'Jan 1995' gives day=undef");
    is($year,  95,  "RT#53267: 'Jan 1995' gives year=95 (1995-1900)");

    # normal 'MONTH DAY' must still work
    ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime('December 25');
    is($month, 11, "RT#53267: 'December 25' still gives month=11");
    is($day,   25, "RT#53267: 'December 25' still gives day=25");
}

# RT#125949: strptime returns negative month for certain inputs
{
    my @t = strptime("199001");
    my $month = $t[4];
    ok(!defined($month) || $month >= 0,
        "RT#125949: strptime('199001') month is not negative");

    my $t = str2time("199001");
    ok(!defined($t),
        "RT#125949: str2time('199001') returns undef for ambiguous 6-digit input");
}

# RT#106105: Date::Parse inconsistent year handling for years before 1901
# strptime() must return year as offset from 1900 consistently, regardless of
# whether the year is before or after 1900.  Previously, years <= 1900 were
# returned as the full 4-digit year rather than (year - 1900).
{
    # 1901: already worked — year=1, century=19
    my @t1901 = strptime('1 Jan 1901 12:00');
    is($t1901[5], 1,  "RT#106105: strptime year field is 1 for 1901 (offset from 1900)");
    is($t1901[7], 19, "RT#106105: strptime century field is 19 for 1901");

    # 1900: boundary — year=0, century=19
    my @t1900 = strptime('1 Jan 1900 12:00');
    is($t1900[5], 0,  "RT#106105: strptime year field is 0 for 1900 (offset from 1900)");
    is($t1900[7], 19, "RT#106105: strptime century field is 19 for 1900");

    # 1899: previously broken — returned 1899 instead of -1
    my @t1899 = strptime('1 Jan 1899 12:00');
    is($t1899[5], -1, "RT#106105: strptime year field is -1 for 1899 (offset from 1900)");
    is($t1899[7], 18, "RT#106105: strptime century field is 18 for 1899");
}

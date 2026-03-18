# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Run all tests (preferred)
prove -l t/

# Run a single test
prove -l t/format.t

# Run a single test verbosely
prove -lv t/lang-data.t

# Dist::Zilla build (generates Makefile.PL, README.md)
dzil build --no-tgz

# Run author/release tests
dzil test --all
```

## Architecture

TimeDate is a Perl distribution providing date parsing, formatting, and timezone handling. No external CPAN dependencies — core Perl only.

### Module relationships

```
Date::Format          - exports time2str(), strftime(), ctime(), asctime()
  └─ delegates to Date::Format::Generic  - core formatting engine (format_* methods, _subs() template engine)

Date::Parse           - exports str2time(), strptime()
  └─ uses Time::Zone  - timezone name/offset lookups

Date::Language        - base class, inherits from Date::Format::Generic
  ├─ factory: new('German') → loads Date::Language::German
  ├─ AUTOLOAD generates strptime parsers lazily via Date::Parse::gen_parser()
  ├─ _build_lookups() builds %MoY/%DoW reverse-lookup hashes for all language modules
  └─ 35 language modules (lib/Date/Language/*.pm)

TimeDate.pm           - empty wrapper for PAUSE ownership; holds distribution-level POD
```

### Language modules

Each language module declares `@DoW`, `@MoY`, `@DoWs`, `@MoYs`, `@AMPM`, `@Dsuf` arrays, calls `Date::Language::_build_lookups()`, and defines 6 format subs (`format_a/A/b/B/h/p`) that reference per-package variables. Some languages (Czech, Hungarian, Russian, Turkish) have additional overrides.

### Versioning

- `[OurPkgVersion]` injects `$VERSION` at build time — source files use `# VERSION: generated` comments
- `[Git::NextVersion]` bumps version from git tags
- `[PodWeaver]` processes `# ABSTRACT:` comments into POD

## Encoding

Language modules use either `use utf8` with native Unicode characters (German, French, Danish, etc.) or explicit byte escapes for legacy encodings (Russian KOI8-R, Chinese GB2312). Turkish uses `use utf8`. Do not mix approaches within a single file.

## Adding Timezones

Timezone abbreviations live in `lib/Time/Zone.pm` in two lookup tables: `@Zone` (standard) and `@dstZone` (daylight saving). Add entries as `"abbrev" => offset_in_seconds` pairs. Offsets use arithmetic like `+3*3600` or `-3*3600-1800` (for half-hour zones). Abbreviation keys must be lowercase.

## Test Naming Conventions

- `t/cpanrt-*.t` — regression tests for CPAN RT bugs
- `t/rt*.t` — additional RT bug regressions (older naming)
- `t/gh*.t` — regression tests for GitHub issues
- `t/format.t`, `t/date.t`, `t/zone.t`, `t/lang.t` — core functionality tests
- `t/lang-data.t`, `t/lang-encoding.t` — language module validation

## CI

GitHub Actions (`.github/workflows/ci.yml`) tests on Linux (Perl 5.8+), macOS, and Windows with author testing enabled. Minimum target Perl is 5.010 (enforced by `Test::MinimumVersion` in dist.ini).

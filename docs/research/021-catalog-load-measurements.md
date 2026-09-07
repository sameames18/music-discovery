---
ticket: 021
title: Prove the Catalog loader and measure its footprint
branch: (worked directly; loader committed to master via scripts/ingest/)
date: 2026-09-07
status: measured on Sam's machine, D: drive, Docker Desktop / Postgres 16
---

# Catalog loader: measured footprint

Real numbers for [ticket 021](https://github.com/sameames18/music-discovery/issues/21),
replacing the estimates in [ticket 007](https://github.com/sameames18/music-discovery/issues/7)
and closing the one figure [ticket 002](../../docs/research/002-musicbrainz-catalog.md)
left unverified (genre coverage on release groups). Loader source: [scripts/ingest/](../../scripts/ingest/).
Export used: `20260905-002519` (2026-09-05 full export).

## Wall-clock per stage

| Stage | Time | Notes |
|---|---|---|
| Download (`mbdump.tar.bz2` 7.0 GB + `mbdump-derived.tar.bz2` 491 MB) | ~12 min of actual transfer at 15–21 MB/s | Session was interrupted once mid-download by an unrelated process exit; resumed cleanly via `curl -C -`. Total wall-clock spanned longer than transfer time because of that gap — not representative of a clean run. |
| Extract (~23 needed tables from both archives) | 115 min | Single-threaded bzip2 (`tar -xjf`); no parallel bzip2 decompressor (`lbzip2`/`pbzip2`) was available on this machine. This is the single biggest stage and the best target for speedup — installing `lbzip2` would parallelize it across cores. |
| Load (COPY into `mb_raw` staging, 27 tables) | 79 min (4,721s summed) | Dominated by `track` (57.7M rows, 1,245s) and `recording` (40.1M rows, 1,222s). Per-table timings in [scripts/ingest output](#per-table-load-timings) below. |
| Transform (`mb_raw` → `catalog` schema) | 188 min as run, including a dead-end | See **First attempt hit a real bug** below — the committed script (`05_transform.sql`) is already fixed and should run considerably faster than this number; it wasn't re-timed clean end-to-end after the fix to avoid a third multi-hour pass. |

**Total, as actually run: ~6.5 hours**, most of it unattended background time (extraction and load need no supervision once started), with one debugging detour in the middle.

### First attempt hit a real bug — worth recording

The first version of the `edition_date` computation (first-release-date per Edition, needed to pick the Canonical Edition) used a `LEFT JOIN LATERAL` correlated subquery against `release_country` — a per-row scan of a 13M-row table, once for each of ~3.7M kept Editions. That's an O(N×M) plan; it was still running after 55 minutes with no end in sight, so it was cancelled. Root cause: no index existed yet on `mb_raw.release_country(release)`, and more fundamentally, a correlated-subquery-per-row shape doesn't fix that even with an index — an aggregate pass does. Rewrote it as a `GROUP BY`-then-join (single scan) and added indexes on the staging tables' join/filter columns that later stages also lean on. `catalog.album` (2.89M rows) and `catalog.edition` (3.69M rows) had already completed successfully before the bug hit and didn't need to be rebuilt.

**Lesson for future loads**: staging tables load with zero indexes (correct, for COPY speed), but anything doing a per-row lookup against a multi-million-row staging table needs either an aggregate reshape or an index added first. Plain `JOIN`/`IN` patterns against staging tables were fine throughout (Postgres picks a hash join); the one `LATERAL` pattern was the only trap.

## Row counts, final Catalog schema

| Table | Rows |
|---|---|
| Album | 2,894,298 |
| Edition | 3,690,588 (3,560,385 Official + 130,203 no-status fallback, covering 128,496 Albums with no Official Edition at all) |
| Canonical Edition | 2,787,861 |
| Edition track listing (`edition_track`) | 47,988,203 |
| Recording (our "Track") | 32,984,596 |
| Artist | 1,460,430 |
| Participant | 13,079,483 |
| Genre tag assignment | 5,459,571 |
| ISRC → Album lookup | 9,938,915 |
| Barcode → Album lookup | 1,640,846 |
| Discogs URL link | 1,642,848 |

**106,437 Albums (3.7% of 2,894,298) have no kept Edition at all** — every release under that release group is a status ticket 007 excludes outright (Bootleg, Promotion, Withdrawn, etc., not the no-status case, which has its own fallback). Worth a decision later: those Albums are still searchable/CC0-valid as release groups, but the product can't show a track list for them; whether they're worth keeping in the Catalog at all, or should be excluded from the Candidate pool specifically, isn't decided here.

## The two numbers ticket 002 couldn't verify

**Share of Albums with ≥1 genre tag (not any folksonomy tag): 62.3%** (1,803,377 of 2,894,298). This is a real measurement, not the "under 1% of distinct tag names are genres, exact release-group coverage unknown" bound ticket 002 left. It's dramatically higher than ticket 002's cautious framing suggested, because coverage concentrates on exactly the Album/EP subset with an Official Edition — the same slice of MusicBrainz that has the most community attention.

**Per-Album genre count distribution:**

| Genre count | Albums | Genre count | Albums |
|---|---|---|---|
| 1 | 505,592 | 10 | 11,057 |
| 2 | 447,171 | 11 | 8,178 |
| 3 | 322,930 | 12 | 4,403 |
| 4 | 204,990 | 13 | 3,191 |
| 5 | 120,848 | 14–20 | ~7,000 combined |
| 6 | 71,282 | 21–116 | long tail, a few thousand total |
| 7 | 42,689 | | |
| 8 | 31,669 | | |
| 9 | 18,612 | | |

Median is 2 genres per tagged Album; the distribution drops off fast after ~5. A handful of Albums (116 genre tags on one) are folksonomy outliers, almost certainly tagging noise rather than signal — worth a sanity cap if genre tags become an Engine input (ticket 012) or a Tag Axis (ticket 014).

**Share of Albums with a Canonical Edition that has a track list: 99.9%** (2,785,337 of 2,787,861). Once an Album has any kept Edition at all, it almost always has tracks — the 0.1% gap is noise (data-entry edge cases in MusicBrainz), not a real ingestion gap.

## Disk footprint

| Item | Size |
|---|---|
| `catalog` schema (final, what the product actually queries) | **14 GB** |
| `mb_raw` schema (staging, droppable after transform) | 20 GB |
| Whole database, both schemas present | 34 GB |

Ticket 007 estimated 20–30 GB for "Catalog loaded with indexes." **The real number is 14 GB — under the low end of the estimate.** If a production reload follows ticket 007's shadow-table-then-swap pattern (load staging fresh, transform, swap, drop old + staging), peak disk during a reload is staging (20 GB) + old catalog (14 GB) + new catalog before swap (14 GB) ≈ 48 GB, plus the 7.5 GB dump on disk during extraction — comfortably under the 60–70 GB peak ticket 007 estimated, and the 80–100 GB provisioning figure has more headroom than assumed. Worth revising ticket 007's cost line down, or leaving the extra headroom as safety margin — both defensible; a Sam decision, not this ticket's.

Largest individual tables: `mb_raw.track` (6.9 GB raw) and `catalog.edition_track` (5.7 GB, the filtered track listing) dominate — expected, since Tracks/Editions are the highest-cardinality thing in the schema. `catalog.recording` (4.2 GB, 33M rows) is the next biggest; its total size including indexes is slightly larger than the equivalent unindexed `mb_raw.recording` (4.1 GB, 40M rows) despite having fewer rows, because the raw staging table has no indexes at all and the final table has a primary key plus a unique index on MBID.

## What's simplified from ticket 007's full description

Recorded in [scripts/ingest/README.md](../../scripts/ingest/README.md):

- **Participant role** is `link_type.name` only — instrument/vocal specifics from `link_attribute`/`link_attribute_type` (e.g. "guitar" on a "performer" credit) aren't loaded. A decision for ticket 014 (Tag model) before Participant becomes a real Tag Axis.
- **First-release date** is computed per Edition only (needed for Canonical Edition selection), not precomputed per Album via the NC `release_group_meta` table — deliberately avoided per ticket 007's own note that this is avoidable.
- Indexes are the minimum needed for the transform itself and the lookup tables (ISRC, barcode); no query-pattern tuning yet, since there are no real read paths to tune against.

## Per-table load timings

```
table,seconds,rows
release_group,56,4499428
release_group_primary_type,1,5
release_group_secondary_type,1,12
release_group_secondary_type_join,5,971648
release,99,5753668
release_status,1,7
release_country,65,13260256
release_unknown_country,2,473625
medium,91,6315744
track,1245,57704258
recording,1222,40076669
isrc,156,6341218
artist,172,2976554
artist_credit,164,3854075
artist_credit_name,133,7174298
l_artist_release,51,1614425
l_artist_release_group,0,17042
l_artist_recording,283,18839430
link,24,1145106
link_type,1,697
genre,0,2195
url,681,21524684
l_release_group_url,21,1028160
l_release_url,164,10521384
release_group_tag,67,5010287
artist_tag,13,758910
tag,3,243910
```

(Raw row counts above are `mb_raw` staging, unfiltered — larger than the final `catalog` schema counts, which apply the Album/EP + Official Edition + kept-recordings filters.)

## Not measured here

- **Reload wall-clock** (the twice-weekly refresh ticket 007 describes) — this was a cold first load into an empty database; a shadow-table swap reload wasn't exercised.
- **Cover art pre-warming** (~2.5 days at 10 req/s per ticket 007's estimate) — out of scope for this ticket, which is the Catalog tables only.
- **A parallel-bzip2 extraction time** — `lbzip2`/`pbzip2` weren't installed; the 115-minute extraction figure is a single-thread upper bound, not the best achievable on this hardware.

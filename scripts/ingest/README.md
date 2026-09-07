# Catalog loader

Loads MusicBrainz's CC0 core dump and BY-NC-SA derived dump into our own
Postgres schema, per [ticket 007](https://github.com/sameames18/music-discovery/issues/7)'s
decisions and the [CONTEXT.md](../../CONTEXT.md) glossary. Built and measured
under [ticket 021](https://github.com/sameames18/music-discovery/issues/21);
numbers are in [docs/research/021-catalog-load-measurements.md](../../docs/research/021-catalog-load-measurements.md).

## Pipeline

1. `01_download.sh <dumps-dir> [export-dir]` — downloads `mbdump.tar.bz2`
   (~7 GB, CC0) and `mbdump-derived.tar.bz2` (~490 MB, BY-NC-SA) from
   data.metabrainz.org.
2. `02_extract.sh <dumps-dir> <extracted-dir>` — extracts only the ~23
   tables our subset needs (bzip2 is single-threaded and sequential, so
   this reads the whole compressed stream regardless, but skips writing
   everything else to disk).
3. `03_staging_schema.sql` — creates the `mb_raw` schema: raw MusicBrainz
   tables, column-for-column matching `admin/sql/CreateTables.sql`, no
   constraints (this is a bulk load target, not a live-edited database).
4. `04_load.sh <container> <db> <output-dir>` — COPYs each extracted
   table into `mb_raw`, timing each and writing `load_timings.csv`.
5. `05_transform.sql` — builds the `catalog` schema (Album, Edition,
   Track/Recording, Artist, Participant, genre_tag, isrc_lookup,
   barcode_lookup, discogs_link) from `mb_raw`, applying the Album/EP
   filter, Official-Edition-with-fallback rule, Canonical Edition pick,
   and the three-level Participant collapse.

## Running it

```bash
# Everything under one working directory, e.g. a drive with headroom
# (the loaded Catalog + a live reload needs ~2x its own size free).
WORK=/d/music-discovery-catalog

./01_download.sh "$WORK/dumps"
./02_extract.sh "$WORK/dumps" "$WORK/extracted"

docker run -d --name musicdiscovery-pg \
  -e POSTGRES_PASSWORD=musicdiscovery -e POSTGRES_DB=musicdiscovery \
  -v "$WORK/pgdata:/var/lib/postgresql/data" \
  -v "$WORK/extracted:/extracted" \
  -p 55432:5432 --shm-size=1g postgres:16

docker exec -i musicdiscovery-pg psql -U postgres -d musicdiscovery < 03_staging_schema.sql
./04_load.sh musicdiscovery-pg musicdiscovery "$WORK"
docker exec -i musicdiscovery-pg psql -U postgres -d musicdiscovery < 05_transform.sql
```

## What's simplified versus ticket 007's full description

- **Participant role** is `link_type.name` only (e.g. "producer",
  "mixer") — `link_attribute`/`link_attribute_type` (instrument and
  vocal specifics, e.g. "guitar" on a "performer" credit) are not loaded.
  Ticket 014 (Tag model) should revisit whether that detail is needed
  before Participant becomes a real Tag Axis.
- **First-release date** is computed per **Edition** (needed to pick the
  Canonical Edition) from `release_country`/`release_unknown_country`,
  not precomputed per Album the way `release_group_meta` does it — we
  don't load that NC table at all (ticket 007 flagged it as avoidable).
- No indexes beyond what Canonical Edition selection and the lookup
  tables need are added yet; a real load would tune these against actual
  query patterns once the site's read paths exist.

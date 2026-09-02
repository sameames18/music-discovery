---
ticket: 002
title: MusicBrainz and Discogs as the Catalog source
branch: research/musicbrainz
date: 2026-09-02
status: findings (no strategy recommendation; that is ticket 007)
---

# MusicBrainz and Discogs as the Catalog source

Findings for [ticket 002](../../wayfinder/tickets/002-research-musicbrainz-catalog.md). Vocabulary is [CONTEXT.md](../../CONTEXT.md): Album = MusicBrainz *release group*, Edition = MusicBrainz *release*, Participant = anyone credited via artist credits or relationships. All numbers are from the primary source linked next to them; MusicBrainz statistics were read on 2026-09-02 and the dump listing is the 2026-08-29 full export. Section 3.2 (genre coverage on release groups) has no published statistic; the doc gives the published bounds, marks the exact figure unverified, and states the one-pass method for computing it from the derived dump.

## Key numbers

| Fact | Value | Source |
|---|---|---|
| Release groups (Albums) | 4,493,395 | [musicbrainz.org/statistics](https://musicbrainz.org/statistics) |
| Releases (Editions) | 5,745,901 | same |
| Artists | 2,974,025 | same |
| Recordings / Tracks | 40,039,901 / 57,648,127 | same |
| Genres in the fixed list | 2,194 (API) / 2,195 (stats page) | [/ws/2/genre/all?fmt=txt](https://musicbrainz.org/ws/2/genre/all?fmt=txt), [statistics](https://musicbrainz.org/statistics) |
| Core dump `mbdump.tar.bz2` | 7 GB compressed, CC0 | [fullexport/20260829-002439](https://data.metabrainz.org/pub/musicbrainz/data/fullexport/20260829-002439/) |
| Tags/ratings dump `mbdump-derived.tar.bz2` | 490 MB compressed, CC BY-NC-SA 3.0 | same + [Download doc](https://musicbrainz.org/doc/MusicBrainz_Database/Download) |
| Full export cadence | twice a week, Wednesdays and Saturdays | [metabrainz.org/datasets/postgres-dumps](https://metabrainz.org/datasets/postgres-dumps) |
| Live Data Feed (replication) | hourly packets, free token for non-commercial, packets are CC BY-NC-SA | [Live_Data_Feed](https://musicbrainz.org/doc/Live_Data_Feed), [Data_License](https://musicbrainz.org/doc/About/Data_License) |
| Loaded Postgres footprint (no search) | "60GB+ of free disk space" (server setup doc); "100 GB" disk, 4 GB RAM, 2 CPU threads (musicbrainz-docker, db-only) | [Server/Setup](https://musicbrainz.org/doc/MusicBrainz_Server/Setup), [musicbrainz-docker README](https://github.com/metabrainz/musicbrainz-docker) |
| With Solr search indexes | 350 GB disk, 16 GB RAM, 16 threads; index build 4.5 h or 60 GB download | [musicbrainz-docker README](https://github.com/metabrainz/musicbrainz-docker) |
| API rate limit | 1 request/second per IP; 503 above it | [Rate_Limiting](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting), [MusicBrainz_API](https://musicbrainz.org/doc/MusicBrainz_API) |
| Releases with cover art | 3,867,070 (67.3%); release groups with art 3,102,167 | [statistics/coverart](https://musicbrainz.org/statistics/coverart) |
| Cover Art Archive API rate limit | none ("There are currently no rate limiting rules in place") | [Cover_Art_Archive/API](https://musicbrainz.org/doc/Cover_Art_Archive/API) |
| Discogs API rate limit | 60/min authenticated, 25/min unauthenticated; search requires auth | [discogs.com/developers](https://www.discogs.com/developers/) |
| Discogs data retention rule | may not display Content older than 6 hours; may not cache "longer than is necessary" | [API Terms of Use](https://support.discogs.com/hc/en-us/articles/360009334593-API-Terms-of-Use) |
| Discogs monthly dump (2026-09-01) | releases 10.5 GB gz, masters 596.8 MB, artists 474.1 MB, labels 86.4 MB; CC0 | [data.discogs.com](https://data.discogs.com/) |

## 1. Full-dump route

### 1.1 What is in the export and how big it is

The 2026-08-29 full export ([directory listing](https://data.metabrainz.org/pub/musicbrainz/data/fullexport/20260829-002439/)):

| File | Size | Contents ([Download doc](https://musicbrainz.org/doc/MusicBrainz_Database/Download)) | License (same doc) |
|---|---|---|---|
| `mbdump.tar.bz2` | 7 GB | "The core MusicBrainz database, including the tables for Artist, Release, Recording, etc." | CC0 |
| `mbdump-derived.tar.bz2` | 490 MB | "annotations, user ratings, user tags, and search indexes" | CC BY-NC-SA 3.0 |
| `mbdump-edit.tar.bz2` | 15 GB | complete edit history | CC BY-NC-SA 3.0 |
| `mbdump-editor.tar.bz2` | 80 MB | non-personal editor data | CC BY-NC-SA 3.0 |
| `mbdump-cover-art-archive.tar.bz2` | 158 MB | "Connections between MusicBrainz and the Cover Art Archive" (index only, no images) | CC BY-NC-SA 3.0 |
| `mbdump-event-art-archive.tar.bz2` | 526 KB | same for event art | CC BY-NC-SA 3.0 |
| `mbdump-stats.tar.bz2` | 115 MB | site statistics | CC BY-NC-SA 3.0 |
| `mbdump-cdstubs.tar.bz2` | 62 MB | anonymous CD stubs, "untrusted" | CC0 |
| `mbdump-documentation.tar.bz2` | 26 KB | relationship docs | (not stated) |
| `mbdump-wikidocs.tar.bz2` | 7.3 KB | wiki revision pointers | (not stated) |

For the Catalog only `mbdump` (7 GB) and `mbdump-derived` (490 MB) matter; everything else can be skipped. Full exports are produced "Twice a week, Wednesdays and Saturdays" ([postgres-dumps](https://metabrainz.org/datasets/postgres-dumps)); the listing shows `20260826` and `20260829`, consistent with that.

Loaded size: the MusicBrainz Server setup doc says "60GB+ of free disk space" for a full import ([Server/Setup](https://musicbrainz.org/doc/MusicBrainz_Server/Setup)); the official Docker mirror says "Disk Space: 350 GB (or 100 without indexed search)", "RAM: 16 GB (or 4 without indexed search)", "CPU: 16 threads (or 2 without indexed search)" ([musicbrainz-docker README](https://github.com/metabrainz/musicbrainz-docker)). The 100 GB figure includes room for the downloaded dumps and Postgres working space; the 60 GB figure is the older server-doc number. Neither source states an import duration (the docker README carries a `TODO: estimate replication time per missing day`).

### 1.2 Which tables carry what

Table-to-dump membership is defined in [`lib/MusicBrainz/Server/Constants.pm`](https://github.com/metabrainz/musicbrainz-server/blob/master/lib/MusicBrainz/Server/Constants.pm) (`@CORE_TABLE_LIST`, `@DERIVED_TABLE_LIST`, `@CAA_TABLE_LIST`) and used by [`admin/ExportAllTables`](https://github.com/metabrainz/musicbrainz-server/blob/master/admin/ExportAllTables). Column definitions are in [`admin/sql/CreateTables.sql`](https://github.com/metabrainz/musicbrainz-server/blob/master/admin/sql/CreateTables.sql); schema description in [MusicBrainz_Database/Schema](https://musicbrainz.org/doc/MusicBrainz_Database/Schema) (schema version 31).

| Our term | MusicBrainz tables | Dump | Notes |
|---|---|---|---|
| Album | `release_group`, `release_group_primary_type`, `release_group_secondary_type`, `release_group_secondary_type_join` | core (CC0) | Primary types: Album, Single, EP, Broadcast, Other; secondary: Compilation, Soundtrack, Spokenword, Interview, Audiobook, Audio drama, Live, Remix, DJ-mix, Mixtape/Street, Demo, Field recording ([Release_Group/Type](https://musicbrainz.org/doc/Release_Group/Type)). Filtering to primary type Album is how you get "albums". |
| Album first-release date | `release_group_meta` (`first_release_date_year/month/day`, `release_count`, `rating`, `rating_count`) | **derived (NC)** | The precomputed first date and MusicBrainz's own 0–100 rating live in the NC dump. The date is recomputable from core `release_country` / `release_unknown_country`. |
| Edition | `release`, `release_status`, `release_packaging`, `medium`, `medium_format`, `release_label`, `label` | core | |
| Edition country and date | `release_country (release, country, date_year, date_month, date_day)`, `release_unknown_country (release, date_year, date_month, date_day)` | core | One row per release event; `country` references `country_area.area` → `area`. |
| Track | `track`, `medium`, `recording`, `isrc` | core | `track` sits on a `medium`; `recording` is the shared audio. Spotify ISRCs match `isrc.isrc` → `recording`. |
| Artist | `artist_credit`, `artist_credit_name (artist_credit, position, artist, name, join_phrase)`, `artist` | core | The credited-as-printed name is `artist_credit_name.name`; the join phrase gives "feat." etc. |
| Participant (non-credit roles) | `l_artist_release`, `l_artist_release_group`, `l_artist_recording`, `link`, `link_type`, `link_attribute`, `link_attribute_credit` | core | Producer, engineer, session player etc. are advanced relationships; role name is `link_type.name`, instrument/vocal specifics are link attributes. |
| Genre list | `genre (id, gid, name, comment)`, `genre_alias` | core (CC0) | The controlled list itself is core data. |
| Tags on Albums | `release_group_tag`, `tag (id, name, ref_count)` | **derived (NC)** | A genre "on" a release group is simply a `release_group_tag` row whose `tag.name` matches a `genre.name`. `release_group_tag.count` is the net vote. `artist_tag`, `release_tag`, `recording_tag` likewise. |
| Cover art index | `cover_art_archive.cover_art`, `cover_art_type`, `release_group_cover_art` | CAA dump (NC) | Only the index; images are on archive.org (section 4). |
| Replication state | `replication_control` | core | One-row table with `current_schema_sequence` and `current_replication_sequence` ([Replication_Mechanics](https://musicbrainz.org/doc/Replication_Mechanics)). |

### 1.3 Licensing, and which of our uses the NC clause touches

- Core data: "licensed under the CC0, which is effectively placing the data into the Public Domain" ([Data_License](https://musicbrainz.org/doc/About/Data_License)).
- Supplementary data: "user submitted annotations, tags (including genre associations) and ratings", plus statistics, search indexes, edit history and editor data, are "released under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 license" ([MusicBrainz_Database](https://musicbrainz.org/doc/MusicBrainz_Database)).
- Replication: "The Live Data Feed replication packets are licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 license" ([Data_License](https://musicbrainz.org/doc/About/Data_License)). This applies to the packet as a whole, so an hourly-replicated mirror is under NC terms even for core rows; the twice-weekly CC0 dump is the only route that keeps core data unencumbered.
- The NC test in the license: "You may not exercise any of the rights granted to You in Section 3 above in any manner that is primarily intended for or directed toward commercial advantage or private monetary compensation" ([CC BY-NC-SA 3.0 legal code, 4(c)](https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode)). Creative Commons' own guidance: "NonCommercial turns on the use, not the identity of the reuser", and "it is only the primary purpose of the reuse that needs to be considered" ([CC wiki: NonCommercial interpretation](https://wiki.creativecommons.org/wiki/NonCommercial_interpretation)).
- MetaBrainz's own framing: "All of our data is available for commercial licensing"; the supporter page's non-commercial tier is "$0.00/month and up" for "Personal or university assignment user" and says open source developers, small non-profits and research projects "may also qualify"; commercial tiers start at Bronze "$100.00/month+" for "popular mobile apps and small to mid-size start-ups", with a "Stealth Start-Up" tier at $0 ([account-type](https://metabrainz.org/supporters/account-type)). The datasets page says commercial use is "Allowed, but financial support strongly urged, even for CC0 data" ([postgres-dumps](https://metabrainz.org/datasets/postgres-dumps)).

What this means for each use in the map (facts, not a decision):

| Our use | Data | License touched | Practical reading |
|---|---|---|---|
| Catalog: Albums, Editions, Tracks, Artists, Participants, dates, countries, labels | core | CC0 | No constraint. |
| Genre Tags on Albums (the genre Axis; Engine Signal) | `release_group_tag` + `tag` | BY-NC-SA | Usable while the site is non-commercial (no ads, no paid tier, no affiliate revenue). Attribution to MusicBrainz required. ShareAlike: any Tag table we publish that is derived from these rows must itself be BY-NC-SA. |
| Popularity Proxy from MusicBrainz ratings | `release_group_meta.rating`, `rating_count` | BY-NC-SA | Same as above. Weak signal anyway: see 3.3 for coverage. |
| Album first-release date | `release_group_meta.first_release_date_*` | BY-NC-SA | Avoidable: recompute from core `release_country` rows. |
| Cover art lookup | CAA API (live) | no license statement; images "copyrighted by their respective copyright owners" | The NC-licensed CAA *index dump* is not needed if the API is used. |
| Hourly freshness | Live Data Feed | BY-NC-SA on the packets | Touches the whole mirror. Twice-weekly dump reload avoids it. |

If the site ever takes money, the affected pieces are genre Tags, MusicBrainz ratings, and any replication-fed mirror; the fix MetaBrainz offers is a commercial supporter tier, which at $100/month+ is the whole hosting budget in the map's Notes.

### 1.4 Replication (Live Data Feed)

- Mechanism: "downloading replication packets (served from metabrainz.org) at hourly intervals"; a mirror is "never more than about an hour off sync with the main server" ([Live_Data_Feed](https://musicbrainz.org/doc/Live_Data_Feed)). Packets are `replication-[number].tar.bz2` with a `REPLICATION_SEQUENCE` file; applied against the `replication_control` sequence numbers ([Replication_Mechanics](https://musicbrainz.org/doc/Replication_Mechanics)).
- Access: "Non-commercial / personal users may sign up and obtain a free access token for Live Data Feed" at metabrainz.org; "MetaBrainz does not charge for access to the data" but asks commercial users to "support our efforts financially" ([Live_Data_Feed](https://musicbrainz.org/doc/Live_Data_Feed)). Signing up requires an account, which this ticket did not do.
- Schema changes: replication packets can carry schema-sequence bumps; a mirror must upgrade its schema when `current_schema_sequence` changes ([Replication_Mechanics](https://musicbrainz.org/doc/Replication_Mechanics)). The musicbrainz-docker README documents this upgrade path and warns "Search indexes are not included in replication" ([README](https://github.com/metabrainz/musicbrainz-docker)).
- Only relevant if the site needs sub-week freshness. The map already lists "Catalog freshness and new releases" as not-yet-specified.

### 1.5 Tooling to load it

| Tool | What it is | Source |
|---|---|---|
| `musicbrainz-docker` (official) | Compose project: Postgres, MusicBrainz Server, Valkey, Solr, indexer. Has a **database-only mirror** mode (`admin/configure with alt-db-only-mirror`) that skips the website and Solr, with the 100 GB / 4 GB / 2-thread footprint. `createdb.sh -fetch` downloads and loads dumps; replication via `admin/set-replication-token` + `admin/configure add replication-cron` (default cron "every day at 3 am UTC"). Requires Linux/macOS, Docker Compose 2. | [README](https://github.com/metabrainz/musicbrainz-docker) |
| MusicBrainz Server scripts | `./admin/InitDb.pl --createdb --import /tmp/dumps/mbdump*.tar.bz2 --echo`; Perl, needs the full server checkout. | [INSTALL.md](https://github.com/metabrainz/musicbrainz-server/blob/master/INSTALL.md) |
| `mbslave` (AcoustID) | Python: imports dumps into Postgres and syncs replication with a token (`MBSLAVE_MUSICBRAINZ_TOKEN`), no server code; schema versions 24–31 supported, last schema entry 2026-05-11. | [github.com/acoustid/mbslave](https://github.com/acoustid/mbslave) |
| `mbdata` (lalinsky) | SQLAlchemy models for every MusicBrainz table, for Python apps that read a loaded mirror. | [github.com/lalinsky/mbdata](https://github.com/lalinsky/mbdata) |

Dump format: each tar contains one tab-separated file per table under `mbdump/`, in Postgres `COPY` format, plus `COPYING` and `SCHEMA_SEQUENCE`; the derived tar I partially extracted for section 3.2 yielded `mbdump/artist_tag` and `mbdump/recording_tag` as plain TSV (the table names match `@DERIVED_TABLE_LIST`, so `release_group_tag`, `tag` and `release_group_meta` are members of the same tar). Loading a subset of tables with `COPY` into a schema built from `CreateTables.sql` is therefore possible without any MusicBrainz tooling; that is what an application-shaped ingest would do.

### 1.6 Alternative MetaBrainz datasets

- JSON dumps: one `tar.xz` per entity, same cadence as the Postgres dumps (`20260826`, `20260829`): `release-group.tar.xz` 1 GB, `release.tar.xz` 21 GB, `artist.tar.xz` 2 GB, `label.tar.xz` 169 MB, `recording.tar.xz` 32 MB, `work.tar.xz` 644 MB ([json-dumps listing](https://data.metabrainz.org/pub/musicbrainz/data/json-dumps/20260829-001001/)). These are the web-service JSON documents pre-rendered, so an ingest that only needs release groups with artist credits could read the 1 GB file instead of the 7 GB relational dump. Whether the release-group documents include tags/genres was not verified (the datasets page for JSON dumps returned 404).
- Canonical MusicBrainz data: "one single record for each set of mostly equivalent releases and recordings", zstd CSV, CC0, "Twice a month, on the 1st and 15th" ([derived-dumps](https://metabrainz.org/datasets/derived-dumps)). Built by ListenBrainz for listen-to-MBID resolution (section 6.1); relevant to Import matching, not to the Catalog itself.

## 2. API route

- Base URL `https://musicbrainz.org/ws/2/`; entities include `release-group`, `release`, `artist`, `genre`; JSON via `fmt=json` or `Accept: application/json` ([MusicBrainz_API](https://musicbrainz.org/doc/MusicBrainz_API)).
- Rate limit: "All users of the API must ensure that each of their client applications never make more than ONE call per second" ([MusicBrainz_API](https://musicbrainz.org/doc/MusicBrainz_API)). Per IP "(on average) 1 request per second"; global "300 requests each second"; over the limit "all your requests will be declined (http 503) until the rate drops again" ([Rate_Limiting](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting)).
- User-Agent is required, format `Application name/<version> ( contact-url )` or `( contact-email )`; blank/generic agents (Java, Python-urllib, Apache-HttpClient) are throttled harder ([Rate_Limiting](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting)).
- Terms: "Non-commercial use of this web service is free; please see our commercial plans or contact us if you would like to use this service commercially" ([MusicBrainz_API](https://musicbrainz.org/doc/MusicBrainz_API)).
- Lookups: `/release-group/<mbid>?inc=artist-credits+releases+tags+genres+ratings+artist-rels+url-rels` (release-group supports `releases`, `artist-credits`, `aliases`, `annotation`, `tags`, `genres`, `ratings`, and `*-rels`) ([MusicBrainz_API](https://musicbrainz.org/doc/MusicBrainz_API)). Search: `/release-group?query=...` with Lucene syntax, fields include `releasegroup`, `artist`, `arid`, `primarytype`, `tag`, `firstreleasedate`; limit "between 1 and 100", default 25 ([Search](https://musicbrainz.org/doc/MusicBrainz_API/Search)).
- Viability for a public site: one request per second per IP is the site's entire budget for search-as-you-type, Import resolution and page loads combined. Every project in section 6 that serves more than one user fronts MusicBrainz with its own database. On-demand fetch-and-cache is workable for warming a local Catalog (one Album per second, ~4.5 M release groups = 52 days for everything, but only Acclaimed Albums need warming) and for long-tail misses; it is not workable as the primary read path.
- Hosted mirror under $50–100/month: the requirement is the db-only footprint above (100 GB disk, 4 GB RAM, 2 threads; no Solr). That is a small VPS plus block storage. I did not find a vendor price page that rendered without JavaScript, so no price is cited here; ticket 017 (stack) should price it. Note that a mirror without Solr has no search; search would be built on Postgres (section 6.1: ListenBrainz builds its own index rather than using MusicBrainz search).

## 3. Genre coverage

### 3.1 How genres work

- Genres are tags: "The genre list ... tags (the ones in the genre list) are automatically read and presented as genres"; the list "is expanded according to user requests" via a style ticket; editors "upvote and downvote genres" per entity ([Genre](https://musicbrainz.org/doc/Genre)). Any entity except URLs can be tagged; "The total of votes has to be positive for the tag to be displayed" ([Folksonomy_Tagging](https://musicbrainz.org/doc/Folksonomy_Tagging)).
- The list is fixed and machine-readable: `GET https://musicbrainz.org/ws/2/genre/all?fmt=txt` returned 2,194 names on 2026-09-02 (the statistics page says 2,195). It is flat: the `/genres` page is an alphabetical list with no parent/child structure ([musicbrainz.org/genres](https://musicbrainz.org/genres)); the `genre` table has `id, gid, name, comment` and no parent column ([CreateTables.sql](https://github.com/metabrainz/musicbrainz-server/blob/master/admin/sql/CreateTables.sql)). "Sub-genre with a parent" from CONTEXT.md is therefore not something MusicBrainz supplies; `l_genre_genre` relationships exist as a table but their content was not examined.
- The list is the CC0 `genre` table; the *assignments* to Albums are NC `release_group_tag` rows (section 1.3).

### 3.2 Coverage on release groups (computed)

MusicBrainz publishes no "release groups with at least one genre" figure. The closest published numbers ([musicbrainz.org/statistics](https://musicbrainz.org/statistics), read 2026-09-02):

- Tags (raw votes): 20,304,022; distinct tag names (aggregated): 243,786; editors using tags: 55,527 (16.0% of active editors).
- Genres in the fixed list: 2,195. So of 243,786 distinct tag names, under 1% are recognised genres; the rest are free-text folksonomy.
- No per-entity-type breakdown (tagged release groups, tagged artists) is on the page.

An upper bound follows from those numbers: 20.3 M tag votes spread over 4.49 M release groups, 2.97 M artists, 40.0 M recordings and 5.75 M releases, with most votes historically on artists and release groups. The exact share of Albums (release groups) carrying at least one genre tag is **unverified**: I began computing it directly from `mbdump-derived.tar.bz2` (join `release_group_tag` to `tag` on `tag.id`, keep rows where `tag.name` is in the `/genre/all` list and `count > 0`, count distinct `release_group`, divide by 4,493,395), but the bzip2 extraction had not reached the `release_group_tag` and `tag` members by the time this doc was closed. The method is one `COPY`-free pass over two TSV files and is worth running in ticket 007 before sizing the genre Axis; it also yields the per-Album genre count distribution and how many Albums have a single dominant genre.

Two structural facts that hold regardless of the number: genre coverage is folksonomy, so it is dense on popular Albums and sparse on the long tail (only 16% of active editors tag at all); and the Album-level genre in MusicBrainz is whatever editors typed on the release group, with artist-level tags as a separate, generally denser fallback (`artist_tag` alone was 33 MB of TSV in the dump versus 144 MB+ for `recording_tag`).

### 3.3 MusicBrainz ratings (Popularity Proxy candidate)

Published totals ([musicbrainz.org/statistics](https://musicbrainz.org/statistics)): ratings (raw) 1,739,459; rated entities (aggregated) 1,305,018; editors using ratings 50,816 (14.6% of active editors). No per-type breakdown is published, so the number of *release groups* with a rating is **unverified**; it is bounded above by 1,305,018, i.e. at most 29% of the 4,493,395 release groups, and in practice lower because artists, recordings, labels and works share that total. Per rated entity the average is 1.3 votes (1,739,459 / 1,305,018), so the MusicBrainz rating is mostly a single editor's opinion: as a Popularity Proxy it indicates "someone cared enough to rate" more than any aggregate verdict. The values sit in `release_group_meta.rating` (0–100) and `rating_count`, CC BY-NC-SA.

## 4. Cover Art Archive

- What it is: "a joint project between the Internet Archive and MusicBrainz"; images "are uploaded from users' computers directly to Internet Archive servers. All images are copyrighted by their respective copyright owners" ([coverartarchive.org](https://coverartarchive.org/)). The MusicBrainz doc adds: "Use the images at your own risk" and "Be respectful of the rights of the artists and labels" ([Cover_Art_Archive](https://musicbrainz.org/doc/Cover_Art_Archive)). There is no license grant on the images; the metadata index is in the NC dump (section 1.1).
- API ([Cover_Art_Archive/API](https://musicbrainz.org/doc/Cover_Art_Archive/API)): `/release/{mbid}/` JSON listing; `/release/{mbid}/front`, `/back`, `/{id}`; thumbnails `-250`, `-500`, `-1200`; and for Albums directly `/release-group/{mbid}/front[-250|-500|-1200]`, which picks a release's front image for the group. Responses are 307 redirects to `archive.org/download/mbid-.../`. "There are currently no rate limiting rules in place at coverartarchive.org."
- Coverage: 3,867,070 releases with art (67.3%), 3,102,167 release groups with art, 4,041,814 front images; by format Digital Media 2,200,275, CD 1,133,964 ([statistics/coverart](https://musicbrainz.org/statistics/coverart)). Against 4,493,395 release groups that is roughly 69% of Albums with some art via the release-group endpoint.
- Practical: hot-linking the 250/500 thumbnails through the release-group endpoint costs nothing and needs no dump; caching copies locally is a copyright question the archive explicitly declines to answer for you.

## 5. Discogs

### 5.1 Terms ([API Terms of Use](https://support.discogs.com/hc/en-us/articles/360009334593-API-Terms-of-Use), last updated 2025-05-27)

- Two classes of Content. **CC0 Data**: "Release titles, notes, dates, format, track listings, barcodes and other identifiers, credits, versions, URL links to third-party sites; Artist names, notes, associated releases; Label ... names and contact information, notes, and associated releases". **Restricted Data**: "Discogs User Data" (usernames, collection, wantlist...), "Marketplace Data" (pricing, sales history, num_for_sale-type data) and "Images".
- Restricted Data: "You may not: Transfer Restricted Data to any third party. Use Restricted Data for any commercial purposes."
- Applies to all Content, CC0 included, when it comes through the API: "You may not display in any format or to any audience the Content if it is more than six (6) hours older than the information on Our online properties or applications ... You may not cache or store the Content longer than is necessary to provide a service to Your application's users."
- Mandatory notices: "This application uses Discogs' API but is not affiliated with, sponsored or endorsed by Discogs. 'Discogs' is a trademark of Zink Media, LLC." and, "directly next to any data You use from the Discogs API", "Data provided by Discogs." with a follow-able hyperlink to the discogs.com page.
- Commercial use "is generally permitted" but prohibited uses include "Charging a fee to use or access any part of Your application that integrates with Our API or the Content if we provide that access to users free of charge" and "Using Our API or the Content with the intent to drive traffic to other non-Discogs websites or services". "We reserve the right to charge for access to, or use of, Our API in the future."
- The community `have`/`want` counts and `rating.average`/`rating.count` returned on `/releases/{id}` are not in the CC0 list; they are aggregates of User Data (collection, wantlist). Read with the Restricted rules: no commercial use, no transfer, six-hour display limit, no long-term storage.
- The monthly dumps are a separate channel: "made available under the CC0 No Rights Reserved license" and cover "Release, Artist, Label, and Master Release data" in XML ([data.discogs.com](https://data.discogs.com/)). The six-hour and no-cache rules are API terms and do not attach to the dumps.

### 5.2 API mechanics ([discogs.com/developers](https://www.discogs.com/developers/))

- "Authenticated requests are limited to 60 per minute, and unauthenticated requests are limited to 25 per minute"; moving 60-second window; headers `X-Discogs-Ratelimit*`. User-Agent required ("we just silently block it" otherwise). `/database/search` — "Authentication (as any user) is required." Images: "Image requests require authentication and are subject to rate limiting."
- Entities: `/releases/{id}` (an Edition; includes `master_id`, `genres`, `styles`, `extraartists` with free-text `role`, `companies`, `identifiers`, `community.have/want/rating`, `num_for_sale`, `lowest_price`), `/masters/{id}` (roughly an Album; `main_release`, `versions_url`), `/masters/{id}/versions` (each with `stats.community.in_collection/in_wantlist`), `/releases/{id}/stats` (`num_have`, `num_want`), `/releases/{id}/rating` (community average and count), `/artists/{id}`, `/labels/{id}`.

### 5.3 What Discogs adds that MusicBrainz lacks

| Need | MusicBrainz | Discogs |
|---|---|---|
| Album-level identity | release group (CC0) | master (CC0 in dumps); Discogs masters exist only when a release has been grouped; unverified how many releases lack a master |
| Credits depth | relationships with typed `link_type` roles and instrument attributes; core CC0 | `extraartists` free-text `role` strings ("Producer, Written-By") plus `companies` (mastering studio, copyright holder). Broader on physical-release credits, less structured. CC0 in the dumps. |
| Genre/style | 2,194-item flat community list, NC assignments | fixed editorial `genres` (broad) + `styles` (narrow), CC0 in dumps; count of styles not verified |
| Popularity counts | `release_group_meta.rating` (NC); no collection counts | `have`/`want` per release, rating average/count — Restricted Data via API; not in the CC0 list; presence in the monthly dumps not verified |
| Marketplace | none | `num_for_sale`, `lowest_price` — Restricted |
| Cover images | CAA, no rate limit, no license | auth required, Restricted |
| Bulk | 7 GB core dump twice weekly | 10.5 GB `releases.xml.gz` + 597 MB masters monthly, CC0 |

Net: Discogs' extra value for this map is credits breadth and an editorial genre/style taxonomy, both CC0 via the monthly dumps. Its popularity counts, the thing a Popularity Proxy would most want, come only through the API under Restricted terms that forbid storing them.

## 6. How existing open-source projects consume MusicBrainz

### 6.1 ListenBrainz (MetaBrainz)

- Runs against a MusicBrainz Postgres replica rather than the API: `config.py.sample` has `MB_DATABASE_URI` and `MBID_MAPPING_DATABASE_URI` ([config.py.sample](https://github.com/metabrainz/listenbrainz-server/blob/master/listenbrainz/config.py.sample)); the dev `docker-compose.yml` says "Uncomment the following lines if you want to connect the LB network to a musicbrainz-docker network to access a MB replica" ([docker-compose.yml](https://github.com/metabrainz/listenbrainz-server/blob/master/docker/docker-compose.yml)).
- The `mbid_mapping` component "chooses the earliest digital releases from MusicBrainz and then creates a table with the first instance of any (artist_credit, recording_name)" and builds "a typesense index ... that can be used to quickly and fuzzily look up data"; "You will need to have a copy of musicbrainz-docker installed and running" ([mbid_mapping/README.md](https://github.com/metabrainz/listenbrainz-server/blob/master/mbid_mapping/README.md)). The output is published as the CC0 canonical dumps (section 1.6).
- Lesson: MetaBrainz's own consumer app does not use MusicBrainz's Solr search; it derives a canonical table from the replica and builds a separate fuzzy index. That is the shape an Import resolver (Spotify track → Track → Edition → Album) would take.

### 6.2 Lidarr

- The client never calls musicbrainz.org. `LidarrCloudRequestBuilder.cs` hard-codes `Search = new HttpRequestBuilder("https://api.lidarr.audio/api/v0.4/{route}")` ([source](https://github.com/Lidarr/Lidarr/blob/develop/src/NzbDrone.Common/Cloud/LidarrCloudRequestBuilder.cs)).
- That service is [LidarrAPI.Metadata](https://github.com/Lidarr/LidarrAPI.Metadata): "The metadata API server requires access to a musicbrainz postgresql database" and a Solr search server; it is loaded from the MusicBrainz dump with optional replication ("wait for the database / indices to catch up with the latest hourly replication") and adds its own cache (`docker-compose up -d cache-db`, Redis).
- Lesson: a desktop app with many users still needed a hosted mirror plus a cache in front of it; the 1 req/s API was not an option at their scale.

### 6.3 beets

- Talks to the musicbrainz.org web service directly; `BASE_URL = "https://musicbrainz.org/"` ([beetsplug/musicbrainz.py](https://github.com/beetbox/beets/blob/master/beetsplug/musicbrainz.py)). Config defaults: `ratelimit: 1`, `ratelimit_interval: 1.0`, `search_limit: 5`, `host: musicbrainz.org`; "you can redirect beets to use a custom MusicBrainz mirror by specifying `host`" and "The server must have search indices enabled"; `genres` option pulls genre tags from release group and release, "sorted by vote count" ([beets MusicBrainz plugin docs](https://beets.readthedocs.io/en/stable/plugins/musicbrainz.html)).
- Lesson: single-user CLI, so the 1 req/s ceiling is the whole design; the mirror escape hatch requires Solr, which is the 350 GB / 16 GB tier.

### 6.4 mbslave / mbdata (AcoustID)

- AcoustID keeps its own mirror with `mbslave` (import + token-based sync, no MusicBrainz Server) and reads it through `mbdata` SQLAlchemy models ([mbslave](https://github.com/acoustid/mbslave), [mbdata](https://github.com/lalinsky/mbdata)). Lesson: the minimal mirror is a plain Postgres with the MusicBrainz schema; the server code is optional.

## 7. If you want X, the cheapest sane route is Y

Facts assembled into routes; choosing between them is ticket 007.

| If you want | Cheapest sane route | Cost driver |
|---|---|---|
| The whole Catalog searchable, offline from MusicBrainz | Load `mbdump.tar.bz2` (7 GB, CC0) into Postgres with the official schema (`musicbrainz-docker` db-only, or plain `COPY` of the ~15 tables in section 1.2), reload twice weekly or on demand. | 60–100 GB disk, 4 GB RAM. No token, no account. |
| Only Albums + Artists + dates, no Tracks | Same dump, but `COPY` only `release_group`, `release_group_*`, `artist_credit*`, `artist`, `release`, `release_country`, `release_unknown_country`, `release_label`, `label`, `area`; or read `release-group.tar.xz` (1 GB JSON). | A few GB. Loses Import-by-ISRC until `recording`/`isrc`/`track` are added. |
| Genre Tags on Albums | Add `mbdump-derived.tar.bz2` (490 MB): `release_group_tag` + `tag`, filtered to names in the CC0 `genre` table. | BY-NC-SA on the assignments; attribution; site stays non-commercial. |
| Hourly freshness | Live Data Feed with a free non-commercial token via `musicbrainz-docker` or `mbslave`. | BY-NC-SA on the whole mirror; schema-change upgrades; an account. |
| Weekly freshness | Re-download and reload the twice-weekly dump. | Bandwidth 7.5 GB per reload; reload window. |
| Search over the Catalog | Postgres full-text/trigram over the loaded tables (what ListenBrainz does with its own index). MusicBrainz Solr is the 350 GB / 16 GB tier and not replicated. | Engineering, not hosting. |
| Album art | Hot-link `coverartarchive.org/release-group/{mbid}/front-250` (no rate limit, no dump). | Zero. Local copies are a copyright judgement. |
| Long-tail Album not in the local Catalog | On-demand `/ws/2/release-group/<mbid>?inc=artist-credits+releases` at ≤1 req/s with a proper User-Agent, cached locally. | Fine as a miss path, not as the read path. |
| Credits breadth / editorial genre+style | Discogs monthly dumps (CC0): `masters.xml.gz` 597 MB, `releases.xml.gz` 10.5 GB. | Matching Discogs masters to MusicBrainz release groups is unsolved here (MusicBrainz has Discogs URL relationships in `l_release_url`/`l_release_group_url`; coverage not measured). |
| Popularity counts from Discogs | API only, Restricted Data: ≤60 req/min, six-hour display limit, no storage, non-commercial. | Cannot be stored as a Signal. Not a sane route for a Popularity Proxy. |

## 8. Could not verify

- Share of release groups with at least one genre tag, and number of release groups with a MusicBrainz rating: no published per-type statistic; my dump computation did not finish (method in 3.2).
- Import wall-clock time for the full dump: no primary source states it (docker README has a TODO).
- Whether MusicBrainz JSON dumps include tags/genres per release group (datasets page 404).
- Whether Discogs monthly dumps carry `have`/`want`/rating aggregates (S3 listing is access-denied outside the JS page; XML not opened).
- Discogs style count and the share of releases without a master.
- VPS pricing for the 100 GB / 4 GB mirror (vendor pages did not render); left to ticket 017.
- `l_genre_genre` contents (whether MusicBrainz encodes any genre hierarchy there).
- Whether the MusicBrainz web-service `release` JSON's `cover-art-archive` block is an adequate substitute for the NC CAA index dump (not tested).

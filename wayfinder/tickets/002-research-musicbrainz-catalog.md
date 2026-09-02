---
id: 002
title: MusicBrainz and Discogs as the Catalog source
label: wayfinder:research
status: closed
assignee: agent
blocked_by: []
---

## Question

The Catalog's source of truth is MusicBrainz, with Discogs acceptable as a secondary source (see CONTEXT.md: Album = release group, Edition = release). Surface the facts needed to choose an ingestion strategy and size the database:

- Full-dump route: current dump size (compressed and loaded into Postgres), what tables cover release groups, releases, artist credits (Participants), genres/tags, release country, release dates; licensing of each part (CC0 core data vs CC-BY-NC-SA supplementary data — which of *our* uses does the NC clause touch, given an open-source but public hosted site?); replication/live-update mechanism and its terms.
- API route: rate limits, required user-agent, whether searching + fetching on demand is viable for a public site, and whether a hosted mirror (`musicbrainz-docker`) is realistic under $50–100/month.
- Genre coverage: how complete MusicBrainz genre tags are on release groups, and whether there's a fixed genre list.
- Cover Art Archive: how to get album art and its terms.
- Discogs API: terms of use (notably any restriction on storing data or on commercial/derivative use), rate limits, and whether it adds anything MusicBrainz lacks (credits depth, popularity counts).
- Existing open-source projects that ingest MusicBrainz into their own DB (ListenBrainz, Lidarr, Beets, others): how they do it and what they learned.

Deliver: a findings doc with numbers and citations, plus a short "if you want X, the cheapest sane route is Y" section. No recommendation on the strategy itself — that is ticket 007's decision.

## Resolution

Resolved 2026-09-01. Findings: [docs/research/002-musicbrainz-catalog.md](../../docs/research/002-musicbrainz-catalog.md) (branch `research/musicbrainz`, merged). Ends with an "if you want X, cheapest route is Y" table; the strategy decision is ticket 007.

Key facts:
- **Scale** (musicbrainz.org/statistics, 2026-09-02): 4.49M release groups (Albums), 5.75M releases (Editions), 2.97M artists, 40.0M recordings.
- **Full dump**: `mbdump.tar.bz2` 7 GB compressed, **CC0**; `mbdump-derived.tar.bz2` (tags, ratings) 490 MB, **CC BY-NC-SA 3.0**. Exported twice weekly. Loaded footprint "60 GB+"; the official db-only Docker mirror wants 100 GB disk / 4 GB RAM / 2 threads (350 GB / 16 GB if you also run MusicBrainz's Solr search). Import wall-clock time is undocumented.
- **Table map**: Album = `release_group` (+ primary/secondary type); Edition = `release`; dates/countries = `release_country` / `release_unknown_country`; credited Artist = `artist_credit_name`; Participants = `l_artist_release` / `l_artist_recording` + `link_type`; genre *list* = CC0 `genre` table; genre *assignments* = NC `release_group_tag` + `tag`.
- **NC clause reach**: genre Tag assignments, MusicBrainz ratings, and the hourly Live Data Feed (BY-NC-SA regardless of content). Core data via the twice-weekly dump stays CC0. Commercial supporter tier starts at $100/month — the whole hosting budget.
- **API**: hard 1 req/s per IP (503 above), User-Agent mandatory, free for non-commercial use. Viable as a cache-miss path, not as a public site's read path. Every multi-user consumer studied (ListenBrainz, Lidarr, AcoustID) runs its own Postgres replica.
- **Genres**: fixed flat list of ~2,195 names, no hierarchy; 243,786 distinct folksonomy tag names; only 16% of active editors tag. Share of Albums with ≥1 genre tag: unverified (method for computing it from the derived dump is in §3.2 for ticket 007).
- **Cover Art Archive**: no rate limit; `/release-group/{mbid}/front-250|500|1200` gives Album art directly; ~3.1M release groups have art; images carry no licence ("use at your own risk").
- **Discogs**: API 60/min authenticated; content may not be displayed if >6 h old nor cached beyond necessity; have/want/rating counts are *Restricted* (no storage, no commercial use) — dead as a stored Popularity Proxy. Monthly XML dumps are CC0 (releases 10.5 GB gz, masters 597 MB) and add credit breadth plus an editorial genre/style taxonomy.

Computed after the doc was committed (from `mbdump-derived` 2026-08-29; not in the findings file):
- Albums with ≥1 positive tag of any kind: 1,151,738 of 4,486,409 (**25.7%**); with ≥3 tags: 496,460 (11%).
- Albums with a MusicBrainz rating: 253,421 (**5.6%**), of which 212,726 have exactly one vote and only 5,612 have 5+ votes — MusicBrainz ratings are near-useless as a Popularity Proxy.
- Albums with a first-release year: 4,286,545 (95.5%) — the decade Axis is nearly complete.

Unverified: the *genre-specific* share of tagged Albums (needs the `tag` id→name join; method in §3.2); dump import time; whether JSON dumps carry genres; VPS pricing for the 100 GB / 4 GB mirror (left to 017).

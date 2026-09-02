---
id: 005
title: Open-data sources for the Popularity Proxy
label: wayfinder:research
status: closed
assignee: agent
blocked_by: []
---

## Question

Until enough Members have rated an Album, the Community Score is stood in for by a Popularity Proxy built from open data. Find what's actually available, per source: coverage, freshness, licence/terms (may we store and display it? attribute how?), rate limits, and how well it keys to MusicBrainz ids.

Candidates: MusicBrainz native ratings; ListenBrainz listen counts and its statistics API; Last.fm album listeners/playcount (API terms, especially the "no caching beyond X" clauses); Discogs "have"/"want" counts; Wikidata/Wikipedia pageviews for album articles; Spotify album popularity (only if terms allow use outside the user's own session — cross-check ticket 003); Deezer/other APIs.

Also: is there any *quality* signal in open data (not just popularity), e.g. presence on published year-end lists, Wikipedia "critical reception" sections, Grammy/Mercury nominations via Wikidata?

Deliver: a source table and a note on which combination gives the widest coverage of Acclaimed Albums at lowest legal risk. The blend formula is ticket 010's decision.

## Resolution

Resolved 2026-09-01. Findings: [docs/research/005-popularity-proxy.md](../../docs/research/005-popularity-proxy.md) (branch `research/popularity-proxy`, merged). Every terms clause is quoted verbatim with URLs.

Usable, all keyed on the Album's own MBID, no account needed, storage and display allowed:
- **ListenBrainz `POST /1/popularity/release-group`** — primary. Tested live, unauthenticated, 1,000 MBIDs per call, returns `total_listen_count` / `total_user_count` (e.g. OK Computer 1.55M listens / 21.6k listeners); nulls for unknowns. Listens dumps are CC0. Rate limit observed ~30 per ~6 s window.
- **MusicBrainz ratings** — secondary and thin: 5.6% of Albums rated, only 5,612 with 5+ votes; lives in the CC BY-NC-SA derived dump, so any proxy built from it inherits share-alike / non-commercial.
- **Wikipedia pageviews** (via Wikidata P436 → enwiki article) — attention signal, CC0, 148,523 Albums covered, 200 req/min policy.
- **Wikidata quality flags** — review scores (P444) on 4,056 Albums, awards/nominations (P166/P1411) on 2,337, CC0. Year-end lists are not structured anywhere open. Wikipedia's `{{Album ratings}}` template is a cited per-Publication score table — a finding aid for tickets 004/008, not a Signal.

Excluded on terms: **Spotify** (no storing/aggregating Spotify Content; no integrating with other services' content), **Deezer** (non-commercial private use only), **Last.fm** (non-commercial, 100 MB storage cap, mandatory button, pages need Last.fm's written approval), **Discogs** (content older than 6 h may not be displayed; have/want is Edition-level; the stats endpoint now returns nothing useful).

Unverified: provenance/licence of ListenBrainz's popularity numbers (a related dataset page says MLHD+, which is non-commercial; the API docs don't say — ask MetaBrainz, or derive from the CC0 listens dump instead); exact ListenBrainz rate-limit window; whether Discogs have/want counts appear in its CC0 dumps.

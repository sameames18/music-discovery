---
id: 005
title: Open-data sources for the Popularity Proxy
label: wayfinder:research
status: open
assignee: none
blocked_by: []
---

## Question

Until enough Members have rated an Album, the Community Score is stood in for by a Popularity Proxy built from open data. Find what's actually available, per source: coverage, freshness, licence/terms (may we store and display it? attribute how?), rate limits, and how well it keys to MusicBrainz ids.

Candidates: MusicBrainz native ratings; ListenBrainz listen counts and its statistics API; Last.fm album listeners/playcount (API terms, especially the "no caching beyond X" clauses); Discogs "have"/"want" counts; Wikidata/Wikipedia pageviews for album articles; Spotify album popularity (only if terms allow use outside the user's own session — cross-check ticket 003); Deezer/other APIs.

Also: is there any *quality* signal in open data (not just popularity), e.g. presence on published year-end lists, Wikipedia "critical reception" sections, Grammy/Mercury nominations via Wikidata?

Deliver: a source table and a note on which combination gives the widest coverage of Acclaimed Albums at lowest legal risk. The blend formula is ticket 010's decision.

## Resolution

(open)

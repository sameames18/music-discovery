---
id: 002
title: MusicBrainz and Discogs as the Catalog source
label: wayfinder:research
status: open
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

(open)

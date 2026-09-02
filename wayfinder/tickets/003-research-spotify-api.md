---
id: 003
title: Spotify Web API and library export, current state
label: wayfinder:research
status: closed
assignee: agent
blocked_by: []
---

## Question

One onboarding Source is "link your Spotify account" so we can read liked songs / saved albums and derive Favourites and a Library. Spotify's developer terms have tightened over the last few years. Establish the current facts:

- Which scopes/endpoints read a user's saved tracks and saved albums; pagination and rate limits.
- Development mode vs extended quota: how many users an unapproved app can serve, what the approval process demands, typical turnaround, and whether a hobby/open-source site would qualify.
- Which endpoints have been deprecated or restricted for new apps (audio features, recommendations, related artists, etc.) and since when.
- Developer Terms restrictions that touch this product specifically: storing user data, using Spotify data to build recommendations or "compete", caching limits, attribution requirements, and anything about AGPL/open-source apps.
- Matching: does the API expose ISRC (tracks) and UPC/EAN (albums) so we can resolve to MusicBrainz Editions/Albums? What does resolution accuracy look like in practice?
- Manual-import fallback: what does Spotify's account data export (Privacy → "Download your data") contain, in what format, and can a Member upload it? Also whether Last.fm / ListenBrainz scrobble exports are a cheaper universal import.

Deliver: findings with citations and a risk table (what could stop the Spotify Source from working for a public site). No decision on onboarding flows — that's ticket 013.

## Resolution

Resolved 2026-09-01. Findings: [docs/research/003-spotify-api.md](../../docs/research/003-spotify-api.md) (researched on branch `research/spotify`, merged to master).

Headline: **a Spotify OAuth "link your account" Source cannot serve a public site.** Development Mode caps an app at 5 authorised users (and the owner must hold Premium, since 2026-03-09). Extended quota (since 2025-05-15) requires a legal entity, a launched service, and 250k monthly active users; individuals are not accepted, and there is no hobby/open-source track.

Other facts that matter downstream:
- The endpoints we'd use still work in dev mode: `GET /me/albums` (UPC/EAN inline) and `GET /me/tracks` (ISRC inline), scope `user-library-read`, 50 per page. Batch album fetch was removed Feb 2026, so resolving liked tracks to albums is one call per album.
- Three rounds of endpoint removals in 15 months (Nov 2024, Feb 2026, Jul 2026 quota changes). Recommendations, audio features, related artists are gone for new apps.
- Developer Policy III.13 ("do not analyze the Spotify Content… for any purpose") and III.11 ("mimic core user experience") are the clauses closest to a Taste Profile; III.9 explicitly permits user-initiated transfer of the user's own data (an Import). Deletion within 5 days of disconnect is required. Attribution/no-adjacent-services rules apply only if we *display* Spotify metadata — rendering MusicBrainz names avoids them.
- Matching: ISRC → MusicBrainz recording lookup, `barcode:` release search, and Spotify-URL lookup all exist, but MusicBrainz coverage is ~15% of recordings with ISRCs and ~44% of releases with barcodes. No measured match rate; the engine prototype (011) or onboarding ticket (013) should measure it.
- Manual fallback: Spotify's account data export is a zip of JSON (library, playlists, streaming history with track URIs) but contains email/DOB/card-last-4, so uploads must be filtered. **ListenBrainz** is the cheapest universal Import: CC0 data, MBIDs already resolved, public API, and it already parses Spotify's export. Last.fm has no official export and non-commercial-only API terms.

Unverified: whether Spotify tolerates many 5-user Client IDs; exact contents of the "Your Library" export JSON (URIs vs names only); any measured Spotify→MusicBrainz match rate.

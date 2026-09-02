---
id: 003
title: Spotify Web API and library export, current state
label: wayfinder:research
status: open
assignee: none
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

(open)

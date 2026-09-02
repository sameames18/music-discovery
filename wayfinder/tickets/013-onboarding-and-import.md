---
id: 013
title: Onboarding flows and Import resolution
label: wayfinder:grilling
status: open
assignee: none
blocked_by: [003]
---

## Question

Three onboarding Sources were planned: link Spotify, upload a file, or search-and-pick five Favourites. Ticket 003 found that Spotify OAuth is capped at 5 users for any app without a legal entity and 250k MAU — so the first decision here is what replaces "link Spotify" for a public site: a ListenBrainz link (CC0, MBIDs pre-resolved, and ListenBrainz itself imports Spotify), upload of Spotify's own data export, both, or keeping a 5-user Spotify link only as a self-hoster/dev convenience. Then specify each surviving flow end to end. For Spotify: which data is read (saved albums? liked tracks? both?), how tracks resolve to Albums (via ISRC/UPC → MusicBrainz, with fallback matching by artist+title), what becomes a Favourite vs merely a Log (does a liked track make its Album a Favourite, a Log, or neither until the Member confirms?), and what happens when Spotify approval limits users. For file upload: which formats (Spotify export, Last.fm/ListenBrainz CSV), and the same resolution questions. For pick-five: search UX and minimum count. Also: can a Member add a second Source later, and what re-importing does to existing Logs/Ratings.

## Resolution

(open)

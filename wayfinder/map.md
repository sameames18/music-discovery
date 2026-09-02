---
title: Music Discovery — Wayfinder map
labels: [wayfinder:map]
created: 2026-09-01
---

# Music Discovery — Wayfinder map

Tracker convention: [TRACKER.md](./TRACKER.md). Tickets: [tickets/](./tickets/). Vocabulary: [CONTEXT.md](../CONTEXT.md) — every ticket uses its terms.

## Destination

A written spec, in the repo, for an open-source (AGPL-3.0), public, multi-user music catalog and discovery site — a RYM/Letterboxd/Storygraph-class competitor for albums — covering: the album Catalog and Tag model, the Critic Score and Community Score signals, the explainable finite-list Engine, Member onboarding (Spotify link, file import, or pick five Favourites), and Log/Rating/Review/Reaction feedback with a public Member Page. It ends with a phased build order whose phase 1 is buildable by agents under Sam's direction, with mood/content Tags, Influence, and Apple Music named as later phases.

The map is done when every decision that spec needs is made and nothing is left to research.

## Notes

- Domain: album catalog + critic aggregation + explainable recommendations. Read `CONTEXT.md` first; challenge it via the `domain-modeling` skill when a ticket sharpens a term.
- Sam: ops background, not a software engineer; directs agents that write nearly all code; reviews and steers. Brief, direct, lead with the answer, no filler, no "it's not X it's Y". Offer counterpoints proactively — he won't ask. Decisive once informed: bring facts, then put the decision to him.
- Grilling tickets: call `grilling` and `domain-modeling`. Prototype tickets: call `prototype`. Research tickets: call `research`, findings on a `research/<name>` branch, linked from the ticket.
- Standing decisions (don't re-open): GitHub, open source under AGPL-3.0, product name placeholder `music-discovery`. Rating scale 0.5–5 stars in half steps. Sign-in by email magic link; Spotify is an Import Source, not the login. Album = MusicBrainz release group; Ratings attach to Albums. Rating implies Log; Log without Rating allowed. Reactions are feedback on Recommendations, never a Rating. Critic Score is aggregated by us from Publications — no scraping AOTY/RYM/Metacritic. Community Score = native Ratings; Popularity Proxy from open data until Ratings suffice. Catalog = MusicBrainz (Discogs acceptable secondary). Whole Catalog searchable/rateable; dashboard and Candidate pool = Acclaimed Albums only. Stack: one backend language, one frontend language, one database, one deployment method; $50–100/month acceptable at real usage.
- Budget: $0 while charting; research tickets must not sign up for paid services.

## Decisions so far

<!-- one line per closed ticket: [title](tickets/NNN-slug.md): gist -->

- [Spotify Web API and library export, current state](tickets/003-research-spotify-api.md): Spotify OAuth can't serve a public site (5-user dev cap; extended quota needs a legal entity and 250k MAU). Liked-track/album endpoints work for those 5. ListenBrainz (CC0, MBIDs resolved, parses Spotify's export) is the cheapest universal Import; Spotify's own export zip works as a filtered upload. MusicBrainz ISRC/barcode coverage is partial, match rate unmeasured.

## Not yet specified

In scope, not yet sharp enough to ticket. Revisit as the frontier advances.

- **Mood and content Tags** — deferred past v1 by Sam. Source (curation / community / model-derived from review text) undecided; depends on what review-text pipeline ticket 008/009 leave us with and on the Tag data model from 014.
- **Influence Signal** — documented artist influences from interviews and liner notes (the Echoes idea), as a pluggable Engine Signal. Waits on Engine v1 (012) defining the Signal seam, and on whether a text-analysis pipeline exists from mood/content tagging.
- **Apple Music as an Import Source** — waits on the onboarding/Import design (013) and on whether the Apple Developer Program fee is worth it before there are users.
- **Search** — how Members find Albums across the whole Catalog (full-text over MusicBrainz names, aliases, typo tolerance). Depends on the ingestion strategy (007) and stack (017).
- **Catalog freshness and new releases** — how new Albums and new Critic Reviews arrive after launch (dump replication, feed polling cadence, "new this week" surfaces). Depends on 007 and 008.
- **Analytics and product feedback** — Sam wants to "improve the product" via issues; what usage instrumentation, if any, the site collects, within the privacy constraints from 006.
- **Moderation and abuse** — beyond the v1 minimum in 016: spam Ratings, review-bombing, rate limiting. Depends on 016 and on there being users.
- **Reviews as a Signal** — whether Members' Reviews (text) ever feed the Engine or mood/content Tags. Far fog; after 012.

## Out of scope

Ruled beyond this map's destination. Returns only as a fresh effort.

- **Following, lists, activity feeds** — the social layer of RYM/Letterboxd. A years-long community problem, not a spec problem; the Member Page is the only public surface in this map.
- **Scraping AOTY, RYM, or Metacritic for scores** — ruled out on legal/reliability grounds (session 1); Critic Score is aggregated from Publications directly.
- **Sam hand-writing the code** — the build is agent-driven; the spec targets that.
- **Native mobile apps** — web only.

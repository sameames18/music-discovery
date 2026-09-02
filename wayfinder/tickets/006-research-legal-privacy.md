---
id: 006
title: Legal and privacy obligations for a public site holding Members' listening data
label: wayfinder:research
status: closed
assignee: agent
blocked_by: []
---

## Question

A public, open-source (AGPL-3.0), US-hosted site run by one person will store Members' emails, Ratings, Reviews, and imported Spotify library data. Establish what that obligates before the spec fixes the data model:

- GDPR/UK-GDPR exposure for a US hobbyist with EU visitors: is a privacy policy plus data export/deletion enough, or is more needed? CCPA thresholds (does a no-revenue site fall under it?).
- What a minimal, honest privacy policy and terms of service must contain for this product; sources of good open templates.
- Spotify's Developer Terms obligations on stored user data (deletion when a user disconnects, retention limits) — coordinate with ticket 003, don't duplicate it.
- User-generated content: what protections a US host has for Members' Reviews (Section 230 basics), and whether a takedown/moderation path is required or merely wise.
- AGPL-3.0 practicalities: what "network use" means for a hosted app, what the site must display/link, and whether any dependencies we'd likely pick (MusicBrainz data, Spotify SDKs) conflict with AGPL.
- Cover art and publication excerpts: what can be displayed under fair use / with attribution.

Deliver: a short obligations checklist (must / should / later) with citations. Not legal advice; flag where a real lawyer is warranted.

## Resolution

Resolved 2026-09-01. Findings: [docs/research/006-legal-privacy.md](../../docs/research/006-legal-privacy.md) (branch `research/legal-privacy`, merged). Not legal advice; the file ends with a five-item "lawyer warranted" list.

Must-do gist:
- **CCPA does not apply** (for-profit only). What does: **CalOPPA** (privacy policy with a fixed content list incl. Do Not Track disclosure) and California's breach-notification statute (anyone holding CA residents' account credentials).
- **GDPR** catches a US site only if it *targets* the EU (Recital 23); mere accessibility doesn't. The limb a hobbyist actually risks is Art. 3(2)(b) *monitoring* — so no third-party analytics or fingerprinting, and the Taste Profile is a grey area. If caught, the Art. 27 EU/UK representative is the expensive obligation. First lawyer question.
- **Privacy policy + ToS** contents = union of GDPR Art. 13, CalOPPA §22575(b), Spotify Terms §V.12. Open templates: GitHub site-policy (CC0), Basecamp (CC BY), Automattic Legalmattic (CC BY-SA).
- **Spotify** (if any Spotify Source survives ticket 013): disconnect control; delete Spotify personal data within 5 days of disconnect; name Spotify a third-party beneficiary in the ToS; no ML on Spotify Content. Data-model consequence for 016: `source` on Library rows, separate token table, keep only Catalog ids after Import.
- **Section 230** covers Members' Reviews and permits moderation, but not IP claims → **DMCA agent registration ($6, renew every 3 years)**, a takedown path, and a repeat-infringer policy stated to Members are required for the §512(c) safe harbour.
- **AGPL §13**: ship a footer with copyright, no-warranty, licence link, and source-at-commit link from day one. No conflict with MusicBrainz data or Spotify's REST API; avoid Spotify's proprietary SDKs.
- **MusicBrainz licence surprise**: core entities are CC0, but **Tags (incl. genre associations), ratings, and annotations are CC BY-NC-SA 3.0** — attribute, share-alike, and the NC term bites the moment money enters. Affects tickets 005 and 014.
- **Cover art**: thumbnails-as-reference have two Ninth Circuit fair-use holdings (*Kelly*, *Perfect 10*); Cover Art Archive grants no licence. **Review excerpts**: store score + URL + short pull-quote, never full bodies; forbid lyrics in Reviews.

Checklist in the file: 11 Must, 11 Should, 7 Later. Unverified: ICO pages (403; UK positions from legislation.gov.uk), a pending UK GDPR Art. 27(4) amendment (S.I. 2026/386) whose text wasn't retrievable, Spotify's verbatim "Spotify Content" definition.

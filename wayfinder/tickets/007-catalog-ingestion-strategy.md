---
id: 007
title: Catalog ingestion strategy
label: wayfinder:grilling
status: open
assignee: none
blocked_by: [002]
---

## Question

Given the facts from "MusicBrainz and Discogs as the Catalog source": how does the Catalog get into our database and stay current?

Decide: full MusicBrainz dump loaded into our Postgres vs. on-demand fetch-and-cache via the API vs. a self-hosted MusicBrainz mirror; what subset of entities we keep (release groups, primary artist credits, release country/date; do we keep every Edition or only enough to resolve Imports?); how often we refresh; whether Discogs is used at all in v1 and for what; and what this implies for database size and monthly cost (feeds ticket 017).

Bring the numbers. Sam decides.

## Resolution

(open)

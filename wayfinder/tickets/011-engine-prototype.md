---
id: 011
title: Prototype the Engine on Sam's own favourites
label: wayfinder:prototype
status: open
assignee: none
blocked_by: []
---

## Question

Before designing the Engine on paper, find out whether a simple deterministic approach produces recommendations Sam would actually take. Build a throwaway prototype: Sam hand-picks 5–10 Favourite Albums; the prototype pulls their MusicBrainz metadata (genres/tags, artists, year, country, credits), computes a Taste Profile, scores Candidate Albums from a small acclaimed pool (a public year-end-lists dataset or a hand-assembled few hundred albums is fine), and prints a ranked list of 10 with a Reason for each.

Questions the prototype answers by reaction, not argument: does tag-overlap similarity feel right or does it need weighting by rarity (a shared "rock" tag should count for far less than a shared "Glasgow post-punk")? Is a Reason in the form "shares X, Y with your favourites; Critic Score N" convincing? Does excluding same-artist albums make results better? Does Sam want "more like this" or "adjacent to this"?

Link the prototype from this ticket. The design decisions it informs are recorded in ticket 012, not here.

## Resolution

(open)

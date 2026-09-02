---
id: 004
title: Where critic reviews can be sourced from, per Publication
label: wayfinder:research
status: open
assignee: none
blocked_by: []
---

## Question

The Critic Score is built by aggregating reviews from Publications ourselves, the way AlbumOfTheYear does — we are *not* scraping AOTY, RYM, or Metacritic. Sam wants a curated list of 10–15 Publications (ticket 008 picks them). Research the landscape so that pick is made with facts:

- For each of the ~25 publications AOTY and Metacritic most commonly aggregate (Pitchfork, The Guardian, The Quietus, NME, Rolling Stone, Stereogum, Paste, Consequence, PopMatters, The Line of Best Fit, DIY, Clash, Exclaim!, AllMusic, Spectrum Culture, Under the Radar, Uncut, Mojo, The Skinny, Loud and Quiet, Beats Per Minute, Slant, Sputnikmusic staff reviews, The Needle Drop, Resident Advisor, others you find): how reviews are published (RSS/Atom feed? JSON API? structured data like schema.org `Review` with `reviewRating` in the HTML?), how the score is expressed (0–10 decimals, stars, letter grades, none), and what their terms of service / robots.txt say about automated access.
- Legal shape: in the US, is a numeric score a fact (uncopyrightable), and does aggregating scores with attribution and a link have precedent (Metacritic, AOTY, Rotten Tomatoes all do it)? What did the hiQ v. LinkedIn line of cases settle about scraping public pages vs ToS? Keep it to what's known, cite sources, flag uncertainty.
- Any existing open dataset or API of album critic reviews/scores (academic datasets, Kaggle, Wikidata review properties) that could seed history.
- How AOTY / Metacritic normalise heterogeneous scores (documented methods, if any).

Deliver: a table (publication × feed/API × score format × ToS stance) and a short legal-risk summary. Selecting the list is ticket 008; the normalisation formula is ticket 009.

## Resolution

(open)

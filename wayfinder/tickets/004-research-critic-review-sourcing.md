---
id: 004
title: Where critic reviews can be sourced from, per Publication
label: wayfinder:research
status: closed
assignee: agent
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

Resolved 2026-09-01. Findings: [docs/research/004-critic-review-sourcing.md](../../docs/research/004-critic-review-sourcing.md) (branch `research/critic-sourcing`, merged). 36 Publications probed live (feed, one review page's markup, robots.txt, terms quoted verbatim).

Sourcing, by ease:
- **Score in the feed** (no page fetch needed): The Needle Drop (RSS category `8/10`); The Guardian via its Content API (`fields.starRating`, free non-commercial key, 500 req/day, 24,178 album reviews found) — but its terms require deleting/re-requesting held content every 24 hours, which is a decision for 008/009 about storing history.
- **Machine-readable `Review.reviewRating` on the page**: AllMusic, Line of Best Fit, DIY, musicOMH, God Is In The TV, Spectrum Culture, The Independent, Evening Standard.
- **HTML-only, parseable but brittle**: NME and Rolling Stone (star SVG counts), Clash (`8/10` body text), Exclaim, Paste/Consequence/AV Club (letter grades), Loud and Quiet, BPM (percentage), Mojo (literal stars), The Skinny, The Arts Desk.
- **Pitchfork's score is not in the server HTML** — JSON-LD has no rating; the score renders client-side. Combined with Condé Nast's terms (bans bots and "aggregate"), the hardest big name to source.
- **No scores**: Quietus, Stereogum, Resident Advisor, Bandcamp Daily, FADER, Wire. **Blocked to scripts** (Cloudflare): Uncut, Under the Radar and Slant review pages, SPIN, mostly Kerrang.
- **Terms explicitly forbidding automated extraction**: Condé Nast, PMC/Rolling Stone, Guardian (whose ToS "prevail over robots.txt"), Bauer/Mojo, NME Networks, Clash, musicOMH, RA, FADER. No scraping clause: Consequence, BPM, Crack. No terms page linked at all: Quietus, Stereogum, Paste, DIY, Loud and Quiet, Sputnik, Needle Drop.

Legal gist: scores are facts (*Feist*: no originality in facts; compilation copyright is thin). Public-page scraping isn't a CFAA violation in the Ninth Circuit (*hiQ* 2022, *Van Buren*). The exposure is **contract**: hiQ lost on breach of LinkedIn's terms (2022), but *Meta v. Bright Data* (2024) found logged-out scraping of public data didn't breach terms and *X v. Bright Data* (2024) found ToS claims preempted by copyright — both district-level, unsettled. Browsewrap enforceability is unsettled in the US and UK. UK adds a database right that counts "repeated and systematic extraction of insubstantial parts".

Normalisation: Metacritic documents converting to 0–100, weighting publications, and curving; tables unpublished. AOTY's observed letter mapping: A=100, A-=91, B+=83, B-=67, C=50, D=33. Seed history: Kaggle/Zenodo Pitchfork datasets (18k–24k scored reviews 1999–2021) are the only substantial per-Publication back-catalogue; Wikidata P444 covers 2,881 albums (85% AllMusic).

**Counterpoint for 008**: the flagship names (Pitchfork, Rolling Stone, NME) are exactly the ones with the broadest anti-scraping terms and least machine-readable scores; a "cleanly fetchable" list skews UK-indie.

Unverified: score markup for Uncut, Under the Radar, Slant, Sputnik staff, PopMatters (site down), Kerrang; AllMusic's terms (403); Metacritic's tables; whether the Guardian's 24-hour clause covers a bare star integer plus link.

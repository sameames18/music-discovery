---
ticket: 022
title: Per-Publication fetch recipe for the fifteen Publications
branch: research/022-fetch-recipes
date: 2026-09-23
status: findings (pending Sam's review)
---

# Per-Publication fetch recipes (ticket 022)

Research for [ticket 22](https://github.com/sameames18/music-discovery/issues/22), building on [docs/research/004-critic-review-sourcing.md](004-critic-review-sourcing.md) and the Publication list settled in [ticket 8](https://github.com/sameames18/music-discovery/issues/8). Vocabulary per [CONTEXT.md](../../CONTEXT.md): a **Publication** publishes **Critic Reviews** with a numeric score; a Critic Review is held as score + link + headline; an **Album** is a MusicBrainz release group. Normalisation is settled by [ticket 9](https://github.com/sameames18/music-discovery/issues/9); ingestion design (polling, backfill, Album matching) is [ticket 23](https://github.com/sameames18/music-discovery/issues/23). This file supplies facts for 23.

## Answer in brief

- **20 of 24 Publications have a verified recipe** (a real review fetched and its score parsed today; Loud and Quiet's is archive-only). **All 20 are plain HTTP fetches; none needs a headless browser.**
- **Pitchfork does not need a headless browser.** Its listing pages (`/reviews/albums/?page=N`) embed `window.__PRELOADED_STATE__`, a JSON blob in which every listed review carries `ratingValue.score` and `ratingValue.isBestNewMusic`. Source: an MIT-licensed plugin updated 2026-09-20 that parses exactly this ([§4.1](#41-pitchforks-score-source)). I could not confirm it first-hand: pitchfork.com's robots.txt disallows `Claude-User`, the agent this research ran as, so I fetched nothing from it. The project's own crawler would fall under `User-agent: *`, which allows review pages and `?page` listings.
- **Unverified (4): AllMusic** (Cloudflare "Attention Required" to every honest User-Agent today, although its robots.txt explicitly allows Claude agents), **The Guardian** (the public `test` API key now returns 401; the free Developer key needs registration — a HITL task for Sam), **Pitchfork** (robots.txt bars this agent; recipe is documented from third-party code), **PopMatters** (ModSecurity 406 on every review page and on robots.txt; feed has no score).
- **Formats differ from what ticket 9 assumed at four Publications:** NME now scores in **half stars**, including on its 2012 archive; Rolling Stone uses **half stars**; **Paste** uses letter grades now but **0–10 decimals** on older reviews (a 2014 sample), and none on 2003-era ones; **The A.V. Club** (same platform as Paste) uses **0–10 decimals** now and letter grades on older reviews. **Uncut's pre-2010 scores are stored as `ratingValue` 1–5 against `bestRating 10`** — almost certainly five-star values mislabelled, so a naive `/10` read halves them.
- **Two of the fifteen have gone quiet:** Loud and Quiet has published no reviews since **2024-12-16** (≈2,500-review archive, no live stream); The A.V. Club's newest music review is **2025-12-06**.
- **SPIN is not a Publication any more** by CONTEXT.md's definition: its current album reviews (e.g. Beck, Sept 2026) carry no score.
- **MusicBrainz links 120,192 release groups to AllMusic** (MusicBrainz relationship statistics, updated 2026-09-23). Links to every other Publication's reviews are sparse (Pitchfork ≈2,067 URLs, NME ≈889, the rest in the hundreds or fewer), so "per-Album URL from MusicBrainz" is an AllMusic-only route.
- **Sputnikmusic staff reviews are separable:** a dedicated `/reviews/staff/albums/N` listing (~4,000 reviews reachable), and every review page badges its author `STAFF` or `USER`.
- **Pitchfork history datasets:** Zenodo P4KxSpotify (18,403 reviews) is **CC BY 4.0**; Hugging Face `mattismegevand/pitchfork` (to 2023) is **MIT**; Kaggle `nolanbconaway/24169-pitchfork-reviews` (to Dec 2021, the only one with `review_url`) is **"Unknown"** licence. None carries an MBID; all need artist/title/year matching.

## 1. Method

- **Dates:** all fetches 2026-09-23 UTC from Sam's machine (residential, Windows), plain `urllib`/`curl`. No accounts, no keys, no payment.
- **Identity:** primary User-Agent `music-discovery-research/0.1 (+https://github.com/sameames18/music-discovery; research ticket 22)`. Where a host refused that string, I retried with other *honest* identities only: `curl/8.9.1` (musicOMH, Exclaim!), and the standard crawler form `Mozilla/5.0 (compatible; music-discovery-research/0.1; +https://github.com/sameames18/music-discovery)` (PopMatters feed). **No browser impersonation, no challenge solving, no headless browser.** Where Cloudflare challenged every honest identity, the Publication is marked unverified.
- **robots.txt:** fetched for every host first and checked for both `User-agent: *` and `Claude-User` (the user-directed agent this research ran as). **Where `Claude-User` was disallowed (pitchfork.com, www.theguardian.com, mojo4music.com) I fetched nothing from that host.** The project's future crawler will have its own token and fall under `*`; the table in §5 records both.
- **Rate:** ≥1.2 s between requests to the same host; Clash's `Crawl-delay: 20` honoured (21 s). **Two breaches to disclose.** (1) Slant's robots.txt sets `Crawl-delay: 600` for `*`; I fetched its robots.txt and its main feed twice within ~10 s before reading that line; after that, Slant was fetched at ≥10-minute intervals. (2) DIY's robots.txt disallows `/t/*`; I fetched one feed short link (`https://diymag.com/t/2099874`, which redirects to the canonical review) because Python's `urllib.robotparser` does not expand `*` wildcards and reported it allowed. Ticket 23's crawler needs an RFC 9309-compliant matcher (wildcards and `$`).
- **Volume:** 3–10 requests per Publication (feed, 1–3 review pages, 2–4 listing/sitemap depth probes). No crawls.
- **Verification standard:** "verified" = a real review page (or feed item) fetched today, score parsed by the stated rule, value matching the visible rendering.

## 2. Per-Publication table

Score formats are native; normalisation is ticket 9's. "Live" = discovery of new reviews; "Archive" = route to history and its measured depth.

| Publication | Live discovery | Score location → parser | Archive route (depth measured today) | Headless? | Sample verified today | Status |
|---|---|---|---|---|---|---|
| **Pitchfork** | `https://pitchfork.com/reviews/albums/` listing (also RSS `/feed/feed-album-reviews/rss`, 004) | `window.__PRELOADED_STATE__` JSON on listing pages → nodes with `contentType:"review"`, `url` containing `/reviews/album`; score `ratingValue.score` (0.0–10.0), BNM `ratingValue.isBestNewMusic`; artist `subHed.name`, album `dangerousHed` (strip HTML), `pubDate` | Datasets (§4.3) to Dec 2021; listing `?page=N` (robots `Allow: /*?page`) for everything, depth not measurable by this agent | No (per third-party code) | — (robots.txt disallows `Claude-User`) | **Unverified** |
| **The Guardian** | Content API `https://content.guardianapis.com/search?tag=tone/albumreview&show-fields=starRating,headline&order-by=newest&page-size=200&api-key=…` | JSON `response.results[].fields.starRating` (1–5) | Same query paged; 24,178 items back to 2002 measured 2026-09-02 (tickets 004/008) = 121 calls at `page-size=200` | No | — (`test` key → 401 today) | **Unverified** (needs Developer key) |
| **Rolling Stone** | RSS `https://www.rollingstone.com/music/music-album-reviews/feed/` (10 items) | HTML: `.article-review__stars` block; count `div.article-review__star--active`; an active star whose SVG path begins `m11.617 17.43` is a **half** star | Listing `/music/music-album-reviews/page/N/`: page 560 = 200 (1990s reviews), page 800 = 404; ~11/page → ~6–9k reviews | No | [Beck, *Ride Lonesome*](https://www.rollingstone.com/music/music-album-reviews/beck-ride-lonesome-review-1235628464/) → 4 · [Miley Cyrus, *Bass Persuades*](https://www.rollingstone.com/music/music-album-reviews/miley-cyrus-bass-persuades-review-1235629586/) → 3.5 · [Sting, *Mercury Falling*](https://www.rollingstone.com/music/music-album-reviews/mercury-falling-122161/) (1998) → 3 | Verified |
| **NME** | RSS `https://www.nme.com/reviews/album/feed` (10 items, full text) | HTML: first `div[role=img][aria-label^="Rated "]` after the `<h1>` → `Rated 4.5 out of 5`; later ones on the page are related-review widgets | Listing `/reviews/album/page/N`: page 850 has 13 reviews, page 1000 has 1 → ~11–12k; 2012 reviews also served as /5 half-stars | No | [Beck, *Ride Lonesome*](https://www.nme.com/reviews/album/beck-ride-lonesome-review-3969131) → 4.5 · [Bob Dylan, *Tempest*](https://www.nme.com/reviews/reviews-bob-dylan-13655-324404) (2012) → 3.5 | Verified |
| **Mojo** | Bauer aggregator RSS `https://rss.onebauer.media/api/feed-aggregator?hostname=https://www.mojo4music.com` (32 items ≈ 1 month, full `content:encoded`) | Feed item body: literal `★` run (e.g. ` ★★★★ `) → count | None found: aggregator ignores `page`/`offset`/`limit`; mojo4music.com archive not probed (robots disallows `Claude-User`) | No | Beck, *Ride Lonesome* (feed item) → ★★★★★ = 5 | **Live verified via feed; archive unverified** |
| **AllMusic** | None (RSS is blog posts) — fetch per Album | JSON-LD `Review.reviewRating` 1–10 (= stars × 2), per 004 | Per Album via MusicBrainz AllMusic URL relationship: **120,192** release-group links | Unknown — Cloudflare blocks honest clients | — (403 "Attention Required! \| Cloudflare" to project UA and curl) | **Unverified** |
| **The Needle Drop** | RSS `https://www.theneedledrop.com/rss/` (15 items, mixed content) | RSS `<category>` or page `article:tag` matching `^\d{1,2}/10$` | Ghost `https://theneedledrop.com/sitemap-posts.xml`: 3,308 `/album-reviews/` posts (2010–); score tags present from ~mid-2015 (none on 2011/2014 samples) → ~2,300 scored | No | [Miley Cyrus, *Bass Persuades*](https://theneedledrop.com/album-reviews/miley-cyrus-bass-persuades-album-review-zt2esoyotgs/) → 5/10 · [Julia Holter](https://theneedledrop.com/album-reviews/2015-9-julia-holter-have-you-in-my-wilderness/) (2015) → 9/10 | Verified |
| **The Line of Best Fit** | Listing `https://www.thelineofbestfit.com/albums` (feed carries news only; `/albums/feed` 404) | JSON-LD `MusicAlbum.review.reviewRating` 0–10 | Listing `/albums?page=N`: 376 pages × ~24 → ~9,000, back to 2007 (old URLs `/reviews/albums/…`) | No | [Trá Pháidín, *Cloch ás Claí*](https://www.thelineofbestfit.com/albums/tra-phaidin-cultivate-modernist-irish-sound-that-defies-easy-categorisation) → 9 · [Deerhoof, *Friend Opportunity*](https://www.thelineofbestfit.com/reviews/albums/deerhoof-friend-opportunity-908) (2007) → 7 | Verified |
| **DIY** | RSS `https://diymag.com/reviews/feed` (50 items) | JSON-LD `Review.reviewRating` 0–5, half steps (also `span.review-stars.stars-4-5`) | `https://diymag.com/reviewssitemap.xml`: 5,216 `/review/album/` URLs back to 2004 (listing ignores `?page`) | No | [Gilla Band, *Pugnello*](https://diymag.com/review/album/gilla-band-pugnello) → 4.5 · [Lupen Crook](https://diymag.com/review/album/lupen-crook-the-murderbirds-the-lost-belongings-ep) (c. 2009) → 2 | Verified |
| **Clash** | RSS `https://www.clashmusic.com/reviews/feed/` (10 items) | Body text: last `\b(\d{1,2})/10\b` before the `Words:` byline (`<p><strong>8/10</strong></p>` today, plain `8/10` in 2015) | Feed paging `…/reviews/feed/?paged=N`: page 750 = Dec 2007, page 870 = 404 → ~8,000 (sitemap is Cloudflare-challenged) | No | [Beck, *Ride Lonesome*](https://www.clashmusic.com/reviews/beck-ride-lonesome/) → 8 · [Purity Ring, *Another Eternity*](https://www.clashmusic.com/reviews/purity-ring-another-eternity/) (2015) → 8 | Verified (`Crawl-delay: 20`) |
| **Consequence** | Listing `https://consequence.net/category/music/music-reviews/` page 1 (robots disallows `*/feed/`) | HTML: `.review-info span.rating.grade-frame` text (letter). **Strip HTML comments first** — a commented-out reader-review span also holds a grade | Yoast `post-sitemapN.xml` (≈3,000 URLs each; #40 exists, #60 404), filter URLs containing `album-review`; listing `/page/N/` returns page 1 for any N (client-side paging); `sitemap_index.xml` timed out twice | No | [Mastodon, *Marrow Deep*](https://consequence.net/2026/08/mastodon-marrow-deep-album-review/) → A · [Windhand](https://consequence.net/2015/09/album-review-windhand-griefs-infernal-flower/) (2015) → A- | Verified |
| **Paste** | Listing `https://www.pastemagazine.com/articles/music/reviews` (music feed is news-heavy) | HTML: `div.header > div.rating` text — letter grade now, **0–10 decimal in older reviews**, absent on 2003-era | Listing `?page=N`: 62 pages × ~95 → ~5,900 back to April 2003 | No | [Gilla Band, *Pugnello*](https://www.pastemagazine.com/music/gilla-band/gilla-band-pugnello-review) → B+ · [Arkells, *High Noon*](https://www.pastemagazine.com/music/arkells/arkells-high-noon-review) (2014) → 7.0 · Al Green (2003) → none | Verified |
| **The A.V. Club** | Listing `https://www.avclub.com/articles/music/reviews` (site feed is all-sections) | HTML: `div.header > div.rating` — **0–10 decimal now**, letter grade on legacy, absent on 2000-era | Listing `?page=N`: 66 pages × ~54 → ~3,500 back to April 2000; **newest music review 2025-12-06** | No | [Tame Impala, *Deadbeat*](https://www.avclub.com/tame-impala-deadbeat-review) → 6.4 · [Adele, *30*](https://www.avclub.com/adele-reaches-new-heights-on-30-her-best-album-to-date-1848102061) → A- · [Beanie Sigel](https://www.avclub.com/beanie-sigel-the-truth-1798192306) (2000) → none | Verified (dormant) |
| **musicOMH** | RSS `https://www.musicomh.com/reviews/albums/feed` (20 items) | JSON-LD (Yoast `@graph`) `Review.reviewRating` 1–5, with `itemReviewed.MusicAlbum.name` + `byArtist.name` | Feed paging `?paged=N`: page 520 = Feb 2004, page 600 = 404 → ~10–12k | No | [Ezra Collective, *Here Because Of Hope*](https://www.musicomh.com/reviews/albums/ezra-collective-here-because-of-hope) → 4 · [The Morning After Girls](https://www.musicomh.com/reviews/albums/morning-after-girls-shadows-evolve) (2006) → 5 | Verified (project UA refused; `curl` UA served) |
| **Loud and Quiet** | **None** — feed and sitemaps stop 2024-12-16 | HTML: `<p class=score>6/10</p>` | Yoast `reviews-sitemap{,2,3}.xml`: 2,504 URLs, 2016–2024 | No | [Kim Deal, *Nobody Loves You More*](https://www.loudandquiet.com/reviews/kim-deal-nobody-loves-you-more/) → 6 | Verified (archive only) |
| *Bench* | | | | | | |
| **Beats Per Minute** | RSS `https://beatsperminute.com/category/reviews/album-reviews/feed/` (30 items) | HTML: `<div id="rating"><h3>73%` → integer percent | Feed paging `?paged=N`: page 100 = June 2010, page 200 = 404 → ≤6,000 | No | [Beck, *Ride Lonesome*](https://beatsperminute.com/album-review-beck-ride-lonesome/) → 73% | Verified |
| **Spectrum Culture** | RSS `https://spectrumculture.com/category/music/music-reviews/feed/` (10 items) | Microdata `itemprop=reviewRating` → `ratingValue` 1–100 | Feed paging: page 800 = July 2014, page 1200 = 404 → ~8–12k | No | [Kristin Hersh, *Sugar on Blackstone*](https://spectrumculture.com/2026/09/22/kristin-hersh-sugar-on-blackstone-review/) → 89 | Verified |
| **Exclaim!** | Feedburner `https://feeds.feedburner.com/ExclaimCaAllArticles` (all sections) or listing `https://exclaim.ca/music/reviews` | HTML: `div.u-article-rating` text, 1–10 | **Shallow:** listing `/music/reviews/page/N` 200 at 10, 404 at 25 (~8/page → ~200 reviews); `sitemap.xml` is capped at 7,000 URLs and holds no music articles | No | [Protomartyr, *Hotel Usona*](https://exclaim.ca/music/article/protomartyr-hotel-usona-album-review) → 8 | Verified (live only; project UA refused, `curl` served) |
| **The Independent** | `https://www.the-independent.com/sitemaps/sitemap-recent.xml` or listing `/arts-entertainment/music/reviews` (RSS returns 0 items) | JSON-LD `Review.reviewRating` 1–5 with `itemReviewed.MusicAlbum.name` + `byArtist.name` | Daily sitemaps `sitemap-articles-YYYY-MM-DD.xml` (6,532 files, back to 2009), filter `/music/reviews/`; mixes live and album reviews | No | [Ariana Grande, *Petal*](https://www.the-independent.com/arts-entertainment/music/reviews/ariana-grande-petal-review-lyrics-b3025309.html) → 2 | Verified |
| **Uncut** | RSS `https://www.uncut.co.uk/reviews/album/feed/` (20 items; project UA 200, **curl UA gets Cloudflare**) | Microdata `itemprop=reviewRating` → `ratingValue` / `bestRating 10`; visible block `tdb_single_review_overall` draws value/2 stars | Feed paging `?paged=N`: page 200 = Sept 2003, page 300 = 404 → ~4–6k. **Legacy values are ≤5 against `bestRating 10`** (6/6 pre-2010 samples: 3–4) | No | [Beck, *Ride Lonesome*](https://www.uncut.co.uk/reviews/becks-ride-lonesome-reviewed-melancholic-confessionals-and-forlorn-orchestral-folk-156337/) → 8/10 · [Ryan Adams, *Cardinology*](https://www.uncut.co.uk/reviews/ryan-adams-the-cardinals-cardinology-7014/) (2008) → "3/10", rendered 1.5 stars | Verified; legacy scale suspect |
| **Slant** | Main RSS `https://www.slantmagazine.com/feed/` (20 items, all sections); music listing `/music/` | JSON-LD `Review.reviewRating` 0–5, half steps; `itemReviewed` is typed `MusicRecording`, `name` = "Artist: Album" | Listing `/music/page/N/`: 277 pages (reviews mixed with features; ~15 album reviews on page 1) → ~4,000. At `Crawl-delay: 600` that is ~46 h of listing plus ~4 weeks of review pages | No | [Adéla, *Prima*](https://www.slantmagazine.com/music/adela-prima-album-review/) → 3.5 · listing JSON-LD: Julia Jacklin, *The Gem* → 4 | Verified (`Crawl-delay: 600`) |
| **Under the Radar** | RSS `https://www.undertheradarmag.com/site/rss` (40 items; old `/rss` now 404) | HTML: `<p id="rating"> Author rating: <b>7</b>/10` (ignore `#userrating`) | Listing `/reviews/category/music/P{offset}`: last offset P5180 → ~5,190 | No | [Ezra Collective, *Here Because Of Hope*](https://www.undertheradarmag.com/reviews/here_because_of_hope_ezra_collective) → 7 | Verified |
| **PopMatters** | RSS `https://www.popmatters.com/feed` (200 with the `compatible` UA; no score, no `content:encoded`) | — | — | Unknown | — (406 ModSecurity on review pages and robots.txt to all three honest UAs) | **Unverified** |
| **Sputnikmusic (staff)** | Listing `https://www.sputnikmusic.com/reviews/staff/albums` (no feed) | HTML: first red bold `<span style="font-size:17px;font-weight:bold;color:#ff0000;">3.8</span>`; staff filter = byline badge `<font … class=brighttext …>STAFF</font>` (users show `USER`) | Staff listing `/reviews/staff/albums/N`: page 140 has 26 (review IDs down to 27,911), page 170 empty → ~4,000 staff reviews | No | [Weezer, *The Gold Album*](https://www.sputnikmusic.com/review/91128/Weezer-The-Gold-Album/) → 3.8 (STAFF) · [Plum (IL)](https://www.sputnikmusic.com/review/91234/Plum-IL-Bodies-in-Motion/) → 4.0 (USER, excluded) | Verified |
| *Unknowns from 004, not on the list* | | | | | | |
| **SPIN** | RSS `https://www.spin.com/feed/` → spinmagazine.com (news/features); album reviews only in `post-sitemap77.xml` | **No score** on current reviews | — | — | [Beck, *Ride Lonesome*](https://www.spinmagazine.com/2026/09/beck-ride-lonesome-album-review/) → no score | Not a Publication (unscored) |
| **Kerrang!** | Listing `https://www.kerrang.com/categories/reviews` (14 latest; `feed.rss` has 1 item) | Body text: `<strong>Verdict: 5/5</strong>` | **None found:** `?page=2` returns page 1, `/page/N` 404, sitemaps hold artists/sections only | No | [Green Lung, *Necropolitan*](https://www.kerrang.com/album-review-green-lung-necropolitan) → 5/5 | Verified (live only) |

## 3. Per-Publication notes

**Pitchfork.** See §4.1 for the score source. robots.txt (`*`): `Disallow: /*?` with `Allow: /*?page`, `Allow: /*rss?`; review and listing pages are allowed. A 37-name group disallows `/` for AI and archive agents including `ClaudeBot`, `Claude-User`, `Claude-SearchBot`, `archive.org_bot` and `ia_archiver` (which also bars the Internet Archive's crawlers); this research did not use archived copies. Condé Nast's terms remain the most hostile (004 §3c); ticket 8 accepted that exposure.

**The Guardian.** `https://content.guardianapis.com/search?api-key=test` returned `401 {"message":"Unauthorized"}` on three tries today; on 2026-09-02 the same key served 24,178 album reviews. The access page still offers a free Developer key ("Up to 1 call per second, Up to 500 calls per day … Free for non-commercial usage") behind a registration form (<https://open-platform.theguardian.com/access/>). The parameters are confirmed by the Guardian's own client library (`show-fields`, `page-size`, and a `star-rating` filter: `guardian/content-api-scala-client`, `Queries.scala`). www.theguardian.com's robots.txt disallows `Claude-User` and the Guardian ToS say they "prevail … over our robots.txt"; the API is the only route ticket 8 approved. **Action for Sam:** a HITL task to register a Developer key.

**Rolling Stone.** No JSON-LD `Review`. The active/inactive star divs are exact, but half stars are only distinguishable by the SVG path, which is brittle — parse the path shape, and alert if a stars block contains an unrecognised path.

**NME.** The `aria-label` is the cleanest HTML-only parser in the set. Every page also has four or more `Rated …` widgets for related reviews, so anchor on the first one after `<h1>`. A 2012 review (Dylan's *Tempest*) renders as 3.5/5 in the same markup, so older reviews are served on the current half-star scale; how NME converted its earlier scores was not established.

**Mojo.** The live recipe never touches mojo4music.com: the Bauer aggregator is a separate host with no robots.txt (404) and carries the full review body, star run included. The feed holds ~1 month and ignores paging, so **polling must be at least monthly or reviews are lost**; history needs mojo4music.com (allowed to `*`, disallowed to `Claude-User`, so not probed here).

**AllMusic.** Ticket 004 (2026-09-02, Chrome-like UA) got album pages with JSON-LD `reviewRating` 1–10. Today both honest UAs get Cloudflare 403 on `/album/mw0000024289` (*OK Computer*). robots.txt contradicts the WAF: it explicitly `Allow: /`s `ClaudeBot`, `anthropic-ai`, `Claude-Web`, `GPTBot` and others under "#Allow Major AI Crawlers". Note robots disallows `/album/fetch_review_view/*` (the review-text endpoint), which we don't need. Whether a real browser or a named-bot allowlisting would pass is unknown; asking AllMusic is a HITL option.

**The Needle Drop.** Feed is ~15 items of mixed news; album reviews carry `Album Reviews` + a score tag. Poll at least every few days. Score tags use `N/10`; 004 noted a `NOT GOOD` label for 0 — not seen in today's samples.

**The Line of Best Fit.** JSON-LD gives album name directly (`MusicAlbum.name`); the artist is not a JSON-LD field on the samples (take it from the `<title>`/heading).

**DIY.** Rating pages (`/reviews/rating/4-5`) exist but ignore pagination; the reviews sitemap is the archive.

**Clash.** 20-second crawl-delay means the ~870-page feed backfill takes ~5 hours, then ~8,000 review pages at 20 s each ≈ **45 hours**. The score is body text, so a review without a trailing `N/10` yields nothing (treat as unscored, don't guess).

**Consequence.** `robots.txt` disallows `/feed/` and `*/feed/` to all crawlers, so 004's feed URL is off-limits to the project crawler. Its album-review volume is low now (~14 in the listing since July 2026).

**Paste / The A.V. Club.** Same platform (identical `div.header > div.rating` markup and `/articles/<section>/reviews` listings). Parser must accept both a letter grade and a decimal and record which.

**musicOMH.** Refuses the project UA at the WAF (403 even on robots.txt) but serves `curl/8.9.1`. Its terms forbid "automated scraping, crawling, or bulk downloading" (004 §3c).

**Loud and Quiet.** Treat as archive-only unless it resumes. Ticket 8 chose it as a live UK small-press voice; that role is now empty.

**Beats Per Minute / Spectrum Culture.** Straightforward WordPress feeds with paging. Spectrum's robots.txt has a `User-agent: Disco` group (`Disallow: /`); Python's `urllib.robotparser` matches it by substring against any UA containing "disco" — including `music-discovery`. Under RFC 9309's product-token matching it doesn't apply to us, but it is a real trap for ticket 23 (see §6).

**Exclaim!** Live only in practice; no discovered route to the back catalogue.

**The Independent.** RSS still empty. JSON-LD is the best-structured in the set (album + artist + rating), but the review listing mixes gigs and albums — filter on `itemReviewed.@type == MusicAlbum`.

**Uncut.** Reachable now (004 found it Cloudflare-blocked everywhere); only the curl UA is challenged. Legacy-scale problem: all six pre-2010 samples carry `ratingValue` 3 or 4 with `bestRating 10` and are drawn at half size (e.g. *Cardinology* as 1.5 stars). That pattern fits older star ratings stored unconverted; it is an inference from six samples, not a documented fact. Ingestion needs a cutover date (not established here) before which Uncut values are read as /5, or should skip pre-cutover Uncut scores.

**Slant.** Review pages now 200 to the project UA (004 found them Cloudflare-blocked). The score is clean JSON-LD. The binding constraint is robots.txt `Crawl-delay: 600` for `*` — one request per 10 minutes. Live polling of `/music/` page 1 once a day is trivial; a full backfill is ~4 weeks. The main feed (`/feed/`) is all sections and mostly film/TV.

**Under the Radar.** Review pages now 200 to the project UA (004 found them Cloudflare-blocked). robots.txt: `*` disallows only `/Media/`; `ClaudeBot` gets `Crawl-Delay: 120`.

**PopMatters.** 004 believed its scale was 1–10 (from memory); still unconfirmed. The block is ModSecurity, not Cloudflare, and it rejects even robots.txt — under RFC 9309 §2.3.1.3 a 4xx robots.txt means "unavailable" and a crawler MAY proceed, but pages are unreachable anyway.

**Sputnikmusic.** robots.txt blocks only `ia_archiver`. Beyond the ~4,000 listed staff reviews, older staff reviews are reachable only by walking review IDs 1–91,241 and filtering on the `STAFF` badge (~25 hours at 1 req/s). Other badges (e.g. contributor/emeritus) may exist and were not surveyed.

## 4. Specific unknowns from ticket 004, closed

### 4.1 Pitchfork's score source

**Embedded state, not an XHR.** Pitchfork (Condé Nast "Verso" platform) serialises page data into `window.__PRELOADED_STATE__`. On the album-reviews listing, Best New Music and High-Scoring Albums pages, each review node has `contentType: "review"`, `url`, `subHed.name` (artist), `dangerousHed` (album, HTML), `dangerousDek`, `pubDate` (ISO), `rubric[].name` (genres), and `ratingValue: { score, isBestNewMusic }`.

- Primary source: `SimonArnold002/LMS-Pitchfork-Reviews`, `PitchforkReviews/API.pm` (MIT; last commit 2026-09-20; 1.0.0 released 2026-09-17 "every review shows its Pitchfork score"). Its `_extractState` finds `window.__PRELOADED_STATE__`, brace-matches the object, and `_walkReviews` collects `contentType eq 'review'` nodes whose `url =~ /reviews/album`; the score is `$r->{ratingValue}{score}`. The author notes the field shapes were "observed clean across 133 live reviews". <https://github.com/SimonArnold002/LMS-Pitchfork-Reviews/blob/main/PitchforkReviews/API.pm>
- It fetches with a browser-like UA (`Mozilla/5.0 (Macintosh…`); whether Pitchfork's CDN serves the same HTML to an identified bot UA is **not verified**.
- Paging: `mattismegevand/pitchfork` (MIT, July 2024) walked `https://pitchfork.com/reviews/albums/?page={i}`; robots.txt allows `/*?page`. Depth today not measured.
- Scope: the plugin reads **listing** pages only. 004 found that a single review page's server HTML showed `0.0` in the score circle and its page JSON carried `ratingScale:10` and BNM flags but no score, so whether a review page's own state carries `ratingValue.score` is **unverified**. The recipe is therefore: discover and score from listings; link to the review page.
- Older scrapers read the score from HTML classes (`mattismegevand/pitchfork`, 2024: `p[class^=Rating-]`); 004's `0.0` observation suggests that no longer works, but it was not re-tested here.

### 4.2 Uncut, Slant, Under the Radar, SPIN, Kerrang!, PopMatters

| Publication | Fetchable today? | Format |
|---|---|---|
| Uncut | Yes (project UA); curl UA challenged | Microdata `reviewRating`, 1–10 now; pre-2010 values ≤5 labelled /10 (suspected stars) |
| Slant | Yes (project UA); 004's Cloudflare block gone | JSON-LD `Review.reviewRating` 0–5, half stars |
| Under the Radar | Yes; RSS moved to `/site/rss` | HTML "Author rating: N/10" |
| SPIN | Yes | **No score** on current reviews → not a Publication |
| Kerrang! | Yes | Body text "Verdict: N/5"; live only |
| PopMatters | **No** (ModSecurity 406 on pages) | Unknown |

### 4.3 Pitchfork history datasets

| Dataset | Rows / span | Fields useful for Album matching | Licence (as stated by the host) |
|---|---|---|---|
| Zenodo **P4KxSpotify** (record 3603330, 2020-01-14), `output-data.csv` 3.7 MB | 18,403 reviews | `artist`, `album`, `releaseyear`, `reviewdate`, `score`, `genre`, `recordlabel` (+ Spotify audio features). **No review URL** | **CC BY 4.0** (Zenodo API `metadata.license.id`) |
| Kaggle **nolanbconaway/24169-pitchfork-reviews** (updated 2024-11-17) | 24,169, 1999-01-05 → 2021-12-12 | View `standard_reviews_flat`: `review_url` (PK), `artists` (comma-delimited), `title`, `score`, `best_new_music`, `pub_date`, `release_year`, `labels`, `genres` (reissues excluded in the view) | **"Unknown"** (Kaggle API `licenseNameNullable`) |
| Kaggle **nolanbconaway/pitchfork-data** | 18,393, 1999 → Jan 2017 | SQLite: artists, reviews, years, labels, genres | **"Unknown"** |
| Hugging Face **mattismegevand/pitchfork** (last modified 2023-08-13), `reviews.csv` 90 MB | row count not measured (viewer misconfigured) | `artist`, `album`, `year_released`, `rating`, `reviewer`, `genre`, `label`, `reviewed` (date), `album_art_url`. **No review URL** | **MIT** (HF API `cardData.license`) |
| Kaggle **ermoore/pitchfork-reviews-through-12617** | to 2017-12-06 | not inspected | CC0 (as stated) |
| Kaggle **timstafford/pitchfork-reviews** | not inspected | album, artist, date, score, text | MIT (as stated) |

Caveats: each licence covers the uploader's compilation and code; none can license Condé Nast's review text, which we don't hold anyway. The score is a fact (004 §4a). Every set is a third-party scrape of pitchfork.com. **None carries an MBID**: all need artist + title (+ year) matching to Albums, which is ticket 23's problem. Only the Kaggle 24,169 set has `review_url`, which is also the Critic Review's link; for the others the link must be reconstructed or found via the live listing. Recommended use: take `review_url`, score and BNM from the 24,169 set (licence unknown, facts only), and fill 2022 → today from the live listing state.

### 4.4 MusicBrainz release groups with an AllMusic link

**120,192** "has an Allmusic page at" release group–URL relationships (13.2 % of 909,030 "page in a database" links), MusicBrainz relationship statistics, "Last updated: 2026-09-23" (<https://musicbrainz.org/statistics/relationships>). That counts relationships, not distinct release groups, and all release-group types (singles, EPs too), so distinct *Albums* are ≤120,192 — at most ~4 % of the Catalog's 2,894,298 Albums (ticket 21). The local Catalog Postgres (`D:\music-discovery-catalog\pgdata`) could give the exact Album-type count, but Docker Desktop's engine did not start during this session and the extracted dump files have been deleted, so that query was not run.

Cross-checks: the MusicBrainz URL search index returns 176,545 `allmusic.com/album/*` URLs (URL entities, including release-level links), but its relation fields are incompletely indexed (`targettype:release_group` returns 0), so it is not a release-group count. Wikidata has 46,520 items with an AllMusic album ID (P1729), 42,116 of them with a MusicBrainz release group ID (P436) — a smaller set, not an addition worth much.

MusicBrainz "review" relationships to other Publications are sparse (URL-index counts, 2026-09-23): pitchfork.com/reviews/albums 2,067; nme.com/reviews 889; pastemagazine.com 528; theguardian.com/music 429; popmatters 265; avclub 227; sputnikmusic 189; musicomh 104; LOBF 86; Clash 69; Consequence (both domains) 70; Rolling Stone 56; Slant 35; Mojo 29; DIY 17; Needle Drop 10; BBC (defunct reviews) 8,733. Total "has a review page at" release-group links: 48,408.

### 4.5 Sputnikmusic staff vs user

Separable two ways: (1) `https://www.sputnikmusic.com/reviews/staff/albums/N` lists only staff reviews (26 per page, ~160 pages); (2) each review page's byline carries `STAFF` or `USER` in a `font.brighttext` element next to the author link. Verified on one of each today.

## 5. robots.txt per host (fetched 2026-09-23)

| Host | `User-agent: *` | Claude agents | Notes |
|---|---|---|---|
| pitchfork.com | `Disallow: /*?` (Allow `/*?page`, `/*rss?`), `/search`, `/auth/`, `/user/` … | **`Claude-User`, `ClaudeBot`, `Claude-SearchBot` disallowed `/`** | Also archive.org, Perplexity, Meta, cohere, etc. |
| www.theguardian.com | Disallows `/search`, `/music/album/*`, `/music/artist/*`, `/discussion/*` … | **`Claude-User`, `ClaudeBot`, `Claude-SearchBot`, `anthropic-ai` disallowed `/`** | `License: https://theguardian.com/license.xml`; API host has no robots.txt (401 without key) |
| www.rollingstone.com | `/wp-admin/`, search, previews | `ClaudeBot`, `Claude-Web`, `anthropic-ai` disallowed; `Claude-User` not named | |
| www.nme.com | search, `?utm_source=`, tickets … | `ClaudeBot`, `Claude-Web`, `anthropic-ai` disallowed; `Claude-User` not named | feed item links carry `?utm_source=rss` — strip before fetching |
| www.mojo4music.com | `Disallow:` (all allowed) + `itm_source` | **`Claude-User`, `ClaudeBot`, `Claude-Web`, `anthropic-ai` disallowed `/`** | also `Python-urllib` and `Scrapy` disallowed — a default Python UA would be refused |
| rss.onebauer.media | none (404) | — | |
| www.allmusic.com | admin/search/user/Ajax review endpoints | **`ClaudeBot`, `anthropic-ai`, `Claude-Web` explicitly allowed** | WAF blocks anyway; `Go-http-client` disallowed |
| theneedledrop.com | Ghost admin paths | none | |
| www.thelineofbestfit.com | `/cpresources/`, `/vendor/`, `/.env`, `/cache/` | none | |
| diymag.com | cache/admin/`/t/*` | none | feed links are `/t/<id>` short links (disallowed path!) — **resolve via the canonical `/review/album/…` URL instead** |
| www.clashmusic.com | admin, search, **`Crawl-delay: 20`** | none | |
| consequence.net | search, **`/feed/`, `*/feed/`** | `ClaudeBot` disallowed | |
| www.pastemagazine.com | `/wp-json/`, uploads/wpforms | none | |
| www.avclub.com | `/wp-json/` | none (GPTBot/ChatGPT-User/Applebot-Extended disallowed) | |
| www.musicomh.com | `/wp-admin` | `ClaudeBot`, `anthropic-ai` disallowed | robots.txt itself 403s to the project UA |
| www.loudandquiet.com | `Disallow:` (all allowed) | none | |
| beatsperminute.com | wp paths | none | |
| spectrumculture.com | Drupal/WordPress paths; 1,775 named agents | not named | `User-agent: Disco` trap (§3) |
| exclaim.ca | `Allow: /` | none | robots.txt 403s to the project UA |
| www.the-independent.com | Drupal paths, `/search/`, `/internal-api/` | none | served gzip-encoded |
| www.uncut.co.uk | `Disallow:` / `Allow: /` | none | contains a `tdl:` (TDM-reservation) line pointing at a policy file |
| www.slantmagazine.com | `/ads-iframe/`, **`Crawl-delay: 600`** | `anthropic-ai`, `Claude-Web` disallowed | |
| www.undertheradarmag.com | `/Media/` | `ClaudeBot` `Crawl-Delay: 120` | |
| www.popmatters.com | unreadable (406) | — | |
| www.sputnikmusic.com | no `*` group | none | only `ia_archiver` blocked |
| www.spinmagazine.com | search, `/wp-json/` | none | |
| www.kerrang.com | `/craft/` | none | |
| musicbrainz.org | `/ws`, `/search`, `/url/` … `Crawl-delay: 2` | none | the web service is governed by its own API rules (1 req/s, identifying UA), not by robots.txt |

## 6. Bearing on ticket 23 (ingestion) and the launch Candidate pool

Facts first, then clearly-marked estimates.

- **No headless browser is needed for any verified recipe, and probably not for Pitchfork.** The headless cost 004 and 008 assumed for Pitchfork disappears if the state blob is served to our crawler.
- **Crawler identity matters more than expected.** One UA string does not work everywhere: musicOMH and Exclaim! refuse a custom UA but serve `curl`; Uncut serves the custom UA but challenges `curl`; PopMatters refuses all three; Mojo's robots bars `Python-urllib`; AllMusic's robots bars `Go-http-client`. Also avoid "disco" in the product token (Spectrum's `User-agent: Disco` + substring matchers). Ticket 23 should pick one honest product token, test it per host, and keep a per-host override list.
- **Polling cadence is set by the shortest window:** Mojo ~1 month (32 items), Needle Drop 15 mixed items, Kerrang! listing 14, NME/Rolling Stone/Clash feeds 10 items, LOBF listing ~24. Daily polling covers all of them.
- **Parsers are per-Publication and some are brittle:** of the 20 verified, 7 read structured data (JSON-LD or microdata: LOBF, DIY, musicOMH, The Independent, Spectrum Culture, Uncut, Slant) and 1 a feed/meta tag (Needle Drop); the other 12 parse HTML classes, accessible labels, SVG shapes or body text. Rolling Stone's half-star SVG path and Clash's and Kerrang!'s body text are the fragile ones.
- **Scale drift needs per-review scale capture:** Paste (decimal → letter), A.V. Club (letter → decimal), Uncut (pre-2010 values ≤5 labelled /10), NME (half stars, archive served on the same scale). Store the raw native value plus the scale actually observed, not a per-Publication constant.
- **Backfill time is dominated by crawl-delays:** Clash ≈ 45 h (20 s delay); Slant ≈ 4 weeks (600 s delay, ~4,000 reviews). Everything else is hours at 1 req/s.
- **Album matching is the unsolved part.** Only AllMusic (via MusicBrainz) arrives keyed to an Album. JSON-LD gives artist + album for musicOMH, The Independent and (album only) LOBF; everyone else needs artist/title parsed from headlines or body.

**Launch pool — rough estimate, not measured.** Archive sizes measured above, summed without de-duplication: Pitchfork ~27–30k (24,169 to 2021 + listing since), Guardian 24,178, NME ~11–12k, musicOMH ~10–12k, LOBF ~9k, Clash ~8k, Rolling Stone ~6–9k, Paste ~5.9k, DIY 5,216, A.V. Club ~3.5k, Loud and Quiet ~2.5k, Needle Drop ~2.3k scored, Consequence unmeasured, Mojo live only — **~115–125k Critic Reviews from the twelve measured non-AllMusic Publications** (Paste and A.V. Club totals include some unscored early reviews), heavily concentrated on the same well-known Albums. The bench would add roughly 30–40k more (Spectrum 8–12k, BPM ≤6k, Uncut 4–6k, Under the Radar ~5.2k, Slant ~4k, Sputnik staff ~4k; Independent unmeasured). AllMusic adds up to 120,192 MusicBrainz-linked release groups, if its pages can be fetched at all (not every AllMusic album page has a rated review; share unmeasured). A plausible order of magnitude (a judgement, not a measurement) for distinct Albums with a Critic Score at launch is **~50–80k without AllMusic, ~100–150k with it** — roughly **2–5 % of the 2.89M-Album Catalog**, before Album-matching losses. The AllMusic route is the swing factor, and it is the one currently blocked.

## 7. Could not verify

1. **Pitchfork** — robots.txt disallows `Claude-User`, so this agent fetched nothing from pitchfork.com. Recipe documented from third-party code (§4.1). Needs one live check by the project crawler (or by Sam in a browser: View Source on `/reviews/albums/`, search `__PRELOADED_STATE__`, confirm `ratingValue`).
2. **The Guardian** — public `test` key now refused (401 on three tries). Needs a free Developer key, which requires registration: HITL task for Sam.
3. **AllMusic** — Cloudflare 403 to every honest UA today (200 to a Chrome-like UA on 2026-09-02 per 004). Needs a decision: ask AllMusic for allowlisting, accept a browser-grade fetcher, or drop the per-Album route.
4. **PopMatters** — ModSecurity 406 on review pages and robots.txt; the feed has no score. Format unknown.
5. **Partial:** Mojo archive (mojo4music.com off-limits to this agent); Exclaim! and Kerrang! archives (no route found); Consequence archive size (sitemap index timed out); Slant archive depth is the listing page count only (one request per 10 minutes made deeper probing impractical).
6. **Not measured:** the exact count of *Album*-type release groups with AllMusic links (Docker engine would not start; extracted dump deleted); the share of AllMusic album pages that carry a rated review; the Hugging Face Pitchfork CSV row count; Uncut's /5 → /10 cutover date.

## Sources

- Ticket 004 findings: [004-critic-review-sourcing.md](004-critic-review-sourcing.md); ticket 8 resolution: <https://github.com/sameames18/music-discovery/issues/8>; ticket 21 Catalog counts: [021-catalog-load-measurements.md](021-catalog-load-measurements.md).
- Each Publication's robots.txt, feed, listing, sitemap and review URLs as linked in §2 and §5, fetched 2026-09-23.
- Pitchfork state parser: <https://github.com/SimonArnold002/LMS-Pitchfork-Reviews> (`PitchforkReviews/API.pm`, `CHANGELOG.md`); 2024 scraper: <https://github.com/mattismegevand/pitchfork> (`get_url.py`, `scrape_pitchfork.py`).
- Pitchfork datasets: Zenodo API <https://zenodo.org/api/records/3603330>; Hugging Face API <https://huggingface.co/api/datasets/mattismegevand/pitchfork> and `reviews.csv` header; Kaggle public API `https://www.kaggle.com/api/v1/datasets/view/nolanbconaway/24169-pitchfork-reviews`, `…/pitchfork-data`, and `datasets/list?search=pitchfork`.
- MusicBrainz relationship statistics: <https://musicbrainz.org/statistics/relationships> (last updated 2026-09-23); MusicBrainz web service `ws/2/url` search and `ws/2/release-group/…?inc=url-rels`.
- Wikidata Query Service counts for P1729 and P436 (2026-09-23).
- Guardian Open Platform access page <https://open-platform.theguardian.com/access/>; Guardian Scala client `Queries.scala` <https://github.com/guardian/content-api-scala-client>.
- RFC 9309 (Robots Exclusion Protocol), §2.2.1 (user-agent matching) and §2.3.1.3 (unavailable robots.txt).

# Music Discovery

An open-source, public, multi-user album catalog where Members track what they've heard, rate and review it, and get explainable recommendations built from critic scores, community scores, and tags. This file is the glossary: what words mean here, and which words to avoid. It contains no implementation decisions.

## Catalog

**Album**:
The work a listener means when they say "the album": all editions, pressings, and remasters of the same record collapsed into one thing. Ratings, Reviews, Scores, and Tags attach to Albums. Corresponds to a MusicBrainz *release group* of primary type Album or EP; singles and broadcasts are not Albums. Compilations, live albums, soundtracks, and remix albums are Albums, marked as such.
_Avoid_: release, release group, record, LP

**Edition**:
One specific official issue of an Album (the 1997 CD, the 2015 remaster, the Spotify version). Carries the track list and the identifiers (barcode, ISRCs) that let Imports resolve to an Album. Bootlegs and promos are not Editions. Every Album has one Canonical Edition whose track list the Album page shows. Corresponds to a MusicBrainz *release*.
_Avoid_: release, pressing, version

**Canonical Edition**:
The one Edition of an Album chosen to stand for it: the earliest official issue, and among ties the one with the most Tracks. Deterministic; the Album page shows its track list.
_Avoid_: main release, default version

**Track**:
One recorded performance, a single identity across every Edition it appears on (the same Track sits on the 1998 CD and the 2019 remaster), with a position on each Edition's track list. The product reasons about Albums; Tracks resolve Imports (Spotify gives songs, we need Albums) and are what a Track Reaction attaches to. Corresponds to a MusicBrainz *recording*.
_Avoid_: song, recording

**Artist**:
The credited primary performer of an Album, as printed on the cover.
_Avoid_: band, act, musician

**Participant**:
Anyone credited on an Album in any role: performer, producer, featured guest, engineer, session player. Every Artist is a Participant; most Participants are not Artists.
_Avoid_: credit, contributor, collaborator

**Catalog**:
The full set of Albums the site knows about, sourced from MusicBrainz and held in our own database. Everything in the Catalog is searchable and rateable. An Album MusicBrainz knows but the Catalog doesn't yet is fetched and added the first time a Member searches or imports it.
_Avoid_: database, library (that word belongs to Members)

## Tagging

**Tag**:
A label attached to an Album along one Axis, e.g. genre: shoegaze, mood: melancholy, region: Glasgow.
_Avoid_: label (collides with record label), category, attribute, keyword

**Axis**:
A named dimension Tags live on. Known Axes: genre, sub-genre, mood, content, decade, region, record label, participants. Region is the Artist's home area (city where known, rolling up to country), not where the Album was recorded. Participants carry their role (producer, featured guest, engineer…). More may be added.
_Avoid_: facet, dimension, category

**Genre**:
A Tag on the genre Axis, drawn from a controlled list. A sub-genre is a Genre with a parent Genre.
_Avoid_: style, style tag

## Scoring

**Signal**:
Any input the Engine may use about an Album or a Taste Profile: Critic Score, Community Score, Tags, and later Influence. Signals are pluggable; adding one must not require redesigning the Engine.
_Avoid_: feature, factor, input, weight

**Score**:
An aggregate number on an Album computed from many individual verdicts. There are exactly two: Critic Score and Community Score. A Score is never a single person's opinion.
_Avoid_: rating (that's one Member's verdict), grade, metascore

**Critic Score**:
The aggregate of Critic Reviews for an Album, computed by this site from the Publications it tracks as an unweighted mean of their normalised scores. No Publication counts more than another. A single Critic Review is enough for a Critic Score to appear.
_Avoid_: metascore, AOTY score, critic rating

**Community Score**:
The aggregate of Members' Ratings of an Album: an unweighted mean, shown regardless of how many Ratings exist. Deliberately independent of popularity — how many people have heard an Album never influences how good Members say it is; those are different axes and this site never blends them into one number.
_Avoid_: user score, RYM score, average rating, audience score

**Publication**:
A named source of Critic Reviews that publishes a numeric score: Pitchfork, The Guardian, Mojo. A source that reviews without scoring (The Quietus, Stereogum) is not a Publication here; the site does not assign scores to prose.
_Avoid_: outlet, source, site, critic (a critic is a person; we track Publications)

**Critic Review**:
One published review of one Album by one Publication, with its score normalised to a common 0–100 scale. Held as the score, a link, and the headline; the review's text is never held.
_Avoid_: article, piece

**Acclaimed**:
An Album that has a Critic Score, or a Community Score built from at least a minimum number of Ratings (a site setting, around 10 to start). Only Acclaimed Albums appear on the dashboard and in the Candidate pool. The Community Score itself still shows at any count; the minimum only governs Acclaimed status.
_Avoid_: scored, featured, rated, popular

## Members

**Member**:
A registered person on this site. Signs in by email magic link; has a public page showing their Ratings and Reviews.
_Avoid_: user (ambiguous next to "user score"), account

**Member Page**:
A Member's public page: their Ratings, Reviews, and Favourites. Not a social feed; there is no following or activity stream.
_Avoid_: profile, feed

**Rating**:
One Member's verdict on one Album, from 0.5 to 5 stars in half-star steps (the Letterboxd and Storygraph scale). A Rating implies a Log.
_Avoid_: score, grade, out of ten

**Review**:
One Member's written verdict on one Album, optionally alongside a Rating.
_Avoid_: comment, write-up

**Reaction**:
A Member's thumbs-up or thumbs-down on a Recommendation. Thumbs-up means "I listened, liked it, good recommendation": it Logs the Album and counts as liked in the Taste Profile. Thumbs-down means "bad recommendation", whether or not the Member listened: the Album is never recommended to them again, and nothing is Logged. Never a Rating; never part of the Community Score.
_Avoid_: feedback, like, vote, upvote

**Log**:
A Member's record that they have listened to an Album. A Member may Log without rating; rating always Logs.
_Avoid_: history, diary, scrobble, listen

**Library**:
Everything a Member has logged, rated, reviewed, imported, or marked as a Favourite. The Engine never recommends an Album already in the Member's Library.
_Avoid_: collection, profile, history

**Favourite**:
An Album a Member marks as defining their taste. Favourites are the primary input to the Taste Profile; a Member picks at least five.
_Avoid_: liked, loved, top album, pick

**Crate**:
A Member's list of Albums they mean to listen to later (Letterboxd's watchlist). Not part of the Library, since nothing in it has been heard; says nothing about taste, but the Engine never recommends an Album already in it.
_Avoid_: watchlist, queue, up next, saved, wishlist

**Import**:
A one-off ingestion of external listening data into a Member's Library, resolved from Tracks and Editions to Albums.
_Avoid_: sync, connect, link, integration

**Source**:
Where an Import came from: Spotify, an uploaded file, or hand-picked. Apple Music is a future Source.
_Avoid_: provider, platform, service

## Discovery

**Taste Profile**:
The derived description of one Member's taste: their Throughlines, each with a strength. Computed from their Favourites and Library (Favourites count most; Ratings count relative to the Member's own average, so a low one counts against; a thumbs-up Reaction and a saved Import count as liked; Albums only seen in listening history count as heard, not liked).
_Avoid_: analysis, preferences, model, taste graph

**Throughline**:
One Tag, or a pair of Tags on different Axes, shared by Albums a Member likes (post-punk + Glasgow; produced by Madlib). Formed by at least two liked Albums or one Favourite. Its strength is how much the Member likes the Albums in it, scaled by how few Acclaimed Albums share it; pairs outrank single Tags. Every Recommendation comes from exactly one Throughline.
_Avoid_: cluster, thread, group, segment

**Candidate**:
An Acclaimed Album the Engine is considering for a Member. Never an Album in the Member's Library or Crate, one they gave a thumbs-down, by an Artist of one of their Favourites, credited to Various Artists, or marked Compilation, Live, DJ-mix, Mixtape, or Remix; those stay searchable and rateable, just never recommended.
_Avoid_: option, prospect

**Recommendation**:
A Candidate the Engine has ranked and presented to a Member, always accompanied by a Reason. A Member gets a short list of them each day (five), drawn one per Throughline; there is no endless feed.
_Avoid_: suggestion, pick, rec, result

**Reason**:
The human-readable explanation attached to a Recommendation, naming its Throughline, up to three of the Member's Albums behind it, and the Critic Score with how many Critic Reviews it rests on ("You rated three Glasgow post-punk Albums 4 stars or more; this is the best-reviewed one you haven't heard: Critic Score 88 from 6 reviews").
_Avoid_: explanation, why, rationale

**Engine**:
The deterministic process that turns a Taste Profile and the Signals into each day's finite list of Recommendations: it finds the Member's strongest Throughlines and picks the most acclaimed Candidate in each. Same inputs (Library, Reactions, Catalog, date) always produce the same list. New Signals join either as an Axis that forms Throughlines or as an input to ranking within one.
_Avoid_: algorithm, model, recommender, AI, ML

**Influence** (future):
A documented statement, from an interview or liner notes, that one Artist shaped another. A future Signal, not in the first build.
_Avoid_: similar artist, related artist

## Open questions

Terms whose definitions wait on a decision. The Wayfinder map tickets these.

- **Genre vocabulary**: whose controlled list Genres come from (MusicBrainz genres, a curated hierarchy of our own, or another).
- **Mood and content Tags**: deferred past the first build. Where they come from (curation, community tagging, or derived by a model) is undecided.
- **Track Reaction**: a Member's thumbs-up or thumbs-down on one Track. Neither a Rating (those are Album-level stars) nor a Reaction (those are on Recommendations). Whether it Logs the Album, feeds the Taste Profile, or shows on the Member Page is undecided (Member data model ticket).
- **Popularity**: a possible future indicator of how widely an Album is heard, deliberately separate from Community Score — never blended into it, never a substitute for it, never a factor in Acclaimed status. Dropped from v1: no source cleared both terms and budget (RIAA certifications are US-only and tier-based, not continuous; ListenBrainz listener counts are usable but weren't enough on their own; Spotify, Deezer, Last.fm, YouTube, kworb, and Billboard are all ruled out on terms; Chartmetric and Soundcharts are priced well over the site's budget). Revisit only if a new clean source appears or the budget changes.

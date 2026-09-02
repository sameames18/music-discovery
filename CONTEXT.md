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
A named dimension Tags live on. Known Axes: genre, sub-genre, mood, content, decade, region, participants. More may be added.
_Avoid_: facet, dimension, category

**Genre**:
A Tag on the genre Axis, drawn from a controlled list. A sub-genre is a Genre with a parent Genre.
_Avoid_: style, style tag

## Scoring

**Signal**:
Any input the Engine may use about an Album or a Taste Profile: Critic Score, Community Score, Popularity Proxy, Tags, and later Influence. Signals are pluggable; adding one must not require redesigning the Engine.
_Avoid_: feature, factor, input, weight

**Score**:
An aggregate number on an Album computed from many individual verdicts. There are exactly two: Critic Score and Community Score. A Score is never a single person's opinion.
_Avoid_: rating (that's one Member's verdict), grade, metascore

**Critic Score**:
The aggregate of Critic Reviews for an Album, computed by this site from the Publications it tracks as an unweighted mean of their normalised scores. No Publication counts more than another. A single Critic Review is enough for a Critic Score to appear.
_Avoid_: metascore, AOTY score, critic rating

**Community Score**:
The aggregate of Members' Ratings of an Album.
_Avoid_: user score, RYM score, average rating, audience score

**Popularity Proxy**:
An open-data stand-in (listener counts, collection counts, third-party ratings) used in place of Community Score while an Album has too few native Ratings. Always weaker than a real Community Score.
_Avoid_: fallback score, external rating

**Publication**:
A named source of Critic Reviews that publishes a numeric score: Pitchfork, The Guardian, Mojo. A source that reviews without scoring (The Quietus, Stereogum) is not a Publication here; the site does not assign scores to prose.
_Avoid_: outlet, source, site, critic (a critic is a person; we track Publications)

**Critic Review**:
One published review of one Album by one Publication, with its score normalised to a common 0–100 scale. Held as the score, a link, and the headline; the review's text is never held.
_Avoid_: article, piece

**Acclaimed**:
An Album that has at least one Critic Score or Community Score. Only Acclaimed Albums appear on the dashboard and in the Candidate pool.
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
A Member's thumbs-up or thumbs-down on a Recommendation. A Reaction is about the recommendation ("good call" / "not for me"), not a Rating of the Album.
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

**Import**:
A one-off ingestion of external listening data into a Member's Library, resolved from Tracks and Editions to Albums.
_Avoid_: sync, connect, link, integration

**Source**:
Where an Import came from: Spotify, an uploaded file, or hand-picked. Apple Music is a future Source.
_Avoid_: provider, platform, service

## Discovery

**Taste Profile**:
The derived description of one Member's taste, computed from their Favourites and Library and expressed in Tags and Signals. Recomputed whenever the Library changes.
_Avoid_: analysis, preferences, model, taste graph

**Candidate**:
An Acclaimed Album not in the Member's Library that the Engine is considering.
_Avoid_: option, prospect

**Recommendation**:
A Candidate the Engine has ranked and presented to a Member, always accompanied by a Reason.
_Avoid_: suggestion, pick, rec, result

**Reason**:
The human-readable explanation attached to a Recommendation, naming the Signals and Favourites that produced it ("You rated three Glasgow post-punk albums 8+; this is the highest Critic Score among them you haven't logged").
_Avoid_: explanation, why, rationale

**Engine**:
The deterministic process that turns a Taste Profile and the Signals into a finite, ranked list of Recommendations. Same inputs always produce the same list.
_Avoid_: algorithm, model, recommender, AI, ML

**Influence** (future):
A documented statement, from an interview or liner notes, that one Artist shaped another. A future Signal, not in the first build.
_Avoid_: similar artist, related artist

## Open questions

Terms whose definitions wait on a decision. The Wayfinder map tickets these.

- **Genre vocabulary**: whose controlled list Genres come from (MusicBrainz genres, a curated hierarchy of our own, or another).
- **Mood and content Tags**: deferred past the first build. Where they come from (curation, community tagging, or derived by a model) is undecided.
- **Track Reaction**: a Member's thumbs-up or thumbs-down on one Track. Neither a Rating (those are Album-level stars) nor a Reaction (those are on Recommendations). Whether it Logs the Album, feeds the Taste Profile, or shows on the Member Page is undecided (Member data model ticket).

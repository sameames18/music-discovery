# music-discovery

An open-source, public, multi-user album catalog and discovery site, in the family of Rate Your Music, Letterboxd and The StoryGraph. Members log, rate and review albums, and get a short, explained daily list of recommendations built from critic scores, community scores and tags. The name is a placeholder.

The site tracks Albums, not songs. It shows two scores side by side:

- **Critic Score:** our own average of scored reviews from named Publications (Pitchfork, the Guardian, Mojo and others).
- **Community Score:** the average of Members' star Ratings.

Popularity is never mixed into either score. Recommendations come from a deterministic Engine: it finds threads running through the Albums a Member loves and names them ("post-punk from Glasgow", "produced by Madlib"), then picks the best-reviewed unheard Album in each. Five a day, each with a Reason, and no endless feed.

## Status

_Updated 2026-09-27._

**Planning, not yet building.** The project is charting every decision the build spec needs before any site code is written. The plan lives on a Wayfinder map, [issue #20](https://github.com/sameames18/music-discovery/issues/20): what's decided, what's open, and what's out of scope.

- **Progress:** 15 of 26 planning tickets closed.
- **Settled:**
  - where the Catalog comes from (MusicBrainz, about 2.9 million Albums);
  - which Publications feed the Critic Score, and how their scores combine;
  - how the Community Score works;
  - the Engine's design;
  - legal and privacy obligations;
  - onboarding: import a Spotify data export or a Last.fm username, or pick Favourites by hand.
- **Built so far:** a Catalog loader that turns the MusicBrainz data dump into our own database, measured at 14 GB ([scripts/ingest](scripts/ingest)).
- **Up next:**
  - the Tag model;
  - a clickable prototype of the dashboard, Album page and Member Page;
  - the tech stack;
  - how AllMusic and the Guardian are fetched;
  - loading Critic Reviews.

The map is done when the spec is written. It ends with a phased build order, and phase 1 is built by agents.

## Repository

- [CONTEXT.md](CONTEXT.md): the glossary. Every term used here (Album, Edition, Critic Score, Throughline, Import…) is defined there.
- [docs/research](docs/research): findings from research tickets, one file per ticket.
- [scripts/ingest](scripts/ingest): the Catalog loader.
- [wayfinder/TRACKER.md](wayfinder/TRACKER.md): how the planning tickets work on GitHub Issues.
- [AGENTS.md](AGENTS.md): operating instructions for the AI agents doing the work.

## Licence

[AGPL-3.0](LICENSE). Catalog data comes from [MusicBrainz](https://musicbrainz.org). Its core data is CC0; its genre tags and ratings are CC BY-NC-SA 3.0.

---
ticket: 003
title: Spotify Web API and library export, current state
branch: research/spotify
researched: 2026-09-01
---

# Spotify Web API and library export (ticket 003)

All sources accessed 2026-09-01 unless noted. Spotify's developer terms and quota rules have changed three times in the last 22 months (Nov 2024, May 2025, Feb 2026) plus a quota tweak in Jul 2026; every claim below carries the date of the page or post it came from. Re-check the dated items before the spec is finalised.

Vocabulary follows `CONTEXT.md`: a Spotify **Import** is a one-off ingestion of a **Member**'s saved content into their **Library**, resolved via **Tracks** and **Editions** to **Albums**.

## Headline

**A Spotify OAuth "link your account" Source cannot serve a public multi-user site today.** Development Mode caps an app at five authorised Spotify users, and the only way out (extended quota) is closed to anyone who is not a registered business with 250,000 monthly active users. The endpoints we need (`GET /me/albums`, `GET /me/tracks`) still work and still expose ISRC and UPC, so the API is usable for an allowlisted handful of Members and for server-side lookups. For everyone else the workable Spotify Source is the **account data export** (a zip of JSON the Member downloads from Spotify and uploads to us), and ListenBrainz is a cheaper universal Import because it hands us MusicBrainz IDs directly.

## 1. Scopes and endpoints for saved tracks and saved albums

Source: Scopes reference, https://developer.spotify.com/documentation/web-api/concepts/scopes (page undated; footer "© 2026 Spotify AB").

- `user-library-read` — "Read access to a user's library." Consent screen shows "Access your saved content." This single scope covers both saved tracks and saved albums.
- `user-top-read` — "Read access to a user's top artists and tracks."
- `user-read-recently-played` — "Read access to a user's recently played tracks."
- `user-read-email` / `user-read-private` — not needed; sign-in is by magic link (standing decision), so we should not request them.

### `GET /me/albums` (Get User's Saved Albums)

Source: https://developer.spotify.com/documentation/web-api/reference/get-users-saved-albums

- Scope `user-library-read`. Params `limit` (default 20, max 50), `offset`, `market`.
- Returns a paged object (`href, limit, next, offset, previous, total, items`). Each item is `{ added_at, album }` where `album` is the **full** album object, including `external_ids` with `upc` / `ean` / `isrc` keys, `release_date`, `release_date_precision`, `artists`, and a paged `tracks` list.
- This is the endpoint that gives UPC without extra calls.

### `GET /me/tracks` (Get User's Saved Tracks)

Source: https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks

- Scope `user-library-read`. Params `limit` (default 20, max 50), `offset`, `market`.
- Each item is `{ added_at, track }`. The track carries `external_ids.isrc`. The nested `album` is a **SimplifiedAlbumObject** which does **not** include `external_ids` (confirmed on https://developer.spotify.com/documentation/web-api/reference/get-track — simplified album fields are `album_type, total_tracks, available_markets, external_urls, href, id, images, name, release_date, release_date_precision, restrictions, type, uri, artists`).
- To get a UPC for the album a saved track belongs to, call `GET /albums/{id}` per album. The batch `GET /albums` (max 20 ids, https://developer.spotify.com/documentation/web-api/reference/get-multiple-albums) was **removed from Development Mode in Feb 2026** (see §3), so it is one call per distinct album.

### Other Library-shaped endpoints still available

- `GET /me/top/{type}` — scope `user-top-read`; `time_range` = `long_term` ("calculated from ~1 year of data"), `medium_term` (~6 months), `short_term` (~4 weeks); `limit` max 50. https://developer.spotify.com/documentation/web-api/reference/get-users-top-artists-and-tracks
- `GET /me/player/recently-played` — scope `user-read-recently-played`; `limit` max 50; cursors `after`/`before` (ms timestamps). Only a 50-item window; not a listening history. https://developer.spotify.com/documentation/web-api/reference/get-recently-played

### Pagination

Source: https://developer.spotify.com/documentation/web-api/concepts/api-calls — "Some endpoints support a way of paging the dataset, taking an offset and limit as query parameters." Responses carry `next`/`previous` URLs and `total`. Base URL `https://api.spotify.com/v1`. Errors include `429` "Rate limiting or quota restrictions have been applied", with an optional `reason` such as `QUOTA_EXCEEDED`.

### Rate limits

Source: https://developer.spotify.com/documentation/web-api/concepts/rate-limits (undated).

- "Spotify's API rate limit is calculated based on the number of calls that your app makes to Spotify in a rolling 30 second window."
- On breach: `429` with "a `Retry-After` header with a value in seconds."
- "The limit varies depending on whether your app is in development mode or extended quota mode." **No numbers are published.**
- Since 23 Jul 2026 quota is counted **per developer account, not per Client ID**, and quota breaches return `429` with reason `QUOTA_EXCEEDED` (https://developer.spotify.com/blog/2026-07-23-web-api-quota-updates and https://developer.spotify.com/documentation/web-api/references/changes/july-2026). Any server-side lookups we make (e.g. resolving `spotify_track_uri`s from an uploaded export) draw from the same pool as Member-authorised calls.

A full Library pull for one Member is `ceil(saved_albums/50) + ceil(saved_tracks/50)` calls plus one `GET /albums/{id}` per distinct album seen only via saved tracks. A Member with 2,000 saved tracks across 600 albums and 300 saved albums is roughly 40 + 6 + 600 ≈ 650 calls.

## 2. Development Mode vs extended quota mode

Source: Quota modes, https://developer.spotify.com/documentation/web-api/concepts/quota-modes (reflects the 15 May 2025 and Feb 2026 rules).

### Development Mode (what every new app is)

Verbatim: "Newly-created apps begin in development mode. This mode is perfect for apps that are under construction and apps that have been built for accessing or managing data in a single Spotify account. The app owner must have a Spotify Premium account for apps in development mode to function. Up to 5 authenticated Spotify users can use an app that is in development mode — so you can share your app with beta testers, friends, or with fellow developers who are working on the app. Each Spotify user who installs your app will need to be added to your app's allowlist before they can use it."

The 6 Feb 2026 announcement (https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security) set these rules: "Development Mode use will require a Spotify Premium account"; "Developers will be limited to one Development Mode Client ID"; "Each Client ID will be limited to up to five authorized users"; "API access will be limited to a smaller set of supported endpoints." Effective 11 Feb 2026 for new Client IDs, 9 Mar 2026 for existing ones. Framing: Development Mode "will continue to support learning, experimentation, and personal projects for non-commercial use by individual developers" and "should not be relied on as a foundation for building or scaling a business."

The Client ID limit was raised back from 1 to 25 per developer account on 23 Jul 2026 (https://developer.spotify.com/blog/2026-07-23-web-api-quota-updates); the five-user cap per Client ID was not changed. Because quota is now per account, 25 Client IDs do not multiply throughput, and nothing in the Jul 2026 post suggests the five-user allowlist is per-account rather than per-Client-ID — I could not verify whether 25 × 5 allowlisted users is permitted or would be treated as circumvention (Terms IV.2.2 prohibits "excessive service calls" and circumvention; Policy III.13 prohibits analysing the Service). Treat it as not available.

### Extended quota mode

Verbatim from the quota-modes page: "Extended quota mode is for Spotify apps that are ready for a wider audience. Apps in this category can be installed by an unlimited number of users and the allowlist in development mode no longer applies. Extended quota mode apps also have access to a higher rate limit than development mode apps do. As of May 15th 2025, Spotify only accepts applications from organizations (not individuals). Application must be sent through a company email by using this form. Implementation requirements: 1. Established Business Entity (legally registered business or organisation) 2. Operating an active, and Launched Service 3. Maintaining a minimum of active users (at least 250k MAUs) 4. Being available in key Spotify markets 5. Commercial Viability 6. Adherence to Terms". Review "can take up to six weeks."

The 15 Apr 2025 blog post (https://developer.spotify.com/blog/2025-04-15-updating-the-criteria-for-web-api-extended-access) gives the rationale: extended access is "reserved for apps with established, scalable, and impactful use cases that help drive our platform strategy forward and promote artists and creator discovery"; "Over 95% of the applications we receive for extended Web API access fall short of basic security, privacy, and licensing standards." Apps already holding extended access "will remain unaffected."

### Would a hobby / open-source site qualify?

No. The criteria are conjunctive and the first three (legal entity, launched service, 250k MAU) are each individually disqualifying for a pre-launch AGPL project with no company behind it. There is no non-commercial, research, or open-source track. The community-forum threads where developers asked about early-stage apps (e.g. https://community.spotify.com/t5/Spotify-for-Developers/How-to-transition-out-of-Development-Mode-under-the-May-2025/td-p/7490273 and https://community.spotify.com/t5/Spotify-for-Developers/How-to-Apply-for-Extended-Quota/td-p/7452014) returned HTTP 403 to automated fetching, so I could not quote staff replies; the primary documentation above is unambiguous on its own.

## 3. Endpoints deprecated or restricted for new apps

### Round 1 — 27 Nov 2024

Source: https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api. Restricted for "Existing apps that are still in development mode without a pending extension request" and "New apps that are registered on or after today's date":

1. Related Artists
2. Recommendations
3. Audio Features
4. Audio Analysis
5. Get Featured Playlists
6. Get Category's Playlists
7. 30-second preview URLs in multi-get responses
8. Algorithmic and Spotify-owned editorial playlists

None of these matter for an Import; the standing decision is that our Engine is our own. The reference page for Recommendations (https://developer.spotify.com/documentation/web-api/reference/get-recommendations) now carries policy banners rather than a functioning contract.

### Round 2 — Feb 2026 (new apps 11 Feb, existing apps 9 Mar)

Source: changelog https://developer.spotify.com/documentation/web-api/references/changes/february-2026 and migration guide https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide.

**Still supported in Development Mode (relevant to us):** `GET /me`, `GET /me/tracks`, `GET /me/albums`, `GET /me/following`, `GET /me/top/{type}`, `GET /me/player/recently-played`, `GET /albums/{id}`, `GET /albums/{id}/tracks`, `GET /tracks/{id}`, `GET /artists/{id}`, `GET /search`, `GET /me/playlists`, `GET /playlists/{id}/items`, and the new generic `PUT /me/library`, `DELETE /me/library`, `GET /me/library/contains`.

**Removed from Development Mode:** batch fetches `GET /tracks`, `GET /albums`, `GET /artists`, `GET /episodes`, `GET /shows`, `GET /audiobooks`, `GET /chapters`; `GET /browse/new-releases`, `GET /browse/categories`, `GET /browse/categories/{id}`; `GET /artists/{id}/top-tracks`; other-user endpoints `GET /users/{id}`, `GET /users/{id}/playlists`, `POST /users/{user_id}/playlists`; `GET /markets`.

**Changed:** `GET /search` "limit parameter maximum value has been reduced from 50 to 10" (default 5). Entity-specific save/remove/contains endpoints (`PUT|DELETE /me/tracks`, `/me/albums`, `GET /me/tracks/contains`, `GET /me/albums/contains`, etc.) are deprecated in favour of `/me/library`.

**Deprecated fields on album/track objects** (per https://developer.spotify.com/documentation/web-api/reference/get-multiple-albums): `available_markets`, `linked_from`, `genres` ("always returns empty array"), `label`, `popularity`, `preview_url`. Do not design any Signal around Spotify `popularity` or `genres`.

### Round 3 — 23 Jul 2026

Quota accounting changes only (per-account quota, 25 Client IDs, `QUOTA_EXCEEDED` reason). No endpoint changes.

**Pattern:** three restriction rounds in fifteen months, each applied to dev-mode apps first. Anything built on the Spotify API should sit behind an adapter that can be switched off without touching the Import model.

## 4. Developer Terms and Developer Policy clauses that touch this product

Developer Terms: https://developer.spotify.com/terms — "Version 10, effective as of 15 May, 2025". Developer Policy: https://developer.spotify.com/policy — effective 15 May 2025. Both are accepted at app registration (https://developer.spotify.com/documentation/web-api/concepts/apps) and "Modifications take effect upon posting" (Terms IX.2). "SDA" = Spotify Developer Application, i.e. our site.

### Definitions

- **Spotify Content** (Terms): "any content, data, information or material made available through the Spotify Platform, Spotify Service or by Spotify. This may include, among other things, sound recordings, short-form videos, cover art, musical works, podcasts, artist biographies, song lyrics, metadata, playlists, and user data including Spotify Personal Data." — so a Member's saved-album list, and every ISRC/UPC we read, is Spotify Content.
- **Spotify Personal Data** (Terms Appendix A): "any Personal Data in respect of which Spotify or a Spotify Affiliate is a data controller, which you process in connection with the Developer Terms." We act as an "independent data controller" for it (Terms V).

### Storing and caching

- Terms IV.2.1 (storage): "you may not store, aggregate or create compilations or databases of Spotify Content, other than as strictly necessary to operate your SDA."
- Terms IV.3.2 (caching): "Do not locally cache any Spotify Content, except as strictly necessary to enhance the performance of your SDA and its functionality, and limited to the temporary caching of: (1) metadata and cover art; or (2) Conditional Downloads". No numeric retention period is stated in Version 10 (I searched for "24 hours" and "30 days"; the only hits are the 24-hour security-incident notice and a 30-day dispute-resolution window).
- Terms V.7: process Spotify Personal Data "for as long as is necessary to provide your SDA to the applicable user".
- Terms V.8 / Policy I.1.b: "when a user disconnects their Spotify account or otherwise expresses an intent to prevent your SDA from accessing their data, you agree to delete and no longer request or process any of that user's personal data." Appendix A.5.c: delete "within five (5) days". Terms IX.8.7: on termination of the agreement, "delete all Spotify Content (including Spotify Personal Data) obtained through use of the Spotify Platform."
- Terms IV.2.2.2: no "robot, spider, site search/retrieval application, or other tool to retrieve, duplicate, or index any portion of the Spotify Service".
- Terms IV.2.5: no transfer of "any data (including aggregate, anonymous or derivative data)" to any "ad network, ad exchange, data broker, or other advertising or monetization-related toolset".

**Reading for this product.** An Import that reads the saved list, resolves each item to a MusicBrainz Album, writes Logs/Favourites, and then discards the Spotify payload keeps only what is "strictly necessary to operate" the site. What we retain afterwards (Logs pointing at MusicBrainz release groups) is arguably our data derived from the Member's own Library, but it was obtained through the Platform, so the disconnect-and-delete duty (V.8) plausibly reaches it. Whether a Member disconnecting Spotify must also wipe the Logs the Import created is a legal call for ticket 006 and a data-model call for 016; the safest reading is to keep Import provenance on each Log so deletion is possible.

### Recommendations, "competing", and analysis

- Policy III.11: "Do not build products and services that mimic, or replicate or attempt to replace a core user experience of Spotify or its group companies without our prior written permission."
- Policy III.13: "Do not analyze the Spotify Content or the Spotify Service for any purpose, including without limitation, creating new or derived listenership metrics, benchmarking, functionality, usage statistics, user metrics."
- Policy III.14 / Terms IV.2.1: "Do not use the Spotify Platform or any Spotify Content to train a machine learning or AI model or otherwise ingest Spotify Content into a machine learning or AI model."
- Policy III.5: "Do not create any product or service which is integrated with streams or content from another service."
- Policy III.9: "Do not build an SDA that enables the transfer of data to another service, except for the purpose of enabling a user to transfer their personal data, or the metadata of the user's playlists to another service."
- Policy II.4.c: "You must not offer metadata, cover art, and/or Audio Preview Clips as a standalone service or product."
- Terms IX.3 (the only "compete" language): the agreement is non-exclusive and "Spotify and/or other third parties may be developing products and services that may be similar to or competitive with your SDA" — this is a disclaimer, not a prohibition.

**Reading for this product.** III.13 is the sharpest clause: computing a Taste Profile is "analysis" of what was, at the moment of Import, Spotify Content. The defensible position is that the Taste Profile is computed from the Member's Library (Albums in our Catalog, MusicBrainz identities, our Tags and Scores) after the Import has ended, not from Spotify Content, and that the Engine is deterministic (no ML training, so III.14 is not engaged). III.9's exception ("enabling a user to transfer their personal data") is close to a description of an Import. III.11 ("replace a core user experience") is the residual risk: an explainable-recommendations site is adjacent to Spotify's discovery features. These are questions for the legal/privacy ticket (006); nothing here is a bright-line block, and nothing here is a clearance.

### Attribution and branding

- Policy II.4.a: "If you display any Spotify Content you must clearly attribute the content as being supplied and made available by Spotify, by using the Spotify Marks."
- Policy II.4.b: "Metadata, cover art and Audio Preview Clips must be accompanied by a link back to the applicable album, content or playlist on the Spotify Service."
- Design guidelines (https://developer.spotify.com/documentation/design, undated): "If you use any Spotify metadata (including artist, album and track names, album artwork, and audio playback) it must always be accompanied by the Spotify brand" and "must always link back to the Spotify Service"; "Track, artist, playlist, and album titles must always be presented with the metadata provided by Spotify"; "Spotify content should never be seated next to content from similar services."

**Reading for this product.** These obligations attach to *displaying* Spotify Content. If the Import resolves to MusicBrainz and the site only ever renders MusicBrainz names and Cover Art Archive images, no Spotify Mark or link-back is required and the "never seated next to content from similar services" rule (which would collide with an Apple Music Source later) is not triggered. Showing Spotify album titles or artwork on an Import review screen ("we matched these 300 albums") would trigger all three.

### Open source / AGPL

Neither document mentions open source licensing of the developer's own application. Terms III.3 says only that Spotify's SDKs may contain "open source software or third party software... made available to you under the terms of the applicable licenses." Terms IV.2.1 prohibits "modifying, editing, altering, creating derivative works, disassembling, decompiling, reverse-engineering" the *Spotify Platform*, not our code. Terms V requires us to show Members an end-user agreement that disclaims Spotify warranties, prohibits derivative works and reverse-engineering of the Platform, and names Spotify as a third-party beneficiary — that is a clause for our Member terms, not a licence conflict. The practical constraint is operational: the Client Secret must never be in the public repo ("never reveal it publicly!", apps page), so the AGPL codebase ships without credentials and each deployer registers their own app — which, under Development Mode, gives each deployer five users.

### Privacy policy and security

- Policy I.1.a / Terms V: a privacy policy "which clearly describes how you intend to access, use, process and disclose user data", shown before installation/sign-up; "industry standard security protection"; security incidents reported to security@spotify.com "within twenty-four (24) hours" (Appendix A.9); GDPR standards apply "regardless of user or developer location".
- Policy I.1.b: "an easily accessible mechanism to disconnect their Spotify account from your SDA at any time."

## 5. Matching Spotify items to MusicBrainz Editions and Albums

### What Spotify exposes

- Track `external_ids.isrc` (https://developer.spotify.com/documentation/web-api/reference/get-track); album `external_ids.upc` / `.ean` on the **full** album object only (https://developer.spotify.com/documentation/web-api/reference/get-an-album). `GET /me/albums` returns full albums; `GET /me/tracks` returns simplified albums (no UPC).
- Spotify Search accepts `isrc:` (tracks) and `upc:` (albums) filters (https://developer.spotify.com/documentation/web-api/reference/search), but that is the reverse direction; with the dev-mode `limit` cap of 10 it is only useful for spot checks.
- The Spotify album URL / URI itself (`open.spotify.com/album/{id}`) is a matchable key (below).

### What MusicBrainz accepts

Source: https://musicbrainz.org/doc/MusicBrainz_API and https://musicbrainz.org/doc/MusicBrainz_API/Search.

- ISRC lookup: "An `isrc` lookup returns a list of recordings" — `/ws/2/isrc/{isrc}?inc=releases+release-groups` goes ISRC → recording(s) → release(s) → release group, i.e. Track → Edition → Album.
- Barcode: release search field `barcode` ("the barcode for the release"); Spotify UPC/EAN → Edition.
- URL lookup: `/ws/2/url?resource=https://open.spotify.com/album/...&inc=release-rels` — "The 'resource' parameter can be specified multiple times (up to 100) in a single query"; unmatched resources "are simply omitted." MusicBrainz style attaches Spotify album links to the digital-media Edition ("streaming and download links are only appropriate for digital releases", https://musicbrainz.org/doc/Style/Relationships/URLs), which resolves to its Album.
- Rate limit: "never make more than ONE call per second", meaningful `User-Agent` required, IP blocking on breach. A 1,000-item Import is therefore ≥ ~17 minutes of MusicBrainz calls unless we use a local replica of the database (ticket 007's ingestion strategy decides this; the identifiers above are all plain columns in the MusicBrainz dump).

### Coverage (the honest proxy for accuracy)

MusicBrainz statistics, https://musicbrainz.org/statistics (as of 2 Sep 2026): 40,039,901 recordings, of which 6,135,126 have ISRCs (~15%); 5,745,901 releases, of which 2,549,705 have barcodes (~44%); 4,493,395 release groups; 21,465,618 URL relationships (the Spotify-specific count is not broken out).

No primary source publishes a Spotify→MusicBrainz match rate. Coverage skews heavily toward exactly the Albums this site cares about (Acclaimed, widely-listened catalogue), so real-world precision on a typical Library will be far better than 15%/44% suggest, but a long tail of unresolved items (regional editions, singles, compilations, re-issues with new UPCs) is certain. ListenBrainz's own resolver, which has solved this at scale, is a name-based fallback: `GET|POST /1/metadata/lookup/` takes `artist_name`, `recording_name`, `release_name` and returns `recording_mbid`, `release_mbid`, `artist_mbids` — but "requires an auth token" ("Because of possible abuse by AI scrapers") and its response "does not indicate whether a match was found or not" (https://listenbrainz.readthedocs.io/en/latest/users/api/metadata.html). The measured accuracy figure this ticket asks for needs a prototype against real Libraries; that belongs with ticket 013 or a small prototype ticket, not here.

Suggested resolution ladder (facts, not a decision): Spotify album URL → MB `url` lookup; else UPC/EAN → MB release `barcode`; else each Track's ISRC → MB recording → release group (majority vote across the album's tracks); else artist+title fuzzy match; else leave unresolved and show the Member.

## 6. Manual-import fallback

### Spotify "Download your data"

Sources: https://support.spotify.com/us/article/data-rights-and-privacy-settings/ and https://support.spotify.com/us/article/understanding-my-data/ (undated support articles). The request page https://www.spotify.com/account/privacy/ is behind a login wall and was not fetched.

- "You can get a ZIP file with a copy of your personal data by using the automated Download your data tool on your Account Privacy page or by contacting us" (privacy@spotify.com). Files are JSON; a "Read Me First" file is included.
- Three packages: **account data**, **extended streaming history**, **technical log**.
- Account data includes **Your Library**: "A summary (at the point of the date of the request) of the content saved in Your Library (songs, episodes, shows, artists, and albums), including: Entity names. Album & Show names. Creators." Also **Playlist** (names, songs, artists), **Streaming History** ("listened to or watched in the past year"), Search queries, Follow, User Data (username, email, DOB, postal code...), Payments (card type, last four digits), Inferences, Taste Profiles, Wrapped, etc.
- Extended streaming history: "listened to or watched during the lifetime of your account, including... Date and time of when the stream ended in UTC format. Your Spotify username. Platform used when streaming the track."
- Exact JSON field names are not on the support pages. ListenBrainz's production importer (https://github.com/metabrainz/listenbrainz-server/blob/master/listenbrainz/background/listens_importer/spotify.py, master as of 2026-09-01) reads these keys from files whose names contain "audio" or "endsong": `ts`, `ms_played`, `skipped`, `reason_end`, `incognito_mode`, `master_metadata_track_name`, `master_metadata_album_artist_name`, `master_metadata_album_name`, `spotify_track_uri`; it drops plays under 30,000 ms that were skipped. MetaBrainz notes "The Spotify data archives do not contain the track artist name but the album artist name" and resolves via "the spotify identifiers in the data archive" against the Spotify API (https://blog.metabrainz.org/2025/08/30/gsoc-2025-importing-listening-history-files-in-listenbrainz/, 30 Aug 2025).
- **Can a Member upload it?** Yes, technically: it is a zip of JSON the Member owns, and uploading it is exactly the "transfer their personal data" exception in Policy III.9. The package also contains email, DOB, postal code and partial card numbers, so the upload path must read only the library/streaming files and discard the rest client-side or immediately on receipt (this matters for ticket 006/016).
- **Caveats.** The Your Library file gives names, not IDs (whether it carries Spotify URIs is **unverified** — I could not open a sample). The extended history carries `spotify_track_uri`, which is an exact key but needs a Spotify API call (`GET /tracks/{id}`, client-credentials, quota-limited, dev mode) or a name/ISRC fallback to reach MusicBrainz. Package preparation time is stated on the login-walled request page; community threads report "up to 30 days" for extended history and a few days for account data, which I could not confirm from a primary page.

### Last.fm

- **No official self-serve export.** The privacy policy (effective 26 May 2026, https://www.last.fm/legal/privacy) offers "Access a copy of your personal data" by emailing dp3@last.fm with "Data Request" in the subject, answered "within one month", and for EU/UK residents "Receive your data in a structured, machine-readable format." All third-party "export" tools use the public API.
- API: `user.getRecentTracks` (https://www.last.fm/api/show/user.getRecentTracks) — "This service does not require authentication"; `limit` "Defaults to 50. Maximum is 200"; `from`/`to` UNIX timestamps; returns artist `mbid`, album `mbid`, track `mbid` and `date uts`. Works only if the Member's privacy setting "hide recent listening information" is off. Error 29 = "Rate limit exceeded"; the intro page (https://www.last.fm/api/intro) says accounts making "several calls per second" may be suspended and "If you are planning to use our API for commercial purposes, please contact us via email at partners@last.fm."
- API ToS (https://www.last.fm/api/tos, undated): "Any use by You of the Last.fm Data for commercial purposes without obtaining a commercial use agreement constitutes a material breach"; storage cap "a maximum of 100 MB"; attribution ("powered by AudioScrobbler" buttons, links to Last.fm catalogue pages) required.
- **Verdict.** Cheap to build (one unauthenticated call per 200 scrobbles, MBIDs when present), but the MBID fields are frequently empty in practice (unverified, no primary figure), the 100 MB cap and non-commercial clause constrain a growing site, and Last.fm's Terms include their own attribution burden. Fine as a Source; not the "universal" one.

### ListenBrainz

- **Export**: the user export (settings → export; page is login-walled) produces `listenbrainz_{user}_{timestamp}.zip` containing `user.json`, `listens/{year}/{month}.jsonl`, `feedback.jsonl`, `pinned_recording.jsonl`; archives expire after 30 days (source code https://github.com/metabrainz/listenbrainz-server/blob/master/listenbrainz/background/export.py, master as of 2026-09-01). Each listen carries the submitted `track_metadata` (`artist_name`, `track_name`, `release_name`, `additional_info` with optional `isrc`, `spotify_id`, `recording_mbid`, `release_mbid`, `release_group_mbid`) **and** the server-resolved `mbid_mapping` (https://listenbrainz.readthedocs.io/en/latest/users/json.html).
- **Public API**: `GET /1/user/{user_name}/listens` with `count` up to 1000 and `min_ts`/`max_ts` cursors; no token needed for public reads, tokens get "higher rate limits"; limits exposed via `X-RateLimit-*` headers (https://listenbrainz.readthedocs.io/en/latest/users/api/core.html, https://listenbrainz.readthedocs.io/en/latest/users/api/index.html).
- **ListenBrainz already imports Spotify's export zip** (Settings → Import, shipped Aug 2025 per the MetaBrainz post above) and can scrobble from Spotify directly. A Member can therefore route Spotify → ListenBrainz → us and arrive with MusicBrainz IDs pre-resolved by MetaBrainz's own mapper.
- **Verdict.** ListenBrainz is the cheapest universal Import: CC0 open data, the same MusicBrainz identifiers our Catalog is keyed on, a public read API, and an upstream that has already solved Spotify export parsing. Its weakness is reach — few Members have an account — and that listens are plays, not saved albums, so Favourites still need the Member's hand.

## 7. Risk table — what could stop the Spotify Source working for a public site

| # | Risk | Likelihood | Impact | Evidence | Mitigation |
|---|------|-----------|--------|----------|------------|
| 1 | Development Mode caps an app at **5 authorised users** | Certain (in force since 9 Mar 2026) | Blocks OAuth Import for the public | Quota modes page; 6 Feb 2026 post | OAuth Source only for allowlisted testers; file-upload Source for everyone |
| 2 | Extended quota requires a **legal entity + launched service + 250k MAU** | Certain (since 15 May 2025) | No path out of (1) for an AGPL hobby site | Quota modes page; 15 Apr 2025 post | None available; do not plan around approval |
| 3 | Spotify **Premium required** for the app owner | Certain | Small recurring cost; Import breaks if lapsed | Quota modes page | Budget it; decouple Import from any single account |
| 4 | **Further endpoint removals** (three rounds in 15 months, dev mode hit first) | High | Import adapter breaks without notice | Nov 2024, Feb 2026, Jul 2026 posts | Adapter behind the Import seam; dated re-check before spec; file export as the durable path |
| 5 | Policy III.13 "**do not analyze** the Spotify Content" and III.11 "mimic... a core user experience" | Medium | Taste Profile / Engine could be argued to breach | Policy 15 May 2025 | Compute Taste Profile from Library (MusicBrainz identities) after Import; discard Spotify payload; refer to ticket 006 |
| 6 | **Disconnect = delete within 5 days**, ambiguous reach into derived Logs | Medium | Data-model constraint | Terms V.8, Appendix A.5.c | Import provenance on Logs so deletion is possible (ticket 016) |
| 7 | **Attribution/link-back/no-adjacent-services** if Spotify metadata is displayed | Low (avoidable) | UI and Apple-Music-later conflict | Policy II.4; design guidelines | Render only MusicBrainz names and CAA art, even on Import review |
| 8 | **Per-account quota**, unpublished rate limits, `GET /albums` batch removed | High | Slow Imports; server-side URI resolution competes with Member calls | Rate-limits page; Jul 2026 post; Feb 2026 changelog | Prefer `/me/albums` (UPC inline); resolve URIs via MusicBrainz first, Spotify last |
| 9 | **Match coverage**: ~15% of MB recordings have ISRCs, ~44% of releases have barcodes | Certain long tail | Unresolved items in every Import | MB statistics 2 Sep 2026 | Resolution ladder + name fallback + Member confirmation; measure in a prototype |
| 10 | **Terms change on posting**; Client Secret cannot ship in the AGPL repo | Certain | Every self-hoster is a separate 5-user app | Terms IX.2; apps page | Document per-deploy registration; treat OAuth as optional |
| 11 | Spotify data export contains **sensitive fields** (email, DOB, card last-4) | Certain | Privacy exposure on upload | Understanding-my-data article | Parse only library/history files; drop the rest before storage |

## 8. What I could not verify

- Spotify staff replies on the community forum (403 to fetch tools): whether any exception exists for non-commercial apps, and whether 25 Client IDs × 5 users is tolerated.
- The wording on the login-walled Account Privacy page: package names and preparation times ("up to 5 / 30 days" are community reports).
- Whether the Your Library JSON in the account-data package includes Spotify URIs or only names.
- Any measured Spotify→MusicBrainz match rate; ISRC/barcode coverage is the only primary figure.
- How often Last.fm's `mbid` fields are populated.
- The pre-Feb-2026 Development Mode user cap (widely reported as 25; only the current "5" is on a primary page).

## Sources (all accessed 2026-09-01)

Spotify developer documentation: scopes; get-users-saved-tracks; get-users-saved-albums; get-track; get-an-album; get-multiple-albums; search; get-users-top-artists-and-tracks; get-recently-played; get-recommendations; concepts/api-calls; concepts/rate-limits; concepts/quota-modes; concepts/apps; documentation/design; references/changes/february-2026; references/changes/july-2026; tutorials/february-2026-migration-guide — all under https://developer.spotify.com/documentation/.
Spotify developer blog: 2024-11-27-changes-to-the-web-api; 2025-04-15-updating-the-criteria-for-web-api-extended-access; 2026-02-06-update-on-developer-access-and-platform-security; 2026-07-23-web-api-quota-updates — under https://developer.spotify.com/blog/.
Spotify Developer Terms v10 (15 May 2025): https://developer.spotify.com/terms. Developer Policy (15 May 2025): https://developer.spotify.com/policy.
Spotify support: https://support.spotify.com/us/article/data-rights-and-privacy-settings/ ; https://support.spotify.com/us/article/understanding-my-data/.
MusicBrainz: https://musicbrainz.org/doc/MusicBrainz_API ; https://musicbrainz.org/doc/MusicBrainz_API/Search ; https://musicbrainz.org/doc/Style/Relationships/URLs ; https://musicbrainz.org/statistics (2 Sep 2026).
ListenBrainz: https://listenbrainz.readthedocs.io/en/latest/users/json.html ; .../users/api/core.html ; .../users/api/index.html ; .../users/api/metadata.html ; https://blog.metabrainz.org/2025/08/30/gsoc-2025-importing-listening-history-files-in-listenbrainz/ ; https://github.com/metabrainz/listenbrainz-server (listens_importer/spotify.py, background/export.py).
Last.fm: https://www.last.fm/api/show/user.getRecentTracks ; https://www.last.fm/api/intro ; https://www.last.fm/api/tos ; https://www.last.fm/legal/privacy (26 May 2026).

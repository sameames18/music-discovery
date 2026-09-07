-- Transform staged raw MusicBrainz tables (mb_raw schema) into our own
-- Catalog schema (catalog schema), per ticket 007's decisions and the
-- CONTEXT.md glossary. Ticket 021.
--
-- Album = release_group, primary type Album or EP.
-- Edition = release, status Official, with a no-status fallback when an
--   Album has no Official Edition at all.
-- Canonical Edition = earliest Official Edition by computed release date,
--   tie-break to most tracks.
-- Track (our term) = recording, a single identity across Editions.
-- Participant = artist credits + artist relationships at all three levels
--   (release_group, release, recording), collapsed to one row per
--   (Album, Participant, role).
-- Genre = release_group_tag / artist_tag rows whose tag name is a genre.

CREATE SCHEMA IF NOT EXISTS catalog;
SET search_path TO catalog, mb_raw, public;

-- Staging tables have no indexes, so these joins lean on hash joins over
-- multi-million-row tables (l_artist_recording, track, artist_credit_name).
-- Bump work_mem for this session so they don't spill to disk.
SET work_mem = '1GB';
SET maintenance_work_mem = '1GB';

-- ============================================================
-- STAGE: Album (release_group, primary type Album or EP)
-- ============================================================
CREATE TABLE catalog.album AS
SELECT
    rg.id,
    rg.gid AS mbid,
    rg.name,
    rg.artist_credit,
    pt.name AS primary_type,
    rg.comment
FROM mb_raw.release_group rg
JOIN mb_raw.release_group_primary_type pt ON pt.id = rg.type
WHERE pt.name IN ('Album', 'EP');

ALTER TABLE catalog.album ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX idx_album_mbid ON catalog.album (mbid);

CREATE TABLE catalog.album_secondary_type AS
SELECT j.release_group AS album_id, st.name AS secondary_type
FROM mb_raw.release_group_secondary_type_join j
JOIN mb_raw.release_group_secondary_type st ON st.id = j.secondary_type
WHERE j.release_group IN (SELECT id FROM catalog.album);

CREATE INDEX idx_album_secondary_type_album ON catalog.album_secondary_type (album_id);

-- ============================================================
-- STAGE: Edition (release, Official + no-status fallback)
-- ============================================================
CREATE TEMP TABLE official_release_groups AS
SELECT DISTINCT r.release_group
FROM mb_raw.release r
JOIN mb_raw.release_status rs ON rs.id = r.status
WHERE rs.name = 'Official'
  AND r.release_group IN (SELECT id FROM catalog.album);

CREATE TABLE catalog.edition AS
SELECT
    r.id,
    r.gid AS mbid,
    r.name,
    r.artist_credit,
    r.release_group AS album_id,
    rs.name AS status,
    r.barcode
FROM mb_raw.release r
LEFT JOIN mb_raw.release_status rs ON rs.id = r.status
WHERE r.release_group IN (SELECT id FROM catalog.album)
  AND (
        rs.name = 'Official'
        OR (r.status IS NULL AND r.release_group NOT IN (SELECT release_group FROM official_release_groups))
      );

ALTER TABLE catalog.edition ADD PRIMARY KEY (id);
CREATE INDEX idx_edition_album ON catalog.edition (album_id);
CREATE UNIQUE INDEX idx_edition_mbid ON catalog.edition (mbid);

-- Protective indexes on staging join/filter columns used by the stages
-- below. Learned the hard way: the first version of edition_date used a
-- per-row LATERAL correlated subquery against release_country (13M rows)
-- for each of ~3.7M Editions, and did not finish in under an hour.
CREATE INDEX idx_mbraw_release_country_release ON mb_raw.release_country (release);
CREATE INDEX idx_mbraw_release_unknown_country_release ON mb_raw.release_unknown_country (release);
CREATE INDEX idx_mbraw_track_medium ON mb_raw.track (medium);
CREATE INDEX idx_mbraw_medium_release ON mb_raw.medium (release);
CREATE INDEX idx_mbraw_l_artist_recording_entity1 ON mb_raw.l_artist_recording (entity1);
CREATE INDEX idx_mbraw_l_artist_release_entity1 ON mb_raw.l_artist_release (entity1);
CREATE INDEX idx_mbraw_l_artist_release_group_entity1 ON mb_raw.l_artist_release_group (entity1);
CREATE INDEX idx_mbraw_artist_credit_name_artist_credit ON mb_raw.artist_credit_name (artist_credit);
CREATE INDEX idx_mbraw_artist_credit_name_artist ON mb_raw.artist_credit_name (artist);
CREATE INDEX idx_mbraw_isrc_recording ON mb_raw.isrc (recording);
CREATE INDEX idx_mbraw_release_group_tag_release_group ON mb_raw.release_group_tag (release_group);
CREATE INDEX idx_mbraw_artist_tag_artist ON mb_raw.artist_tag (artist);
CREATE INDEX idx_mbraw_l_release_group_url_entity0 ON mb_raw.l_release_group_url (entity0);
CREATE INDEX idx_mbraw_l_release_url_entity0 ON mb_raw.l_release_url (entity0);

-- Computed first-release-date per Edition (avoids the NC release_group_meta
-- table; recomputed from core release_country / release_unknown_country).
-- Aggregate-then-join, not a per-row correlated subquery: a GROUP BY pass
-- is a single scan regardless of how many Editions there are.
CREATE TABLE catalog.edition_date AS
WITH rc_agg AS (
    SELECT
        release,
        MIN(make_date(
            COALESCE(date_year, 9999),
            COALESCE(date_month, 1),
            COALESCE(date_day, 1)
        )) AS d,
        MIN(date_year) AS y
    FROM mb_raw.release_country
    WHERE date_year IS NOT NULL
      AND release IN (SELECT id FROM catalog.edition)
    GROUP BY release
),
ruc_agg AS (
    SELECT
        release,
        MIN(make_date(
            COALESCE(date_year, 9999),
            COALESCE(date_month, 1),
            COALESCE(date_day, 1)
        )) AS d,
        MIN(date_year) AS y
    FROM mb_raw.release_unknown_country
    WHERE date_year IS NOT NULL
      AND release IN (SELECT id FROM catalog.edition)
    GROUP BY release
)
SELECT
    e.id AS edition_id,
    COALESCE(rc.d, ruc.d) AS release_date,
    COALESCE(rc.y, ruc.y) AS release_year
FROM catalog.edition e
LEFT JOIN rc_agg rc ON rc.release = e.id
LEFT JOIN ruc_agg ruc ON ruc.release = e.id;

CREATE UNIQUE INDEX idx_edition_date_edition ON catalog.edition_date (edition_id);

-- ============================================================
-- STAGE: Track listing (medium/track rows) + track_count per Edition
-- ============================================================
CREATE TABLE catalog.edition_track AS
SELECT
    t.id,
    t.gid AS mbid,
    m.release AS edition_id,
    m.position AS medium_position,
    t.position AS track_position,
    t.recording,
    t.name,
    t.artist_credit,
    t.length
FROM mb_raw.track t
JOIN mb_raw.medium m ON m.id = t.medium
WHERE m.release IN (SELECT id FROM catalog.edition);

CREATE INDEX idx_edition_track_edition ON catalog.edition_track (edition_id);
CREATE INDEX idx_edition_track_recording ON catalog.edition_track (recording);

CREATE TABLE catalog.edition_track_count AS
SELECT edition_id, COUNT(*) AS track_count
FROM catalog.edition_track
GROUP BY edition_id;

CREATE UNIQUE INDEX idx_edition_track_count_edition ON catalog.edition_track_count (edition_id);

-- ============================================================
-- STAGE: Canonical Edition per Album
-- earliest Official Edition by computed date, tie-break most tracks.
-- Falls back to no-status Editions when that's all the Album has.
-- ============================================================
CREATE TABLE catalog.canonical_edition AS
SELECT DISTINCT ON (e.album_id)
    e.album_id,
    e.id AS edition_id
FROM catalog.edition e
LEFT JOIN catalog.edition_date ed ON ed.edition_id = e.id
LEFT JOIN catalog.edition_track_count tc ON tc.edition_id = e.id
ORDER BY
    e.album_id,
    (e.status = 'Official') DESC,
    COALESCE(ed.release_date, DATE '9999-12-31') ASC,
    COALESCE(tc.track_count, 0) DESC,
    e.id ASC;

ALTER TABLE catalog.canonical_edition ADD PRIMARY KEY (album_id);

-- ============================================================
-- STAGE: Recording (our "Track" identity) — only ones referenced
-- by a kept Edition's track listing.
-- ============================================================
CREATE TABLE catalog.recording AS
SELECT DISTINCT
    rec.id,
    rec.gid AS mbid,
    rec.name,
    rec.artist_credit,
    rec.length
FROM mb_raw.recording rec
WHERE rec.id IN (SELECT DISTINCT recording FROM catalog.edition_track);

ALTER TABLE catalog.recording ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX idx_recording_mbid ON catalog.recording (mbid);

-- ============================================================
-- STAGE: Artist (only ones credited on a kept Album/Edition/Recording,
-- or in a kept relationship — built after participant/credit tables
-- below, so this is populated last via a follow-up statement.)
-- ============================================================
CREATE TABLE catalog.artist AS
SELECT id, gid AS mbid, name, sort_name
FROM mb_raw.artist
WHERE FALSE; -- populated below once we know which artist ids are referenced

-- ============================================================
-- STAGE: Participant — artist credits (printed Artist) collapsed to
-- Album level, role = 'artist'.
-- ============================================================
CREATE TABLE catalog.participant AS
SELECT DISTINCT
    a.id AS album_id,
    acn.artist AS artist_id,
    'artist' AS role
FROM catalog.album a
JOIN mb_raw.artist_credit_name acn ON acn.artist_credit = a.artist_credit;

-- Relationships at all three levels, projected up to Album, collapsed
-- to (Album, Participant, role). Role name = link_type.name.
INSERT INTO catalog.participant (album_id, artist_id, role)
SELECT DISTINCT a.id, l1.entity0, lt.name
FROM mb_raw.l_artist_release_group l1
JOIN mb_raw.link lk ON lk.id = l1.link
JOIN mb_raw.link_type lt ON lt.id = lk.link_type
JOIN catalog.album a ON a.id = l1.entity1;

INSERT INTO catalog.participant (album_id, artist_id, role)
SELECT DISTINCT e.album_id, l2.entity0, lt.name
FROM mb_raw.l_artist_release l2
JOIN mb_raw.link lk ON lk.id = l2.link
JOIN mb_raw.link_type lt ON lt.id = lk.link_type
JOIN catalog.edition e ON e.id = l2.entity1;

INSERT INTO catalog.participant (album_id, artist_id, role)
SELECT DISTINCT et.edition_id_album, l3.entity0, lt.name
FROM mb_raw.l_artist_recording l3
JOIN mb_raw.link lk ON lk.id = l3.link
JOIN mb_raw.link_type lt ON lt.id = lk.link_type
JOIN (
    SELECT DISTINCT et.recording, e.album_id AS edition_id_album
    FROM catalog.edition_track et
    JOIN catalog.edition e ON e.id = et.edition_id
) et ON et.recording = l3.entity1;

-- Collapse exact duplicates across the three levels.
CREATE TABLE catalog.participant_collapsed AS
SELECT DISTINCT album_id, artist_id, role FROM catalog.participant;
DROP TABLE catalog.participant;
ALTER TABLE catalog.participant_collapsed RENAME TO participant;
CREATE INDEX idx_participant_album ON catalog.participant (album_id);
CREATE INDEX idx_participant_artist ON catalog.participant (artist_id);

-- Now populate Artist with every artist id actually referenced.
DROP TABLE catalog.artist;
CREATE TABLE catalog.artist AS
SELECT DISTINCT ar.id, ar.gid AS mbid, ar.name, ar.sort_name
FROM mb_raw.artist ar
WHERE ar.id IN (SELECT artist_id FROM catalog.participant);

ALTER TABLE catalog.artist ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX idx_artist_mbid ON catalog.artist (mbid);

-- ============================================================
-- STAGE: Genre — release_group_tag + artist_tag (fallback), filtered
-- to names in the controlled genre list. NC-licensed, marked as such.
-- ============================================================
CREATE TABLE catalog.genre_tag AS
SELECT
    a.id AS album_id,
    g.name AS genre,
    rgt.count,
    'release_group' AS source
FROM mb_raw.release_group_tag rgt
JOIN mb_raw.tag t ON t.id = rgt.tag
JOIN mb_raw.genre g ON g.name = t.name
JOIN catalog.album a ON a.id = rgt.release_group
WHERE rgt.count > 0;

INSERT INTO catalog.genre_tag (album_id, genre, count, source)
SELECT DISTINCT
    a.id, g.name, at.count, 'artist_fallback'
FROM mb_raw.artist_tag at
JOIN mb_raw.tag t ON t.id = at.tag
JOIN mb_raw.genre g ON g.name = t.name
JOIN mb_raw.artist_credit_name acn ON acn.artist = at.artist
JOIN catalog.album a ON a.artist_credit = acn.artist_credit
WHERE at.count > 0
  AND a.id NOT IN (SELECT album_id FROM catalog.genre_tag);

CREATE INDEX idx_genre_tag_album ON catalog.genre_tag (album_id);

-- ============================================================
-- STAGE: Identifiers — ISRC -> Album, barcode -> Album
-- ============================================================
CREATE TABLE catalog.isrc_lookup AS
SELECT DISTINCT i.isrc, e.album_id, et.recording AS recording_id
FROM mb_raw.isrc i
JOIN catalog.edition_track et ON et.recording = i.recording
JOIN catalog.edition e ON e.id = et.edition_id;

CREATE INDEX idx_isrc_lookup_isrc ON catalog.isrc_lookup (isrc);

CREATE TABLE catalog.barcode_lookup AS
SELECT DISTINCT e.barcode, e.album_id
FROM catalog.edition e
WHERE e.barcode IS NOT NULL AND e.barcode <> '';

CREATE INDEX idx_barcode_lookup_barcode ON catalog.barcode_lookup (barcode);

-- ============================================================
-- STAGE: Discogs URL links (kept as CC0 join material, no Discogs
-- data itself loaded in v1).
-- ============================================================
CREATE TABLE catalog.discogs_link AS
SELECT DISTINCT a.id AS album_id, u.url
FROM mb_raw.l_release_group_url lru
JOIN mb_raw.url u ON u.id = lru.entity1
JOIN catalog.album a ON a.id = lru.entity0
WHERE u.url ILIKE '%discogs.com%'
UNION
SELECT DISTINCT e.album_id, u.url
FROM mb_raw.l_release_url lru2
JOIN mb_raw.url u ON u.id = lru2.entity1
JOIN catalog.edition e ON e.id = lru2.entity0
WHERE u.url ILIKE '%discogs.com%';

CREATE INDEX idx_discogs_link_album ON catalog.discogs_link (album_id);

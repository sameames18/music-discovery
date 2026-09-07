-- Measurements ticket 002 left unverified, plus load footprint. Ticket 021.
SET search_path TO catalog, mb_raw, public;

-- Row counts, final schema
SELECT 'album' AS table, count(*) FROM catalog.album
UNION ALL SELECT 'edition', count(*) FROM catalog.edition
UNION ALL SELECT 'canonical_edition', count(*) FROM catalog.canonical_edition
UNION ALL SELECT 'edition_track', count(*) FROM catalog.edition_track
UNION ALL SELECT 'recording', count(*) FROM catalog.recording
UNION ALL SELECT 'artist', count(*) FROM catalog.artist
UNION ALL SELECT 'participant', count(*) FROM catalog.participant
UNION ALL SELECT 'genre_tag', count(*) FROM catalog.genre_tag
UNION ALL SELECT 'isrc_lookup', count(*) FROM catalog.isrc_lookup
UNION ALL SELECT 'barcode_lookup', count(*) FROM catalog.barcode_lookup
UNION ALL SELECT 'discogs_link', count(*) FROM catalog.discogs_link;

-- Share of Albums with >=1 genre tag (not any folksonomy tag)
SELECT
  (SELECT count(DISTINCT album_id) FROM catalog.genre_tag) AS albums_with_genre,
  (SELECT count(*) FROM catalog.album) AS albums_total,
  round(
    100.0 * (SELECT count(DISTINCT album_id) FROM catalog.genre_tag)
    / (SELECT count(*) FROM catalog.album), 1
  ) AS pct_with_genre;

-- Per-Album genre count distribution
SELECT genre_count, count(*) AS albums
FROM (
  SELECT album_id, count(*) AS genre_count
  FROM catalog.genre_tag
  GROUP BY album_id
) sub
GROUP BY genre_count
ORDER BY genre_count;

-- Share of Albums with a Canonical Edition that has a track list
SELECT
  (SELECT count(*) FROM catalog.canonical_edition ce
     JOIN catalog.edition_track_count tc ON tc.edition_id = ce.edition_id
     WHERE tc.track_count > 0) AS canonical_with_tracks,
  (SELECT count(*) FROM catalog.canonical_edition) AS canonical_total,
  round(
    100.0 * (SELECT count(*) FROM catalog.canonical_edition ce
       JOIN catalog.edition_track_count tc ON tc.edition_id = ce.edition_id
       WHERE tc.track_count > 0)
    / (SELECT count(*) FROM catalog.canonical_edition), 1
  ) AS pct_canonical_with_tracks;

-- Disk footprint per schema/table, with indexes
SELECT schemaname, relname, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname IN ('catalog', 'mb_raw')
ORDER BY pg_total_relation_size(relid) DESC;

SELECT
  (SELECT pg_size_pretty(sum(pg_total_relation_size(relid))) FROM pg_catalog.pg_statio_user_tables WHERE schemaname = 'catalog') AS catalog_schema_total,
  (SELECT pg_size_pretty(sum(pg_total_relation_size(relid))) FROM pg_catalog.pg_statio_user_tables WHERE schemaname = 'mb_raw') AS staging_schema_total,
  (SELECT pg_size_pretty(pg_database_size('musicdiscovery'))) AS whole_database;

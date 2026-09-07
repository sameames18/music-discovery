-- Staging schema: raw MusicBrainz tables, column-for-column matching
-- admin/sql/CreateTables.sql (schema as of the 2026-09-05 full export),
-- with constraints/defaults stripped since this is a bulk COPY target,
-- not a live-edited database. Ticket 021.

CREATE SCHEMA IF NOT EXISTS mb_raw;
SET search_path TO mb_raw;

CREATE TABLE artist (
    id INTEGER, gid UUID, name TEXT, sort_name TEXT,
    begin_date_year SMALLINT, begin_date_month SMALLINT, begin_date_day SMALLINT,
    end_date_year SMALLINT, end_date_month SMALLINT, end_date_day SMALLINT,
    type INTEGER, area INTEGER, gender INTEGER, comment TEXT,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, ended BOOLEAN,
    begin_area INTEGER, end_area INTEGER
);

CREATE TABLE artist_credit (
    id INTEGER, name TEXT, artist_count SMALLINT, ref_count INTEGER,
    created TIMESTAMPTZ, edits_pending INTEGER, gid UUID
);

CREATE TABLE artist_credit_name (
    artist_credit INTEGER, position SMALLINT, artist INTEGER, name TEXT, join_phrase TEXT
);

CREATE TABLE artist_tag (
    artist INTEGER, tag INTEGER, count INTEGER, last_updated TIMESTAMPTZ
);

CREATE TABLE genre (
    id INTEGER, gid UUID, name TEXT, comment TEXT, edits_pending INTEGER, last_updated TIMESTAMPTZ
);

CREATE TABLE isrc (
    id INTEGER, recording INTEGER, isrc CHAR(12), edits_pending INTEGER, created TIMESTAMPTZ
);

CREATE TABLE l_artist_recording (
    id INTEGER, link INTEGER, entity0 INTEGER, entity1 INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, link_order INTEGER,
    entity0_credit TEXT, entity1_credit TEXT
);

CREATE TABLE l_artist_release (
    id INTEGER, link INTEGER, entity0 INTEGER, entity1 INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, link_order INTEGER,
    entity0_credit TEXT, entity1_credit TEXT
);

CREATE TABLE l_artist_release_group (
    id INTEGER, link INTEGER, entity0 INTEGER, entity1 INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, link_order INTEGER,
    entity0_credit TEXT, entity1_credit TEXT
);

CREATE TABLE l_release_group_url (
    id INTEGER, link INTEGER, entity0 INTEGER, entity1 INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, link_order INTEGER,
    entity0_credit TEXT, entity1_credit TEXT
);

CREATE TABLE l_release_url (
    id INTEGER, link INTEGER, entity0 INTEGER, entity1 INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, link_order INTEGER,
    entity0_credit TEXT, entity1_credit TEXT
);

CREATE TABLE link (
    id INTEGER, link_type INTEGER,
    begin_date_year SMALLINT, begin_date_month SMALLINT, begin_date_day SMALLINT,
    end_date_year SMALLINT, end_date_month SMALLINT, end_date_day SMALLINT,
    attribute_count INTEGER, created TIMESTAMPTZ, ended BOOLEAN
);

CREATE TABLE link_type (
    id INTEGER, parent INTEGER, child_order INTEGER, gid UUID,
    entity_type0 TEXT, entity_type1 TEXT, name TEXT, description TEXT,
    link_phrase TEXT, reverse_link_phrase TEXT, long_link_phrase TEXT,
    last_updated TIMESTAMPTZ, is_deprecated BOOLEAN, has_dates BOOLEAN,
    entity0_cardinality SMALLINT, entity1_cardinality SMALLINT
);

CREATE TABLE medium (
    id INTEGER, release INTEGER, position INTEGER, format INTEGER, name TEXT,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, track_count INTEGER, gid UUID
);

CREATE TABLE recording (
    id INTEGER, gid UUID, name TEXT, artist_credit INTEGER, length INTEGER,
    comment TEXT, edits_pending INTEGER, last_updated TIMESTAMPTZ, video BOOLEAN
);

CREATE TABLE release (
    id INTEGER, gid UUID, name TEXT, artist_credit INTEGER, release_group INTEGER,
    status INTEGER, packaging INTEGER, language INTEGER, script INTEGER,
    barcode TEXT, comment TEXT, edits_pending INTEGER, quality SMALLINT, last_updated TIMESTAMPTZ
);

CREATE TABLE release_country (
    release INTEGER, country INTEGER, date_year SMALLINT, date_month SMALLINT, date_day SMALLINT
);

CREATE TABLE release_unknown_country (
    release INTEGER, date_year SMALLINT, date_month SMALLINT, date_day SMALLINT
);

CREATE TABLE release_status (
    id INTEGER, name TEXT, parent INTEGER, child_order INTEGER, description TEXT, gid UUID
);

CREATE TABLE release_group (
    id INTEGER, gid UUID, name TEXT, artist_credit INTEGER, type INTEGER,
    comment TEXT, edits_pending INTEGER, last_updated TIMESTAMPTZ
);

CREATE TABLE release_group_primary_type (
    id INTEGER, name TEXT, parent INTEGER, child_order INTEGER, description TEXT, gid UUID
);

CREATE TABLE release_group_secondary_type (
    id INTEGER, name TEXT, parent INTEGER, child_order INTEGER, description TEXT, gid UUID
);

CREATE TABLE release_group_secondary_type_join (
    release_group INTEGER, secondary_type INTEGER, created TIMESTAMPTZ
);

CREATE TABLE release_group_tag (
    release_group INTEGER, tag INTEGER, count INTEGER, last_updated TIMESTAMPTZ
);

CREATE TABLE tag (
    id INTEGER, name TEXT, ref_count INTEGER
);

CREATE TABLE track (
    id INTEGER, gid UUID, recording INTEGER, medium INTEGER, position INTEGER,
    number TEXT, name TEXT, artist_credit INTEGER, length INTEGER,
    edits_pending INTEGER, last_updated TIMESTAMPTZ, is_data_track BOOLEAN
);

CREATE TABLE url (
    id INTEGER, gid UUID, url TEXT, edits_pending INTEGER, last_updated TIMESTAMPTZ
);

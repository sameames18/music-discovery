#!/bin/bash
# Load extracted MusicBrainz table dumps into mb_raw staging tables via
# server-side COPY. Assumes the Postgres container has the extracted
# directory (from 02_extract.sh) mounted at /extracted. Times each
# table's COPY into <output-dir>/load_timings.csv. Ticket 021.
#
# Usage: 04_load.sh <container-name> <db-name> <output-dir>
set -e

CONTAINER="${1:?usage: 04_load.sh <container> <db> <output-dir>}"
DB="${2:?usage: 04_load.sh <container> <db> <output-dir>}"
OUT="${3:?usage: 04_load.sh <container> <db> <output-dir>}"

CORE_TABLES="release_group release_group_primary_type release_group_secondary_type release_group_secondary_type_join release release_status release_country release_unknown_country medium track recording isrc artist artist_credit artist_credit_name l_artist_release l_artist_release_group l_artist_recording link link_type genre url l_release_group_url l_release_url"

DERIVED_TABLES="release_group_tag artist_tag tag"

echo "table,seconds,rows" > "$OUT/load_timings.csv"

load_one() {
  local t="$1" f="$2"
  local start end rows
  start=$(date +%s)
  docker exec "$CONTAINER" psql -U postgres -d "$DB" -v ON_ERROR_STOP=1 -c "\\copy mb_raw.$t FROM '$f' WITH (FORMAT text)"
  end=$(date +%s)
  rows=$(docker exec "$CONTAINER" psql -U postgres -d "$DB" -t -c "SELECT count(*) FROM mb_raw.$t")
  echo "$t,$((end-start)),$rows" >> "$OUT/load_timings.csv"
  echo "loaded $t in $((end-start))s ($rows rows)"
}

for t in $CORE_TABLES; do load_one "$t" "/extracted/mbdump/$t"; done
for t in $DERIVED_TABLES; do load_one "$t" "/extracted/derived/mbdump/$t"; done

echo "ALL LOADED"

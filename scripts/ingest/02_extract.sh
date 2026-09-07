#!/bin/bash
# Extract only the ~23 tables our Catalog subset needs from the two
# dump archives (bzip2 is single-threaded and sequential, so this still
# reads the whole compressed stream, but only writes the tables we want
# to disk). Ticket 021. Usage: 02_extract.sh <dumps-dir> <dest-dir>
set -e

DUMPS="${1:?usage: 02_extract.sh <dumps-dir> <dest-dir>}"
DEST="${2:?usage: 02_extract.sh <dumps-dir> <dest-dir>}"
mkdir -p "$DEST/derived"

CORE_TABLES="mbdump/release_group mbdump/release_group_primary_type mbdump/release_group_secondary_type mbdump/release_group_secondary_type_join mbdump/release mbdump/release_status mbdump/release_country mbdump/release_unknown_country mbdump/medium mbdump/track mbdump/recording mbdump/isrc mbdump/artist mbdump/artist_credit mbdump/artist_credit_name mbdump/l_artist_release mbdump/l_artist_release_group mbdump/l_artist_recording mbdump/link mbdump/link_type mbdump/genre mbdump/url mbdump/l_release_group_url mbdump/l_release_url"

DERIVED_TABLES="mbdump/release_group_tag mbdump/artist_tag mbdump/tag"

echo "=== extracting core (CC0) tables ==="
time tar -xjf "$DUMPS/mbdump.tar.bz2" -C "$DEST" $CORE_TABLES

echo "=== extracting derived (BY-NC-SA) tables ==="
time tar -xjf "$DUMPS/mbdump-derived.tar.bz2" -C "$DEST/derived" $DERIVED_TABLES

echo "DONE"
du -sh "$DEST"

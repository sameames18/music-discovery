#!/bin/bash
# Download the latest MusicBrainz full export's core (CC0) and derived
# (BY-NC-SA) dumps. Ticket 021. Usage: 01_download.sh <dest-dir>
#
# Pass the export directory name as $2 if you want a pinned snapshot
# instead of resolving LATEST at run time, e.g.:
#   01_download.sh /d/music-discovery-catalog/dumps 20260905-002519
set -e

DEST="${1:?usage: 01_download.sh <dest-dir> [export-dir]}"
UA="music-discovery-prototype/0.1 (https://github.com/sameames18/music-discovery)"
mkdir -p "$DEST"

if [ -n "$2" ]; then
  EXPORT_DIR="$2"
else
  # LATEST is a small text file containing the current export's directory
  # name (e.g. "20260905-002519"), not a redirect.
  EXPORT_DIR=$(curl -sL --user-agent "$UA" "https://data.metabrainz.org/pub/musicbrainz/data/fullexport/LATEST" | tr -d '[:space:]')
fi

BASE="https://data.metabrainz.org/pub/musicbrainz/data/fullexport/$EXPORT_DIR"
echo "Downloading from $BASE"

curl -L -o "$DEST/mbdump.tar.bz2" -C - --user-agent "$UA" "$BASE/mbdump.tar.bz2"
curl -L -o "$DEST/mbdump-derived.tar.bz2" -C - --user-agent "$UA" "$BASE/mbdump-derived.tar.bz2"

echo "Done. Files in $DEST:"
ls -la "$DEST"

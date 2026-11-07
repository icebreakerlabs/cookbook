#!/usr/bin/env bash
# Merge paginated list_network_syncs_tool JSON pages; dedupe by sync id (first seen wins).
# Usage: merge_sync_pages.sh OUT.json page1.json [page2 ...]
set -euo pipefail

OUT="$1"; shift
[ "$#" -ge 1 ] || { echo "usage: merge_sync_pages.sh OUT.json page..." >&2; exit 1; }

jq -s '
  ([ .[].data.syncs[]? ]
   | map(select(.id != null and ((.id | tostring) | gsub("^\\s+|\\s+$"; "") ) != ""))
   | unique_by(.id)) as $syncs |
  ([ .[].data.counts? ] | map(select(. != null)) | last) as $counts |
  { syncs: $syncs, counts: $counts }
' "$@" > "$OUT"

echo "merged syncs: $(jq '.syncs | length' "$OUT")"

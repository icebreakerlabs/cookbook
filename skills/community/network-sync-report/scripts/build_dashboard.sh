#!/usr/bin/env bash
# Embed normalized rows into the offline HTML template (JSON script block).
# Usage: build_dashboard.sh ROWS.jsonl "Display Name" YYYY-MM-DD OUT.html [--offline-snapshot]
set -euo pipefail

ROWS="${1:?rows.jsonl}"
NAME="${2:?display name}"
DATE="${3:?YYYY-MM-DD}"
OUT="${4:?out.html}"
OFFLINE=0
if [ "${5:-}" = "--offline-snapshot" ]; then OFFLINE=1; fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../assets/network_sync_dashboard_template.html"

NAME_ESC="$(jq -r --arg s "$NAME" '$s | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;") | gsub("\"";"&quot;")')"
FIRST_NON_WS="$(sed -e 's/^[[:space:]]*//' "$ROWS" | head -c1)"
if [ "$FIRST_NON_WS" = "[" ]; then
  DATA_BLOCK="$(jq -c '.' "$ROWS")"
else
  DATA_BLOCK="$(jq -s -c '.' "$ROWS")"
fi

DATA_TMP="$(mktemp)"
BODY_TMP="$(mktemp)"
trap 'rm -f "$DATA_TMP" "$BODY_TMP"' EXIT
printf '%s' "$DATA_BLOCK" > "$DATA_TMP"

OFFLINE_ATTR=""
[ "$OFFLINE" -eq 1 ] && OFFLINE_ATTR=' data-offline-snapshot="1"'

sed -e "s/__NAME__/$NAME_ESC/g" \
    -e "s/__DATE__/$DATE/g" \
    -e "s/__OFFLINE_ATTR__/$OFFLINE_ATTR/g" \
    "$TEMPLATE" > "$BODY_TMP"

awk -v datafile="$DATA_TMP" '
  /__SYNC_DATA__/ {
    while ((getline line < datafile) > 0) printf "%s", line
    close(datafile)
    next
  }
  { print }
' "$BODY_TMP" > "$OUT"

echo "wrote $OUT"

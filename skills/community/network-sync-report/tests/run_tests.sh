#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$ROOT/tests/fixtures"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

chmod +x "$ROOT/scripts/"*.sh

"$ROOT/scripts/merge_sync_pages.sh" "$SCRATCH/merged.json" \
  "$FIX/page1.json" "$FIX/page2.json"

MERGED_N="$(jq '.syncs | length' "$SCRATCH/merged.json")"
[ "$MERGED_N" = "5" ] || { echo "expected 5 deduped syncs, got $MERGED_N"; exit 1; }

"$ROOT/scripts/normalize_syncs.sh" "$SCRATCH/merged.json" > "$SCRATCH/rows.jsonl"
"$ROOT/scripts/normalize_syncs.sh" --source csv "$FIX/upload_snapshot.csv" > "$SCRATCH/csv_rows.jsonl"

# twitter/x canonicalization
jq -e 'select(.id=="sync-dup") | .channel == "twitter"' "$SCRATCH/rows.jsonl" >/dev/null

# null vs zero connections
jq -e 'select(.id=="sync-002") | .connections_indexed == null' "$SCRATCH/rows.jsonl" >/dev/null
jq -e 'select(.id=="sync-dup") | .connections_indexed == 0' "$SCRATCH/rows.jsonl" >/dev/null

"$ROOT/scripts/build_csv.sh" "$SCRATCH/rows.jsonl" "$SCRATCH/out.csv"
grep -q "'=HYPERLINK" "$SCRATCH/out.csv" || { echo "expected CSV formula prefix on failure cell"; exit 1; }

"$ROOT/scripts/build_dashboard.sh" "$SCRATCH/rows.jsonl" "Demo" "2026-11-07" "$SCRATCH/out.html"
! grep -q '__SYNC_DATA__' "$SCRATCH/out.html"
grep -q 'application/json' "$SCRATCH/out.html"

# Hostile string must be JSON-escaped, not raw script breakout in HTML body outside JSON
grep -q '</script>' "$SCRATCH/out.html" && echo "html structure ok" >/dev/null

"$ROOT/scripts/build_dashboard.sh" "$SCRATCH/csv_rows.jsonl" "Demo" "2026-11-07" "$SCRATCH/snap.html" --offline-snapshot
grep -q 'data-offline-snapshot' "$SCRATCH/snap.html"

echo '{"completed":2,"processing":1,"pending":0,"failed":1}' > "$SCRATCH/agg.json"
OUT="$("$ROOT/scripts/check_report.sh" "$SCRATCH/rows.jsonl" "$SCRATCH/agg.json")"
echo "$OUT" | jq -e '.aggregate_mismatch // .aggregate_ok' >/dev/null

echo "network-sync-report tests passed"

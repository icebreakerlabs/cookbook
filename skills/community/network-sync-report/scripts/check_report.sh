#!/usr/bin/env bash
# Validate normalized rows and optional API aggregate counts.
# Usage: check_report.sh rows.jsonl [aggregates.json]
# aggregates.json is { "completed": n, "processing": n, "pending": n, "failed": n, ... }
set -euo pipefail

ROWS="${1:?rows.jsonl}"
AGG="${2:-}"

read_rows() {
  FIRST="$(sed -e 's/^[[:space:]]*//' "$ROWS" | head -c1)"
  if [ "$FIRST" = "[" ]; then
    jq -c '.[]' "$ROWS"
  else
    cat "$ROWS"
  fi
}

NOW_EPOCH="$(date -u +%s)"
ROWS_JSON="$(read_rows | jq -s '.')"

jq -n --argjson rows "$ROWS_JSON" --argjson now "$NOW_EPOCH" '
  def status_count($s): [ $rows[] | select(.status == $s) ] | length;
  def known: ["completed","processing","pending","failed"];
  def unknown_statuses:
    [ $rows[].status | select(. as $s | (known | index($s)) | not) ] | unique;
  {
    row_total: ($rows | length),
    by_status: (known | map({key: ., value: status_count(.)}) | from_entries),
    unknown_statuses: unknown_statuses,
    unknown_status_count: ([ $rows[] | select(.status as $s | (known|index($s))|not) ] | length)
  }
' > /tmp/nsr_counts.$$
mv /tmp/nsr_counts.$$ /tmp/nsr_counts.json 2>/dev/null || true

FLAGS="$(jq -n --argjson rows "$ROWS_JSON" --argjson now "$NOW_EPOCH" '
  def day_ago: $now - 86400;
  def week_ago: $now - (7*86400);
  def parse_epoch($s):
    if $s == null or $s == "" then null else
      try (($s | tostring | sub(" "; "T")) + "Z" | fromdateiso8601) catch null
    end;
  (
    [ $rows[] |
      select((parse_epoch(.updated_at) // 0) >= day_ago)
    ] | length
  ) as $last24 |
  (
    [ $rows[] |
      select(.status == "pending" or .status == "processing") |
      select((parse_epoch(.queued_at) // 0) < week_ago)
    ] | length
  ) as $stuck |
  (
    [ $rows[] | select(.status == "failed" and (((.failure // "") | tostring) | gsub("\\s";"")) == "") ] | length
  ) as $failed_no_reason |
  (
    [ $rows[] | {k:(.channel+"/"+.handle)} ] | group_by(.k) | map(select(length>1)) | length
  ) as $dup_profiles |
  {
    updated_last_24h: $last24,
    stuck_over_7d: $stuck,
    failed_without_reason: $failed_no_reason,
    duplicate_profiles: $dup_profiles
  }
')"

echo "$FLAGS" | jq .

if [ -n "$AGG" ] && [ -f "$AGG" ]; then
  jq -n --argjson rows "$ROWS_JSON" --slurpfile agg "$AGG" '
    def status_count($s): [ $rows[] | select(.status == $s) ] | length;
    def known: ["completed","processing","pending","failed"];
    ($agg[0]) as $api |
    [
      known[] as $k |
      { status: $k, rows: status_count($k), api: ($api[$k] // null) }
      | select(.api != null and .rows != .api)
    ] as $mismatch |
    if ($mismatch|length) > 0 then
      { aggregate_mismatch: $mismatch, note: "Queue may have moved during pagination, or pages are incomplete." }
    else { aggregate_ok: true } end
  '
fi

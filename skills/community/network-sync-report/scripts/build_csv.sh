#!/usr/bin/env bash
# Write a formula-safe shareable CSV from normalize_syncs JSONL (one object per line).
# Usage: build_csv.sh rows.jsonl OUT.csv
set -euo pipefail

ROWS="${1:?rows.jsonl}"
OUT="${2:?out.csv}"

{
  echo "profile,url,channel,status,connections_indexed,queued_at,updated_at,failure"
  FIRST="$(sed -e 's/^[[:space:]]*//' "$ROWS" | head -c1)"
  if [ "$FIRST" = "[" ]; then
    jq -c '.[]' "$ROWS"
  else
    cat "$ROWS"
  fi | while IFS= read -r row; do
    [ -z "$row" ] && continue
    jq -r '
      def url:
        if .channel == "linkedin" then "https://www.linkedin.com/in/" + (.handle|@uri)
        elif .channel == "github" then "https://github.com/" + (.handle|@uri)
        elif .channel == "twitter" then "https://x.com/" + (.handle|@uri)
        else "" end;
      def esc($s):
        if $s == null then ""
        elif ($s|type)=="number" then ($s|tostring)
        else
          ($s|tostring) as $t |
          (if ($t|test("^[\\s]*[=+\\-@\\t\\r]")) then "'"'"'" + $t else $t end) as $g |
          if ($g|test("[\",\n]")) then "\"" + ($g|gsub("\"";"\"\"")) + "\"" else $g end
        end;
      [
        esc(.channel + "/" + .handle),
        esc(url),
        esc(.channel),
        esc(.status),
        esc(if .connections_indexed == null then "" else (.connections_indexed|tostring) end),
        esc(.queued_at),
        esc(.updated_at),
        esc(.failure)
      ] | join(",")
    ' <<<"$row"
  done
} > "$OUT"

echo "wrote $OUT"

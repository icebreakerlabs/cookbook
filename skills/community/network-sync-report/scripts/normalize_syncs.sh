#!/usr/bin/env bash
# Normalize merged API JSON or a CSV export into JSON row objects (one per line).
# Usage:
#   normalize_syncs.sh merged.json
#   normalize_syncs.sh --source csv upload.csv
set -euo pipefail

SOURCE=api
INPUT="${1:?input required}"
if [ "${1:-}" = "--source" ]; then
  SOURCE="${2:?csv|api}"
  INPUT="${3:?path}"
fi

emit_api() {
  jq -c '
    def split_path($p):
      if $p == null or $p == "" then {channel: "unknown", handle: ""}
      else ($p | split("/")) as $parts |
        if ($parts | length) >= 2 then {channel: $parts[0], handle: $parts[1]}
        elif ($parts | length) == 1 then {channel: "unknown", handle: $parts[0]}
        else {channel: "unknown", handle: ""} end
      end;
    def canon($c):
      ($c | ascii_downcase) as $x |
      if $x == "linkedin" then "linkedin"
      elif $x == "github" then "github"
      elif ($x == "twitter" or $x == "x") then "twitter"
      elif $x == "" or $x == "null" then "unknown"
      else "unknown" end;
    def fmt_time($t):
      if $t == null or $t == "" then ""
      else
        try (
          ($t | tostring | sub("\\.[0-9]+"; "")) as $s |
          (if ($s | test("Z$|[+-][0-9]{2}:|[+-][0-9]{4}$")) then $s else $s + "Z" end)
          | fromdateiso8601 | strftime("%Y-%m-%d %H:%M:%S")
        ) catch ""
      end;
    def conn($n):
      if $n == null then null
      elif ($n | type) == "number" then $n
      elif ($n | type) == "string" and ($n | test("^-?[0-9]+$")) then ($n | tonumber)
      else null end;
    .syncs[]? | split_path(.targetSocialPath) as $sp |
    (if .channelType != null and ((.channelType | tostring) | gsub("^\\s+|\\s+$"; "")) != ""
      then canon(.channelType | tostring)
      else canon($sp.channel) end) as $ch |
    {
      id: (.id | tostring),
      handle: ($sp.handle | tostring),
      channel: $ch,
      status: (.status // "unknown" | tostring),
      connections_indexed: conn(.connectionCount),
      queued_at: fmt_time(.createdAt),
      updated_at: fmt_time(.updatedAt),
      failure: ((.failureDetail // .failureReason // "") | tostring)
    }
  ' "$INPUT"
}

emit_csv() {
  # Expected header: id,target_social_path,status,connections_indexed,created_at,updated_at,failure_reason,failure_detail
  tail -n +2 "$INPUT" | while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    jq -c -n --arg line "$line" '
      def split_path($p):
        if $p == "" then {channel: "unknown", handle: ""}
        else ($p | split("/")) as $parts |
          if ($parts | length) >= 2 then {channel: $parts[0], handle: $parts[1]}
          else {channel: "unknown", handle: ($parts[0] // "")} end
        end;
      def canon($c):
        ($c | ascii_downcase) as $x |
        if $x == "linkedin" then "linkedin"
        elif $x == "github" then "github"
        elif ($x == "twitter" or $x == "x") then "twitter"
        elif $x == "" then "unknown"
        else "unknown" end;
      def conn($s):
        if $s == "" or $s == "null" then null elif ($s | test("^-?[0-9]+$")) then ($s | tonumber) else null end;
      ($line | split(",")) as $c |
      split_path($c[1] // "") as $sp |
      {
        id: ($c[0] // ""),
        handle: $sp.handle,
        channel: canon($sp.channel),
        status: ($c[2] // "unknown"),
        connections_indexed: conn($c[3] // ""),
        queued_at: ($c[4] // ""),
        updated_at: ($c[5] // ""),
        failure: (if ($c[7] // "") != "" then $c[7] elif ($c[6] // "") != "" then $c[6] else "" end)
      }
    '
  done
}

case "$SOURCE" in
  api) emit_api ;;
  csv) emit_csv ;;
  *) echo "unknown source: $SOURCE" >&2; exit 1 ;;
esac

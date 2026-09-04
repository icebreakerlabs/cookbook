#!/usr/bin/env bash
# Merge saved Icebreaker `search_network` result files into one clean, deduped
# network JSON. The MCP saves large search responses to files under the
# tool-results dir; pass those files here.
#
# Usage:
#   build_network_json.sh OUT.json FILE1 [FILE2 ...]
#
# Files whose params_used.connectionFollowType == "following" are treated as
# the Twitter-follows pass; everyone else is a connection. Each person is
# tagged rel = connection | following | both so you can see how you're tied to
# them. Dedup is by social_name (Icebreaker's canonical per-person handle).
set -euo pipefail

OUT="$1"; shift
[ "$#" -ge 1 ] || { echo "no input files" >&2; exit 1; }

conn="$(mktemp)"; foll="$(mktemp)"
trap 'rm -f "$conn" "$foll"' EXIT
for f in "$@"; do
  ft="$(jq -r '.params_used.connectionFollowType // "connection"' "$f" 2>/dev/null || echo connection)"
  if [ "$ft" = "following" ]; then
    jq -r '.response.profiles[]?.omni_profile.social_name // empty' "$f" >> "$foll"
  else
    jq -r '.response.profiles[]?.omni_profile.social_name // empty' "$f" >> "$conn"
  fi
done
sort -u "$conn" -o "$conn"; sort -u "$foll" -o "$foll"

jq -s \
  --slurpfile c <(jq -R . "$conn" | jq -s .) \
  --slurpfile f <(jq -R . "$foll" | jq -s .) '
  def yr(d): (d // "" | if . == "" then null else (try (.[0:4]|tonumber) catch null) end);
  ($c[0]) as $conn | ($f[0]) as $foll |
  [ .[].response.profiles[]? ]
  | unique_by(.omni_profile.social_name)
  | map( .omni_profile as $o | {
      name: $o.name,
      social_name: $o.social_name,
      source: $o.source,
      rel: ( ($o.social_name | IN($conn[])) as $ic
           | ($o.social_name | IN($foll[])) as $if
           | if $ic and $if then "both" elif $if then "following" else "connection" end ),
      location: $o.location,
      job_title: $o.job_title,
      bio: $o.bio,
      linkedin: ([$o.linked_accounts[]?|select(.type=="linkedin")|.value][0]),
      twitter:  ([$o.linked_accounts[]?|select(.type=="twitter")|.value][0]),
      github:   ([$o.linked_accounts[]?|select(.type=="github")|.value][0]),
      schools:  [ $o.education_history[]?.schoolName ],
      education:[ $o.education_history[]? | {degree, schoolName, endDate} ],
      work:     [ $o.work_history[]? | {company, title, startDate, endDate, location} ],
      first_job_year:  ( [ $o.work_history[]?.startDate | yr(.) ] | map(select(.!=null)) | min ),
      latest_grad_year:( [ $o.education_history[]?.endDate | yr(.) ] | map(select(.!=null)) | max )
    } )
' "$@" > "$OUT"

echo "unique profiles: $(jq 'length' "$OUT")"
echo "rel breakdown:"; jq -r '.[].rel' "$OUT" | sort | uniq -c
echo "source breakdown:"; jq -r '.[].source' "$OUT" | sort | uniq -c

#!/usr/bin/env bash
# Join the reviewers' flagged people back to the full network, dedupe, build
# real external URLs + Icebreaker social paths, and (optionally) tier them.
#
# Usage:
#   flagged_to_shortlist.sh NETWORK.json HANDLES.txt OUT.csv PATHS.json
#
#   HANDLES.txt  one social_name per line (the last path segment of each
#                reviewer's url, e.g. `vyvyenyue`, `alysiawenjiewu`). Resolve
#                flags by handle, never by the reviewer's index number.
#   OUT.csv      the shortlist (one row per unique person).
#   PATHS.json   JSON array of "source/handle" paths, ready to paste into
#                manage_list_tool's social_paths.
#
# Optional tiering via env vars (leave unset to emit tier="" and tier by hand):
#   LOC_RE    regex of in-target locations   e.g. 'San Francisco|Bay Area|SF|Palo Alto'
#   SCHOOL_RE regex of target schools        e.g. 'Stanford|MIT|Berkeley|CMU|Waterloo'
#   EXP_LO    earliest first-job year in band (inclusive)  e.g. 2017
#   EXP_HI    latest  first-job year in band (inclusive)  e.g. 2024
# Tier A = location match AND school match AND (experience in band OR unknown);
# B = strong on two of the three; C = the rest. Location/school are matched
# against location + bio + schools + title, so thin Twitter profiles that only
# name their school in the bio still count. Experience unknown is treated as
# neutral (never disqualifying) because thin profiles and PhDs lack a clean
# first-job year.
set -euo pipefail

NET="$1"; HANDLES="$2"; OUTCSV="$3"; OUTPATHS="$4"
LOC_RE="${LOC_RE:-}"; SCHOOL_RE="${SCHOOL_RE:-}"
EXP_LO="${EXP_LO:-0}"; EXP_HI="${EXP_HI:-9999}"

sort -u "$HANDLES" > "${HANDLES}.uniq"

jq -r --rawfile hraw "${HANDLES}.uniq" \
      --arg loc "$LOC_RE" --arg sch "$SCHOOL_RE" \
      --argjson lo "$EXP_LO" --argjson hi "$EXP_HI" '
  ($hraw | split("\n") | map(select(length>0))) as $h |
  def clean(s): (s // "" | gsub("[\n\r]+";" ") | gsub("  +";" "));
  def hit($re; s): ($re != "" and (s | test($re;"i")));
  [ .[] | select(.social_name as $s | $h|index($s)) |
    ((.schools|map(select(.!=null))|join(", ")) + " || " + (.bio//"") + " || " + (.job_title//"")) as $ctx |
    (.location // "") as $locstr |
    (hit($loc; $locstr) or (($locstr=="") and hit($loc; (.bio//"")))) as $sf |
    (hit($sch; $ctx)) as $top |
    ( .first_job_year as $y | if $y==null then null elif ($y>=$lo and $y<=$hi) then true else false end) as $inband |
    { tier: ( if ($sf and $top and ($inband==true or $inband==null)) then "A"
              elif (($sf and $top) or ($top and ($inband==true or $inband==null)) or ($sf and ($inband==true or $inband==null))) then "B"
              elif ($loc=="" and $sch=="") then ""
              else "C" end ),
      name: clean(.name),
      social_path: (.source + "/" + .social_name),
      external_url: ( if .source=="linkedin" and .linkedin then "https://www.linkedin.com/in/"+.linkedin
                      elif .source=="twitter" and .twitter then "https://x.com/"+.twitter
                      elif .linkedin then "https://www.linkedin.com/in/"+.linkedin
                      elif .twitter then "https://x.com/"+.twitter
                      else "https://app.icebreaker.xyz/"+.social_name end ),
      source: .source, tie: .rel, location: clean(.location),
      first_job_year: ((.first_job_year // "")|tostring),
      top_school: (if $top then "yes" else "no" end),
      loc_match: (if $sf then "yes" else "no" end),
      schools: clean(.schools | map(select(. != null)) | join(", ")),
      title: clean(.job_title), bio: clean(.bio // "" | .[0:200]) } ]
  | (sort_by(.tier, (.name|ascii_downcase)))
  | (["tier","name","social_path","external_url","source","tie","location","first_job_year","top_school","loc_match","schools","title","bio"]),
    (.[] | [.tier,.name,.social_path,.external_url,.source,.tie,.location,.first_job_year,.top_school,.loc_match,.schools,.title,.bio])
  | @csv
' "$NET" > "$OUTCSV"

# social paths for the Icebreaker list, tier order preserved
jq --rawfile hraw "${HANDLES}.uniq" '
  ($hraw | split("\n") | map(select(length>0))) as $h |
  [ .[] | select(.social_name as $s | $h|index($s)) | (.source + "/" + .social_name) ]
' "$NET" > "$OUTPATHS"

rm -f "${HANDLES}.uniq"
echo "shortlist rows: $(($(wc -l < "$OUTCSV")-1))"
echo "paths: $(jq 'length' "$OUTPATHS")"

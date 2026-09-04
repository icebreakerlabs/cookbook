#!/usr/bin/env bash
# Turn a clean network JSON (from build_network_json.sh) into compact one-line-
# per-person records and split them into batch files for parallel reviewers.
# Compact records keep only what a reviewer needs to judge fit, so a whole
# ~1000-person network fits comfortably across a handful of subagents.
#
# Usage:
#   build_compact_batches.sh NETWORK.json OUT_DIR [PER_BATCH]
#
# PER_BATCH defaults to 175 (≈6 batches per 1000 people). Emits OUT_DIR/batch_00,
# batch_01, ... Each line carries a stable index `i` so you can cross-check, but
# always resolve a flagged person by their handle/url, never by index — reviewer
# index numbers drift.
set -euo pipefail

NET="$1"; OUTDIR="$2"; PER="${3:-175}"
mkdir -p "$OUTDIR"

jq -r '
  to_entries[] | .key as $i | .value as $p |
  ($p.work | map((.title // "?") + "@" + (.company // "?")
      + "(" + ((.startDate // "")[0:4]) + "-" + ((.endDate // "now")[0:4]) + ")")
   | .[0:4] | join("; ")) as $wk |
  { i: $i, name: $p.name, loc: $p.location, title: $p.job_title,
    bio: ($p.bio // "" | .[0:280]),
    schools: ($p.schools | map(select(. != null)) | join(", ")),
    fjy: $p.first_job_year, grad: $p.latest_grad_year,
    work: $wk, li: $p.linkedin, tw: $p.twitter, src: $p.source, rel: $p.rel,
    url: ("https://app.icebreaker.xyz/" + $p.social_name) } | @json
' "$NET" > "$OUTDIR/_compact.jsonl"

split -d -l "$PER" "$OUTDIR/_compact.jsonl" "$OUTDIR/batch_"
echo "total records: $(wc -l < "$OUTDIR/_compact.jsonl")"
echo "batches:"; ls "$OUTDIR"/batch_* | sed 's/^/  /'

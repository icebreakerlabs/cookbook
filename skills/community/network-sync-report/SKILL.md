---
name: network-sync-report
description: >-
  Build a read-only network sync status report for yourself or a team
  collaborator — a standalone offline HTML dashboard plus a shareable CSV of
  completed, processing, pending, failed, and other syncs from Icebreaker
  list_network_syncs_tool. Use when someone asks what syncs are pending, done,
  or failed for a teammate, wants a sync report or dashboard, asks why a sync
  failed, or uploads a network sync CSV export. Triggers on phrases like "syncs
  for Alex" or "how are Sam's syncs doing".
---

# Network sync report

**Output:** one self-contained HTML dashboard, one shareable CSV, and a short chat
note on anything odd.

**Requires:** Icebreaker MCP (`list_network_syncs_tool`, and for teammate scope
`get_team_collaborators`). Read-only — do **not** call `queue_network_sync_tool`
or queue any syncs from this skill.

Bundled helpers (run them; do not re-type jq each time):

- `scripts/merge_sync_pages.sh` — dedupe paginated `list_network_syncs_tool` pages
- `scripts/normalize_syncs.sh` — API or CSV rows → canonical JSON lines
- `scripts/build_csv.sh` — shareable CSV (formula-safe)
- `scripts/build_dashboard.sh` — offline HTML from template + normalized JSON
- `scripts/check_report.sh` — counts, flags, and optional API aggregate check
- `assets/network_sync_dashboard_template.html` — dashboard shell
- `tests/` — synthetic fixtures only (no live MCP calls in CI)

Work in a scratch dir, not the repo. File basename pattern:
`<slug>_<team-scope>_network_syncs.{html,csv}` where `<slug>` is a lowercase
ascii slug from the person's first name and `<team-scope>` is `personal` or a
sanitized domain (e.g. `example_com`) so two teammates named Alex do not collide.

## 0. Scope — personal vs collaborator

| Intent | `collaborator_pkid` | `teamDomainScope` |
|--------|---------------------|-------------------|
| Signed-in viewer's own syncs | omit | omit |
| A teammate's syncs | required non-empty pkid | required team FQDN |

**Never** pass or override `viewerPkid` (undocumented; identity comes from the MCP session).

**Never** omit `collaborator_pkid` while also passing `teamDomainScope` to mean
"someone on the team" — that drifts into personal scope. If pkid or domain is
missing, ask once; do not guess.

Collaborator scope needs team admin on the domain and the pkid belonging to that
team (same semantics as `queue_network_sync_status_tool`).

## 1. Find the person (collaborator scope only)

```
get_team_collaborators(company_domain="<domain>", team_limit=1000)
```

Match on `omni_profile.name` (case-insensitive). **0 matches** → say so and stop.
**2+ matches** → list candidates (name + pkid); ask which one — do not pick silently.

Trimmed-empty pkids are invalid. For personal scope, skip this step.

No domain given for a named teammate? Ask once; do not invent a domain.

## 2. Pull every sync (live path)

Tool: `list_network_syncs_tool`.

| Param | Value |
|-------|-------|
| `collaborator_pkid` | pkid from step 1 (omit for personal) |
| `teamDomainScope` | team domain, e.g. `example.com` (omit for personal) |
| `limit` | `100` (backend max) |
| `cursor` | omit first call, then prior `data.nextCursor` |
| `status` | leave unset (filter hides rows; aggregate `counts` ignore status filter) |

**Assumed response shape** (not fully described in the public tool descriptor;
treat missing fields as empty):

- `data.syncs[]` — rows with `id`, `targetSocialPath`, `channelType`, `status`,
  `createdAt`, `updatedAt`, `connectionCount`, `failureReason`, `failureDetail`, …
- `data.counts` — totals by status across **all** pages (status filter ignored)
- `data.nextCursor` — `null` when no more pages

Rows are treated as newest-updated-first per page; keep order stable after dedupe.

**Paginate** until `nextCursor` is null/empty. Save each page verbatim (file or
scratch). Dedupe by sync `id` across pages (`merge_sync_pages.sh`).

**Guards:** stop after 500 pages (50k rows) and report truncation. If aggregate
`data.counts` still disagrees with deduped row counts after a full walk, paginate
**once** more in case of a race; if still mismatched, report that the queue may
have moved during the pull — do not loop forever.

If the tool is unavailable, stop and offer the CSV upload path (section 2b).

## 2b. CSV upload fallback (offline snapshot)

User-provided export columns:
`id, target_social_path, status, connections_indexed, created_at, updated_at, failure_reason, failure_detail`

Map into the same normalized shape via `normalize_syncs.sh --source csv`. Label
the dashboard subtitle and chat note **offline snapshot**. Do **not** compare to
live API `data.counts` (there are none).

## 3. Normalize, CSV, checks

```
normalize_syncs.sh merged.json > rows.json
build_csv.sh rows.json out.csv
build_dashboard.sh rows.json "Display Name" YYYY-MM-DD out.html
check_report.sh rows.json [aggregates.json]
```

Normalization rules:

- **Handle / channel** — from `targetSocialPath` (`channel/handle`) or
  `channelType`; canonicalize channel to `linkedin`, `github`, or `twitter`
  (`twitter` and `x` aliases, case-insensitive). Unknown channel → `unknown` (no
  invented LinkedIn URL).
- **connections_indexed** — JSON `null`/missing → empty string in CSV; numeric
  `0` stays `0` (do not conflate missing with zero).
- **Times** — parse ISO timestamps; emit `YYYY-MM-DD HH:MM:SS` UTC when valid;
  leave blank when unparseable.
- **failure** — `failureDetail`, else `failureReason`, else blank (render as text only).

`check_report.sh` flags (using system clock for "today"):

- Counts vs API aggregates when `aggregates.json` is passed (live path only)
- Syncs updated in the last 24h
- Stuck pending/processing older than 7 days
- Failed with blank failure text
- Duplicate profiles (`channel/handle`) across rows
- Unknown `status` values (listed explicitly)

**Deduplicate connections for totals:** for each `channel/handle`, count
connections only from the latest **completed** row (max `updated_at`). Sync row
counts stay raw so they can match API totals.

## 4. Deliver

- Attach or path both `*.html` and `*.csv`.
- Reply tersely: counts, then only flags that matter.
- Remind once: anyone the files are shared with can see the sync list (including
  failure text — treat as sensitive).

## Dashboard

The template loads data from a `<script type="application/json" id="sync-data">`
block filled by `build_dashboard.sh` (proper JSON encoding — never hand-escape into
inline JS). All untrusted fields use `textContent`; profile links use
`encodeURIComponent` on handles only for known channels.

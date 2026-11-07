---
name: network-sync-report
description: Build a read-only network sync status report for yourself or a team collaborator — offline HTML dashboard plus shareable CSV from Icebreaker list_network_syncs_tool. Use for pending/done/failed sync questions, teammate sync dashboards, failure reasons, or an uploaded sync CSV export.
---

# Network sync report

Output: one self-contained HTML dashboard + one shareable CSV + a short chat note on anything odd. **Read-only** — do not call `queue_network_sync_tool`.

Requires Icebreaker MCP. Work in a scratch dir, not the repo. Basenames: `<slug>_<scope>_network_syncs.{html,csv}` where `<slug>` is a lowercase ascii slug from the person's first name and `<scope>` is `personal` or a sanitized team domain (e.g. `example_com`).

## 0. Scope

| Intent | `collaborator_pkid` | `teamDomainScope` |
|--------|---------------------|-------------------|
| Your own syncs | omit | omit |
| Teammate's syncs | required | required team FQDN |

Never pass `viewerPkid`. Never pass `teamDomainScope` without a validated `collaborator_pkid` (no silent personal scope). Empty/whitespace pkids are invalid.

## 1. Find the person (teammate only)

```
get_team_collaborators(company_domain="<domain>", team_limit=1000)
```

Match `omni_profile.name` case-insensitively. Zero matches → stop. Multiple matches → list and ask; do not pick silently. No domain → ask once.

For your own syncs, skip this step.

## 2. Pull every sync

`list_network_syncs_tool` with `limit=100`, `status` unset, `cursor` from prior `data.nextCursor`. Omit scope params for personal syncs.

Assumed shape (treat missing fields as empty): `data.syncs[]`, `data.counts` (totals for all pages; ignores status filter), `data.nextCursor` (null/empty when done).

Paginate until `data.nextCursor` is null/empty. Dedupe by sync `id` (first seen wins). Cap at 500 pages; if hit, say the report may be truncated. Save pages verbatim; read from tool-result files when provided.

If counts still disagree with deduped rows after a full walk, re-fetch once (queue may have moved); if still off, report the mismatch without infinite retries.

**CSV fallback:** columns `id, target_social_path, status, connections_indexed, created_at, updated_at, failure_reason, failure_detail`. Label outputs **offline snapshot**; skip API `data.counts` checks.

## 3. Normalize, CSV, checks

- **Channel:** lowercase; `twitter` and `x` → `twitter`; else `linkedin`, `github`, or `unknown`.
- **Handle:** part after `/` in `targetSocialPath` (or `channelType` when present).
- **connections_indexed:** blank if null/missing; `0` only when actually zero.
- **Times:** `YYYY-MM-DD HH:MM:SS` UTC when parseable.
- **failure:** `failureDetail` else `failureReason`.

CSV columns: `profile, url, channel, status, connections_indexed, queued_at, updated_at, failure`. URLs only for linkedin/github/twitter via `encodeURIComponent` on the handle; leave blank for `unknown`. Prefix CSV cells that start with `=`, `+`, `-`, `@`, or tab with `'`. Render all failure text as data, not formulas.

Flags (system clock): last-24h updates; stuck pending/processing >7d; failed with blank failure; duplicate `channel/handle`. Connection totals: latest completed row per profile only; row counts stay raw.

## 4. Dashboard

Replace `__NAME__` (HTML-escaped), `__DATE__` (`YYYY-MM-DD`), and `__SYNC_DATA__` inside the template.

Serialize normalized rows as one JSON array, then **must** neutralize HTML script closers in the serialized text: `JSON.stringify(rows).replace(/</g, '\\u003c')` (same rule in any language: every `<` → the six characters `\u003c`). Plain `JSON.stringify` alone is not enough — a literal `</script>` in row data can end the element before `JSON.parse` runs. Insert that string into `<script type="application/json" id="sync-data">` only; do not paste raw objects into executable JS.

Offline; no external deps. Untrusted fields use `textContent` only (template already does). Profile links only for known channels.

## 5. Deliver

Both files to the user. Tersely: counts, then only important flags. Remind once: shared files expose the sync list (including failure text).

## Dashboard page

~~~~html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__NAME__'s network syncs</title>
<style>
:root{--fg:#1f1f1f;--muted:#6b6b6b;--bg:#fafaf8;--panel:#fff;--line:#e5e4df;--ok:#2f8f5b;--warn:#c27c0e;--bad:#c4423a;--idle:#a8a8a3;--accent:#3b6fd4;--sans:system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;--serif:Georgia,'Times New Roman',serif}
@media (prefers-color-scheme:dark){:root{--fg:#ececea;--muted:#a3a3a0;--bg:#1a1a19;--panel:#242423;--line:#383836;--ok:#4cb67d;--warn:#e0a03a;--bad:#e26a62;--idle:#6f6f6b;--accent:#7aa2f0}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font-family:var(--sans);font-size:15px;line-height:1.45}
.wrap{max-width:1100px;margin:0 auto;padding:24px 16px;display:flex;flex-direction:column;gap:20px}
h1{font-family:var(--serif);font-weight:400;font-size:2rem;margin:0}
.sub{color:var(--muted);margin:4px 0 0}
.sub b{color:var(--fg);font-weight:600}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,9rem),1fr));gap:12px}
.tile,.card{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:16px}
.tile{display:flex;flex-direction:column;gap:4px}
.label{font-size:.8rem;color:var(--muted);display:flex;align-items:center;gap:6px}
.dot{width:.5rem;height:.5rem;border-radius:50%;display:inline-block}
.big{font-family:var(--serif);font-size:2.25rem;line-height:1.1;font-variant-numeric:tabular-nums}
.bar{display:flex;height:10px;border-radius:999px;overflow:hidden;background:var(--line)}
.bar span{height:100%}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,22rem),1fr));gap:12px;align-items:start}
.card h2{font-size:1.05rem;font-weight:600;margin:0;display:flex;align-items:center;gap:8px}
.note{font-size:.8rem;color:var(--muted);margin:4px 0 12px}
.scroll{overflow-x:auto}
table{width:100%;border-collapse:collapse;font-variant-numeric:tabular-nums}
th{text-align:left;font-weight:600;font-size:.8rem;color:var(--muted);padding:4px 8px;border-bottom:1px solid var(--line)}
td{padding:4px 8px;border-bottom:1px solid var(--line);white-space:nowrap}
tr:last-child td{border-bottom:0}
.r{text-align:right}
.m{color:var(--muted)}
a{color:var(--fg);text-decoration:none}
a:hover{text-decoration:underline}
.conn{display:flex;align-items:center;gap:8px;justify-content:flex-end}
.conn i{display:block;height:6px;border-radius:3px;background:var(--accent);opacity:.85}
.conn em{font-style:normal;min-width:2.75rem;text-align:right}
.pill{font-size:.8rem;padding:0 8px;border-radius:999px;border:1px solid var(--line);color:var(--muted)}
.pill.proc{color:var(--warn);border-color:currentColor}
.empty{color:var(--muted);font-size:.85rem}
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>__NAME__'s network syncs</h1>
    <p class="sub"><b id="t-done"></b> of <b id="t-total"></b> syncs complete, <b id="t-conn"></b> connections indexed so far. Pulled __DATE__ (UTC).</p>
  </header>
  <div class="tiles">
    <div class="tile"><span class="label"><span class="dot" style="background:var(--ok)"></span>Completed</span><span class="big" id="n-completed"></span></div>
    <div class="tile"><span class="label"><span class="dot" style="background:var(--warn)"></span>Processing</span><span class="big" id="n-processing"></span></div>
    <div class="tile"><span class="label"><span class="dot" style="background:var(--idle)"></span>Pending</span><span class="big" id="n-pending"></span></div>
    <div class="tile"><span class="label"><span class="dot" style="background:var(--bad)"></span>Failed</span><span class="big" id="n-failed"></span></div>
    <div class="tile" id="tile-other" hidden><span class="label">Other</span><span class="big" id="n-other"></span></div>
    <div class="tile"><span class="label">Connections indexed</span><span class="big" id="n-conn"></span></div>
  </div>
  <div class="bar" id="bar"></div>
  <div class="grid">
    <section class="card">
      <h2><span class="dot" style="background:var(--ok)"></span>Completed</h2>
      <p class="note">One row per profile (latest sync), sorted by connections indexed</p>
      <div class="scroll"><table><thead><tr><th>Profile</th><th class="r">Connections</th><th class="r">Done</th></tr></thead><tbody id="done-rows"></tbody></table></div>
    </section>
    <section class="card">
      <h2><span class="dot" style="background:var(--idle)"></span>Pending and processing</h2>
      <p class="note">Processing first, then oldest queued</p>
      <div class="scroll"><table><thead><tr><th>Profile</th><th>Status</th><th class="r">Queued</th></tr></thead><tbody id="pend-rows"></tbody></table></div>
    </section>
    <section class="card">
      <h2><span class="dot" style="background:var(--bad)"></span>Failed</h2>
      <p class="note">Failure reasons from the queue</p>
      <div class="scroll"><table><thead><tr><th>Profile</th><th>Reason</th><th class="r">Failed</th></tr></thead><tbody id="fail-rows"></tbody></table></div>
    </section>
    <section class="card" id="card-other" hidden>
      <h2>Other statuses</h2>
      <div class="scroll"><table><thead><tr><th>Profile</th><th>Status</th><th class="r">Updated</th></tr></thead><tbody id="other-rows"></tbody></table></div>
    </section>
  </div>
</div>
<script type="application/json" id="sync-data">__SYNC_DATA__</script>
<script>
const KNOWN = new Set(['completed','processing','pending','failed']);
const SYNCS = JSON.parse(document.getElementById('sync-data').textContent);
const fmt = (n) => new Intl.NumberFormat('en-US').format(n);
const day = (s) => s ? new Date(String(s).slice(0, 10) + 'T00:00:00Z').toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' }) : '';
const conns = (r) => (r.connections_indexed === null || r.connections_indexed === '') ? null : Number(r.connections_indexed);
const BASE = { linkedin: 'https://www.linkedin.com/in/', github: 'https://github.com/', twitter: 'https://x.com/' };
const latest = new Map();
SYNCS.filter((r) => r.status === 'completed').forEach((r) => {
  const k = r.channel + '/' + r.handle;
  if (!latest.has(k) || String(r.updated_at) > String(latest.get(k).updated_at)) latest.set(k, r);
});
const done = [...latest.values()].sort((a, b) => (conns(b) ?? -1) - (conns(a) ?? -1));
const count = (s) => SYNCS.filter((r) => r.status === s).length;
const otherN = SYNCS.filter((r) => !KNOWN.has(r.status)).length;
const c = { completed: count('completed'), processing: count('processing'), pending: count('pending'), failed: count('failed'), other: otherN };
const total = SYNCS.length;
const connTotal = done.reduce((s, r) => s + (conns(r) ?? 0), 0);
const set = (id, v) => { const el = document.getElementById(id); if (el) el.textContent = v; };
set('t-done', fmt(c.completed)); set('t-total', fmt(total)); set('t-conn', fmt(connTotal)); set('n-conn', fmt(connTotal));
Object.keys(c).forEach((k) => set('n-' + k, fmt(c[k])));
if (otherN) { document.getElementById('tile-other').hidden = false; document.getElementById('card-other').hidden = false; }
const bar = document.getElementById('bar');
[['completed','var(--ok)'],['processing','var(--warn)'],['pending','var(--idle)'],['failed','var(--bad)'],['other','var(--accent)']].forEach(([k,col]) => {
  if (!total || !c[k]) return;
  const seg = document.createElement('span'); seg.style.width = (c[k] / total * 100) + '%'; seg.style.background = col; bar.appendChild(seg);
});
const td = (cls, text) => { const el = document.createElement('td'); if (cls) el.className = cls; if (text != null) el.textContent = text; return el; };
const profile = (r) => {
  const cell = td(); const base = BASE[r.channel];
  if (base && r.handle) { const a = document.createElement('a'); a.href = base + encodeURIComponent(r.handle); a.target = '_blank'; a.rel = 'noopener noreferrer'; a.textContent = r.handle; cell.appendChild(a); }
  else { cell.textContent = r.handle || '—'; }
  return cell;
};
const fill = (id, rows, cols, n) => {
  const body = document.getElementById(id);
  if (!rows.length) { const tr = document.createElement('tr'); const cell = td('empty', 'None'); cell.colSpan = n; tr.appendChild(cell); body.appendChild(tr); return; }
  rows.forEach((r) => { const tr = document.createElement('tr'); tr.append(...cols(r)); body.appendChild(tr); });
};
const maxC = Math.max(1, ...done.map((r) => conns(r) ?? 0));
fill('done-rows', done, (r) => {
  const cell = td('r'); const v = conns(r);
  if (v != null && !Number.isNaN(v)) { const wrap = document.createElement('div'); wrap.className = 'conn'; const i = document.createElement('i'); i.style.width = (v / maxC * 4) + 'rem'; const em = document.createElement('em'); em.textContent = fmt(v); wrap.append(i, em); cell.appendChild(wrap); } else cell.textContent = '—';
  return [profile(r), cell, td('r m', day(r.updated_at))];
}, 3);
const pend = SYNCS.filter((r) => r.status === 'pending' || r.status === 'processing')
  .sort((a, b) => (a.status === 'processing' ? 0 : 1) - (b.status === 'processing' ? 0 : 1) || String(a.queued_at).localeCompare(String(b.queued_at)));
fill('pend-rows', pend, (r) => { const cell = td(); const p = document.createElement('span'); p.className = 'pill' + (r.status === 'processing' ? ' proc' : ''); p.textContent = r.status; cell.appendChild(p); return [profile(r), cell, td('r m', day(r.queued_at))]; }, 3);
const failed = SYNCS.filter((r) => r.status === 'failed').sort((a, b) => String(a.updated_at).localeCompare(String(b.updated_at)));
fill('fail-rows', failed, (r) => [profile(r), td('m', r.failure || '—'), td('r m', day(r.updated_at))], 3);
const other = SYNCS.filter((r) => !KNOWN.has(r.status)).sort((a, b) => String(a.updated_at).localeCompare(String(b.updated_at)));
fill('other-rows', other, (r) => { const cell = td(); const p = document.createElement('span'); p.className = 'pill'; p.textContent = r.status; cell.appendChild(p); return [profile(r), cell, td('r m', day(r.updated_at))]; }, 3);
</script>
</body>
</html>
~~~~

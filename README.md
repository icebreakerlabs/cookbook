# Icebreaker Cookbook

Sample skills and recipes for building on the **[Icebreaker](https://app.icebreaker.xyz)**
network — your professional graph across LinkedIn, X, and GitHub — from inside
[Claude Code](https://code.claude.com), Cowork, or any client that speaks MCP.

Everything here is **optional and copy-what-you-want**. Each skill is a
self-contained folder you can drop into your own setup and adapt.

## Prerequisite: connect the Icebreaker MCP connector

Every recipe here calls the Icebreaker MCP server (tools like `search_network`
and `manage_list_tool`). Before any skill will work, connect Icebreaker as a
connector in your Claude client and sign in — see the
[MCP Quickstart](https://docs.icebreaker.xyz/docs/mcp-quickstart) for setup
steps across Claude, ChatGPT, Codex, Cursor, and Goose. Some features (e.g.
team-shared lists) require a paid Icebreaker Teams plan; skills degrade
gracefully and tell you when a step needs one. Full tool reference:
[Available Tools](https://docs.icebreaker.xyz/docs/mcp-available-tools).

## Skills

| Skill | What it does |
|-------|--------------|
| [`network-lead-scan`](skills/network-lead-scan) | Exhaustively scan one person's whole Icebreaker network against a description or job description, then hand back a browsable network, a tiered shortlist CSV (with real profile URLs), and a shared Icebreaker list. Built for sourcing candidates, hires, prospects, and warm leads from a teammate's or investor's connections. |
| [`referral-jam`](skills/referral-jam) | When a new teammate joins, scan their network against your open roles and return a short list per role with why each person fits, how the teammate knows them, and a referral note they can send. Builds on `network-lead-scan`. |
| [`start-sync-team-trusted-connections`](skills/start-sync-team-trusted-connections) | Same as `start-sync-trusted-connections`, for one teammate's network, with syncs queued on their behalf. Team admins. |
| [`start-sync-trusted-connections`](skills/start-sync-trusted-connections) | Scan your network for the people you're closest to (teammates, former colleagues, classmates, people on several of your networks), show who's synced, and queue syncs for the ones you pick. |
| [`report-unsynced-teammates`](skills/report-unsynced-teammates) | Report verified members and collaborators whose LinkedIn, X, or GitHub networks are not synced on the team, then offer to queue the missing syncs. Safe on a schedule. |
| [`monitor-list-for-updates`](skills/monitor-list-for-updates) | Daily email of all activity from people on a team list. No text rule. |
| [`monitor-list-for-hiring`](skills/monitor-list-for-hiring) | Daily email when people on a team list post about hiring or new hires. |
| [`monitor-list-for-launches`](skills/monitor-list-for-launches) | Daily email when people on a team list post a product launch or update. |
| [`monitor-list-for-job-changes`](skills/monitor-list-for-job-changes) | Daily email when people on a team list post a job change. |
| [`monitor-list-for-fundraises`](skills/monitor-list-for-fundraises) | Daily email when people on a team list post a fundraise or investment. |

Community-contributed skills live under [`skills/community/`](skills/community/). See that README for the list.

## Installing a skill

Pick whichever fits your setup — no marketplace or submission required.

**Claude Code (project or personal):** copy the skill folder into your skills
directory. Claude picks it up automatically.

```bash
# personal (available in every project)
cp -r skills/network-lead-scan ~/.claude/skills/

# or per-project (checked in with your repo)
mkdir -p .claude/skills && cp -r skills/network-lead-scan .claude/skills/
```

**Cowork / claude.ai:** enable the skill from **Customize → Skills** in the
desktop app or on claude.ai. Note that the heavier recipes here lean on a shell
and parallel subagents; those run fully in Claude Code and Cowork, and in a
reduced (slower, serial) form elsewhere.

## What's in a skill

Icebreaker-maintained skills live in `skills/<name>/`. User-submitted skills
live in [`skills/community/<name>/`](skills/community).

```
skills/<name>/                  # or skills/community/<name>/
├── SKILL.md        # the workflow — when it triggers and how to run it
├── scripts/        # helper scripts for the mechanical, repeated steps
├── references/     # prompt templates and docs loaded as needed
└── assets/         # templates used in output (e.g. HTML)
```

## Compatibility notes

- **Environment.** The bundled scripts assume a POSIX shell with `jq`, and the
  parallel-review step uses subagents — available in Claude Code and Cowork.
- **Icebreaker plan.** Reading and searching networks works on the free tier;
  creating **team-shared** lists needs a paid Icebreaker Teams plan.
- **Keeping current.** These skills call the Icebreaker MCP server, so a skill
  can break if the server's tool names or parameters change. Open an issue if a
  recipe stops working and we'll update it.

## Contributing

Have a recipe worth sharing? Add a folder under [`skills/community/`](skills/community)
with a clear `SKILL.md` and open a PR. Icebreaker-maintained skills stay in
`skills/`.

---

Maintained by [Icebreaker Labs](https://app.icebreaker.xyz). Full developer docs: [docs.icebreaker.xyz](https://docs.icebreaker.xyz).

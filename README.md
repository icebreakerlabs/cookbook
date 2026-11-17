# Icebreaker Cookbook

Browse and copy these skills at https://www.icebreaker.xyz/prompts.

Sample skills and recipes for building on the **[Icebreaker](https://app.icebreaker.xyz)**
network, your professional graph across LinkedIn, X, and GitHub, from inside
[Claude Code](https://code.claude.com), Cowork, or any client that speaks MCP.

Everything here is **optional and copy-what-you-want**. Each skill is a
self-contained folder you can drop into your own setup and adapt.

## Prerequisite: connect the Icebreaker MCP connector

Every recipe here calls the Icebreaker MCP server (tools like `search_network`
and `manage_list_tool`). Before any skill will work, connect Icebreaker as a
connector in your Claude client and sign in. See the
[MCP Quickstart](https://docs.icebreaker.xyz/docs/mcp-quickstart) for setup
steps across Claude, ChatGPT, Codex, Cursor, and Goose. Some features (e.g.
team-shared lists) require Starter or higher; skills degrade
gracefully and tell you when a step needs one. Full tool reference:
[Available Tools](https://docs.icebreaker.xyz/docs/mcp-available-tools).

## Skills

| Skill | What it does |
|-------|--------------|
| [`network-lead-scan`](skills/network-lead-scan) | Search one person's whole network for people who fit a profile you describe. Returns a ranked shortlist and a shared team list. |
| [`referral-jam`](skills/referral-jam) | Find people in a new teammate's network who fit your open roles, and draft referral notes they can send. |
| [`sync-team-trusted-connections`](skills/sync-team-trusted-connections) | For team admins: find a teammate's closest connections, pick who to sync, and queue syncs for them. |
| [`sync-trusted-connections`](skills/sync-trusted-connections) | Find the people you're closest to, see who's synced, and queue syncs for the ones you pick. |
| [`report-unsynced-teammates`](skills/report-unsynced-teammates) | See which teammates and collaborators haven't synced their LinkedIn, X, or GitHub, then queue the missing syncs. |
| [`network-sync-report`](skills/network-sync-report) | See which of your networks, or a teammate's, are synced. Builds a read-only dashboard and a CSV. |
| [`monitor-list-for-updates`](skills/monitor-list-for-updates) | Get a daily email of everything people on your team list post. |
| [`monitor-list-for-hiring`](skills/monitor-list-for-hiring) | Get a daily email when someone on your team list posts about hiring. |
| [`monitor-list-for-launches`](skills/monitor-list-for-launches) | Get a daily email when someone on your team list posts a product launch or major update. |
| [`monitor-list-for-job-changes`](skills/monitor-list-for-job-changes) | Get a daily email when someone on your team list changes jobs. |
| [`monitor-list-for-fundraises`](skills/monitor-list-for-fundraises) | Get a daily email when someone on your team list announces a raise or an investment. |

## Installing a skill

Pick whichever fits your setup. No marketplace or submission required.

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

Each skill is one file:

```
skills/<name>/                  # or skills/community/<name>/
└── SKILL.md        # the full workflow: frontmatter, when to use, and steps
```

## Compatibility notes

- **Environment.** Heavier skills assume a POSIX shell with `jq`, and the
  parallel-review step uses subagents, available in Claude Code and Cowork.
- **Icebreaker plan.** Reading and searching networks works on the free tier;
  creating **team-shared** lists and list monitors needs Starter or higher.
- **Keeping current.** These skills call the Icebreaker MCP server, so a skill
  can break if the server's tool names or parameters change. Open an issue if a
  recipe stops working and we'll update it.

## Contributing

Have a recipe worth sharing? Add a folder under [`skills/community/`](skills/community)
with a clear `SKILL.md` and open a PR. Icebreaker-maintained skills stay in
`skills/`.

---

Maintained by [Icebreaker Labs](https://app.icebreaker.xyz). Full developer docs: [docs.icebreaker.xyz](https://docs.icebreaker.xyz).
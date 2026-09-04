# Icebreaker Cookbook

Sample skills and recipes for building on the **[Icebreaker](https://app.icebreaker.xyz)**
network — your professional graph across LinkedIn, X, and GitHub — from inside
[Claude Code](https://code.claude.com), Cowork, or any client that speaks MCP.

Everything here is **optional and copy-what-you-want**. Each skill is a
self-contained folder you can drop into your own setup and adapt.

## Prerequisite: connect the Icebreaker MCP connector

Every recipe here calls the Icebreaker MCP server (tools like `search_network`
and `manage_list_tool`). Before any skill will work, connect Icebreaker as a
connector in your Claude client and sign in. Some features (e.g. team-shared
lists) require a paid Icebreaker Teams plan; skills degrade gracefully and tell
you when a step needs one.

## Skills

| Skill | What it does |
|-------|--------------|
| [`network-lead-scan`](skills/network-lead-scan) | Exhaustively scan one person's whole Icebreaker network against a description or job description, then hand back a browsable network, a tiered shortlist CSV (with real profile URLs), and a shared Icebreaker list. Built for sourcing candidates, hires, prospects, and warm leads from a teammate's or investor's connections. |

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

```
skills/<name>/
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

Have a recipe worth sharing? Add a folder under `skills/` (or a walkthrough
under a future `examples/`) with a clear `SKILL.md` and open a PR.

---

Maintained by [Icebreaker Labs](https://app.icebreaker.xyz).

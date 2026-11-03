---
name: start-sync-team-trusted-connections
description: >-
  Run start-sync-trusted-connections for a teammate: scan their network for the
  people they're closest to, let you pick, and queue the syncs on their behalf.
  Use when someone says "sync <teammate>'s trusted connections" or "run trusted
  connections across the team".
---

# Sync a teammate's trusted connections

Same as `start-sync-trusted-connections`, but for one teammate's network, with
syncs queued on their behalf. Run it once per teammate.

Requires: Icebreaker team plan, team admin, and the teammate listed as a team
collaborator. If any is missing, stop and say so.

## 1. Pick the teammate

```
get_entitlements_tool()
get_team_collaborators(company_domain="<team.com>")
```

Use `company_domain` as `<team.com>`. Note the teammate's `pkid` and
`omni_profile.social_name`. No `pkid` means you can't queue on their behalf.
Stop.

## 2. Run start-sync-trusted-connections with these changes

- **Step 1.1**: instead of `lookup_viewer_tool`, look up the teammate and save
  that response as `viewer.json`:

  ```
  search_network(socialPaths=["<teammate social_name>"], ordinality=["Global"],
    sources=["all"], limit=1, hideViewer=true)
  ```

- **Step 1.2**: pull the teammate's network (`connectedSocialPaths` = their
  `social_name`).
- **Steps 1.5 and 3**: add `teamDomainScope="<team.com>"` and
  `collaborator_pkid="<pkid>"` to every status check and queue call.
- **Step 2**: the teammate (or the admin, with the teammate) confirms the
  shortlist.
- **Step 4**: suggest the teammate install the extension. Lists are team
  lists (`teamDomainScope="<team.com>"`).

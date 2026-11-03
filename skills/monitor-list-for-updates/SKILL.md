---
name: monitor-list-for-updates
description: >-
  Get a daily email of posts from people on an Icebreaker list, with no text
  rule. Turns on the list monitor for an existing team list. Use when someone
  says "ping me when <people> post", "monitor this list for updates", or
  "watch <people>".
---

# Monitor a list for updates

Icebreaker list monitors send a daily digest (around 9am ET) of activity from
people on a team list. This one includes every post. No text rule.

Requires: Icebreaker Starter+ team plan and manage-members permission on the
list. Personal lists can't have monitors. If either is missing, stop and say so.

## Inputs

- **List**: an existing team list ID.
- **Team domain** from `get_entitlements_tool()` → `company_domain`.

## 1. Confirm the list

```
get_list_tool(list_id="<id>", teamDomainScope="<team.com>")
```

Confirm it's team-scoped and readable. If they didn't name a list, ask which
one.

## 2. Turn on the monitor

Check for an existing one first (one monitor per list):

```
manage_list_monitor_tool(action="get", list_id="<id>",
  teamDomainScope="<team.com>")
```

Then save, with no `text_rule`:

```
manage_list_monitor_tool(action="save", list_id="<id>",
  teamDomainScope="<team.com>", enabled=true)
```

If a monitor already exists with a text rule, show it and ask before clearing
it. One list has one monitor.

## 3. Report

- List name, member count, link `https://app.icebreaker.xyz/teams/<team.com>/lists/<id>`.
- No text rule. The digest includes all activity on the list.
- The digest goes to the signed-in user's Icebreaker account email, daily around 9am ET.
- Turning on a monitor doesn't trigger a fresh scrape, so the first digest may be quiet.

## Adjusting

- Add a filter later: `save` again with a `text_rule`.
- Pause: `save` with `enabled=false` (keeps settings).

---
name: monitor-list-for-launches
description: >-
  Get a daily email when people on an Icebreaker list announce a product
  launch or update. Turns on the list monitor with a default launch rule. Use
  when someone says "ping me when <people> launch something" or "monitor this
  list for launches".
---

# Monitor a list for launches

Icebreaker list monitors send a daily digest (around 9am ET) of activity from
people on a team list. This one keeps product launches and updates.

A launch is a reason to reach out, and a way to follow competitors and partners.

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

Then save. Use this rule unless they ask for a different one:

```
manage_list_monitor_tool(action="save", list_id="<id>",
  teamDomainScope="<team.com>", enabled=true,
  text_rule="Any major product launches or updates")
```

If a monitor already exists with a different rule, show both and ask before
overwriting. One list has one monitor.

## 3. Report

- List name, member count, link `https://app.icebreaker.xyz/teams/<team.com>/lists/<id>`.
- The saved rule.
- The digest goes to the signed-in user's Icebreaker account email, daily around 9am ET.
- Turning on a monitor doesn't trigger a fresh scrape, so the first digest may be quiet.

## Adjusting

- Change the filter: `save` again with a new `text_rule`.
- Pause: `save` with `enabled=false` (keeps settings).

---
id: 001
title: Set up GitHub and move the tracker there
label: wayfinder:task
status: open
assignee: none
blocked_by: []
---

## Question

Sam wants this project on GitHub, open source, with Issues as the tracker — and is learning GitHub from scratch. Nothing on the map is *decided* by this ticket, but the tracker migration and the "first real project" goal both wait on it.

Work (HITL: Sam does the account-side steps, the agent drives everything else — use the `wizard` skill to hand Sam a step-by-step for the parts only he can do):

1. Sam creates a GitHub account if he doesn't have one, and an empty public repo `music-discovery` (no README/license — the local repo already has content).
2. Install the `gh` CLI on this machine and authenticate it (`gh auth login`); confirm `gh auth status` succeeds.
3. Add the remote, push `master`, confirm the repo renders CONTEXT.md and wayfinder/.
4. Add an AGPL-3.0 `LICENSE` file.
5. Enable Issues; create labels `wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`.
6. `AGENTS.md` at the repo root — **done ahead of this ticket (2026-09-01)** so sessions started in this directory orient without Sam's vault. Re-read it when closing this ticket and update its Orient section if the GitHub move changes how sessions start.
7. Migrate the map: one issue per ticket file (title, label, body), the map issue with `wayfinder:map`, blocking expressed via GitHub's native "blocked by" relationships (or task-list checkboxes if unavailable on the plan). Update `wayfinder/TRACKER.md` to say the tracker is now GitHub Issues and how the operations map.

## Resolution

(open)

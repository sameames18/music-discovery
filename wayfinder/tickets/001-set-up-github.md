---
id: 001
title: Set up GitHub and move the tracker there
label: wayfinder:task
status: open
assignee: agent
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

Resolved 2026-09-01 (agent prep) and completed when Sam ran `scripts/github-setup.sh`.

- Repo: {{REPO_URL}} — public, `master` pushed, AGPL-3.0 `LICENSE` at the root (canonical GNU text, sha256 `0d96a4ff…`).
- `gh` CLI installed via winget (GitHub.cli 2.98.0) and signed in on Sam's machine; `gh auth setup-git` configured the credential helper so `git push` works without a password prompt.
- Issues enabled; labels `wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`.
- Tracker migrated by `scripts/migrate-tracker.py`: ticket NNN became issue #NNN, the map is {{MAP_URL}}, tickets are its sub-issues, blocking uses GitHub's native "blocked by" (REST `dependencies/blocked_by`, API version 2026-03-10). Closed tickets carry their Resolution as a comment. Local `wayfinder/tickets/` removed; `wayfinder/map.md` is a pointer; `wayfinder/TRACKER.md` and `AGENTS.md` describe the `gh` operations.
- Account creation and the device-flow login were Sam's; everything else ran from the wizard.

Facts later tickets depend on: `gh` is the tracker interface (see TRACKER.md); commits still go straight to `master`; the two scripts in `scripts/` are one-shot and can be deleted once the migration is confirmed.

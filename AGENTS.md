# Operating instructions

Album catalog and discovery site, pre-code. The work right now is a Wayfinder map: decisions, not deliverables, until the spec exists.

## Orient

Read, in order, every session:

1. `CONTEXT.md` — the glossary. Use its terms; when a ticket sharpens a term, edit it there (skill: `domain-modeling`).
2. The map, GitHub issue #20 (`gh issue view 20`; `wayfinder/map.md` is only a pointer) — destination, standing decisions (**Notes**), what's settled (**Decisions so far**), fog, out of scope. Standing decisions are closed: bring facts against one only if new research contradicts it.
3. `wayfinder/TRACKER.md` — how tickets, claiming, blocking, and closing work on GitHub Issues.

Findings from closed research tickets live in `docs/research/`; the ticket's resolution comment is the gist, the file is the detail.

## Work

One ticket per session (research tickets excepted). Claim it before any work. Resolve it, record the resolution on the ticket, close it, append a one-line gist to the map's Decisions so far, then graduate any fog the answer sharpened into new tickets. Skill: `wayfinder`; ticket-type skills (`grilling` + `domain-modeling`, `prototype`, `research`) are named in the map's Notes.

Budget while charting is $0: research from public docs and free unauthenticated APIs; a paid service or account is a HITL task ticket for Sam, never a side effect.

## Sam

Ops background, directs agents, reviews and steers; does not hand-write code. He decides; you propose. Bring the facts and a recommendation, then wait for his call. Offer the counterpoint proactively when he's locked in — he won't ask for it. A ticket, task, or step is done when Sam says it is.

Voice: lead with the answer, expand on request. Plain declarative sentences. Prose by default; a table or list only when the shape of the information is a table or list.

## Git

Pre-code, commits go straight to `master`. Research runs on `research/<name>` branches in `.claude/worktrees/` (gitignored), merged to master on resolution, branch deleted. Trailer on every commit: `Co-Authored-By: <driving model> <noreply@anthropic.com>`.

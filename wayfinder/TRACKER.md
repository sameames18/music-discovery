# Local-markdown tracker convention

No external issue tracker (GitHub/Linear/etc.) was configured for this project, so Wayfinder uses plain files in this repo.

## Layout

- `wayfinder/map.md` — the map. Front matter: `labels: [wayfinder:map]`.
- `wayfinder/tickets/NNN-slug.md` — one file per ticket (child of the map), NNN zero-padded sequential id.

## Ticket file format

```markdown
---
id: 007
title: <ticket title>
label: wayfinder:<research|prototype|grilling|task>
status: open|closed
assignee: none|agent|sam
blocked_by: [003, 005]   # ticket ids; empty list if unblocked
---

## Question

<the decision or investigation this ticket resolves>

## Resolution

<filled in on close: the answer>
```

## Wayfinding operations

- **Claim** a ticket: set `assignee` in its front matter before starting work.
- **Blocking**: `blocked_by` lists ticket ids. A ticket is unblocked when every id in `blocked_by` has `status: closed`.
- **Frontier**: open tickets with `assignee: none` and all `blocked_by` ids closed. Find by scanning `wayfinder/tickets/*.md` front matter.
- **Close** a ticket: set `status: closed`, fill in `## Resolution`.
- **Map update on close**: append a line to the map's `## Decisions so far` linking the closed ticket file with a one-line gist.
- Ticket ids are assigned in creation order and never reused.

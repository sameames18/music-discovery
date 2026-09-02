# GitHub Issues tracker convention

The Wayfinder tracker is GitHub Issues on `sameames18/music-discovery`. Local files are gone;
`wayfinder/map.md` is only a pointer. Everything below is `gh` from the repo root.

## Layout

- **Map**: issue #20, label `wayfinder:map`. Body = destination, notes, decisions so far, fog, out of scope.
- **Tickets**: sub-issues of the map, one label each from `wayfinder:research|prototype|grilling|task`.
  Ticket ids from the old files are the issue numbers (#1–#19 were migrated 1:1).

## Wayfinding operations

- **Load the map**: `gh issue view 20`. Open tickets are not listed in the body; query them.
- **Frontier** (open, unblocked, unclaimed): `gh issue list --state open --search "no:assignee -label:wayfinder:map"`, then drop any whose `blocked_by` is non-empty and not all closed:
  `gh api -H "X-GitHub-Api-Version: 2026-03-10" repos/sameames18/music-discovery/issues/N/dependencies/blocked_by --jq '.[] | "\(.number) \(.state)"'`.
  The GitHub UI shows the same thing in each issue's "Relationships" panel and on the map's sub-issue list.
- **Claim**: `gh issue edit N --add-assignee sameames18` before any work. Assignee is the claim; unassigned and open means unclaimed.
- **Create a ticket**: `gh issue create --title "..." --label wayfinder:<type> --body "## Question\n..."`, then attach it to the map and wire blocking in a second pass:
  - sub-issue: `gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/sameames18/music-discovery/issues/20/sub_issues -F sub_issue_id=<database id>`
  - blocked by: `gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/sameames18/music-discovery/issues/N/dependencies/blocked_by -F issue_id=<database id of the blocker>`
  - database id: `gh api repos/sameames18/music-discovery/issues/N --jq .id`.
- **Close**: post the answer as a comment headed `## Resolution`, then `gh issue close N --reason completed`. Research findings go in `docs/research/` and are linked from the comment.
- **Map update on close**: `gh issue edit 20 --body-file -` with the body from `gh issue view 20 --json body --jq .body` plus one new line under **Decisions so far**: `- [ticket title](issue URL): gist`. Graduate fog into new tickets the same way; remove the graduated patch from **Not yet specified**.
- **Out of scope**: close the ticket with `--reason "not planned"` and add one line under the map's **Out of scope**.

#!/usr/bin/env python3
"""Move the Wayfinder tracker from wayfinder/*.md to GitHub Issues.

One-shot. Run from the repo root after `gh auth login` and after the repo
exists on GitHub with Issues enabled and the wayfinder:* labels created
(scripts/github-setup.sh does all of that and then calls this).

What it does, in order:
  1. Creates one issue per wayfinder/tickets/NNN-*.md, in id order, so that
     ticket NNN becomes issue #NNN on a fresh repo (asserted, not assumed).
  2. Creates the map issue from wayfinder/map.md, labelled wayfinder:map,
     with ticket links rewritten to issue URLs.
  3. Makes every ticket a sub-issue of the map and wires blocked_by using
     GitHub's native issue dependencies. Falls back to a "Blocked by" line
     in the body if the API refuses.
  4. Posts each closed ticket's Resolution as a comment and closes it.
     Ticket 001 (this migration) is closed the same way.
  5. Rewrites the local files: wayfinder/map.md becomes a pointer to the map
     issue, wayfinder/tickets/ is removed, wayfinder/TRACKER.md describes the
     GitHub operations, AGENTS.md's Orient section points at the issue.
     Committing is left to the caller so the diff can be reviewed.

Idempotence: not safe to re-run after step 1 has created issues. If it
fails midway, delete the created issues (or the repo) before re-running.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TICKETS = ROOT / "wayfinder" / "tickets"
MAP_MD = ROOT / "wayfinder" / "map.md"
TRACKER_MD = ROOT / "wayfinder" / "TRACKER.md"
AGENTS_MD = ROOT / "AGENTS.md"
API_VERSION = "2026-03-10"  # issue dependencies + sub-issues need this
PAUSE = 1.2  # seconds between writes; GitHub secondary rate limits are real


def sh(*args: str, input: str | None = None, check: bool = True) -> str:
    p = subprocess.run(args, input=input, capture_output=True, text=True, encoding="utf-8")
    if check and p.returncode != 0:
        raise RuntimeError(f"{' '.join(args)}\n{p.stderr.strip()}")
    return p.stdout


def api(method: str, path: str, body: dict | None = None, check: bool = True) -> dict | list | None:
    args = ["gh", "api", "-X", method, "-H", f"X-GitHub-Api-Version: {API_VERSION}", path]
    if body is not None:
        args += ["--input", "-"]
    out = sh(*args, input=json.dumps(body) if body is not None else None, check=check)
    return json.loads(out) if out.strip() else None


# ---------------------------------------------------------------- parsing

FRONT = re.compile(r"^---\n(.*?)\n---\n", re.S)


def parse_ticket(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = FRONT.match(text)
    if not m:
        raise ValueError(f"{path.name}: no front matter")
    fm: dict[str, str] = {}
    for line in m.group(1).splitlines():
        k, _, v = line.partition(":")
        fm[k.strip()] = v.strip()
    body = text[m.end():]
    q = re.search(r"## Question\n(.*?)(?=\n## Resolution|\Z)", body, re.S)
    r = re.search(r"## Resolution\n(.*)\Z", body, re.S)
    blocked = [int(x) for x in re.findall(r"\d+", fm.get("blocked_by", "[]"))]
    return {
        "id": int(fm["id"]),
        "title": fm["title"],
        "label": fm["label"],
        "status": fm["status"],
        "blocked_by": blocked,
        "question": (q.group(1) if q else body).strip(),
        "resolution": (r.group(1) if r else "").strip(),
        "path": path,
    }


# ---------------------------------------------------------------- links

def make_link_rewriter(owner: str, repo: str, numbers: dict[int, int], base_dir: Path):
    """Rewrite relative markdown links in a file under base_dir for an issue body.

    tickets/NNN-*.md      -> the issue for ticket NNN
    ../foo.md, ./foo.md   -> blob URL on master
    """
    blob = f"https://github.com/{owner}/{repo}/blob/master/"
    issue = f"https://github.com/{owner}/{repo}/issues/"

    def repl(m: re.Match) -> str:
        label, target = m.group(1), m.group(2)
        if "://" in target or target.startswith("#"):
            return m.group(0)
        resolved = (base_dir / target).resolve()
        try:
            rel = resolved.relative_to(ROOT).as_posix()
        except ValueError:
            return m.group(0)
        t = re.match(r"wayfinder/tickets/(\d{3})-[^/]+\.md$", rel)
        if t and int(t.group(1)) in numbers:
            return f"[{label}]({issue}{numbers[int(t.group(1))]})"
        return f"[{label}]({blob}{rel})"

    return lambda text: re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", repl, text)


# ---------------------------------------------------------------- main

def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # titles carry em-dashes
    login = sh("gh", "api", "user", "--jq", ".login").strip()
    nwo = sh("gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner").strip()
    owner, repo = nwo.split("/")
    repo_url = f"https://github.com/{nwo}"
    print(f"Migrating to {repo_url} as {login}")

    existing = api("GET", f"repos/{nwo}/issues?state=all&per_page=1")
    if existing:
        print("Repo already has issues; refusing to migrate on top of them.", file=sys.stderr)
        return 1

    tickets = sorted((parse_ticket(p) for p in TICKETS.glob("*.md")), key=lambda t: t["id"])
    numbers: dict[int, int] = {}   # ticket id -> issue number
    db_ids: dict[int, int] = {}    # ticket id -> issue database id

    # Fill in the placeholders in ticket 001's resolution once we know the repo.
    for t in tickets:
        t["resolution"] = t["resolution"].replace("{{REPO_URL}}", repo_url)
        if t["id"] == 1:
            t["status"] = "closed"

    # 1. tickets, in id order ------------------------------------------------
    for t in tickets:
        rewrite = make_link_rewriter(owner, repo, numbers, TICKETS)
        body = "## Question\n\n" + rewrite(t["question"]) + "\n"
        created = api("POST", f"repos/{nwo}/issues", {
            "title": t["title"], "body": body, "labels": [t["label"]],
        })
        numbers[t["id"]] = created["number"]
        db_ids[t["id"]] = created["id"]
        flag = "" if created["number"] == t["id"] else "   (number differs from ticket id)"
        print(f"  #{created['number']:<3} {t['title']}{flag}")
        time.sleep(PAUSE)

    # 2. the map --------------------------------------------------------------
    map_text = MAP_MD.read_text(encoding="utf-8")
    map_body = FRONT.sub("", map_text, count=1).lstrip()
    map_body = re.sub(r"\A# .*\n\n?", "", map_body, count=1)  # H1 is the issue title
    map_body = re.sub(
        r"^Tracker convention:.*$",
        f"Tracker convention: [wayfinder/TRACKER.md]({repo_url}/blob/master/wayfinder/TRACKER.md). "
        f"Tickets are the sub-issues of this issue. Vocabulary: [CONTEXT.md]({repo_url}/blob/master/CONTEXT.md) "
        "— every ticket uses its terms.",
        map_body, count=1, flags=re.M,
    )
    map_body = re.sub(r"<!-- one line per closed ticket:.*?-->\n\n?", "", map_body, count=1)
    one = next(t for t in tickets if t["id"] == 1)
    gist = ("GitHub repo, gh CLI, AGPL-3.0 LICENSE, labels, and this tracker "
            "migrated from wayfinder/*.md to Issues (sub-issues + native blocking).")
    map_body = map_body.replace(
        "\n## Not yet specified",
        f"- [{one['title']}]({repo_url}/issues/{numbers[1]}): {gist}\n\n## Not yet specified",
        1,
    )
    map_body = make_link_rewriter(owner, repo, numbers, MAP_MD.parent)(map_body)
    map_title = re.search(r"^# (.*)$", map_text, re.M).group(1)
    created = api("POST", f"repos/{nwo}/issues", {
        "title": map_title, "body": map_body.strip() + "\n", "labels": ["wayfinder:map"],
    })
    map_number = created["number"]
    map_url = f"{repo_url}/issues/{map_number}"
    print(f"  #{map_number:<3} {map_title}   (map)")
    time.sleep(PAUSE)

    # 3. sub-issues + blocking ----------------------------------------------
    failures: list[str] = []
    for t in tickets:
        try:
            api("POST", f"repos/{nwo}/issues/{map_number}/sub_issues", {"sub_issue_id": db_ids[t["id"]]})
        except RuntimeError as e:
            failures.append(f"sub-issue #{numbers[t['id']]}: {e}")
        time.sleep(PAUSE)
    for t in tickets:
        for b in t["blocked_by"]:
            try:
                api("POST", f"repos/{nwo}/issues/{numbers[t['id']]}/dependencies/blocked_by",
                    {"issue_id": db_ids[b]})
            except RuntimeError as e:
                failures.append(f"#{numbers[t['id']]} blocked by #{numbers[b]}: {e}")
                # fallback: say it in the body so the frontier is still readable
                cur = api("GET", f"repos/{nwo}/issues/{numbers[t['id']]}")
                api("PATCH", f"repos/{nwo}/issues/{numbers[t['id']]}",
                    {"body": cur["body"].rstrip() + f"\n\nBlocked by #{numbers[b]}\n"})
            time.sleep(PAUSE)
    print("  wired sub-issues and blocking" + (f" ({len(failures)} fell back)" if failures else ""))

    # 4. close the closed ------------------------------------------------------
    for t in tickets:
        if t["status"] != "closed":
            continue
        n = numbers[t["id"]]
        rewrite = make_link_rewriter(owner, repo, numbers, TICKETS)
        api("PATCH", f"repos/{nwo}/issues/{n}", {"assignees": [login]})
        api("POST", f"repos/{nwo}/issues/{n}/comments",
            {"body": "## Resolution\n\n" + rewrite(t["resolution"]).replace("{{MAP_URL}}", map_url) + "\n"})
        sh("gh", "issue", "close", str(n), "--reason", "completed", "--repo", nwo)
        print(f"  closed #{n}")
        time.sleep(PAUSE)

    # 5. local files ---------------------------------------------------------
    MAP_MD.write_text(
        f"# Music Discovery — Wayfinder map\n\n"
        f"The map lives on GitHub: [{map_title}]({map_url}) (issue #{map_number}, label `wayfinder:map`).\n"
        f"Tickets are its sub-issues. Operations: [TRACKER.md](./TRACKER.md).\n\n"
        f"```bash\ngh issue view {map_number}\n```\n",
        encoding="utf-8",
    )
    shutil.rmtree(TICKETS)
    TRACKER_MD.write_text(TRACKER_TEMPLATE.format(map=map_number, nwo=nwo, login=login), encoding="utf-8")

    agents = AGENTS_MD.read_text(encoding="utf-8")
    agents = re.sub(
        r"2\. `wayfinder/map\.md` — .*?\n3\. `wayfinder/TRACKER\.md` — .*?\n",
        f"2. The map, GitHub issue #{map_number} (`gh issue view {map_number}`; `wayfinder/map.md` is only a "
        "pointer) — destination, standing decisions (**Notes**), what's settled (**Decisions so far**), fog, "
        "out of scope. Standing decisions are closed: bring facts against one only if new research "
        "contradicts it.\n"
        "3. `wayfinder/TRACKER.md` — how tickets, claiming, blocking, and closing work on GitHub Issues.\n",
        agents, count=1, flags=re.S,
    )
    agents = agents.replace(
        "Findings from closed research tickets live in `docs/research/`; the ticket's Resolution section is the gist, the file is the detail.",
        "Findings from closed research tickets live in `docs/research/`; the ticket's resolution comment is the gist, the file is the detail.",
    )
    AGENTS_MD.write_text(agents, encoding="utf-8")

    print(f"\nMap: {map_url}")
    if failures:
        print("\nNative relationships the API refused (body fallback used):")
        for f in failures:
            print("  - " + f.splitlines()[0])
    return 0


TRACKER_TEMPLATE = """# GitHub Issues tracker convention

The Wayfinder tracker is GitHub Issues on `{nwo}`. Local files are gone;
`wayfinder/map.md` is only a pointer. Everything below is `gh` from the repo root.

## Layout

- **Map**: issue #{map}, label `wayfinder:map`. Body = destination, notes, decisions so far, fog, out of scope.
- **Tickets**: sub-issues of the map, one label each from `wayfinder:research|prototype|grilling|task`.
  Ticket ids from the old files are the issue numbers (#1–#19 were migrated 1:1).

## Wayfinding operations

- **Load the map**: `gh issue view {map}`. Open tickets are not listed in the body; query them.
- **Frontier** (open, unblocked, unclaimed): `gh issue list --state open --search "no:assignee -label:wayfinder:map"`, then drop any whose `blocked_by` is non-empty and not all closed:
  `gh api -H "X-GitHub-Api-Version: 2026-03-10" repos/{nwo}/issues/N/dependencies/blocked_by --jq '.[] | "\\(.number) \\(.state)"'`.
  The GitHub UI shows the same thing in each issue's "Relationships" panel and on the map's sub-issue list.
- **Claim**: `gh issue edit N --add-assignee {login}` before any work. Assignee is the claim; unassigned and open means unclaimed.
- **Create a ticket**: `gh issue create --title "..." --label wayfinder:<type> --body "## Question\\n..."`, then attach it to the map and wire blocking in a second pass:
  - sub-issue: `gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/{nwo}/issues/{map}/sub_issues -F sub_issue_id=<database id>`
  - blocked by: `gh api -X POST -H "X-GitHub-Api-Version: 2026-03-10" repos/{nwo}/issues/N/dependencies/blocked_by -F issue_id=<database id of the blocker>`
  - database id: `gh api repos/{nwo}/issues/N --jq .id`.
- **Close**: post the answer as a comment headed `## Resolution`, then `gh issue close N --reason completed`. Research findings go in `docs/research/` and are linked from the comment.
- **Map update on close**: `gh issue edit {map} --body-file -` with the body from `gh issue view {map} --json body --jq .body` plus one new line under **Decisions so far**: `- [ticket title](issue URL): gist`. Graduate fog into new tickets the same way; remove the graduated patch from **Not yet specified**.
- **Out of scope**: close the ticket with `--reason "not planned"` and add one line under the map's **Out of scope**.
"""


if __name__ == "__main__":
    sys.exit(main())

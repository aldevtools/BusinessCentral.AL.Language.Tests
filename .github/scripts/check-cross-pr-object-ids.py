#!/usr/bin/env python3
"""Fail when two SIMULTANEOUSLY OPEN pull requests each claim the same AL object id.

Why this exists
---------------
`check-object-ids.py` validates one working tree: the pull request's own merge
commit. That catches a PR colliding with `master`, or with itself, and it is
blind by construction to every other open branch -- `actions/checkout` hands it
one tree and nothing else.

So two PRs can each add `codeunit 60940`, each pass, and break `master` on the
second merge. Branch protection's "require branches to be up to date" used to
close that window by forcing the second PR to rebase and recompile; turning it
off to let PRs drain without being serialized reopened it. This closes it
directly instead.

How
---
For each pull request, the ids it CLAIMS are the ids in its head tree minus the
ids in its MERGE BASE with `master` -- the same base `git diff master...<head>`
uses. So a claim is an id the PR itself adds (a new object, or an object it
renumbers). An id the PR merely inherits is not a claim, and neither is an id
that was on `master` when the PR branched and that `master` has since
renumbered or removed. Two PRs collide when those two claimed sets intersect.

Comparing against `master`'s TIP instead was wrong: a PR branched before master
renumbered table 60369 still has `table 60369` in its tree, master's tip does
not, so the PR was reported as claiming 60369 although it never touched that
table, and every other open PR failed against it.

The comparison runs in whichever PR's CI fires, so the collision is reported on
the PR itself within seconds of opening, on both PRs, and neither can merge
until one of them renumbers.

Contained PRs
-------------
Two PRs do not collide when the head commit of one is an ancestor of the
other's head. Then the other PR already contains the first (a merge train, a
stacked PR), so the shared ids are the same objects. The check uses
`git merge-base --is-ancestor` on the pull/N/head refs it already fetches.

Modes
-----
  PR_NUMBER set   -- compare that PR against every other open PR (the CI case).
  PR_NUMBER unset -- compare every open PR against every other, pairwise. This
                     is what a push to `master` runs, so a collision that only
                     became reachable when master moved is still reported.

Requires GITHUB_TOKEN with `pull-requests: read`, GITHUB_REPOSITORY, and a
checkout deep enough to hold `master` (`fetch-depth: 0`).

Limitations, stated rather than hidden
--------------------------------------
* Draft PRs are included. A draft still claims ids and still merges eventually;
  excluding them would put the hole back for exactly the branches most likely to
  sit open long enough to collide.
* An abandoned-but-open PR blocks new PRs from reusing its ids. That is the
  intended direction of the tradeoff -- close the PR and the block lifts.
* Preprocessor branches are not interpreted, same as the sibling script.

What this does NOT close
------------------------
A PR whose checks last ran before the colliding PR existed, and which never
pushes again, can still merge on a stale green -- GitHub does not re-run checks
on open PRs when master moves, and "require branches to be up to date" is off
here on purpose. The pairwise sweep on push to master reports that case, but
only as an annotation on the master run; nothing blocks the stale PR.

Closing it completely needs one of: turning the up-to-date requirement back on
(which serializes the queue again, the thing this replaced), or a job on push
to master that re-dispatches checks on every open PR. Until then, a PR that has
been open across several master merges is worth re-running before merging it.
"""
import importlib.util
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from collections import defaultdict
from itertools import combinations
from pathlib import Path

HERE = Path(__file__).resolve().parent

# The declaration regex and the list of id-bearing object kinds have exactly one
# definition, in the sibling script. Duplicating them here would guarantee they
# drift apart the first time a new AL object kind appears.
_spec = importlib.util.spec_from_file_location(
    "check_object_ids", HERE / "check-object-ids.py")
_sib = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_sib)
DECL, ID_BEARING = _sib.DECL, _sib.ID_BEARING

API = "https://api.github.com"

# A POSIX ERE prefilter for `git grep`, which cannot read Python named groups.
# It only has to be no NARROWER than DECL -- every line it yields is re-parsed
# with DECL below, so a prefilter that is too broad costs nothing.
GREP_ERE = r"^(" + "|".join(ID_BEARING) + r")[[:space:]]+[0-9]+[[:space:]]"


def run(*args, check=True):
    p = subprocess.run(args, capture_output=True, text=True)
    if check and p.returncode != 0:
        sys.exit(f"::error::`{' '.join(args)}` failed: {p.stderr.strip()}")
    return p


def api(path):
    token = os.environ.get("GITHUB_TOKEN") or ""
    if not token:
        sys.exit("::error::GITHUB_TOKEN is not set — cannot list open pull "
                 "requests, refusing to pass vacuously")
    req = urllib.request.Request(
        f"{API}{path}",
        headers={"Authorization": f"Bearer {token}",
                 "Accept": "application/vnd.github+json",
                 "User-Agent": "check-cross-pr-object-ids"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"::error::GitHub API {path} returned {e.code}: {e.read()[:400]!r}")
    except urllib.error.URLError as e:
        sys.exit(f"::error::GitHub API {path} unreachable: {e.reason}")


def open_prs(repo):
    prs, page = [], 1
    while True:
        batch = api(f"/repos/{repo}/pulls?state=open&per_page=100&page={page}")
        if not batch:
            break
        prs += batch
        if len(batch) < 100:
            break
        page += 1
    return [{"number": p["number"], "sha": p["head"]["sha"],
             "title": p["title"], "author": (p["user"] or {}).get("login", "?"),
             "draft": bool(p.get("draft")), "ref": p["head"]["ref"]}
            for p in prs]


def decls_at(rev):
    """{(kind, id): [(path, lineno, name)]} for every AL declaration at `rev`.

    Reads the revision through `git grep`, which needs no checkout and no
    per-file subprocess. Output lines are `<rev>:<path>:<lineno>:<content>`;
    the rev prefix is known so it is stripped, and path is split off with
    maxsplit -- content may contain colons, paths in this repo do not.
    """
    p = run("git", "grep", "-I", "-n", "-E", GREP_ERE, rev, "--", "*.al",
            check=False)
    if p.returncode not in (0, 1):
        sys.exit(f"::error::git grep failed at {rev}: {p.stderr.strip()}")
    found = defaultdict(list)
    prefix = f"{rev}:"
    for line in p.stdout.splitlines():
        if not line.startswith(prefix):
            continue
        try:
            path, lineno, content = line[len(prefix):].split(":", 2)
        except ValueError:
            continue
        m = DECL.match(content)
        if not m:
            continue
        found[(m.group("kind"), int(m.group("id")))].append(
            (path, int(lineno), m.group("name").strip('"')))
    return found


_base_cache = {}


def base_decls(base, ref):
    """Set of (kind, id) declared at the merge base of `base` and `ref`."""
    p = run("git", "merge-base", base, ref, check=False)
    mb = p.stdout.strip()
    if p.returncode != 0 or not mb:
        sys.exit(f"::error::no merge base between {base} and {ref} — the checkout "
                 f"needs fetch-depth: 0")
    if mb not in _base_cache:
        _base_cache[mb] = set(decls_at(mb))
    return _base_cache[mb]


def fetch_pr(repo_unused, number, sha):
    ref = f"refs/remotes/xpr/{number}"
    run("git", "fetch", "--no-tags", "--quiet", "origin",
        f"refs/pull/{number}/head:{ref}", "--force")
    have = run("git", "rev-parse", ref).stdout.strip()
    if not have.startswith(sha[:8]) and not sha.startswith(have[:8]):
        print(f"::notice::PR #{number} moved while this ran "
              f"(API said {sha[:8]}, fetched {have[:8]}) — using the fetched head")
    return ref


def is_contained(ref_a, ref_b):
    """True when one head commit is an ancestor of (or equal to) the other."""
    def anc(x, y):
        return run("git", "merge-base", "--is-ancestor", x, y,
                   check=False).returncode == 0
    return anc(ref_a, ref_b) or anc(ref_b, ref_a)


def main() -> int:
    repo = os.environ.get("GITHUB_REPOSITORY")
    if not repo:
        sys.exit("::error::GITHUB_REPOSITORY is not set")

    base = os.environ.get("BASE_REF", "origin/master")
    if run("git", "rev-parse", "--verify", "--quiet", base, check=False).returncode != 0:
        sys.exit(f"::error::base revision {base!r} is not present — the checkout "
                 f"needs fetch-depth: 0")

    print(f"{base} @ {run('git','rev-parse','--short',base).stdout.strip()}")

    prs = open_prs(repo)
    if not prs:
        print("No open pull requests — nothing to cross-check.")
        return 0

    self_num = os.environ.get("PR_NUMBER", "").strip()
    self_num = int(self_num) if self_num.isdigit() else None
    if self_num is not None and not any(p["number"] == self_num for p in prs):
        print(f"::notice::PR #{self_num} is not in the open list (just merged or "
              f"closed?) — cross-checking every open PR pairwise instead")
        self_num = None

    # Ids each PR introduces on top of its merge base with master. Ids inherited
    # from the base -- including ones master renumbered after the PR branched --
    # are not claims.
    claimed = {}
    refs = {}
    for pr in prs:
        ref = fetch_pr(repo, pr["number"], pr["sha"])
        refs[pr["number"]] = ref
        base_ids = base_decls(base, ref)
        ids = decls_at(ref)
        claimed[pr["number"]] = {k: v for k, v in ids.items() if k not in base_ids}
        flag = " (draft)" if pr["draft"] else ""
        print(f"  PR #{pr['number']}{flag} [{pr['author']}] claims "
              f"{len(claimed[pr['number']])} new id(s)  — {pr['title'][:64]}")

    by_num = {p["number"]: p for p in prs}
    if self_num is not None:
        pairs = [(self_num, n) for n in claimed if n != self_num]
    else:
        pairs = list(combinations(sorted(claimed), 2))

    # A PR whose head commit is an ancestor of the other PR's head is CONTAINED
    # in it (a merge train, or a PR stacked on another): the shared ids are the
    # same objects, not two claims. Real clashes with PRs not contained stay.
    contained = [(a, b) for a, b in pairs if is_contained(refs[a], refs[b])]
    for a, b in contained:
        print(f"  PR #{a} and PR #{b}: one contains the other's head, "
              f"shared ids are the same objects — skipped")
    pairs = [p for p in pairs if p not in contained]

    collisions = []
    for a, b in pairs:
        for key in sorted(set(claimed[a]) & set(claimed[b])):
            collisions.append((a, b, key))

    if not collisions:
        scope = (f"PR #{self_num} against {len(claimed) - 1} other open PR(s)"
                 if self_num is not None
                 else f"all {len(claimed)} open PR(s) pairwise")
        print(f"OK — {scope}, no object id claimed twice.")
        return 0

    print("=" * 78)
    print("SAME AL OBJECT ID CLAIMED BY TWO OPEN PULL REQUESTS")
    print("=" * 78)
    print("Each PR passes its own compile, because neither compiles the other's")
    print("files. Merging both produces AL0297 on master. One of them must renumber.")
    print("IDs are namespaced per object type: a page and a table may share a number.")
    print()
    for a, b, (kind, obj_id) in collisions:
        print(f"  {kind} {obj_id}")
        for num in (a, b):
            pr = by_num[num]
            print(f"      PR #{num} [{pr['author']}] {pr['ref']}")
            for path, lineno, name in claimed[num][(kind, obj_id)]:
                print(f"          {path}:{lineno}  \"{name}\"")
        print()
    for a, b, (kind, obj_id) in collisions:
        # In the CI case one side of the pair is this PR, so name only the other.
        # In the pairwise case neither side is "here" -- name both, or the
        # annotation points at an arbitrary one of the two.
        who = (f"open PR #{b if self_num == a else a}" if self_num in (a, b)
               else f"open PRs #{a} and #{b}")
        print(f"::error::{kind} id {obj_id} is claimed by {who} "
              f"— AL0297 once both merge; renumber one of them")
    return 1


if __name__ == "__main__":
    sys.exit(main())

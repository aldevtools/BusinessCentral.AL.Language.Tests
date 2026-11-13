#!/usr/bin/env python3
"""Self-test for check-cross-pr-object-ids.py, run in CI alongside it.

The cross-PR check can only exercise its interesting path when two open pull
requests actually collide, which is rare and cannot be arranged on demand. Left
untested it would sit in CI for months reporting "no collisions" whether or not
it still worked -- the shape of a check that has quietly stopped checking.

So this builds a throwaway git repository with a known collision and asserts
the real detection code reports it, plus the ways it must NOT fire (including a PR
branched before master renumbered an object).
No network, no token, about a second.
"""
import importlib.util
import os
import contextlib
import io
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "xpr", HERE / "check-cross-pr-object-ids.py")
xpr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(xpr)

APP_JSON = '{"id":"a","name":"T","publisher":"p","version":"1.0.0.0",' \
           '"idRanges":[{"from":60000,"to":62000}]}'


def git(*a, cwd):
    p = subprocess.run(("git",) + a, cwd=cwd, capture_output=True, text=True)
    if p.returncode:
        sys.exit(f"setup failed: git {' '.join(a)}\n{p.stderr}")
    return p.stdout


def obj(kind, oid, name):
    return f'{kind} {oid} "{name}"\n{{\n}}\n'


def build(root: Path):
    """master + three branches: A, B (collides with A), C (same number, other type)."""
    git("init", "-q", "-b", "master", cwd=root)
    git("config", "user.email", "t@t", cwd=root)
    git("config", "user.name", "t", cwd=root)
    (root / "app.json").write_text(APP_JSON)
    # An id that master already owns. Both PRs will also contain it, inherited --
    # it must NOT count as a claim by either.
    (root / "Inherited.al").write_text(obj("codeunit", 60001, "Inherited"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "master", cwd=root)

    for branch, files in {
        "A": {"A1.al": obj("codeunit", 61500, "Collide A"),
              "A2.al": obj("codeunit", 61501, "Unique A")},
        "B": {"B1.al": obj("codeunit", 61500, "Collide B")},
        # Same NUMBER as A's codeunit but a different object type. AL namespaces
        # ids per type, so this is legal and must not be reported.
        "C": {"C1.al": obj("page", 61500, "Page Not A Clash")},
    }.items():
        git("checkout", "-q", "-B", branch, "master", cwd=root)
        for name, body in files.items():
            (root / name).write_text(body)
        git("add", "-A", cwd=root)
        git("commit", "-qm", branch, cwd=root)

    # The stale-base case (outside PR #1132): "S" branches from master while
    # master still declares table 60369, touches an unrelated file, and then
    # master renumbers 60369 to 60370. S's tree still says `table 60369`, which
    # master's tip no longer has -- but S never added it, so it is not a claim.
    git("checkout", "-q", "master", cwd=root)
    (root / "Renumbered.al").write_text(obj("table", 60369, "Renumbered"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "master: add table 60369", cwd=root)
    git("checkout", "-q", "-B", "S", "master", cwd=root)
    (root / "S1.al").write_text(obj("codeunit", 61700, "Stale Unrelated"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "S", cwd=root)
    git("checkout", "-q", "master", cwd=root)
    (root / "Renumbered.al").write_text(obj("table", 60370, "Renumbered"))
    git("commit", "-qam", "master: renumber table 60369 -> 60370", cwd=root)
    # "N" is based on the NEW master and reuses the freed id 60369 for a new
    # table. Against S that must still pass: S does not claim 60369. (If both
    # merged, master's renumber wins in S's merge commit; the single-tree check
    # covers anything else.)
    git("checkout", "-q", "-B", "N", "master", cwd=root)
    (root / "N1.al").write_text(obj("table", 60369, "New Reuse"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "N", cwd=root)
    # "D" is also stale-based (same base as S) and adds a NEW id that "E", based
    # on the new master, adds too. A real clash, whatever the bases.
    git("checkout", "-q", "-B", "D", "S~1", cwd=root)
    (root / "D1.al").write_text(obj("codeunit", 61800, "Dup D"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "D", cwd=root)
    git("checkout", "-q", "-B", "E", "master", cwd=root)
    (root / "E1.al").write_text(obj("codeunit", 61800, "Dup E"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "E", cwd=root)
    git("checkout", "-q", "master", cwd=root)
    # "T" is a train: it merges A (head contained) and adds its own object.
    git("checkout", "-q", "-B", "T", "A", cwd=root)
    (root / "T1.al").write_text(obj("codeunit", 61900, "Train Own"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "T", cwd=root)
    git("checkout", "-q", "master", cwd=root)


def run_check(root: Path, refs: dict, pr_number: str) -> tuple[int, str]:
    """Invoke the real main() with the GitHub API and fetch stubbed out.

    Returns (exit code, captured stdout). See the capture note below.
    """
    prs = [{"number": n, "sha": "0" * 40, "title": f"branch {r}",
            "author": "t", "draft": False, "ref": r} for n, r in refs.items()]
    saved_open, saved_fetch = xpr.open_prs, xpr.fetch_pr
    xpr.open_prs = lambda repo: prs
    xpr.fetch_pr = lambda repo, number, sha: refs[number]
    cwd = os.getcwd()
    try:
        os.chdir(root)
        os.environ["GITHUB_REPOSITORY"] = "o/r"
        os.environ["BASE_REF"] = "master"
        os.environ["PR_NUMBER"] = pr_number
        # Capture rather than pass through. The detector reports a collision with
        # `::error::`, which is a GitHub workflow COMMAND, not just text: every fixture
        # collision this self-test deliberately provokes was being hoisted into the run
        # summary as a real object-id conflict against PRs #1 and #2, on runs where the
        # actual check passed. The output is still printed on an unexpected result below,
        # with the `::` prefixes defanged so a genuine self-test failure stays readable
        # without re-entering the annotation channel.
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = xpr.main()
        return code, buf.getvalue()
    finally:
        os.chdir(cwd)
        xpr.open_prs, xpr.fetch_pr = saved_open, saved_fetch


def main() -> int:
    failures = []
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        build(root)

        cases = [
            # label,                                  refs,                    PR_NUMBER, expected
            ("collision is reported on the PR's own run",
             {1: "A", 2: "B"}, "1", 1),
            ("collision is reported from the other side too",
             {1: "A", 2: "B"}, "2", 1),
            ("collision is reported by the pairwise sweep",
             {1: "A", 2: "B"}, "", 1),
            ("same number, different object type is NOT a collision",
             {1: "A", 2: "C"}, "1", 0),
            ("an id inherited from master is NOT a claim",
             {1: "B", 2: "C"}, "1", 0),
            # A train contains A's head: A's ids inside the train are the same objects.
            ("a PR does NOT collide with an open PR whose head it contains",
             {1: "A", 2: "T"}, "2", 0),
            ("contained PR is skipped from the other side too",
             {1: "A", 2: "T"}, "1", 0),
            ("contained PR is skipped by the pairwise sweep",
             {1: "A", 2: "T"}, "", 0),
            ("a PR that is NOT contained still collides with the train",
             {1: "B", 2: "T"}, "2", 1),
            ("a lone open PR has nothing to collide with",
             {1: "A"}, "1", 0),
            # The #1132 incident: two PRs on the same old base both still declare
            # table 60369, which master later renumbered. Neither added it.
            ("two stale-based PRs do NOT claim an id master later renumbered",
             {1: "S", 2: "D"}, "2", 0),
            ("stale-based PR vs a PR reusing the freed id is NOT a collision",
             {1: "S", 2: "N"}, "2", 0),
            ("stale-based sweep stays clean",
             {1: "S", 2: "N", 3: "B"}, "", 0),
            ("two PRs adding the same new id clash across different bases",
             {1: "D", 2: "E"}, "2", 1),
            ("same-new-id clash is reported by the pairwise sweep",
             {1: "D", 2: "E", 3: "S"}, "", 1),
        ]
        for label, refs, pr, expected in cases:
            print(f"\n--- {label} (expect exit {expected}) ---")
            got, out = run_check(root, refs, pr)
            if got != expected:
                defanged = out.replace("::", "__")
                failures.append(f"{label}: expected exit {expected}, got {got}\n{defanged}")

    print("\n" + "=" * 78)
    if failures:
        for f in failures:
            print(f"::error::self-test FAILED — {f}")
        return 1
    print(f"self-test OK — {len(cases)} cases, detection and all "
          f"must-not-fire cases behave as specified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

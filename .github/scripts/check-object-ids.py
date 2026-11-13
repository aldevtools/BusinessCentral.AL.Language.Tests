#!/usr/bin/env python3
"""Fail the build when two AL objects of the same type share an ID, or when an
object's ID falls outside its app's declared idRanges.

Why this exists
---------------
Object IDs must be unique per object type across every app installed together,
and the AL compiler enforces that (AL0297) -- but only for the set of files it
is compiling at once. Two pull requests can each declare the SAME id, each
compile green in isolation, and break `master` the moment both are merged.
Neither PR's own CI can see the other.

That was previously caught only as a side effect of branch protection's
"require branches to be up to date" setting, which forced the second PR to be
rebased onto the first and recompiled. This check replaces that mechanism with
a direct one, so the collision is reported on the PR itself in seconds rather
than after a merge, and the up-to-date requirement is no longer load-bearing.

Two real near-misses that motivated it, both open at the same time:
  #113  codeunit 60909, page 60908
  #117  codeunit 60934, page 60909, table 60908
Those do NOT collide -- AL namespaces IDs per object type, so `page 60908` and
`table 60908` may coexist, as may `page 60909` and `codeunit 60909`. Checking
that by hand, per type, is exactly the error-prone step being automated here.

What counts as an object declaration
------------------------------------
A top-level `<type> <id> <name>` at the start of a line. Types that carry no
numeric ID (`interface`, `profile`, `controladdin`, `pagecustomization`,
`entitlement`) simply never match the pattern, so they need no special case.

Preprocessor branches are NOT interpreted. If an app ever declares the same
object twice under mutually exclusive `#if` branches, that is a legitimate
duplicate and this check would report it falsely -- at the time of writing no
file in the corpus does that (the only `#if` sits inside a codeunit body), and
the honest failure mode is a loud false positive rather than a silent miss.
"""
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

# Every AL object kind that carries a numeric ID. Kinds without one are absent
# on purpose -- see the module docstring.
ID_BEARING = (
    "table", "tableextension",
    "page", "pageextension",
    "report", "reportextension",
    "codeunit", "query", "xmlport",
    "enum", "enumextension",
    "permissionset", "permissionsetextension",
)

DECL = re.compile(
    r"^(?P<kind>" + "|".join(ID_BEARING) + r")\s+(?P<id>\d+)\s+(?P<name>\"[^\"]*\"|\S+)",
)


MOVED = re.compile(r"^\s*ObsoleteState\s*=\s*Moved\s*;", re.IGNORECASE)
FIELDS = re.compile(r"^\s*fields\b", re.IGNORECASE)


def is_moved_stub(lines, lineno):
    """True when the table declared on line `lineno` (1-based) has `ObsoleteState = Moved;` among its
    properties (before its `fields` block). A Moved stub repeats the id and name of the live table of the
    app named by its MovedTo (Base Application's stubs of the tables that moved to Business Foundation),
    so it is not a duplicate id; its id must still lie in its own app's idRanges."""
    for line in lines[lineno:]:
        if FIELDS.match(line) or DECL.match(line):
            return False
        if MOVED.match(line):
            return True
    return False


def app_dirs(root: Path):
    """Every directory holding an app.json, with its declared idRanges."""
    for manifest in sorted(root.rglob("app.json")):
        if ".git" in manifest.parts:
            continue
        try:
            data = json.loads(manifest.read_text(encoding="utf-8-sig"))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"::error file={manifest}::app.json could not be read: {exc}")
            continue
        ranges = [
            (int(r["from"]), int(r["to"]))
            for r in (data.get("idRanges") or [])
            if "from" in r and "to" in r
        ]
        yield manifest.parent, data.get("name") or str(manifest.parent), ranges


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    apps = list(app_dirs(root))
    if not apps:
        print(f"::error::no app.json found under {root} — nothing to check, refusing to pass vacuously")
        return 1

    # (kind, id) -> list of (relative path, line number, name, app name)
    seen = defaultdict(list)
    out_of_range = []
    total = 0

    for app_dir, app_name, ranges in apps:
        for al in sorted(app_dir.rglob("*.al")):
            try:
                text = al.read_text(encoding="utf-8-sig", errors="replace")
            except OSError as exc:
                print(f"::error file={al}::could not be read: {exc}")
                return 1
            lines = text.splitlines()
            for lineno, line in enumerate(lines, start=1):
                m = DECL.match(line)
                if not m:
                    continue
                total += 1
                kind = m.group("kind")
                obj_id = int(m.group("id"))
                name = m.group("name").strip('"')
                rel = al.relative_to(root)
                if not (kind == "table" and is_moved_stub(lines, lineno)):
                    seen[(kind, obj_id)].append((rel, lineno, name, app_name))
                if ranges and not any(lo <= obj_id <= hi for lo, hi in ranges):
                    pretty = ", ".join(f"{lo}..{hi}" for lo, hi in ranges)
                    out_of_range.append((rel, lineno, kind, obj_id, name, app_name, pretty))

    dupes = {k: v for k, v in seen.items() if len(v) > 1}

    if not dupes and not out_of_range:
        print(f"OK — {total} id-bearing AL objects across {len(apps)} app(s), "
              f"no duplicate ids, all within their declared idRanges.")
        return 0

    if dupes:
        print("=" * 78)
        print("DUPLICATE AL OBJECT IDs")
        print("=" * 78)
        print("Two objects of the same type share an ID. The AL compiler rejects this")
        print("as AL0297 when both are compiled together, so this WILL break master.")
        print("IDs are namespaced per object type: a page and a table may share a number.")
        print()
        for (kind, obj_id), sites in sorted(dupes.items()):
            print(f"  {kind} {obj_id} is declared {len(sites)} times:")
            for rel, lineno, name, app_name in sites:
                print(f"      {rel}:{lineno}  \"{name}\"   [{app_name}]")
            print()
        for (kind, obj_id), sites in sorted(dupes.items()):
            first = sites[0]
            print(f"::error file={first[0]},line={first[1]}::duplicate {kind} id {obj_id} "
                  f"({len(sites)} declarations) — AL0297 when compiled together")

    if out_of_range:
        print("=" * 78)
        print("AL OBJECT IDs OUTSIDE THEIR APP'S DECLARED idRanges")
        print("=" * 78)
        print("app.json's idRanges is authoritative. An object outside it is rejected")
        print("at compile time and can also collide with a range another app owns.")
        print()
        for rel, lineno, kind, obj_id, name, app_name, pretty in sorted(out_of_range):
            print(f"  {rel}:{lineno}  {kind} {obj_id} \"{name}\"")
            print(f"      app \"{app_name}\" declares idRanges {pretty}")
            print()
        for rel, lineno, kind, obj_id, name, app_name, pretty in sorted(out_of_range):
            print(f"::error file={rel},line={lineno}::{kind} id {obj_id} is outside "
                  f"\"{app_name}\"'s declared idRanges ({pretty})")

    return 1


if __name__ == "__main__":
    sys.exit(main())
